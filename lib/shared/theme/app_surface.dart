import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_skin.dart';

export 'app_skin.dart';

/// The active palette and skin resolved into paint: widgets read colours and
/// sizes here and never branch on brightness or skin themselves.
abstract final class AppSurface {
  /// The active skin; swapped by the app root together with the palette.
  static AppSkin skin = AppSkin.glass;

  static AppPalette _p(AppPalette? palette) => palette ?? AppColors.palette;

  static Brightness _b(AppPalette? palette) => _p(palette).brightness;

  /// Neutral frost reads white on a light palette and black on a dark one.
  static Color _frost(AppPalette? palette) =>
      _b(palette) == Brightness.light ? Colors.white : Colors.black;

  static Color panelFill([AppPalette? palette]) {
    final int alpha = skin.panelFrost.of(_b(palette));
    return switch (skin.panelFill) {
      SkinFill.frost => _frost(palette).withAlpha(alpha),
      SkinFill.surface => _p(palette).surface.withAlpha(alpha),
    };
  }

  static Color panelEdge([AppPalette? palette]) {
    final int alpha = skin.panelEdge.of(_b(palette));
    return switch (skin.panelFill) {
      SkinFill.frost => Colors.white.withAlpha(alpha),
      SkinFill.surface => _p(palette).surfaceBorder.withAlpha(alpha),
    };
  }

  static Color panelHighlight([AppPalette? palette]) =>
      Colors.white.withAlpha(skin.panelHighlight.of(_b(palette)));

  static Color tileFill([AppPalette? palette]) =>
      _p(palette).surface.withAlpha(skin.tileAlpha.of(_b(palette)));

  /// A tile laid over a picture stays translucent in every skin, or the
  /// picture under it would vanish on an opaque one.
  static Color pictureTileFill([AppPalette? palette]) {
    final int alpha = skin.tileAlpha.of(_b(palette));
    return _p(palette).surface.withAlpha(math.min(alpha, _pictureTileMaxAlpha));
  }

  static const int _pictureTileMaxAlpha = 120;

  /// On frost a dark palette gets a white hairline; everything else uses the
  /// palette's border colour.
  static Color tileEdge([AppPalette? palette]) {
    final int alpha = skin.tileEdge.of(_b(palette));
    final bool whiteLine =
        skin.panelFill == SkinFill.frost && _b(palette) == Brightness.dark;
    return (whiteLine ? Colors.white : _p(palette).surfaceBorder).withAlpha(
      alpha,
    );
  }

  /// Near-solid surface for a chip, optionally tinted by [tint].
  static Color chipFill({Color? tint, int tintAlpha = 0, AppPalette? palette}) {
    final Color surface = _p(palette).surface;
    final Color base = tint == null
        ? surface
        : Color.alphaBlend(tint.withAlpha(tintAlpha), surface);
    return base.withAlpha(skin.chipAlpha);
  }

  static Color cardFill([AppPalette? palette]) {
    final int alpha = skin.cardAlpha.of(_b(palette));
    return switch (skin.panelFill) {
      SkinFill.frost => Colors.white.withAlpha(alpha),
      SkinFill.surface => _p(palette).surface.withAlpha(alpha),
    };
  }

  static Color sheen([AppPalette? palette]) =>
      Colors.white.withAlpha(skin.sheenAlpha.of(_b(palette)));

  static Color inputFill([AppPalette? palette]) =>
      _p(palette).surfaceLight.withAlpha(skin.inputFillAlpha);

  static Color modalFill([AppPalette? palette]) =>
      _p(palette).surface.withAlpha(skin.modalAlpha);

  static Color popupFill([AppPalette? palette]) =>
      _p(palette).surface.withAlpha(skin.popupAlpha);

  static double get panelRadius => skin.panelRadius;

  static double get frameGap => skin.frameGap;

  static double get wallpaperBlurSigma => skin.wallpaperBlurSigma;

  static double get modalBlurSigma => skin.modalBlurSigma;

  static bool get tileShadow => skin.tileShadow;

  static SkinWallpaper get wallpaper => skin.wallpaper;

  static bool get contentOnWallpaper => skin.contentOnWallpaper;

  static double get cardElevation => skin.cardElevation;

  static bool get detailBackdrop => skin.detailBackdrop;

  /// The one scrim for dialogs, sheets and overlays: palette hue, skin depth.
  static Color barrier([AppPalette? palette]) =>
      _p(palette).barrier.withAlpha(skin.barrierAlpha.of(_b(palette)));
}
