// Плавающая перетаскиваемая кнопка с popup-меню действий.
// Раскрывается веером в 2 стороны: primary — влево, secondary — вверх.

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Элемент меню [DraggableFab].
class DraggableFabItem {
  /// Создаёт [DraggableFabItem].
  const DraggableFabItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  /// Иконка пункта.
  final IconData icon;

  /// Текст пункта (показывается в tooltip).
  final String label;

  /// Callback при нажатии.
  final VoidCallback onTap;

  /// Цвет иконки (по умолчанию — [AppColors.textPrimary]).
  final Color? iconColor;
}

/// Разделитель — пропуск в списке кнопок (увеличенный gap).
class DraggableFabDivider extends DraggableFabItem {
  /// Создаёт [DraggableFabDivider].
  const DraggableFabDivider()
      : super(
          icon: Icons.remove,
          label: '',
          onTap: _noop,
        );

  static void _noop() {}
}

/// Плавающая кнопка действий, которую можно перетаскивать по экрану.
///
/// Может содержать всегда-видимое [mainAction] и/или скрытое меню,
/// раскрывающееся веером:
/// - [primaryItems] — круглые иконки влево от ⋮.
/// - [items] — круглые иконки вверх от ⋮.
class DraggableFab extends StatefulWidget {
  /// Создаёт [DraggableFab].
  const DraggableFab({
    this.mainAction,
    this.primaryItems = const <DraggableFabItem>[],
    this.items = const <DraggableFabItem>[],
    this.icon = Icons.more_vert,
    super.key,
  });

  /// Всегда-видимая основная кнопка (например, «+»). Рендерится слева
  /// от ⋮ FAB; перетаскивается вместе с ним как единый блок.
  final DraggableFabItem? mainAction;

  /// Основные действия — веер влево от ⋮.
  final List<DraggableFabItem> primaryItems;

  /// Остальные действия — веер вверх от ⋮.
  final List<DraggableFabItem> items;

  /// Иконка кнопки меню.
  final IconData icon;

  @override
  State<DraggableFab> createState() => _DraggableFabState();
}

class _DraggableFabState extends State<DraggableFab> {
  double _right = AppSpacing.md;
  double _bottom = AppSpacing.md;

  bool _isDragging = false;
  Offset _dragStart = Offset.zero;
  double _dragStartRight = 0;
  double _dragStartBottom = 0;

  static const double _fabSize = 48;
  static const double _menuFabSize = 40;
  static const double _gap = 8;

  bool get _hasMenu =>
      widget.primaryItems.isNotEmpty || widget.items.isNotEmpty;

  double get _blockWidth {
    final bool hasMain = widget.mainAction != null;
    if (hasMain) return _fabSize;
    return _menuFabSize;
  }

  double get _blockHeight {
    final bool hasMain = widget.mainAction != null;
    if (hasMain && _hasMenu) return _menuFabSize + _gap + _fabSize;
    if (hasMain) return _fabSize;
    return _menuFabSize;
  }

  @override
  Widget build(BuildContext context) {
    final bool hasMain = widget.mainAction != null;
    if (!hasMain && !_hasMenu) {
      return const SizedBox.shrink();
    }

    return Positioned(
      right: _right,
      bottom: _bottom,
      child: SizedBox(
        width: _blockWidth,
        height: _blockHeight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            if (_hasMenu)
              _buildButton(
                icon: widget.icon,
                onTap: () => _showMenu(context),
                isMenuAnchor: true,
              ),
            if (hasMain && _hasMenu) const SizedBox(height: _gap),
            if (hasMain)
              _buildButton(
                icon: widget.mainAction!.icon,
                iconColor: widget.mainAction!.iconColor,
                tooltip: widget.mainAction!.label,
                onTap: widget.mainAction!.onTap,
              ),
          ],
        ),
      ),
    );
  }

  /// Single round button that both handles tap (when not dragging) and
  /// drags the whole block. Each button has its own gesture detector so
  /// the tap surface is local; pan state is shared via `_dragStart*` so
  /// from either button the block moves as one.
  Widget _buildButton({
    required IconData icon,
    Color? iconColor,
    String? tooltip,
    required VoidCallback onTap,
    bool isMenuAnchor = false,
  }) {
    final double size = isMenuAnchor ? _menuFabSize : _fabSize;
    final Widget circle = Material(
      elevation: 6,
      shadowColor: AppColors.brand.withAlpha(80),
      shape: const CircleBorder(),
      color: AppColors.brand,
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(
          icon,
          color: iconColor ?? AppColors.textPrimary,
          size: isMenuAnchor ? 20 : 24,
        ),
      ),
    );

    final Widget hosted = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onTap: () {
        if (_isDragging) return;
        onTap();
      },
      child: circle,
    );

    if (tooltip == null) return hosted;
    return Tooltip(message: tooltip, child: hosted);
  }

  void _onPanStart(DragStartDetails details) {
    _isDragging = false;
    _dragStart = details.globalPosition;
    _dragStartRight = _right;
    _dragStartBottom = _bottom;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final Offset delta = details.globalPosition - _dragStart;

    if (delta.distance > 8) {
      _isDragging = true;
    }

    if (!_isDragging) return;

    final Size parentSize = MediaQuery.sizeOf(context);
    setState(() {
      _right = (_dragStartRight - delta.dx)
          .clamp(0.0, parentSize.width - _blockWidth);
      _bottom = (_dragStartBottom - delta.dy)
          .clamp(0.0, parentSize.height - _blockHeight - 100);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _isDragging = false;
  }

  void _showMenu(BuildContext context) {
    // ⋮ sits at the top of the block, horizontally centered above the
    // main action. Pass its actual screen position so the fan radiates
    // around the small (40px) menu button, not the larger main one.
    final RenderBox box = context.findRenderObject()! as RenderBox;
    final Offset blockPos = box.localToGlobal(Offset.zero);
    final double menuLeft = blockPos.dx + (_blockWidth - _menuFabSize) / 2;

    Navigator.of(context, rootNavigator: true).push(
      _FanMenuRoute(
        primaryItems: widget.primaryItems,
        items: widget.items,
        fabPosition: Offset(menuLeft, blockPos.dy),
        fabSize: _menuFabSize,
      ),
    );
  }
}

// =========================================================================
// Fan menu route
// =========================================================================

class _FanMenuRoute extends PopupRoute<void> {
  _FanMenuRoute({
    required this.primaryItems,
    required this.items,
    required this.fabPosition,
    required this.fabSize,
  });

  final List<DraggableFabItem> primaryItems;
  final List<DraggableFabItem> items;
  final Offset fabPosition;
  final double fabSize;

  @override
  Color? get barrierColor => Colors.black38;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 250);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _FanMenuPage(
      primaryItems: primaryItems,
      items: items,
      fabPosition: fabPosition,
      fabSize: fabSize,
      animation: animation,
    );
  }
}

// =========================================================================
// Fan layout — кнопки веером в 2 стороны
// =========================================================================

class _FanMenuPage extends StatelessWidget {
  const _FanMenuPage({
    required this.primaryItems,
    required this.items,
    required this.fabPosition,
    required this.fabSize,
    required this.animation,
  });

  final List<DraggableFabItem> primaryItems;
  final List<DraggableFabItem> items;
  final Offset fabPosition;
  final double fabSize;
  final Animation<double> animation;

  /// Размер кнопки-иконки.
  static const double _btnSize = 42;

  /// Расстояние между кнопками.
  static const double _gap = 10;

  /// Расстояние разделителя (DraggableFabDivider).
  static const double _dividerGap = 18;

  /// Суммарная длина ряда кнопок (без учёта первого gap от FAB).
  double _totalSpan(List<DraggableFabItem> list) {
    double span = 0;
    bool first = true;
    for (final DraggableFabItem item in list) {
      if (item is DraggableFabDivider) {
        span += _dividerGap;
        continue;
      }
      span += first ? fabSize / 2 + _gap + _btnSize / 2 : _btnSize + _gap;
      first = false;
    }
    return span;
  }

  @override
  Widget build(BuildContext context) {
    const double margin = 8;

    final double fabCx = fabPosition.dx + fabSize / 2;
    final double fabCy = fabPosition.dy + fabSize / 2;

    // Определяем направления: хватает ли места влево/вверх.
    final double needH = _totalSpan(primaryItems);
    final double needV = _totalSpan(items);

    final bool goRight = fabCx - needH < margin;
    final bool goDown = fabCy - needV < margin;

    final int hDir = goRight ? 1 : -1; // 1 = вправо, -1 = влево
    final int vDir = goDown ? 1 : -1;  // 1 = вниз, -1 = вверх

    final List<Widget> buttons = <Widget>[];

    // Primary — горизонтально.
    double offsetX = fabSize / 2 + _gap + _btnSize / 2;
    int totalIndex = 0;
    for (final DraggableFabItem item in primaryItems) {
      if (item is DraggableFabDivider) {
        offsetX += _dividerGap;
        continue;
      }
      final double cx = fabCx + offsetX * hDir;
      final double cy = fabCy;
      buttons.add(
        _buildButton(context, item, cx, cy, totalIndex),
      );
      offsetX += _btnSize + _gap;
      totalIndex++;
    }

    // Secondary — вертикально.
    double offsetY = fabSize / 2 + _gap + _btnSize / 2;
    for (final DraggableFabItem item in items) {
      if (item is DraggableFabDivider) {
        offsetY += _dividerGap;
        continue;
      }
      final double cx = fabCx;
      final double cy = fabCy + offsetY * vDir;
      buttons.add(
        _buildButton(context, item, cx, cy, totalIndex),
      );
      offsetY += _btnSize + _gap;
      totalIndex++;
    }

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      behavior: HitTestBehavior.opaque,
      child: Stack(children: buttons),
    );
  }

  Widget _buildButton(
    BuildContext context,
    DraggableFabItem item,
    double cx,
    double cy,
    int index,
  ) {
    // Staggered: каждая кнопка появляется чуть позже.
    final int total = primaryItems.length + items.length;
    final double start = (index / (total + 1)) * 0.4;
    final double end = start + 0.6;

    final Animation<double> itemAnim = CurvedAnimation(
      parent: animation,
      curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.easeOut),
    );

    return AnimatedBuilder(
      animation: itemAnim,
      builder: (BuildContext context, Widget? child) {
        final double scale = itemAnim.value;
        // Кнопки «вылетают» из позиции FAB.
        final double x =
            fabPosition.dx + fabSize / 2 +
            (cx - fabPosition.dx - fabSize / 2) * scale -
            _btnSize / 2;
        final double y =
            fabPosition.dy + fabSize / 2 +
            (cy - fabPosition.dy - fabSize / 2) * scale -
            _btnSize / 2;

        return Positioned(
          left: x,
          top: y,
          child: Opacity(
            opacity: scale,
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          ),
        );
      },
      child: _FanButton(
        item: item,
        size: _btnSize,
        onTap: () {
          Navigator.of(context).pop();
          item.onTap();
        },
      ),
    );
  }
}

// =========================================================================
// Circular icon button
// =========================================================================

class _FanButton extends StatefulWidget {
  const _FanButton({
    required this.item,
    required this.size,
    required this.onTap,
  });

  final DraggableFabItem item;
  final double size;
  final VoidCallback onTap;

  @override
  State<_FanButton> createState() => _FanButtonState();
}

class _FanButtonState extends State<_FanButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.item.label,
      waitDuration: const Duration(milliseconds: 300),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _hovered
                  ? AppColors.surfaceLight
                  : AppColors.surface,
              border: Border.all(
                color: _hovered
                    ? AppColors.brand.withAlpha(120)
                    : AppColors.surfaceBorder,
                width: 0.5,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withAlpha(60),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              widget.item.icon,
              size: 20,
              color: widget.item.iconColor ?? AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
