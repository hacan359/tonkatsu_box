import 'package:material_ui/material_ui.dart';

import '../theme/app_spacing.dart';

/// The one rounded tile behind every small control on a glass panel: filter
/// segments, media-type icons, menu triggers. Colour changes animate.
class ChipTile extends StatelessWidget {
  const ChipTile({
    required this.color,
    required this.child,
    this.onTap,
    this.width,
    this.height,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
    this.radius = AppSpacing.radiusMd,
    this.tooltip,
    super.key,
  });

  final Color color;
  final Widget child;

  /// Null when a parent (a popup button) owns the tap.
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final double radius;
  final String? tooltip;

  static const Duration _duration = Duration(milliseconds: 180);

  @override
  Widget build(BuildContext context) {
    final BorderRadius r = BorderRadius.circular(radius);
    final Widget tile = AnimatedContainer(
      duration: _duration,
      curve: Curves.easeOut,
      width: width,
      height: height,
      decoration: BoxDecoration(color: color, borderRadius: r),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: padding,
            child: Center(child: child),
          ),
        ),
      ),
    );
    final String? message = tooltip;
    return message == null ? tile : Tooltip(message: message, child: tile);
  }
}
