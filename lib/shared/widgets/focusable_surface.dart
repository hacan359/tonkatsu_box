import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Fill, border and focus ring for a hand-made control; the fill is a Material
/// so ink paints above it. Without [onTap] the ring follows [child]'s focus.
class FocusableSurface extends StatefulWidget {
  const FocusableSurface({
    required this.child,
    this.onTap,
    this.color,
    this.borderRadius = AppSpacing.radiusSm,
    this.padding = EdgeInsets.zero,
    this.focusNode,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// Falls back to [AppColors.surface].
  final Color? color;

  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final FocusNode? focusNode;

  @override
  State<FocusableSurface> createState() => _FocusableSurfaceState();
}

class _FocusableSurfaceState extends State<FocusableSurface> {
  static const double _ringWidth = 2;

  bool _focused = false;

  void _onFocusChange(bool focused) {
    if (focused != _focused) setState(() => _focused = focused);
  }

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(widget.borderRadius);
    final VoidCallback? onTap = widget.onTap;
    final Widget content = Padding(
      padding: widget.padding,
      child: widget.child,
    );

    return Material(
      color: widget.color ?? AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: AppColors.surfaceBorder),
      ),
      clipBehavior: Clip.antiAlias,
      // Foreground, so the ring is drawn over the ink and never shifts the
      // layout by its width.
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: _focused
              ? Border.all(color: AppColors.brand, width: _ringWidth)
              : null,
        ),
        child: onTap != null
            ? InkWell(
                focusNode: widget.focusNode,
                onTap: onTap,
                onFocusChange: _onFocusChange,
                child: content,
              )
            // hasFocus covers descendants, so the child's own InkWell counts.
            : Focus(
                canRequestFocus: false,
                skipTraversal: true,
                onFocusChange: _onFocusChange,
                child: content,
              ),
      ),
    );
  }
}
