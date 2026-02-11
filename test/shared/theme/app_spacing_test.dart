// Тесты для AppSpacing.

import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/theme/app_spacing.dart';

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
      });

      test('конкретные значения', () {
        expect(AppSpacing.radiusXs, equals(4));
        expect(AppSpacing.radiusSm, equals(8));
        expect(AppSpacing.radiusMd, equals(12));
        expect(AppSpacing.radiusLg, equals(16));
      });
    });
  });
}
