// Application color palette.

import 'package:flutter/material.dart';

/// Application color palette (dark theme).
///
/// All colors are static constants for consistency across widgets.
abstract final class AppColors {
  // ==================== Backgrounds ====================

  /// Main app background.
  static const Color background = Color(0xFF0A0A0A);

  /// Surface background (cards, panels).
  static const Color surface = Color(0xFF141414);

  /// Elevated surface background (hover, selected items).
  static const Color surfaceLight = Color(0xFF1E1E1E);

  /// Surface border.
  static const Color surfaceBorder = Color(0xFF2A2A2A);

  // ==================== Text ====================

  /// Primary text.
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Secondary text (subtitles, captions).
  static const Color textSecondary = Color(0xFFB0B0B0);

  /// Tertiary text (disabled items, hints).
  static const Color textTertiary = Color(0xFF707070);

  // ==================== Brand / App Accent ====================

  /// Main app accent color (orange).
  static const Color brand = Color(0xFFEF7B44);

  // ==================== Media type accents ====================

  /// Accent for games (indigo).
  static const Color gameAccent = Color(0xFF707DD2);

  /// Accent for movies (orange).
  static const Color movieAccent = Color(0xFFEF7B44);

  /// Accent for TV shows (lime).
  static const Color tvShowAccent = Color(0xFFB1E140);

  /// Accent for animation (purple).
  static const Color animationAccent = Color(0xFFA86ED4);

  /// Accent for visual novels (blue).
  static const Color visualNovelAccent = Color(0xFF2A5FC1);

  /// Accent for manga (AniList light blue).
  static const Color mangaAccent = Color(0xFF3DB4F2);

  /// Accent for anime (AniList pink).
  static const Color animeAccent = Color(0xFFE85D75);

  /// Accent for books (OpenLibrary brown).
  static const Color bookAccent = Color(0xFF9B6A4F);

  /// Accent for custom items (teal).
  static const Color customAccent = Color(0xFF26A69A);

  // ==================== Semantic colors ====================

  /// Success (completed, done).
  static const Color success = Color(0xFF66BB6A);

  /// Warning (on hold, paused).
  static const Color warning = Color(0xFFFFA726);

  /// Error.
  static const Color error = Color(0xFFEF5350);

  // ==================== Statuses ====================

  /// "In Progress" status (playing/watching).
  static const Color statusInProgress = Color(0xFF42A5F5);

  /// "Completed" status.
  static const Color statusCompleted = success;

  /// "Dropped" status.
  static const Color statusDropped = error;

  /// "Planned" status (backlog, wishlist).
  static const Color statusPlanned = Color(0xFF8B5CF6);

  // ==================== Ratings ====================

  /// Rating star icon (amber).
  static const Color ratingStar = Color(0xFFF59E0B);

  /// High rating (>= 8.0).
  static const Color ratingHigh = Color(0xFF22C55E);

  /// Medium rating (>= 6.0).
  static const Color ratingMedium = Color(0xFFFBBF24);

  /// Low rating (< 6.0).
  static const Color ratingLow = Color(0xFFEF4444);
}
