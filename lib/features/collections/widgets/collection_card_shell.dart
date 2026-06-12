// Shared by both the classic (mosaic) and rich (hero) card variants; they
// differ only in the content they build via the builder, which receives the
// current dim animation.

import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_durations.dart';

/// Receives the current dim animation, usable in an [AnimatedBuilder] for
/// hover effects.
typedef CollectionCardContentBuilder = Widget Function(
  BuildContext context,
  Animation<double> dimAnimation,
);

class CollectionCardShell extends StatefulWidget {
  const CollectionCardShell({
    required this.builder,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.onFocusChanged,
    super.key,
  });

  final CollectionCardContentBuilder builder;

  final VoidCallback? onTap;

  final VoidCallback? onLongPress;

  /// Called with the tap position in global coordinates.
  final void Function(Offset globalPosition)? onSecondaryTap;

  final ValueChanged<bool>? onFocusChanged;

  static const double radius = 16;

  /// Maximum dim opacity when the card is neither hovered nor focused.
  static const double dimOpacity = 0.25;

  @override
  State<CollectionCardShell> createState() => _CollectionCardShellState();
}

class _CollectionCardShellState extends State<CollectionCardShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hoverController;
  late final Animation<double> _dimAnimation;
  final FocusNode _focusNode = FocusNode();
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: AppDurations.normal,
    );
    _dimAnimation = Tween<double>(
      begin: CollectionCardShell.dimOpacity,
      end: 0,
    ).animate(CurvedAnimation(parent: _hoverController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      focusNode: _focusNode,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onSecondaryTapUp: widget.onSecondaryTap != null
          ? (TapUpDetails d) => widget.onSecondaryTap!(d.globalPosition)
          : null,
      onFocusChange: (bool hasFocus) {
        if (hasFocus) {
          _hoverController.forward();
        } else {
          _hoverController.reverse();
        }
        widget.onFocusChanged?.call(hasFocus);
        setState(() => _hasFocus = hasFocus);
      },
      onHover: (bool hovering) {
        if (hovering) {
          _hoverController.forward();
        } else if (!_focusNode.hasFocus) {
          _hoverController.reverse();
        }
      },
      borderRadius: BorderRadius.circular(CollectionCardShell.radius),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(CollectionCardShell.radius),
          border: Border.all(
            color: _hasFocus ? AppColors.brand : Colors.transparent,
            width: 2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: widget.builder(context, _dimAnimation),
      ),
    );
  }
}
