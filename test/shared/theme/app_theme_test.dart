// Тесты для AppTheme.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/theme/app_colors.dart';
import 'package:xerabora/shared/theme/app_theme.dart';
import 'package:xerabora/shared/theme/app_typography.dart';

void main() {
  group('AppTheme', () {
    final ThemeData theme = AppTheme.darkTheme;

    test('должна быть тёмной', () {
      expect(theme.brightness, equals(Brightness.dark));
    });

    test('должна использовать Material 3', () {
      expect(theme.useMaterial3, isTrue);
    });

    test('должна использовать Inter как fontFamily в textTheme', () {
      expect(
        theme.textTheme.bodyMedium?.fontFamily,
        equals(AppTypography.fontFamily),
      );
    });

    test('scaffoldBackgroundColor должен быть transparent (тайловый фон в builder)', () {
      expect(theme.scaffoldBackgroundColor, equals(Colors.transparent));
    });

    group('ColorScheme', () {
      test('primary должен быть gameAccent', () {
        expect(theme.colorScheme.primary, equals(AppColors.gameAccent));
      });

      test('surface должен быть AppColors.surface', () {
        expect(theme.colorScheme.surface, equals(AppColors.surface));
      });

      test('onSurface должен быть textPrimary', () {
        expect(theme.colorScheme.onSurface, equals(AppColors.textPrimary));
      });

      test('error должен быть AppColors.error', () {
        expect(theme.colorScheme.error, equals(AppColors.error));
      });
    });

    group('AppBarTheme', () {
      test('backgroundColor должен быть background', () {
        expect(theme.appBarTheme.backgroundColor, equals(AppColors.background));
      });

      test('elevation должен быть 0', () {
        expect(theme.appBarTheme.elevation, equals(0));
      });

      test('foregroundColor должен быть textPrimary', () {
        expect(
          theme.appBarTheme.foregroundColor,
          equals(AppColors.textPrimary),
        );
      });
    });

    group('CardTheme', () {
      test('color должен быть surface', () {
        expect(theme.cardTheme.color, equals(AppColors.surface));
      });

      test('elevation должен быть 0', () {
        expect(theme.cardTheme.elevation, equals(0));
      });
    });

    group('InputDecorationTheme', () {
      test('fillColor должен быть surfaceLight', () {
        expect(
          theme.inputDecorationTheme.fillColor,
          equals(AppColors.surfaceLight),
        );
      });

      test('filled должен быть true', () {
        expect(theme.inputDecorationTheme.filled, isTrue);
      });
    });

    group('DialogTheme', () {
      test('backgroundColor должен быть surface', () {
        expect(theme.dialogTheme.backgroundColor, equals(AppColors.surface));
      });
    });

    group('BottomSheetTheme', () {
      test('backgroundColor должен быть surface', () {
        expect(
          theme.bottomSheetTheme.backgroundColor,
          equals(AppColors.surface),
        );
      });
    });

    group('NavigationRailTheme', () {
      test('backgroundColor должен быть surface', () {
        expect(
          theme.navigationRailTheme.backgroundColor,
          equals(AppColors.surface),
        );
      });
    });

    group('TabBarTheme', () {
      test('indicatorColor должен быть gameAccent', () {
        expect(theme.tabBarTheme.indicatorColor, equals(AppColors.gameAccent));
      });
    });
  });
}
