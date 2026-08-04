import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/theme/app_spacing.dart';
import 'package:tonkatsu_box/shared/theme/app_typography.dart';

void main() {
  group('AppSpacing', () {
    group('Отступы', () {
      test('должны быть в порядке возрастания', () {
        expect(AppSpacing.xs, lessThan(AppSpacing.sm));
        expect(AppSpacing.sm, lessThan(AppSpacing.md));
        expect(AppSpacing.md, lessThan(AppSpacing.lg));
        expect(AppSpacing.lg, lessThan(AppSpacing.xl));
      });

      test('должны быть кратны 4', () {
        expect(AppSpacing.xs % 4, equals(0));
        expect(AppSpacing.sm % 4, equals(0));
        expect(AppSpacing.md % 4, equals(0));
        expect(AppSpacing.lg % 4, equals(0));
        expect(AppSpacing.xl % 4, equals(0));
      });

      test('конкретные значения', () {
        expect(AppSpacing.xs, equals(4));
        expect(AppSpacing.sm, equals(8));
        expect(AppSpacing.md, equals(16));
        expect(AppSpacing.lg, equals(24));
        expect(AppSpacing.xl, equals(32));
      });
    });

    group('Радиусы', () {
      test('должны быть в порядке возрастания', () {
        expect(AppSpacing.radiusXs, lessThan(AppSpacing.radiusSm));
        expect(AppSpacing.radiusSm, lessThan(AppSpacing.radiusMd));
        expect(AppSpacing.radiusMd, lessThan(AppSpacing.radiusLg));
        expect(AppSpacing.radiusLg, lessThan(AppSpacing.radiusXl));
      });

      test('конкретные значения', () {
        expect(AppSpacing.radiusXs, equals(4));
        expect(AppSpacing.radiusSm, equals(8));
        expect(AppSpacing.radiusMd, equals(12));
        expect(AppSpacing.radiusLg, equals(16));
        expect(AppSpacing.radiusXl, equals(20));
      });
    });

    group('Сетка', () {
      test('posterAspectRatio должен быть 2:3', () {
        expect(AppSpacing.posterAspectRatio, closeTo(0.6667, 0.001));
      });

      test('колонки сетки должны убывать от desktop к mobile', () {
        expect(AppSpacing.gridColumnsDesktop,
            greaterThan(AppSpacing.gridColumnsTablet));
        expect(AppSpacing.gridColumnsTablet,
            greaterThan(AppSpacing.gridColumnsMobile));
      });

      test('конкретные значения колонок', () {
        expect(AppSpacing.gridColumnsDesktop, equals(6));
        expect(AppSpacing.gridColumnsTablet, equals(4));
        expect(AppSpacing.gridColumnsMobile, equals(3));
      });
    });

    group('scaledColumns', () {
      test('масштаб 1.0 возвращает базовое число колонок', () {
        expect(AppSpacing.scaledColumns(3, 1.0), equals(3));
        expect(AppSpacing.scaledColumns(4, 1.0), equals(4));
        expect(AppSpacing.scaledColumns(6, 1.0), equals(6));
      });

      test('крупные карточки уменьшают число колонок', () {
        expect(AppSpacing.scaledColumns(3, 1.5), equals(2));
        expect(AppSpacing.scaledColumns(4, 1.3), equals(3));
        expect(AppSpacing.scaledColumns(6, 1.6), equals(4));
      });

      test('мелкие карточки увеличивают число колонок', () {
        expect(AppSpacing.scaledColumns(3, 0.7), equals(4));
        expect(AppSpacing.scaledColumns(4, 0.8), equals(5));
        expect(AppSpacing.scaledColumns(6, 0.7), equals(8));
      });

      test('результат ограничен диапазоном 2..8', () {
        expect(AppSpacing.scaledColumns(3, 10.0), equals(2));
        expect(AppSpacing.scaledColumns(8, 0.1), equals(8));
      });
    });

    group('cardTitleBlockHeight', () {
      test('должен складывать отступ и высоту текстового блока', () {
        expect(
          AppSpacing.cardTitleBlockHeight(
            compact: false,
            textScaler: TextScaler.noScaling,
          ),
          equals(
            AppSpacing.cardTitleBlockGap(compact: false) +
                AppTypography.posterTextBlockHeight(
                  compact: false,
                  textScaler: TextScaler.noScaling,
                ),
          ),
        );
      });

      test('компактная карточка ниже обычной', () {
        expect(
          AppSpacing.cardTitleBlockHeight(
            compact: true,
            textScaler: TextScaler.noScaling,
          ),
          lessThan(
            AppSpacing.cardTitleBlockHeight(
              compact: false,
              textScaler: TextScaler.noScaling,
            ),
          ),
        );
      });

      test('должен расти вместе с системным масштабом шрифта', () {
        expect(
          AppSpacing.cardTitleBlockHeight(
            compact: false,
            textScaler: const TextScaler.linear(2),
          ),
          greaterThan(
            AppSpacing.cardTitleBlockHeight(
              compact: false,
              textScaler: TextScaler.noScaling,
            ),
          ),
        );
      });
    });

    group('posterRowHeight', () {
      test('должен складывать постер 2:3, блок названия и паддинги списка', () {
        expect(
          AppSpacing.posterRowHeight(
            posterWidth: 130,
            compact: false,
            textScaler: TextScaler.noScaling,
          ),
          closeTo(
            130 / AppSpacing.posterAspectRatio +
                AppSpacing.cardTitleBlockHeight(
                  compact: false,
                  textScaler: TextScaler.noScaling,
                ) +
                2 * AppSpacing.posterRowVerticalPadding,
            0.001,
          ),
        );
      });

      test('более широкий постер даёт более высокий ряд', () {
        expect(
          AppSpacing.posterRowHeight(
            posterWidth: 130,
            compact: false,
            textScaler: TextScaler.noScaling,
          ),
          greaterThan(
            AppSpacing.posterRowHeight(
              posterWidth: 100,
              compact: false,
              textScaler: TextScaler.noScaling,
            ),
          ),
        );
      });
    });
  });
}
