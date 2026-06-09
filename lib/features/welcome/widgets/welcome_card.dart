import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';

/// Rounded card with an [accent] gradient and a colored left edge — the shared
/// surface for Welcome step content.
class WelcomeCard extends StatelessWidget {
  const WelcomeCard({
    required this.child,
    this.accent = AppColors.brand,
    this.padding = const EdgeInsets.all(14),
    this.onTap,
    super.key,
  });

  final Widget child;
  final Color accent;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppSpacing.radiusMd);

    final Widget content = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[accent.withAlpha(22), AppColors.surface],
        ),
        borderRadius: radius,
        border: Border.all(color: accent.withAlpha(60)),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: <Widget>[
            Padding(padding: padding, child: child),
            // Positioned so the edge never forces an infinite height in a
            // scroll view (a stretched Row child would).
            PositionedDirectional(
              start: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 4, color: accent.withAlpha(180)),
            ),
          ],
        ),
      ),
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(borderRadius: radius, onTap: onTap, child: content),
    );
  }
}
