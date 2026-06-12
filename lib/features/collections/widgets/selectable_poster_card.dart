// Checkbox overlay for bulk selection, Google Photos style: tapping the
// circle toggles selection, tapping the rest of the card is a normal open.

import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';

class SelectablePosterCard extends StatefulWidget {
  const SelectablePosterCard({
    required this.child,
    required this.isSelected,
    required this.onToggleSelect,
    required this.selectionActive,
    super.key,
  });

  final Widget child;

  final bool isSelected;

  final VoidCallback onToggleSelect;

  /// True while any item is selected. When active, checkmarks are always
  /// visible; otherwise they appear only on hover.
  final bool selectionActive;

  @override
  State<SelectablePosterCard> createState() => _SelectablePosterCardState();
}

class _SelectablePosterCardState extends State<SelectablePosterCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bool show = widget.selectionActive ||
        widget.isSelected ||
        _hovered;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          widget.child,
          if (widget.isSelected)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(120),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 6,
            left: 6,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 120),
              opacity: show ? 1 : 0,
              child: _CheckCircle(
                isSelected: widget.isSelected,
                interactive: show,
                onTap: widget.onToggleSelect,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckCircle extends StatelessWidget {
  const _CheckCircle({
    required this.isSelected,
    required this.interactive,
    required this.onTap,
  });

  final bool isSelected;

  /// When the circle is invisible (opacity 0) it is excluded from
  /// hit-testing so it doesn't swallow clicks meant for the card.
  final bool interactive;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Widget circle = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.brand
                : Colors.black.withAlpha(140),
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected
                  ? AppColors.brand
                  : Colors.white.withAlpha(200),
              width: 1.5,
            ),
          ),
          child: isSelected
              ? const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: Colors.white,
                )
              : null,
        ),
      ),
    );
    return interactive ? circle : IgnorePointer(child: circle);
  }
}
