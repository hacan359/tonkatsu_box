import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/canvas_repository.dart';
import '../../../shared/models/canvas_item.dart';
import '../providers/canvas_provider.dart';
import 'canvas_game_card.dart';

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
    super.key,
  });

  /// ID коллекции.
  final int collectionId;

  /// Можно ли редактировать (перемещать элементы).
  final bool isEditable;

  @override
  ConsumerState<CanvasView> createState() => _CanvasViewState();
}

class _CanvasViewState extends ConsumerState<CanvasView> {
  final TransformationController _transformationController =
      TransformationController();

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

  void _onItemDragStateChanged({required bool isDragging}) {
    setState(() => _isItemDragging = isDragging);
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  /// Центрирует вид на элементах канваса.
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

    final double contentCenterX = (minX + maxX) / 2;
    final double contentCenterY = (minY + maxY) / 2;

    _transformationController.value = Matrix4.identity()
      ..translateByDouble(
        viewportWidth / 2 - contentCenterX,
        viewportHeight / 2 - contentCenterY,
        0.0,
        1.0,
      );
  }

  @override
  Widget build(BuildContext context) {
    final CanvasState canvasState =
        ref.watch(canvasNotifierProvider(widget.collectionId));
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
              'Failed to load canvas',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                ref
                    .read(
                        canvasNotifierProvider(widget.collectionId).notifier)
                    .refresh();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (canvasState.items.isEmpty) {
      return Center(
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
              'Canvas is empty',
              style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add games to the collection first',
              style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
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

        return Stack(
          children: <Widget>[
            // Канвас с зумом и панорамированием
            InteractiveViewer(
              transformationController: _transformationController,
              constrained: false,
              panEnabled: !_isItemDragging,
              minScale: _minScale,
              maxScale: _maxScale,
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
                        _buildCanvasItem(item),
                    ],
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
                      ref
                          .read(canvasNotifierProvider(widget.collectionId)
                              .notifier)
                          .resetPositions(viewportWidth);
                      // Центрируем вид после сброса
                      SchedulerBinding.instance.addPostFrameCallback((_) {
                        final List<CanvasItem> items = ref
                            .read(
                                canvasNotifierProvider(widget.collectionId))
                            .items;
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
          ],
        );
      },
    );
  }

  Widget _buildCanvasItem(CanvasItem item) {
    switch (item.itemType) {
      case CanvasItemType.game:
        return _DraggableCanvasItem(
          key: ValueKey<int>(item.id),
          item: item,
          isEditable: widget.isEditable,
          collectionId: widget.collectionId,
          transformationController: _transformationController,
          onDragStateChanged: _onItemDragStateChanged,
          child: CanvasGameCard(
            item: item,
          ),
        );
      // Остальные типы будут в Stage 8
      case CanvasItemType.text:
      case CanvasItemType.image:
      case CanvasItemType.link:
        return const SizedBox.shrink();
    }
  }
}

/// Обёртка для перетаскиваемых элементов канваса.
///
/// Во время drag позиция обновляется через [ValueNotifier] —
/// пересобирается только [Transform.translate], а дочерний виджет
/// полностью кэшируется через `child` параметр [ListenableBuilder].
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
    required this.child,
    super.key,
  });

  final CanvasItem item;
  final bool isEditable;
  final int collectionId;
  final TransformationController transformationController;

  /// Callback для уведомления родителя о начале/конце drag.
  final void Function({required bool isDragging}) onDragStateChanged;

  final Widget child;

  @override
  ConsumerState<_DraggableCanvasItem> createState() =>
      _DraggableCanvasItemState();
}

class _DraggableCanvasItemState extends ConsumerState<_DraggableCanvasItem> {
  final ValueNotifier<Offset> _dragDelta =
      ValueNotifier<Offset>(Offset.zero);
  bool _isDragging = false;

  /// Глобальная позиция указателя при старте перетаскивания.
  Offset _panStartGlobal = Offset.zero;

  double get _itemWidth =>
      widget.item.width ?? CanvasRepository.defaultCardWidth;
  double get _itemHeight =>
      widget.item.height ?? CanvasRepository.defaultCardHeight;

  @override
  void dispose() {
    _dragDelta.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.isEditable) return;
    _panStartGlobal = details.globalPosition;
    _dragDelta.value = Offset.zero;
    setState(() => _isDragging = true);
    widget.onDragStateChanged(isDragging: true);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    // Вычисляем полное смещение от стартовой позиции (в экранных координатах),
    // затем делим на масштаб для перевода в координаты канваса.
    final double scale =
        widget.transformationController.value.getMaxScaleOnAxis();
    final Offset totalGlobalDelta =
        details.globalPosition - _panStartGlobal;
    _dragDelta.value = Offset(
      totalGlobalDelta.dx / scale,
      totalGlobalDelta.dy / scale,
    );
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDragging) return;

    final double newX = widget.item.x + _dragDelta.value.dx;
    final double newY = widget.item.y + _dragDelta.value.dy;

    ref
        .read(canvasNotifierProvider(widget.collectionId).notifier)
        .moveItem(widget.item.id, newX, newY);

    _dragDelta.value = Offset.zero;
    setState(() => _isDragging = false);
    widget.onDragStateChanged(isDragging: false);
  }

  @override
  Widget build(BuildContext context) {
    final Color shadowColor =
        Theme.of(context).colorScheme.shadow.withAlpha(80);

    return Positioned(
      left: widget.item.x,
      top: widget.item.y,
      width: _itemWidth,
      height: _itemHeight,
      child: MouseRegion(
        cursor: _isDragging
            ? SystemMouseCursors.grabbing
            : SystemMouseCursors.grab,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: ListenableBuilder(
            listenable: _dragDelta,
            builder: (BuildContext context, Widget? child) {
              return Transform.translate(
                offset: _dragDelta.value,
                child: child,
              );
            },
            child: RepaintBoundary(
              child: AnimatedOpacity(
                opacity: _isDragging ? 0.8 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: AnimatedContainer(
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
                  child: widget.child,
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
