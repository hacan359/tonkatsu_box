import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_surface.dart';

/// One block of the app frame: blurred backdrop under a translucent fill, a
/// hairline edge and a faint top highlight. What it is made of is the skin's.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    required this.child,
    this.width,
    this.height,
    this.radius,
    this.borderRadius,
    this.padding = EdgeInsets.zero,
    this.blurSigma,
    this.fill,
    super.key,
  });

  final Widget child;

  /// Overrides the skin's fill; transparent shows the wallpaper through.
  final Color? fill;
  final double? width;
  final double? height;

  /// Defaults to the skin's panel radius.
  final double? radius;

  /// Defaults to the skin's modal blur; 0 skips the backdrop filter.
  final double? blurSigma;

  /// Overrides [radius], for a sheet rounded on top only.
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final BorderRadius r =
        borderRadius ?? BorderRadius.circular(radius ?? AppSurface.panelRadius);
    final double sigma = blurSigma ?? AppSurface.modalBlurSigma;
    final Widget box = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: r,
        color: fill ?? AppSurface.panelFill(),
        border: Border.all(color: AppSurface.panelEdge()),
      ),
      // Separate layer: a BoxDecoration with a gradient drops its color.
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: r,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              AppSurface.panelHighlight(),
              Colors.white.withAlpha(0),
            ],
            stops: const <double>[0, 0.35],
          ),
        ),
        // Ink and ListTile backgrounds paint on the nearest Material;
        // without one here the decorated box above would hide them.
        child: Material(
          type: MaterialType.transparency,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
    return ClipRRect(
      borderRadius: r,
      child: sigma > 0
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
              child: box,
            )
          : box,
    );
  }
}

/// Nested tile for a card inside a panel: no second blur, so the wallpaper
/// still shows through on a translucent skin.
Color glassTileColor() => AppSurface.tileFill();

Color glassTileBorderColor() => AppSurface.tileEdge();

/// Small controls (chips, tags, filter tiles) read badly on a translucent
/// tile, so they sit on a near-solid surface, optionally tinted by [tint].
Color glassChipColor({Color? tint, int tintAlpha = 0}) =>
    AppSurface.chipFill(tint: tint, tintAlpha: tintAlpha);

/// The nested tile as a decoration, for a box that lays out its own child
/// or animates; [GlassTile] is the same look with a shadow.
BoxDecoration glassTileDecoration({
  double radius = AppSpacing.radiusMd,
  double borderWidth = 1,
}) => BoxDecoration(
  color: glassTileColor(),
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: glassTileBorderColor(), width: borderWidth),
);

/// The tile for a box drawn over a picture: its fill never goes opaque, so
/// the picture keeps showing through in every skin.
BoxDecoration pictureTileDecoration({double radius = AppSpacing.radiusMd}) =>
    BoxDecoration(
      color: AppSurface.pictureTileFill(),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: glassTileBorderColor()),
    );

/// A floating block on the panel: the nested tile with a soft drop shadow
/// where the skin allows one, for grouping one piece of a page.
class GlassTile extends StatelessWidget {
  const GlassTile({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.radius = AppSpacing.radiusMd,
    this.background,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Artwork laid under [child], clipped to the tile's corners.
  final Widget? background;

  @override
  Widget build(BuildContext context) {
    final BorderRadius r = BorderRadius.circular(radius);
    final Widget? background = this.background;
    final Widget body = Padding(padding: padding, child: child);
    return Container(
      decoration: glassTileDecoration(radius: radius).copyWith(
        boxShadow: AppSurface.tileShadow
            ? <BoxShadow>[
                BoxShadow(
                  color: AppColors.shadow.withAlpha(70),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                  spreadRadius: -6,
                ),
              ]
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: r,
        clipBehavior: Clip.antiAlias,
        child: background == null
            ? body
            : Stack(
                children: <Widget>[
                  Positioned.fill(child: background),
                  body,
                ],
              ),
      ),
    );
  }
}
