import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/theme/app_palette.dart';
import 'package:tonkatsu_box/shared/theme/app_theme_id.dart';

double _contrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  return la > lb ? (la + 0.05) / (lb + 0.05) : (lb + 0.05) / (la + 0.05);
}

typedef _Pair = (
  String,
  Color Function(AppPalette),
  Color Function(AppPalette),
  double,
);

final List<_Pair> _pairs = <_Pair>[
  (
    'textPrimary/background',
    (AppPalette p) => p.textPrimary,
    (AppPalette p) => p.background,
    4.5,
  ),
  (
    'textPrimary/surface',
    (AppPalette p) => p.textPrimary,
    (AppPalette p) => p.surface,
    4.5,
  ),
  (
    'textPrimary/surfaceLight',
    (AppPalette p) => p.textPrimary,
    (AppPalette p) => p.surfaceLight,
    4.5,
  ),
  (
    'textSecondary/background',
    (AppPalette p) => p.textSecondary,
    (AppPalette p) => p.background,
    3.0,
  ),
  (
    'textTertiary/background',
    (AppPalette p) => p.textTertiary,
    (AppPalette p) => p.background,
    2.5,
  ),
  (
    'onBrand/brand',
    (AppPalette p) => p.onBrand,
    (AppPalette p) => p.brand,
    3.0,
  ),
  (
    'onBadge/badge',
    (AppPalette p) => p.onBadge,
    (AppPalette p) => p.badge,
    3.0,
  ),
  (
    'onOverlay/scrim',
    (AppPalette p) => p.onOverlay,
    (AppPalette p) => p.scrim,
    4.5,
  ),
  (
    'onBrandContainer/brandContainer',
    (AppPalette p) => p.onBrandContainer,
    (AppPalette p) => p.brandContainer,
    4.5,
  ),
];

void main() {
  group('AppThemeId palettes', () {
    test('should round-trip every theme through its stored id', () {
      for (final AppThemeId theme in AppThemeId.values) {
        expect(AppThemeId.fromId(theme.id), theme);
      }
    });

    test('should give every theme its own palette', () {
      final Set<AppPalette> palettes = <AppPalette>{
        for (final AppThemeId theme in AppThemeId.values) theme.palette,
      };
      expect(palettes, hasLength(AppThemeId.values.length));
    });

    test('should point every palette at a background tile that exists', () {
      final List<String> missing = <String>[
        for (final AppThemeId theme in AppThemeId.values)
          if (!File(theme.palette.tileAsset).existsSync()) theme.id,
      ];
      expect(missing, isEmpty);
    });

    // A theme switch once left white text on a white surface; this keeps
    // every text pair readable in every theme, including future ones.
    test('should keep text readable on every surface of every theme', () {
      final List<String> failures = <String>[
        for (final AppThemeId theme in AppThemeId.values)
          for (final _Pair pair in _pairs)
            if (_contrast(pair.$2(theme.palette), pair.$3(theme.palette)) <
                pair.$4)
              '${theme.id}: ${pair.$1}',
      ];
      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    test('should keep brandContainer distinct from brand', () {
      for (final AppThemeId theme in AppThemeId.values) {
        expect(
          theme.palette.brandContainer,
          isNot(theme.palette.brand),
          reason: theme.id,
        );
      }
    });
  });
}
