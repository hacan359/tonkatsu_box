import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/theme/app_colors.dart';
import 'package:tonkatsu_box/shared/theme/app_theme.dart';
import 'package:tonkatsu_box/shared/theme/app_typography.dart';

void main() {
  // Other suites assume the default dark palette — always restore it.
  tearDown(() {
    AppColors.palette = AppPalette.dark;
  });

  group('AppColors palette switching', () {
    test('геттеры читают активную палитру', () {
      AppColors.palette = AppPalette.dark;
      expect(AppColors.background, AppPalette.dark.background);
      expect(AppColors.brand, AppPalette.dark.brand);

      AppColors.palette = AppPalette.sakura;
      expect(AppColors.background, AppPalette.sakura.background);
      expect(AppColors.brand, AppPalette.sakura.brand);
    });

    test('производные статусы следуют за палитрой', () {
      AppColors.palette = AppPalette.sakura;
      expect(AppColors.statusCompleted, AppPalette.sakura.success);
      expect(AppColors.statusDropped, AppPalette.sakura.error);
    });
  });

  group('AppTypography palette switching', () {
    // Regression: styles were `static final` and froze the palette active
    // at first access, surviving a theme switch (white-on-white bug).
    test('стили перечитывают палитру после переключения', () {
      AppColors.palette = AppPalette.dark;
      expect(AppTypography.h1.color, AppPalette.dark.textPrimary);

      AppColors.palette = AppPalette.sakura;
      expect(AppTypography.h1.color, AppPalette.sakura.textPrimary);
      expect(AppTypography.body.color, AppPalette.sakura.textPrimary);
      expect(AppTypography.caption.color, AppPalette.sakura.textTertiary);
    });
  });

  group('AppTheme.build', () {
    test('brightness берётся из палитры', () {
      expect(AppTheme.build(AppPalette.dark).brightness, Brightness.dark);
      expect(AppTheme.build(AppPalette.sakura).brightness, Brightness.light);
    });

    test('darkTheme собран из тёмной палитры', () {
      expect(AppTheme.darkTheme.brightness, Brightness.dark);
      expect(
        AppTheme.darkTheme.colorScheme.primary,
        AppPalette.dark.brand,
      );
    });

    test('colorScheme собирается из переданной палитры', () {
      final ThemeData theme = AppTheme.build(AppPalette.sakura);
      expect(theme.colorScheme.primary, AppPalette.sakura.brand);
      expect(theme.colorScheme.onPrimary, AppPalette.sakura.onBrand);
      expect(theme.colorScheme.surface, AppPalette.sakura.surface);
    });

    test('производные роли следуют за палитрой, как в 0.41', () {
      // Both ColorScheme() and the 0.41 ColorScheme.dark(...) leave the
      // derived roles null, so the getters resolve them from our overrides.
      final ColorScheme scheme = AppTheme.darkTheme.colorScheme;
      expect(scheme.primaryContainer, AppPalette.dark.brand);
      expect(scheme.errorContainer, AppPalette.dark.error);
      expect(scheme.onSurfaceVariant, AppPalette.dark.textPrimary);
    });
  });
}
