import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/canvas_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/models/canvas_item.dart';
import '../../../shared/theme/app_durations.dart';
import '../../../shared/widgets/media_poster_card.dart';
import '../providers/canvas_provider.dart';
import '../providers/steamgriddb_panel_provider.dart';
import '../providers/vgmaps_panel_provider.dart';
import 'canvas_connection_painter.dart';
import 'canvas_context_menu.dart';
import 'canvas_image_item.dart';
import 'canvas_item_actions.dart';
import 'canvas_link_item.dart';
import 'canvas_text_item.dart';

class CanvasView extends ConsumerStatefulWidget {
  const CanvasView({
    required this.collectionId,
    required this.isEditable,
    this.collectionItemId,
    super.key,
  });

  final int? collectionId;

  final bool isEditable;

  /// When set, uses [gameCanvasNotifierProvider] (independent per-item canvas)
  /// instead of [canvasNotifierProvider].
  final int? collectionItemId;

  @override
  ConsumerState<CanvasView> createState() => _CanvasViewState();
}

class _CanvasViewState extends ConsumerState<CanvasView> {
  final TransformationController _transformationController =
      TransformationController();

  final FocusNode _focusNode = FocusNode();

  bool get _isGameCanvas => widget.collectionItemId != null;

  ({int? collectionId, int collectionItemId}) get _gameCanvasArg => (
        collectionId: widget.collectionId,
        collectionItemId: widget.collectionItemId!,
      );

  CanvasState _watchCanvasState() {
    if (_isGameCanvas) {
      return ref.watch(gameCanvasNotifierProvider(_gameCanvasArg));
    }
    return ref.watch(canvasNotifierProvider(widget.collectionId));
  }

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

  late final CanvasItemActions _actions = CanvasItemActions(
    context: context,
    controller: _readNotifier,
  );

  static const double _minScale = 0.1;
  static const double _maxScale = 3.0;
  static const double _minCanvasSize = 5000.0;
  static const double _canvasBuffer = 1000.0;

  bool _hasScrolledToItems = false;

  /// Blocks InteractiveViewer pan while an item is being dragged.
  bool _isItemDragging = false;

  /// ValueNotifier (not setState) so only ConnectionPainter rebuilds during
  /// drag, not every canvas item.
  final ValueNotifier<Map<int, Offset>> _dragOffsetsNotifier =
      ValueNotifier<Map<int, Offset>>(const <int, Offset>{});

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

  /// Viewport padding around content for zoom-to-fit.
  static const double _fitPadding = 32;

  /// Desktop keeps min scale at 1.0 (don't shrink below natural size);
  /// mobile fits everything in viewport and zooms out further for overview.
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

    final double availableWidth = viewportWidth - _fitPadding * 2;
    final double availableHeight = viewportHeight - _fitPadding * 2;
    double scale = 1.0;
    if (contentWidth > 0 && contentHeight > 0) {
      final double scaleX = availableWidth / contentWidth;
      final double scaleY = availableHeight / contentHeight;
      scale = scaleX < scaleY ? scaleX : scaleY;
    }

    final bool isMobile = kIsMobile;
    // Mobile: zoom out 5x further so all items are visible at once.
    if (isMobile) scale /= 5;
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

  void _onCanvasSecondaryTap(
    Offset globalPosition,
    Offset localPosition,
  ) {
    // localPosition is already in canvas coords (inside InteractiveViewer).
    final double canvasX = localPosition.dx;
    final double canvasY = localPosition.dy;

    CanvasContextMenu.showCanvasMenu(
      context,
      position: globalPosition,
      onAddText: () => _actions.addText(canvasX, canvasY),
      onAddImage: () => _actions.addImage(canvasX, canvasY),
      onAddLink: () => _actions.addLink(canvasX, canvasY),
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

  void _onItemSecondaryTap(
    Offset globalPosition,
    CanvasItem item,
  ) {
    final BaseCanvasController notifier = _readNotifier();

    CanvasContextMenu.showItemMenu(
      context,
      position: globalPosition,
      itemType: item.itemType,
      onEdit: () => _actions.editItem(item),
      onDelete: () => notifier.deleteItem(item.id),
      onBringToFront: () => notifier.bringToFront(item.id),
      onSendToBack: () => notifier.sendToBack(item.id),
      onConnect: () {
        notifier.startConnection(item.id);
        _focusNode.requestFocus();
      },
    );
  }

  void _onCanvasSecondaryTapWithConnections(
    Offset globalPosition,
    Offset localPosition,
    CanvasState canvasState,
  ) {
    final CanvasConnectionPainter painter = CanvasConnectionPainter(
      connections: canvasState.connections,
      items: canvasState.items,
    );

    final int? connectionId = painter.hitTestConnection(localPosition);
    if (connectionId != null) {
      _showConnectionContextMenu(globalPosition, connectionId, canvasState);
      return;
    }

    _onCanvasSecondaryTap(globalPosition, localPosition);
  }

  void _showConnectionContextMenu(
    Offset globalPosition,
    int connectionId,
    CanvasState canvasState,
  ) {
    CanvasContextMenu.showConnectionMenu(
      context,
      position: globalPosition,
      onEdit: () => _actions.editConnection(connectionId, canvasState),
      onDelete: () {
        _readNotifier().deleteConnection(connectionId);
      },
    );
  }

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
              S.of(context).canvasFailedToLoad,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _readNotifier().refresh();
              },
              child: Text(S.of(context).retry),
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
              S.of(context).canvasBoardEmpty,
              style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              S.of(context).canvasBoardEmptyHint,
              style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );

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
                            for (final CanvasItem item in sortedItems)
                              _buildCanvasItem(item, isConnecting),
                            // IgnorePointer: clicks pass through connections.
                            // ValueListenableBuilder isolates connection
                            // repaints from canvas item rebuilds.
                            if (canvasState.connections.isNotEmpty ||
                                isConnecting)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: ValueListenableBuilder<
                                      Map<int, Offset>>(
                                    valueListenable: _dragOffsetsNotifier,
                                    builder: (
                                      BuildContext context,
                                      Map<int, Offset> dragOffsets,
                                      Widget? child,
                                    ) {
                                      return CustomPaint(
                                        painter: CanvasConnectionPainter(
                                          connections:
                                              canvasState.connections,
                                          items: canvasState.items,
                                          connectingFrom:
                                              connectingFromItem,
                                          mousePosition:
                                              _mouseCanvasPosition,
                                          labelStyle: TextStyle(
                                            fontSize: 11,
                                            color: colorScheme.onSurface,
                                          ),
                                          labelBackgroundColor:
                                              colorScheme
                                                  .surfaceContainerLow
                                                  .withAlpha(220),
                                          dragOffsets: dragOffsets,
                                        ),
                                      );
                                    },
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
            Positioned(
              right: 16,
              bottom: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // VGMaps Browser: Windows only (requires webview_windows).
                  if (widget.isEditable && kVgMapsEnabled)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: FloatingActionButton.small(
                        heroTag: 'canvas_vgmaps',
                        onPressed: () {
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
                        tooltip: S.of(context).canvasVgmapsBrowser,
                        child: const Icon(Icons.map),
                      ),
                    ),
                  if (widget.isEditable)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: FloatingActionButton.small(
                        heroTag: 'canvas_steamgriddb',
                        onPressed: () {
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
                        tooltip: S.of(context).canvasSteamGridDbImages,
                        child: const Icon(Icons.image_search),
                      ),
                    ),
                  FloatingActionButton.small(
                    heroTag: 'canvas_reset_view',
                    onPressed: () {
                      _centerViewOnItems(
                        viewportWidth,
                        viewportHeight,
                        canvasState.items,
                      );
                    },
                    tooltip: S.of(context).canvasCenterView,
                    child: const Icon(Icons.fit_screen),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'canvas_reset_positions',
                    onPressed: () {
                      _readNotifier().resetPositions(viewportWidth);
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
                    tooltip: S.of(context).canvasResetPositions,
                    child: const Icon(Icons.grid_view),
                  ),
                ],
              ),
            ),
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
      case CanvasItemType.movie:
      case CanvasItemType.tvShow:
      case CanvasItemType.animation:
      case CanvasItemType.visualNovel:
      case CanvasItemType.manga:
      case CanvasItemType.anime:
      case CanvasItemType.book:
      case CanvasItemType.custom:
        child = _buildMediaCard(item);
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

  Widget _buildMediaCard(CanvasItem item) {
    final String fallback = switch (item.itemType) {
      CanvasItemType.game => S.of(context).unknownGame,
      CanvasItemType.movie => S.of(context).unknownMovie,
      CanvasItemType.tvShow => S.of(context).unknownTvShow,
      CanvasItemType.animation => S.of(context).unknownAnimation,
      CanvasItemType.visualNovel => S.of(context).unknownVisualNovel,
      CanvasItemType.manga => S.of(context).unknownManga,
      _ => '',
    };

    return MediaPosterCard(
      variant: CardVariant.canvas,
      title: item.mediaTitle ?? fallback,
      imageUrl: item.mediaThumbnailUrl ?? '',
      cacheImageType: item.mediaImageType,
      cacheImageId: item.mediaCacheId,
      mediaType: item.asMediaType,
      placeholderIcon: item.mediaPlaceholderIcon,
    );
  }
}

/// Tracks drag by absolute globalPosition (not incremental deltas) and uses
/// [Positioned] + setState — `Transform.translate` inside InteractiveViewer
/// would double-scale. InteractiveViewer pan is disabled during drag via
/// callback to avoid double movement.
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
  final int? collectionId;
  final int? collectionItemId;
  final TransformationController transformationController;

  final void Function({required bool isDragging}) onDragStateChanged;

  final void Function(int itemId, Offset delta) onDragUpdate;

  final void Function(Offset globalPosition, CanvasItem item)? onSecondaryTap;

  /// Used in connection-creation mode (replaces drag).
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

  Offset _panStartGlobal = Offset.zero;

  bool _isResizing = false;

  double _resizeStartWidth = 0;
  double _resizeStartHeight = 0;

  Offset _resizeDelta = Offset.zero;

  static const double _minItemSize = 50;
  static const double _maxItemSize = 5000;

  static final bool _isMobile = kIsMobile;

  /// Larger handle on mobile for touch hit-area.
  static final double _handleSize = _isMobile ? 24 : 14;

  double get _itemWidth {
    if (widget.item.width != null) return widget.item.width!;
    return switch (widget.item.itemType) {
      CanvasItemType.game => CanvasRepository.defaultCardWidth,
      CanvasItemType.movie => CanvasRepository.defaultCardWidth,
      CanvasItemType.tvShow => CanvasRepository.defaultCardWidth,
      CanvasItemType.animation => CanvasRepository.defaultCardWidth,
      CanvasItemType.visualNovel => CanvasRepository.defaultCardWidth,
      CanvasItemType.manga => CanvasRepository.defaultCardWidth,
      CanvasItemType.anime => CanvasRepository.defaultCardWidth,
      CanvasItemType.book => CanvasRepository.defaultCardWidth,
      CanvasItemType.custom => CanvasRepository.defaultCardWidth,
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
      CanvasItemType.visualNovel => CanvasRepository.defaultCardHeight,
      CanvasItemType.manga => CanvasRepository.defaultCardHeight,
      CanvasItemType.anime => CanvasRepository.defaultCardHeight,
      CanvasItemType.book => CanvasRepository.defaultCardHeight,
      CanvasItemType.custom => CanvasRepository.defaultCardHeight,
      CanvasItemType.text => 100,
      CanvasItemType.image => 200,
      CanvasItemType.link => 48,
    };
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.isEditable) return;
    _panStartGlobal = details.globalPosition;
    setState(() {
      _dragDelta = Offset.zero;
      _isDragging = true;
    });
    widget.onDragStateChanged(isDragging: true);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    // entry(0,0) is real X scale. getMaxScaleOnAxis() returns
    // max(scaleX,scaleY,scaleZ), and scaleZ is always 1.0, so at zoom<1 it
    // wrongly returns 1.0.
    final double scale =
        widget.transformationController.value.entry(0, 0);
    final Offset totalGlobalDelta =
        details.globalPosition - _panStartGlobal;
    final Offset newDelta = Offset(
      totalGlobalDelta.dx / scale,
      totalGlobalDelta.dy / scale,
    );
    setState(() {
      _dragDelta = newDelta;
    });
    widget.onDragUpdate(widget.item.id, newDelta);
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDragging) return;

    final double newX = widget.item.x + _dragDelta.dx;
    final double newY = widget.item.y + _dragDelta.dy;

    _readNotifier().moveItem(widget.item.id, newX, newY);

    setState(() {
      _dragDelta = Offset.zero;
      _isDragging = false;
    });
    widget.onDragStateChanged(isDragging: false);
  }

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
        widget.transformationController.value.entry(0, 0);
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
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color shadowColor = colorScheme.shadow.withAlpha(80);

    final double left =
        widget.item.x + (_isDragging ? _dragDelta.dx : 0);
    final double top =
        widget.item.y + (_isDragging ? _dragDelta.dy : 0);

    final double currentWidth = _isResizing
        ? (_resizeStartWidth + _resizeDelta.dx)
            .clamp(_minItemSize, _maxItemSize)
        : _itemWidth;
    final double currentHeight = _isResizing
        ? (_resizeStartHeight + _resizeDelta.dy)
            .clamp(_minItemSize, _maxItemSize)
        : _itemHeight;

    return Positioned(
      left: left,
      top: top,
      width: currentWidth,
      height: currentHeight,
      child: MouseRegion(
        cursor: widget.onTap != null
            ? SystemMouseCursors.cell
            : _isDragging
                ? SystemMouseCursors.grabbing
                : SystemMouseCursors.grab,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          // Connection-creation mode: onTap replaces drag.
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
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                // Mobile skips boxShadow blur — GPU-expensive on weaker chips.
                if (_isMobile)
                  SizedBox.expand(child: widget.child)
                else
                  AnimatedContainer(
                    duration: AppDurations.fast,
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
    );
  }
}

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
