import 'package:flutter/material.dart';

import '../app_assets.dart';
import '../app_palette.dart';

/// Eva Design System shade card: Primary column for the skeleton, the other
/// hues for semantic roles at the darkest step that reads on the pale ground.
const AppPalette evaPalette = AppPalette(
  brightness: Brightness.light,
  // Primary 100 — the pale end of the card's own column.
  background: Color(0xFFD6E4FF),
  // Plain white so panels float; surfaceLight is the midpoint back to 100.
  surface: Color(0xFFFFFFFF),
  surfaceLight: Color(0xFFEAF2FF),
  surfaceBorder: Color(0xFFADC8FF), // Primary 200
  // Primary 800 / 700 — a near-black indigo, the card's own dark end.
  textPrimary: Color(0xFF102693),
  textSecondary: Color(0xFF1A39B6),
  // Primary 400 measures 2.34 here (under the 2.5 floor), so this tier is the
  // same hue de-saturated: 3.35.
  textTertiary: Color(0xFF6C7A9C),
  // Primary 500 exactly as the card prints it: a fill, so white clears 4.68.
  brand: Color(0xFF3366FF),
  onBrand: Color(0xFFFFFFFF),
  brandContainer: Color(0xFFDAE3FF),
  onBrandContainer: Color(0xFF0E1D47),
  // Primary 600 — darkened from 500 (3.66) to 5.16 for glyph duty.
  gameAccent: Color(0xFF254EDA),
  // Danger 700 — 500 measures 2.85 on the pale ground.
  movieAccent: Color(0xFFB71A39),
  // Success 700 — 500 measures 1.81 on the pale ground.
  tvShowAccent: Color(0xFF588409),
  // mix(Primary 600, Danger 700) — the card has no violet.
  animationAccent: Color(0xFF6E348A),
  visualNovelAccent: Color(0xFF102693), // Primary 800
  // Info 600 — 500 measures 1.80 on the pale ground.
  mangaAccent: Color(0xFF008DDC),
  // Danger 500 at the card's chroma; it already carries the badge.
  animeAccent: Color(0xFFFF3236),
  // Warning 800 — 500 measures 1.58 on the pale ground.
  bookAccent: Color(0xFF944C00),
  // mix(Danger 500, Primary 600) — the card has no magenta.
  audioAccent: Color(0xFF924088),
  // mix(Info 600, Success 700) — the card has no teal.
  customAccent: Color(0xFF2C8872),
  success: Color(0xFF588409), // Success 700
  warning: Color(0xFFB86600), // Warning 700
  error: Color(0xFFDB2438), // Danger 600
  favorite: Color(0xFFDB2438),
  statusInProgress: Color(0xFF254EDA), // Primary 600
  statusPlanned: Color(0xFF6E348A), // the violet above
  statusReplaying: Color(0xFF006AB6), // Info 700
  ratingStar: Color(0xFFB86600), // Warning 700
  ratingHigh: Color(0xFF588409), // Success 700
  ratingMedium: Color(0xFFDB8200), // Warning 600
  ratingLow: Color(0xFFB71A39), // Danger 700
  ratingGold: Color(0xFF944C00), // Warning 800
  scrim: Color(0xFF000000),
  onOverlay: Color(0xFFFFFFFF),
  barrier: Color(0x73000000),
  shadow: Color(0xFF000000),
  rowFade: Color(0xFFC2D6FF), // midway, background -> surfaceBorder
  // Danger 500 as printed: a filled counter badge, white reads 3.64.
  badge: Color(0xFFFF3236),
  onBadge: Color(0xFFFFFFFF),
  // Same glyph mask as the other themes, tinted to the card's Primary 500.
  tileAsset: AppAssets.backgroundTileEva,
  tileOpacity: 0.06,
);
