import 'package:flutter/material.dart';

import 'palettes/dark_palette.dart';
import 'palettes/sakura_palette.dart';

export 'palettes/dark_palette.dart';
export 'palettes/sakura_palette.dart';

/// Widgets never read a palette directly — they go through [AppColors].
/// A new theme is a file under `palettes/`, an alias here, an [AppThemeId].
@immutable
class AppPalette {
  const AppPalette({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceLight,
    required this.surfaceBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.brand,
    required this.onBrand,
    required this.gameAccent,
    required this.movieAccent,
    required this.tvShowAccent,
    required this.animationAccent,
    required this.visualNovelAccent,
    required this.mangaAccent,
    required this.animeAccent,
    required this.bookAccent,
    required this.audioAccent,
    required this.customAccent,
    required this.success,
    required this.warning,
    required this.error,
    required this.favorite,
    required this.statusInProgress,
    required this.statusPlanned,
    required this.statusReplaying,
    required this.ratingStar,
    required this.ratingHigh,
    required this.ratingMedium,
    required this.ratingLow,
    required this.ratingGold,
    required this.scrim,
    required this.onOverlay,
    required this.barrier,
    required this.shadow,
    required this.rowFade,
    required this.badge,
    required this.onBadge,
    required this.tileAsset,
    required this.tileOpacity,
  });

  static const AppPalette dark = darkPalette;

  static const AppPalette sakura = sakuraPalette;

  final Brightness brightness;

  final Color background;
  final Color surface;
  final Color surfaceLight;
  final Color surfaceBorder;

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  final Color brand;

  /// Text/icons drawn on top of [brand]-filled controls.
  final Color onBrand;

  final Color gameAccent;
  final Color movieAccent;
  final Color tvShowAccent;
  final Color animationAccent;
  final Color visualNovelAccent;
  final Color mangaAccent;
  final Color animeAccent;
  final Color bookAccent;
  final Color audioAccent;
  final Color customAccent;

  final Color success;
  final Color warning;
  final Color error;
  final Color favorite;

  final Color statusInProgress;
  Color get statusCompleted => success;
  Color get statusDropped => error;
  final Color statusPlanned;
  final Color statusReplaying;

  final Color ratingStar;
  final Color ratingHigh;
  final Color ratingMedium;
  final Color ratingLow;

  /// Community-rating gold in card meta lines — sits on [surface], so it
  /// needs a darker shade on light themes.
  final Color ratingGold;

  /// Base for gradients/dimming over poster art — theme-independent, use
  /// `withAlpha`/`withValues` at the call site.
  final Color scrim;

  /// Text/icons drawn over [scrim]-dimmed images — theme-independent.
  final Color onOverlay;

  /// Modal barrier behind dialogs and fullscreen viewers.
  final Color barrier;

  /// Drop shadows (cards, floating panels).
  final Color shadow;

  /// Edge-fade base of horizontally scrollable rows.
  final Color rowFade;

  /// Counter badge fill (nav bell / wishlist counts).
  final Color badge;

  /// Counter badge text on [badge].
  final Color onBadge;

  /// Tiled wallpaper asset (route backgrounds, bottom sheets).
  final String tileAsset;

  /// Wallpaper opacity — the light theme needs a stronger tile to read.
  final double tileOpacity;

  DecorationImage get tileImage => DecorationImage(
        image: AssetImage(tileAsset),
        repeat: ImageRepeat.repeat,
        opacity: tileOpacity,
        scale: 0.667,
      );
}
