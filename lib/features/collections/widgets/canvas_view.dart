import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/canvas_repository.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/models/canvas_connection.dart';
import '../../../shared/models/canvas_item.dart';
import '../providers/canvas_provider.dart';
import 'canvas_connection_painter.dart';
import 'canvas_context_menu.dart';
import 'canvas_game_card.dart';
import 'canvas_image_item.dart';
import 'canvas_media_card.dart';
import 'canvas_link_item.dart';
import 'canvas_text_item.dart';
import 'dialogs/add_image_dialog.dart';
import 'dialogs/add_link_dialog.dart';
import 'dialogs/add_text_dialog.dart';
import 'dialogs/edit_connection_dialog.dart';
import '../providers/steamgriddb_panel_provider.dart';
import '../providers/vgmaps_panel_provider.dart';

// Виджет канваса для визуального размещения элементов коллекции.
//
// Поддерживает зум (0.3x–3.0x), панорамирование и перетаскивание элементов.
// Канвас расширяется автоматически под контент. Элементы размещаются
// по центру канваса, чтобы можно было перемещать их во все стороны.
class CanvasView extends ConsumerStatefulWidget {
  /// Создаёт [CanvasView].
  const CanvasView({
    required this.collectionId,
    required this.isEditable,
    this.collectionItemId,
    super.key,
  });

  /// ID коллекции.
  final int collectionId;

  /// Можно ли редактировать (перемещать элементы).
  final bool isEditable;

  /// ID элемента коллекции для per-game canvas.
  ///
  /// Если задан, используется [gameCanvasNotifierProvider] вместо
  /// [canvasNotifierProvider]. Game canvas независим от коллекционного.
  final int? collectionItemId;

  @override
  ConsumerState<CanvasView> createState() => _CanvasViewState();
}

class _CanvasViewState extends ConsumerState<CanvasView> {
  final TransformationController _transformationController =
      TransformationController();

  final FocusNode _focusNode = FocusNode();

  /// Является ли это per-game canvas.
  bool get _isGameCanvas => widget.collectionItemId != null;

  /// Аргумент для [gameCanvasNotifierProvider].
  ({int collectionId, int collectionItemId}) get _gameCanvasArg => (
        collectionId: widget.collectionId,
        collectionItemId: widget.collectionItemId!,
      );

  /// Смотрит за состоянием нужного canvas.
  CanvasState _watchCanvasState() {
    if (_isGameCanvas) {
      return ref.watch(gameCanvasNotifierProvider(_gameCanvasArg));
    }
    return ref.watch(canvasNotifierProvider(widget.collectionId));
  }

  /// Читает нотификатор нужного canvas.
  BaseCanvasController _readNotifier() {
    if (_isGameCanvas) {
      return ref.read(
        gameCanvasNotifierProvider(_gameCanvasArg).notifier,
      );
    }
    return ref.read(
      canvasNotifierProvider(widget.collectionId).notifier,
    );
  }

  /// Минимальный зум.
  static const double _minScale = 0.3;

  /// Максимальный зум.
  static const double _maxScale = 3.0;

  /// Минимальный размер канваса.
  static const double _minCanvasSize = 5000.0;

  /// Буфер за последним элементом.
  static const double _canvasBuffer = 1000.0;

  /// Флаг: начальное центрирование вида уже выполнено.
  bool _hasScrolledToItems = false;

  /// Флаг: элемент перетаскивается (блокирует пан InteractiveViewer).
  bool _isItemDragging = false;

  /// Текущие drag-смещения элементов для обновления связей в реальном времени.
  ///
  /// Используем ValueNotifier вместо setState, чтобы при перетаскивании
  /// перестраивался только ConnectionPainter, а не все элементы канваса.
  final ValueNotifier<Map<int, Offset>> _dragOffsetsNotifier =
      ValueNotifier<Map<int, Offset>>(const <int, Offset>{});

  /// Позиция мыши на канвасе (для временной линии связи).
  Offset? _mouseCanvasPosition;

  void _onItemDragStateChanged({required bool isDragging}) {
    setState(() {
      _isItemDragging = isDragging;
    });
    if (!isDragging) {
      _dragOffsetsNotifier.value = const <int, Offset>{};
    }
  }

  void _onItemDragUpdate(int itemId, Offset delta) {
    _dragOffsetsNotifier.value = <int, Offset>{
      ..._dragOffsetsNotifier.value,
      itemId: delta,
    };
  }

  /// Обработчик клавиши Escape для отмены создания связи.
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      final CanvasState canvasState = _watchCanvasState();
      if (canvasState.connectingFromId != null) {
        _readNotifier().cancelConnection();
        setState(() => _mouseCanvasPosition = null);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _dragOffsetsNotifier.dispose();
    _transformationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Отступ вокруг контента при zoom-to-fit (в пикселях viewport).
  static const double _fitPadding = 32;

  /// Центрирует вид на элементах канваса с автоподгонкой масштаба.
  ///
  /// На мобильных устройствах контент масштабируется так, чтобы все элементы
  /// помещались в viewport с отступами. На десктопе масштаб не уменьшается
  /// ниже 1.0, чтобы не делать элементы мельче чем нужно.
  void _centerViewOnItems(
    double viewportWidth,
    double viewportHeight,
    List<CanvasItem> items,
  ) {
    if (items.isEmpty) return;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final CanvasItem item in items) {
      if (item.x < minX) minX = item.x;
      if (item.y < minY) minY = item.y;
      final double right =
          item.x + (item.width ?? CanvasRepository.defaultCardWidth);
      final double bottom =
          item.y + (item.height ?? CanvasRepository.defaultCardHeight);
      if (right > maxX) maxX = right;
      if (bottom > maxY) maxY = bottom;
    }

    final double contentWidth = maxX - minX;
    final double contentHeight = maxY - minY;
    final double contentCenterX = (minX + maxX) / 2;
    final double contentCenterY = (minY + maxY) / 2;

    // Вычисляем масштаб, чтобы контент поместился в viewport с отступами.
    final double availableWidth = viewportWidth - _fitPadding * 2;
    final double availableHeight = viewportHeight - _fitPadding * 2;
    double scale = 1.0;
    if (contentWidth > 0 && contentHeight > 0) {
      final double scaleX = availableWidth / contentWidth;
      final double scaleY = availableHeight / contentHeight;
      scale = scaleX < scaleY ? scaleX : scaleY;
    }

    // На десктопе не уменьшаем ниже 1.0, на мобильных — ограничиваем
    // минимальным масштабом InteractiveViewer.
    final bool isMobile = Platform.isAndroid || Platform.isIOS;
    final double minFitScale = isMobile ? _minScale : 1.0;
    scale = scale.clamp(minFitScale, _maxScale);

    _transformationController.value = Matrix4.identity()
      ..scaleByDouble(scale, scale, 1.0, 1.0)
      ..translateByDouble(
        (viewportWidth / scale) / 2 - contentCenterX,
        (viewportHeight / scale) / 2 - contentCenterY,
        0.0,
        1.0,
      );
  }

  /// Обрабатывает ПКМ на пустом месте канваса.
  void _onCanvasSecondaryTap(
    Offset globalPosition,
    Offset localPosition,
  ) {
    // localPosition уже в координатах канваса (внутри InteractiveViewer)
    final double canvasX = localPosition.dx;
    final double canvasY = localPosition.dy;

    CanvasContextMenu.showCanvasMenu(
      context,
      position: globalPosition,
      onAddText: () => _handleAddText(canvasX, canvasY),
      onAddImage: () => _handleAddImage(canvasX, canvasY),
      onAddLink: () => _handleAddLink(canvasX, canvasY),
      onFindImages: widget.isEditable
          ? () {
              ref
                  .read(vgMapsPanelProvider(widget.collectionId).notifier)
                  .closePanel();
              ref
                  .read(
                      steamGridDbPanelProvider(widget.collectionId).notifier)
                  .openPanel();
            }
          : null,
      onBrowseMaps: widget.isEditable && kVgMapsEnabled
          ? () {
              ref
                  .read(
                      steamGridDbPanelProvider(widget.collectionId).notifier)
                  .closePanel();
              ref
                  .read(vgMapsPanelProvider(widget.collectionId).notifier)
                  .openPanel();
            }
          : null,
    );
  }

  /// Обрабатывает ПКМ на элементе канваса.
  void _onItemSecondaryTap(
    Offset globalPosition,
    CanvasItem item,
  ) {
    final BaseCanvasController notifier = _readNotifier();

    CanvasContextMenu.showItemMenu(
      context,
      position: globalPosition,
      itemType: item.itemType,
      onEdit: () => _handleEditItem(item),
      onDelete: () => notifier.deleteItem(item.id),
      onBringToFront: () => notifier.bringToFront(item.id),
      onSendToBack: () => notifier.sendToBack(item.id),
      onConnect: () {
        notifier.startConnection(item.id);
        _focusNode.requestFocus();
      },
    );
  }

  /// Добавляет текстовый блок на канвас.
  Future<void> _handleAddText(double x, double y) async {
    final Map<String, dynamic>? result = await AddTextDialog.show(context);
    if (result == null) return;
    if (!mounted) return;

    _readNotifier().addTextItem(
      x,
      y,
      result['content'] as String,
      (result['fontSize'] as num).toDouble(),
    );
  }

  /// Добавляет изображение на канвас.
  Future<void> _handleAddImage(double x, double y) async {
    final Map<String, dynamic>? result = await AddImageDialog.show(context);
    if (result == null) return;
    if (!mounted) return;

    _readNotifier().addImageItem(x, y, result);
  }

  /// Добавляет ссылку на канвас.
  Future<void> _handleAddLink(double x, double y) async {
    final Map<String, dynamic>? result = await AddLinkDialog.show(context);
    if (result == null) return;
    if (!mounted) return;

    _readNotifier().addLinkItem(
      x,
      y,
      result['url'] as String,
      result['label'] as String,
    );
  }

  /// Редактирует элемент через соответствующий диалог.
  Future<void> _handleEditItem(CanvasItem item) async {
    switch (item.itemType) {
      case CanvasItemType.text:
        await _editTextItem(item);
      case CanvasItemType.image:
        await _editImageItem(item);
      case CanvasItemType.link:
        await _editLinkItem(item);
      case CanvasItemType.game:
      case CanvasItemType.movie:
      case CanvasItemType.tvShow:
      case CanvasItemType.animation:
        break; // Медиа-элементы не редактируются через контекстное меню
    }
  }

  /// Редактирует текстовый блок.
  Future<void> _editTextItem(CanvasItem item) async {
    final Map<String, dynamic>? result = await AddTextDialog.show(
      context,
      initialContent: item.data?['content'] as String?,
      initialFontSize: (item.data?['fontSize'] as num?)?.toDouble(),
    );
    if (result == null) return;
    if (!mounted) return;

    _readNotifier().updateItemData(item.id, result);
  }

  /// Редактирует изображение.
  Future<void> _editImageItem(CanvasItem item) async {
    final Map<String, dynamic>? result = await AddImageDialog.show(
      context,
      initialUrl: item.data?['url'] as String?,
    );
    if (result == null) return;
    if (!mounted) return;

    _readNotifier().updateItemData(item.id, result);
  }

  /// Редактирует ссылку.
  Future<void> _editLinkItem(CanvasItem item) async {
    final Map<String, dynamic>? result = await AddLinkDialog.show(
      context,
      initialUrl: item.data?['url'] as String?,
      initialLabel: item.data?['label'] as String?,
    );
    if (result == null) return;
    if (!mounted) return;

    _readNotifier().updateItemData(item.id, result);
  }

  /// Обрабатывает ПКМ на пустом месте с проверкой hit-test на связи.
  void _onCanvasSecondaryTapWithConnections(
    Offset globalPosition,
    Offset localPosition,
    CanvasState canvasState,
  ) {
    // Сначала проверяем, не попали ли мы по связи
    final CanvasConnectionPainter painter = CanvasConnectionPainter(
      connections: canvasState.connections,
      items: canvasState.items,
    );

    final int? connectionId = painter.hitTestConnection(localPosition);
    if (connectionId != null) {
      _showConnectionContextMenu(globalPosition, connectionId, canvasState);
      return;
    }

    // Иначе показываем стандартное меню канваса
    _onCanvasSecondaryTap(globalPosition, localPosition);
  }

  /// Показывает контекстное меню связи.
  void _showConnectionContextMenu(
    Offset globalPosition,
    int connectionId,
    CanvasState canvasState,
  ) {
    CanvasContextMenu.showConnectionMenu(
      context,
      position: globalPosition,
      onEdit: () => _handleEditConnection(connectionId, canvasState),
      onDelete: () {
        _readNotifier().deleteConnection(connectionId);
      },
    );
  }

  /// Открывает диалог редактирования связи.
  Future<void> _handleEditConnection(
    int connectionId,
    CanvasState canvasState,
  ) async {
    final CanvasConnection? conn = canvasState.connections
        .where((CanvasConnection c) => c.id == connectionId)
        .firstOrNull;
    if (conn == null) return;

    final Map<String, dynamic>? result = await EditConnectionDialog.show(
      context,
      initialLabel: conn.label,
      initialColor: conn.color,
      initialStyle: conn.style,
    );
    if (result == null) return;
    if (!mounted) return;

    _readNotifier().updateConnection(
      connectionId,
          label: result['label'] as String?,
          color: result['color'] as String?,
          style: result['style'] != null
              ? ConnectionStyle.fromString(result['style'] as String)
              : null,
        );
  }

  /// Обрабатывает клик в режиме создания связи.
  void _handleConnectionModeClick(CanvasItem item) {
    _readNotifier().completeConnection(item.id);
    setState(() => _mouseCanvasPosition = null);
  }

  @override
  Widget build(BuildContext context) {
    final CanvasState canvasState = _watchCanvasState();
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    if (canvasState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (canvasState.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.error_outline,
              size: 48,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load board',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _readNotifier().refresh();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (canvasState.items.isEmpty) {
      final Widget emptyContent = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.dashboard_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Board is empty',
              style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add items to the collection first',
              style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );

      // Позволяем добавлять элементы через ПКМ или long press на пустом board
      if (widget.isEditable) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onSecondaryTapUp: (TapUpDetails details) {
            _onCanvasSecondaryTap(
              details.globalPosition,
              details.localPosition,
            );
          },
          onLongPressStart: (LongPressStartDetails details) {
            _onCanvasSecondaryTap(
              details.globalPosition,
              details.localPosition,
            );
          },
          child: emptyContent,
        );
      }

      return emptyContent;
    }

    final List<CanvasItem> sortedItems =
        List<CanvasItem>.from(canvasState.items)
          ..sort(
              (CanvasItem a, CanvasItem b) => a.zIndex.compareTo(b.zIndex));

    // Размер канваса: подстраивается под контент
    double canvasWidth = _minCanvasSize;
    double canvasHeight = _minCanvasSize;
    for (final CanvasItem item in canvasState.items) {
      final double right = item.x +
          (item.width ?? CanvasRepository.defaultCardWidth) +
          _canvasBuffer;
      final double bottom = item.y +
          (item.height ?? CanvasRepository.defaultCardHeight) +
          _canvasBuffer;
      if (right > canvasWidth) canvasWidth = right;
      if (bottom > canvasHeight) canvasHeight = bottom;
    }

    final bool isConnecting = canvasState.connectingFromId != null;
    final CanvasItem? connectingFromItem = isConnecting
        ? canvasState.items
            .where(
                (CanvasItem i) => i.id == canvasState.connectingFromId)
            .firstOrNull
        : null;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double viewportWidth = constraints.maxWidth;
        final double viewportHeight = constraints.maxHeight;

        // При первой загрузке центрируем вид на элементах
        if (!_hasScrolledToItems && canvasState.isInitialized) {
          _hasScrolledToItems = true;
          SchedulerBinding.instance.addPostFrameCallback((_) {
            _centerViewOnItems(
              viewportWidth,
              viewportHeight,
              canvasState.items,
            );
          });
        }

        return Focus(
          focusNode: _focusNode,
          onKeyEvent: _handleKeyEvent,
          child: Stack(
            children: <Widget>[
              // Канвас с зумом и панорамированием
              InteractiveViewer(
                transformationController: _transformationController,
                constrained: false,
                panEnabled: !_isItemDragging,
                minScale: _minScale,
                maxScale: _maxScale,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onSecondaryTapUp: widget.isEditable
                      ? (TapUpDetails details) {
                          _onCanvasSecondaryTapWithConnections(
                            details.globalPosition,
                            details.localPosition,
                            canvasState,
                          );
                        }
                      : null,
                  onLongPressStart: widget.isEditable
                      ? (LongPressStartDetails details) {
                          _onCanvasSecondaryTapWithConnections(
                            details.globalPosition,
                            details.localPosition,
                            canvasState,
                          );
                        }
                      : null,
                  child: MouseRegion(
                    cursor: isConnecting
                        ? SystemMouseCursors.cell
                        : MouseCursor.defer,
                    onHover: isConnecting
                        ? (PointerEvent event) {
                            setState(() {
                              _mouseCanvasPosition = event.localPosition;
                            });
                          }
                        : null,
                    child: SizedBox(
                      width: canvasWidth,
                      height: canvasHeight,
                      child: CustomPaint(
                        painter: _CanvasGridPainter(
                          color: colorScheme.outlineVariant.withAlpha(60),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: <Widget>[
                            // Связи рисуются под элементами.
                            // ValueListenableBuilder изолирует перерисовку
                            // связей от остальных элементов канваса.
                            if (canvasState.connections.isNotEmpty ||
                                isConnecting)
                              Positioned.fill(
                                child: ValueListenableBuilder<Map<int, Offset>>(
                                  valueListenable: _dragOffsetsNotifier,
                                  builder: (
                                    BuildContext context,
                                    Map<int, Offset> dragOffsets,
                                    Widget? child,
                                  ) {
                                    return CustomPaint(
                                      painter: CanvasConnectionPainter(
                                        connections: canvasState.connections,
                                        items: canvasState.items,
                                        connectingFrom: connectingFromItem,
                                        mousePosition: _mouseCanvasPosition,
                                        labelStyle: TextStyle(
                                          fontSize: 11,
                                          color: colorScheme.onSurface,
                                        ),
                                        labelBackgroundColor:
                                            colorScheme.surfaceContainerLow
                                                .withAlpha(220),
                                        dragOffsets: dragOffsets,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            for (final CanvasItem item in sortedItems)
                              _buildCanvasItem(item, isConnecting),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // Кнопки управления (поверх канваса, фиксированы)
            Positioned(
              right: 16,
              bottom: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // VGMaps Browser (Windows only — requires webview_windows)
                  if (widget.isEditable && kVgMapsEnabled)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: FloatingActionButton.small(
                        heroTag: 'canvas_vgmaps',
                        onPressed: () {
                          // Закрываем SteamGridDB панель при открытии VGMaps
                          ref
                              .read(steamGridDbPanelProvider(
                                      widget.collectionId)
                                  .notifier)
                              .closePanel();
                          ref
                              .read(vgMapsPanelProvider(
                                      widget.collectionId)
                                  .notifier)
                              .togglePanel();
                        },
                        tooltip: 'VGMaps Browser',
                        child: const Icon(Icons.map),
                      ),
                    ),
                  // Поиск изображений SteamGridDB
                  if (widget.isEditable)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: FloatingActionButton.small(
                        heroTag: 'canvas_steamgriddb',
                        onPressed: () {
                          // Закрываем VGMaps панель при открытии SteamGridDB
                          ref
                              .read(vgMapsPanelProvider(
                                      widget.collectionId)
                                  .notifier)
                              .closePanel();
                          ref
                              .read(steamGridDbPanelProvider(
                                      widget.collectionId)
                                  .notifier)
                              .togglePanel();
                        },
                        tooltip: 'SteamGridDB Images',
                        child: const Icon(Icons.image_search),
                      ),
                    ),
                  // Центрировать вид на элементах
                  FloatingActionButton.small(
                    heroTag: 'canvas_reset_view',
                    onPressed: () {
                      _centerViewOnItems(
                        viewportWidth,
                        viewportHeight,
                        canvasState.items,
                      );
                    },
                    tooltip: 'Center view',
                    child: const Icon(Icons.fit_screen),
                  ),
                  const SizedBox(height: 8),
                  // Сброс позиций всех элементов в сетку
                  FloatingActionButton.small(
                    heroTag: 'canvas_reset_positions',
                    onPressed: () {
                      _readNotifier().resetPositions(viewportWidth);
                      // Центрируем вид после сброса
                      SchedulerBinding.instance.addPostFrameCallback((_) {
                        final List<CanvasItem> items =
                            _watchCanvasState().items;
                        _centerViewOnItems(
                          viewportWidth,
                          viewportHeight,
                          items,
                        );
                      });
                    },
                    tooltip: 'Reset positions',
                    child: const Icon(Icons.grid_view),
                  ),
                ],
              ),
            ),
            // Индикатор режима создания связи
            if (isConnecting)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Material(
                  color: colorScheme.primaryContainer.withAlpha(230),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.timeline,
                          size: 18,
                          color: colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tap an element to create a connection.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            size: 18,
                            color: colorScheme.onPrimaryContainer,
                          ),
                          onPressed: () {
                            _readNotifier().cancelConnection();
                            setState(
                                () => _mouseCanvasPosition = null);
                          },
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
          ),
        );
      },
    );
  }

  Widget _buildCanvasItem(CanvasItem item, bool isConnecting) {
    final Widget child;
    switch (item.itemType) {
      case CanvasItemType.game:
        child = CanvasGameCard(item: item);
      case CanvasItemType.movie:
      case CanvasItemType.tvShow:
      case CanvasItemType.animation:
        child = CanvasMediaCard(item: item);
      case CanvasItemType.text:
        child = CanvasTextItem(item: item);
      case CanvasItemType.image:
        child = CanvasImageItem(item: item);
      case CanvasItemType.link:
        child = CanvasLinkItem(item: item);
    }

    return _DraggableCanvasItem(
      key: ValueKey<int>(item.id),
      item: item,
      isEditable: widget.isEditable,
      collectionId: widget.collectionId,
      collectionItemId: widget.collectionItemId,
      transformationController: _transformationController,
      onDragStateChanged: _onItemDragStateChanged,
      onDragUpdate: _onItemDragUpdate,
      onSecondaryTap: widget.isEditable ? _onItemSecondaryTap : null,
      onTap: isConnecting
          ? () => _handleConnectionModeClick(item)
          : null,
      child: child,
    );
  }
}

/// Обёртка для перетаскиваемых элементов канваса.
///
/// Позиция и размер обновляются через [setState] напрямую в [Positioned],
/// обеспечивая визуальную обратную связь в реальном времени при drag и resize.
///
/// Используется абсолютное отслеживание позиции (globalPosition)
/// вместо накопления инкрементальных дельт. При старте drag
/// InteractiveViewer отключает пан через callback, чтобы избежать
/// двойного смещения.
class _DraggableCanvasItem extends ConsumerStatefulWidget {
  const _DraggableCanvasItem({
    required this.item,
    required this.isEditable,
    required this.collectionId,
    required this.transformationController,
    required this.onDragStateChanged,
    required this.onDragUpdate,
    required this.child,
    this.collectionItemId,
    this.onSecondaryTap,
    this.onTap,
    super.key,
  });

  final CanvasItem item;
  final bool isEditable;
  final int collectionId;
  final int? collectionItemId;
  final TransformationController transformationController;

  /// Callback для уведомления родителя о начале/конце drag.
  final void Function({required bool isDragging}) onDragStateChanged;

  /// Callback для обновления drag-смещения (для связей).
  final void Function(int itemId, Offset delta) onDragUpdate;

  /// Callback для ПКМ или long press на элементе (контекстное меню).
  final void Function(Offset globalPosition, CanvasItem item)? onSecondaryTap;

  /// Callback для клика (используется в режиме создания связи).
  final VoidCallback? onTap;

  final Widget child;

  @override
  ConsumerState<_DraggableCanvasItem> createState() =>
      _DraggableCanvasItemState();
}

class _DraggableCanvasItemState extends ConsumerState<_DraggableCanvasItem> {
  BaseCanvasController _readNotifier() {
    if (widget.collectionItemId != null) {
      return ref.read(
        gameCanvasNotifierProvider((
          collectionId: widget.collectionId,
          collectionItemId: widget.collectionItemId!,
        )).notifier,
      );
    }
    return ref.read(
      canvasNotifierProvider(widget.collectionId).notifier,
    );
  }

  Offset _dragDelta = Offset.zero;
  bool _isDragging = false;

  /// ValueNotifier для drag offset — обновляет только Transform.translate,
  /// без перестройки всего виджета (setState не нужен при перетаскивании).
  final ValueNotifier<Offset> _dragNotifier =
      ValueNotifier<Offset>(Offset.zero);

  /// Глобальная позиция указателя при старте перетаскивания.
  Offset _panStartGlobal = Offset.zero;

  /// Флаг: элемент ресайзится.
  bool _isResizing = false;

  /// Стартовые размеры при ресайзе.
  double _resizeStartWidth = 0;
  double _resizeStartHeight = 0;

  /// Текущие дельты ресайза.
  Offset _resizeDelta = Offset.zero;

  /// Минимальный размер элемента.
  static const double _minItemSize = 50;

  /// Максимальный размер элемента.
  static const double _maxItemSize = 2000;

  /// Размер resize handle (больше на мобильных для удобства тач-ввода).
  static final double _handleSize =
      (Platform.isAndroid || Platform.isIOS) ? 24 : 14;

  double get _itemWidth {
    if (widget.item.width != null) return widget.item.width!;
    return switch (widget.item.itemType) {
      CanvasItemType.game => CanvasRepository.defaultCardWidth,
      CanvasItemType.movie => CanvasRepository.defaultCardWidth,
      CanvasItemType.tvShow => CanvasRepository.defaultCardWidth,
      CanvasItemType.animation => CanvasRepository.defaultCardWidth,
      CanvasItemType.text => 200,
      CanvasItemType.image => 200,
      CanvasItemType.link => 200,
    };
  }

  double get _itemHeight {
    if (widget.item.height != null) return widget.item.height!;
    return switch (widget.item.itemType) {
      CanvasItemType.game => CanvasRepository.defaultCardHeight,
      CanvasItemType.movie => CanvasRepository.defaultCardHeight,
      CanvasItemType.tvShow => CanvasRepository.defaultCardHeight,
      CanvasItemType.animation => CanvasRepository.defaultCardHeight,
      CanvasItemType.text => 100,
      CanvasItemType.image => 200,
      CanvasItemType.link => 48,
    };
  }

  // ==================== Drag ====================

  void _onPanStart(DragStartDetails details) {
    if (!widget.isEditable) return;
    _panStartGlobal = details.globalPosition;
    _dragDelta = Offset.zero;
    _dragNotifier.value = Offset.zero;
    setState(() {
      _isDragging = true;
    });
    widget.onDragStateChanged(isDragging: true);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    final double scale =
        widget.transformationController.value.getMaxScaleOnAxis();
    final Offset totalGlobalDelta =
        details.globalPosition - _panStartGlobal;
    final Offset newDelta = Offset(
      totalGlobalDelta.dx / scale,
      totalGlobalDelta.dy / scale,
    );
    _dragDelta = newDelta;
    // Обновляем только ValueNotifier — без setState, перестраивается
    // только ConnectionPainter и Transform.translate (через _dragNotifier).
    _dragNotifier.value = newDelta;
    widget.onDragUpdate(widget.item.id, newDelta);
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDragging) return;

    final double newX = widget.item.x + _dragDelta.dx;
    final double newY = widget.item.y + _dragDelta.dy;

    _readNotifier().moveItem(widget.item.id, newX, newY);

    _dragDelta = Offset.zero;
    _dragNotifier.value = Offset.zero;
    setState(() {
      _isDragging = false;
    });
    widget.onDragStateChanged(isDragging: false);
  }

  // ==================== Resize ====================

  void _onResizeStart(DragStartDetails details) {
    _panStartGlobal = details.globalPosition;
    _resizeStartWidth = _itemWidth;
    _resizeStartHeight = _itemHeight;
    setState(() {
      _resizeDelta = Offset.zero;
      _isResizing = true;
    });
    widget.onDragStateChanged(isDragging: true);
  }

  void _onResizeUpdate(DragUpdateDetails details) {
    if (!_isResizing) return;

    final double scale =
        widget.transformationController.value.getMaxScaleOnAxis();
    final Offset totalGlobalDelta =
        details.globalPosition - _panStartGlobal;
    setState(() {
      _resizeDelta = Offset(
        totalGlobalDelta.dx / scale,
        totalGlobalDelta.dy / scale,
      );
    });
  }

  void _onResizeEnd(DragEndDetails details) {
    if (!_isResizing) return;

    final double newWidth =
        (_resizeStartWidth + _resizeDelta.dx).clamp(_minItemSize, _maxItemSize);
    final double newHeight =
        (_resizeStartHeight + _resizeDelta.dy).clamp(_minItemSize, _maxItemSize);

    _readNotifier().updateItemSize(
      widget.item.id,
      width: newWidth,
      height: newHeight,
    );

    setState(() {
      _resizeDelta = Offset.zero;
      _isResizing = false;
    });
    widget.onDragStateChanged(isDragging: false);
  }

  @override
  void dispose() {
    _dragNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color shadowColor = colorScheme.shadow.withAlpha(80);

    // Размер обновляется в реальном времени при ресайзе.
    final double currentWidth = _isResizing
        ? (_resizeStartWidth + _resizeDelta.dx)
            .clamp(_minItemSize, _maxItemSize)
        : _itemWidth;
    final double currentHeight = _isResizing
        ? (_resizeStartHeight + _resizeDelta.dy)
            .clamp(_minItemSize, _maxItemSize)
        : _itemHeight;

    // Positioned остаётся на базовой позиции — не меняется при drag.
    // Transform.translate обновляется через ValueListenableBuilder
    // без setState, что значительно ускоряет drag на мобильных.
    return Positioned(
      left: widget.item.x,
      top: widget.item.y,
      width: currentWidth,
      height: currentHeight,
      child: ValueListenableBuilder<Offset>(
        valueListenable: _dragNotifier,
        builder: (BuildContext context, Offset dragOffset, Widget? child) {
          return Transform.translate(
            offset: dragOffset,
            child: child,
          );
        },
        child: MouseRegion(
        cursor: widget.onTap != null
            ? SystemMouseCursors.cell
            : _isDragging
                ? SystemMouseCursors.grabbing
                : SystemMouseCursors.grab,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          // В режиме создания связи — onTap вместо drag.
          onTap: widget.onTap,
          onPanStart: widget.onTap == null ? _onPanStart : null,
          onPanUpdate: widget.onTap == null ? _onPanUpdate : null,
          onPanEnd: widget.onTap == null ? _onPanEnd : null,
          onSecondaryTapUp: widget.onSecondaryTap != null
              ? (TapUpDetails details) {
                  widget.onSecondaryTap!(
                    details.globalPosition,
                    widget.item,
                  );
                }
              : null,
          onLongPressStart: widget.onSecondaryTap != null
              ? (LongPressStartDetails details) {
                  widget.onSecondaryTap!(
                    details.globalPosition,
                    widget.item,
                  );
                }
              : null,
          child: RepaintBoundary(
            child: AnimatedOpacity(
              opacity: _isDragging ? 0.8 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      boxShadow: _isDragging
                          ? <BoxShadow>[
                              BoxShadow(
                                color: shadowColor,
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: SizedBox.expand(child: widget.child),
                  ),
                  // Resize handle (правый нижний угол)
                  if (widget.isEditable)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.resizeDownRight,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanStart: _onResizeStart,
                          onPanUpdate: _onResizeUpdate,
                          onPanEnd: _onResizeEnd,
                          child: Container(
                            width: _handleSize,
                            height: _handleSize,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                              ),
                              border: Border.all(
                                color: colorScheme.primary,
                                width: 0.5,
                              ),
                            ),
                            child: Icon(
                              Icons.drag_handle,
                              size: _handleSize * 0.6,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

/// Рисует фоновую сетку на канвасе.
class _CanvasGridPainter extends CustomPainter {
  _CanvasGridPainter({required this.color});

  final Color color;

  static const double _gridStep = 50.0;
  static const double _dotRadius = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += _gridStep) {
      for (double y = 0; y < size.height; y += _gridStep) {
        canvas.drawCircle(Offset(x, y), _dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_CanvasGridPainter oldDelegate) =>
      color != oldDelegate.color;
}
