import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class DraggableFabItem {
  const DraggableFabItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
}

/// Inserts an extra vertical gap between menu sections.
class DraggableFabDivider extends DraggableFabItem {
  const DraggableFabDivider()
      : super(
          icon: Icons.remove,
          label: '',
          onTap: _noop,
        );

  static void _noop() {}
}

/// Draggable FAB block with an optional always-visible [mainAction] and a
/// popup pill menu fed by [primaryItems] + [items] (concatenated, in order).
class DraggableFab extends StatefulWidget {
  const DraggableFab({
    this.mainAction,
    this.primaryItems = const <DraggableFabItem>[],
    this.items = const <DraggableFabItem>[],
    this.icon = Icons.more_vert,
    this.initialRight,
    this.initialBottom,
    super.key,
  });

  final DraggableFabItem? mainAction;
  final List<DraggableFabItem> primaryItems;
  final List<DraggableFabItem> items;
  final IconData icon;

  /// Initial right offset (defaults to [AppSpacing.md]). Set on the canvas
  /// view so the FAB clears the right-side toolbar column instead of
  /// overlapping it.
  final double? initialRight;

  /// Initial bottom offset (defaults to [AppSpacing.md]).
  final double? initialBottom;

  @override
  State<DraggableFab> createState() => _DraggableFabState();
}

class _DraggableFabState extends State<DraggableFab> {
  late double _right = widget.initialRight ?? AppSpacing.md;
  late double _bottom = widget.initialBottom ?? AppSpacing.md;

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
    // Anchor the popup to the ⋮ button (top of the block), not the larger
    // main FAB below it, so pills line up with the menu trigger.
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

/// Vertical stack of labeled pills anchored to the FAB's right edge.
/// When the stack is taller than the available vertical room it scrolls
/// in place so the menu always fits on screen regardless of item count.
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

  static const double _pillHeight = 40;
  static const double _pillGap = 8;
  static const double _dividerGap = 14;
  static const double _fabGap = 12;
  static const double _edgeMargin = 8;
  static const double _pillMaxWidth = 220;

  @override
  Widget build(BuildContext context) {
    final List<DraggableFabItem> all = <DraggableFabItem>[
      ...primaryItems,
      if (primaryItems.isNotEmpty && items.isNotEmpty)
        const DraggableFabDivider(),
      ...items,
    ];

    final Size screen = MediaQuery.sizeOf(context);
    // Status bar / nav bar insets — without subtracting these the pill
    // stack can extend under the system chrome and look unreachable.
    final EdgeInsets safe = MediaQuery.viewPaddingOf(context);
    final double fabRight = screen.width - fabPosition.dx - fabSize;
    final double spaceAbove = fabPosition.dy - safe.top;
    final double spaceBelow =
        screen.height - (fabPosition.dy + fabSize) - safe.bottom;
    final bool goUp = spaceAbove >= spaceBelow;
    final double maxHeight =
        (goUp ? spaceAbove : spaceBelow) - _fabGap - _edgeMargin;

    final int actionCount = all
        .where((DraggableFabItem i) => i is! DraggableFabDivider)
        .length;

    final List<Widget> columnChildren = <Widget>[];
    int actionIndex = 0;
    bool lastWasItem = false;
    for (final DraggableFabItem item in all) {
      if (item is DraggableFabDivider) {
        if (lastWasItem) {
          columnChildren.add(const SizedBox(height: _dividerGap));
        }
        lastWasItem = false;
        continue;
      }
      if (lastWasItem) {
        columnChildren.add(const SizedBox(height: _pillGap));
      }
      columnChildren.add(_buildAnimatedPill(
        context: context,
        item: item,
        index: actionIndex,
        total: actionCount,
        goUp: goUp,
      ));
      actionIndex++;
      lastWasItem = true;
    }

    // When opening upward the closest-to-FAB pill is the LAST in original
    // order, so flip the column so item N-1 sits at the bottom (next to
    // the FAB) and item 0 at the top (scrolled-away if overflowing).
    final List<Widget> ordered = goUp
        ? columnChildren.reversed.toList(growable: false)
        : columnChildren;

    final Widget pillsColumn = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: ordered,
    );

    final Widget scrollable = ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: maxHeight,
        maxWidth: _pillMaxWidth,
      ),
      child: SingleChildScrollView(
        reverse: goUp,
        physics: const ClampingScrollPhysics(),
        child: pillsColumn,
      ),
    );

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: <Widget>[
          Positioned(
            right: fabRight,
            top: goUp ? null : fabPosition.dy + fabSize + _fabGap,
            bottom: goUp
                ? screen.height - fabPosition.dy + _fabGap
                : null,
            child: scrollable,
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedPill({
    required BuildContext context,
    required DraggableFabItem item,
    required int index,
    required int total,
    required bool goUp,
  }) {
    // Staggered: pills appear sequentially as the menu opens.
    final double start = total > 0 ? (index / (total + 1)) * 0.4 : 0;
    final double end = (start + 0.6).clamp(0.0, 1.0);
    final Animation<double> itemAnim = CurvedAnimation(
      parent: animation,
      curve: Interval(start, end, curve: Curves.easeOut),
    );

    final _PillButton pill = _PillButton(
      item: item,
      height: _pillHeight,
      onTap: () {
        Navigator.of(context).pop();
        item.onTap();
      },
    );

    return AnimatedBuilder(
      animation: itemAnim,
      builder: (BuildContext context, Widget? child) {
        final double v = itemAnim.value;
        final double dy = (goUp ? 16.0 : -16.0) * (1 - v);
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, dy),
            child: child,
          ),
        );
      },
      child: pill,
    );
  }
}
class _PillButton extends StatefulWidget {
  const _PillButton({
    required this.item,
    required this.height,
    required this.onTap,
  });

  final DraggableFabItem item;
  final double height;
  final VoidCallback onTap;

  @override
  State<_PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<_PillButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          height: widget.height,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.surfaceLight : AppColors.surface,
            borderRadius: BorderRadius.circular(widget.height / 2),
            border: Border.all(
              color: _hovered
                  ? AppColors.brand.withAlpha(160)
                  : AppColors.surfaceBorder,
              width: 0.5,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withAlpha(70),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Flexible(
                child: Text(
                  widget.item.label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.none,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                widget.item.icon,
                size: 20,
                color: widget.item.iconColor ?? AppColors.textPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
