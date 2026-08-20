import 'package:flutter/material.dart';

import 'app_palette.dart';

export 'app_palette.dart';

/// Getters, not consts, so the app re-skins when [palette] is swapped; the
/// MaterialApp subtree is remounted on switch to flush stale consts.
abstract final class AppColors {
  /// The active palette; swapped by the app root on theme change.
  static AppPalette palette = AppPalette.dark;

  /// Main app background.
  static Color get background => palette.background;

  /// Surface background (cards, panels).
  static Color get surface => palette.surface;

  /// Elevated surface background (hover, selected items).
  static Color get surfaceLight => palette.surfaceLight;

  /// Surface border.
  static Color get surfaceBorder => palette.surfaceBorder;

  /// Primary text.
  static Color get textPrimary => palette.textPrimary;

  /// Secondary text (subtitles, captions).
  static Color get textSecondary => palette.textSecondary;

  /// Tertiary text (disabled items, hints).
  static Color get textTertiary => palette.textTertiary;

  /// Main app accent color.
  static Color get brand => palette.brand;

  /// Text/icons on top of [brand]-filled controls.
  static Color get onBrand => palette.onBrand;

  /// Accent for games.
  static Color get gameAccent => palette.gameAccent;

  /// Accent for movies.
  static Color get movieAccent => palette.movieAccent;

  /// Accent for TV shows.
  static Color get tvShowAccent => palette.tvShowAccent;

  /// Accent for animation.
  static Color get animationAccent => palette.animationAccent;

  /// Accent for visual novels.
  static Color get visualNovelAccent => palette.visualNovelAccent;

  /// Accent for manga.
  static Color get mangaAccent => palette.mangaAccent;

  /// Accent for anime.
  static Color get animeAccent => palette.animeAccent;

  /// Accent for books.
  static Color get bookAccent => palette.bookAccent;

  static Color get audioAccent => palette.audioAccent;

  /// Accent for custom items.
  static Color get customAccent => palette.customAccent;

  /// Success (completed, done).
  static Color get success => palette.success;

  /// Warning (on hold, paused).
  static Color get warning => palette.warning;

  /// Error.
  static Color get error => palette.error;

  /// Favorite heart (filled).
  static Color get favorite => palette.favorite;

  /// "In Progress" status (playing/watching).
  static Color get statusInProgress => palette.statusInProgress;

  /// "Completed" status.
  static Color get statusCompleted => palette.statusCompleted;

  /// "Dropped" status.
  static Color get statusDropped => palette.statusDropped;

  /// "Planned" status (backlog, wishlist).
  static Color get statusPlanned => palette.statusPlanned;

  /// "Replay" status (replaying / rewatching / rereading).
  static Color get statusReplaying => palette.statusReplaying;

  /// "Ignored" status — muted on purpose, the item is parked.
  static Color get statusIgnored => palette.statusIgnored;

  /// Rating star icon.
  static Color get ratingStar => palette.ratingStar;

  /// High rating (>= 8.0).
  static Color get ratingHigh => palette.ratingHigh;

  /// Medium rating (>= 6.0).
  static Color get ratingMedium => palette.ratingMedium;

  /// Low rating (< 6.0).
  static Color get ratingLow => palette.ratingLow;

  /// Community-rating gold in card meta lines.
  static Color get ratingGold => palette.ratingGold;

  /// Base for gradients/dimming over poster art (`withAlpha` at call site).
  static Color get scrim => palette.scrim;

  /// Text/icons drawn over [scrim]-dimmed images.
  static Color get onOverlay => palette.onOverlay;

  /// Modal barrier behind dialogs and fullscreen viewers.
  static Color get barrier => palette.barrier;

  /// Drop shadows (cards, floating panels).
  static Color get shadow => palette.shadow;

  /// Edge-fade base of horizontally scrollable rows.
  static Color get rowFade => palette.rowFade;

  /// Counter badge fill (nav bell / wishlist counts).
  static Color get badge => palette.badge;

  /// Counter badge text on [badge].
  static Color get onBadge => palette.onBadge;

  /// Tiled wallpaper image of the active palette.
  static DecorationImage get tileImage => palette.tileImage;
}
