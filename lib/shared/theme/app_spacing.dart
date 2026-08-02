// Spacing and sizing constants.

import 'package:flutter/painting.dart';

import 'app_typography.dart';

/// Spacing and sizing constants.
///
/// One spacing system for a consistent UI.
/// Base step is 4px; the main values are multiples of it.
abstract final class AppSpacing {
  // ==================== Padding ====================

  /// 4px — minimal padding.
  static const double xs = 4;

  /// 8px — small padding.
  static const double sm = 8;

  /// 16px — standard padding.
  static const double md = 16;

  /// 24px — large padding.
  static const double lg = 24;

  /// 32px — extra large padding.
  static const double xl = 32;

  // ==================== Border radii ====================

  /// 2px — half-height rounding for 4px-tall elements
  /// (sheet grab handles, thin progress bars).
  static const double radiusXxs = 2;

  /// 4px — minimal rounding (badges, chips).
  static const double radiusXs = 4;

  /// 8px — small rounding (buttons, input fields).
  static const double radiusSm = 8;

  /// 12px — standard rounding (cards).
  static const double radiusMd = 12;

  /// 16px — large rounding (hero cards).
  static const double radiusLg = 16;

  /// 20px — extra large rounding (modal dialogs).
  static const double radiusXl = 20;

  // ==================== Controls ====================

  /// 48px — standard button height (filled/outlined buttons).
  static const double buttonHeight = 48;

  /// 36px — compact button height (inline and toolbar buttons that must
  /// not stretch to the theme's full-width default).
  static const double buttonHeightCompact = 36;

  /// 28px — dense chip-like button height (filter sheets).
  static const double buttonHeightDense = 28;

  // ==================== Grid ====================

  /// 16px — gap between grid cards.
  static const double gridGap = 16;

  /// 20px — content inset from screen edges.
  static const double screenPadding = 20;

  /// Poster aspect ratio (2:3).
  static const double posterAspectRatio = 2.0 / 3.0;

  /// Grid column count on desktop (>= 800px).
  static const int gridColumnsDesktop = 6;

  /// Grid column count on tablet (>= 500px).
  static const int gridColumnsTablet = 4;

  /// Grid column count on mobile (< 500px).
  static const int gridColumnsMobile = 3;

  /// Max card width on desktop grids at 100% card scale.
  static const double desktopMaxCardWidth = 170;

  /// Grid cell ratio for poster cards: a ~2:3 poster plus the title block
  /// below it.
  static const double posterCardAspectRatio = 0.55;

  /// Padding a horizontal poster row puts above and below its cards.
  static const double posterRowVerticalPadding = 4;

  /// Gap between the poster and the title block under it.
  static double cardTitleBlockGap({required bool compact}) => compact ? 2 : xs;

  /// Fixed height of the title + subtitle block under a poster card: the gap
  /// plus room for exactly two title lines and one subtitle line.
  static double cardTitleBlockHeight({
    required bool compact,
    required TextScaler textScaler,
  }) =>
      cardTitleBlockGap(compact: compact) +
      AppTypography.posterTextBlockHeight(
        compact: compact,
        textScaler: textScaler,
      );

  /// Height of a horizontal poster row: the 2:3 poster of [posterWidth], the
  /// title block under it and the list's vertical padding.
  static double posterRowHeight({
    required double posterWidth,
    required bool compact,
    required TextScaler textScaler,
  }) =>
      posterWidth / posterAspectRatio +
      cardTitleBlockHeight(compact: compact, textScaler: textScaler) +
      2 * posterRowVerticalPadding;

  /// Column count for fixed-count grids adjusted by the card scale setting:
  /// larger cards → fewer columns.
  static int scaledColumns(int base, double scale) =>
      (base / scale).round().clamp(2, 8);
}
