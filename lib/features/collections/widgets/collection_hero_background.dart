import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import 'hero_image.dart';

/// The image fills the parent's size; the parent is responsible for sizing
/// and corner rounding.
class CollectionHeroBackground extends StatelessWidget {
  const CollectionHeroBackground({
    required this.imagePath,
    this.isMobile = false,
    this.strength = HeroGradientStrength.standard,
    this.cacheWidth,
    this.child,
    super.key,
  });

  /// Absolute path to the hero image file.
  final String imagePath;

  /// Mobile mode: wider gradients for better readability in portrait.
  final bool isMobile;

  final HeroGradientStrength strength;

  /// Decode-width hint: without it a 4K hero on a 150x150 grid card is
  /// decoded in full and floods the ImageCache.
  final int? cacheWidth;

  /// Content laid over the image. Must not be `Positioned` — the parent
  /// places it via `Stack`, or pass an `Align`.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final Color bg = AppColors.background;
    final double leftStop = isMobile ? 0.75 : 0.55;
    final double bottomStop = isMobile ? 0.70 : 0.55;
    final double leftDark = strength.leftDarkOpacity;
    final double bottomDark = strength.bottomDarkOpacity;
    final double dpr = MediaQuery.devicePixelRatioOf(context);
    final int effectiveCacheWidth =
        ((cacheWidth ?? strength.defaultCacheWidth) * dpr).round();

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image(
            image: ResizeImage(
              heroImageProviderFor(imagePath),
              width: effectiveCacheWidth,
            ),
            fit: BoxFit.cover,
            alignment: Alignment.topRight,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, _, _) =>
                ColoredBox(color: AppColors.surface),
          ),

          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: <Color>[
                  bg.withValues(alpha: leftDark),
                  bg.withValues(alpha: leftDark * 0.55),
                  Colors.transparent,
                ],
                stops: <double>[0.0, leftStop * 0.5, leftStop],
              ),
            ),
          ),

          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: <Color>[
                  bg,
                  bg.withValues(alpha: bottomDark * 0.65),
                  Colors.transparent,
                ],
                stops: <double>[0.0, bottomStop * 0.45, bottomStop],
              ),
            ),
          ),

          ?child,
        ],
      ),
    );
  }
}

enum HeroGradientStrength {
  /// For grid cards: softer, so a small image is not drowned out.
  soft(
    leftDarkOpacity: 0.75,
    bottomDarkOpacity: 0.90,
    defaultCacheWidth: 320,
  ),

  /// For the full-size banner.
  standard(
    leftDarkOpacity: 0.85,
    bottomDarkOpacity: 1.0,
    defaultCacheWidth: 1280,
  );

  const HeroGradientStrength({
    required this.leftDarkOpacity,
    required this.bottomDarkOpacity,
    required this.defaultCacheWidth,
  });

  final double leftDarkOpacity;

  /// Bottom-gradient opacity; the very bottom is fully the background color.
  final double bottomDarkOpacity;

  /// Default decode width in logical pixels (multiplied by DPR).
  final int defaultCacheWidth;
}
