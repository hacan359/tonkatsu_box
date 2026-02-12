// Тесты для AppTypography.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/theme/app_colors.dart';
import 'package:xerabora/shared/theme/app_typography.dart';

void main() {
  group('AppTypography', () {
    test('fontFamily должен быть Inter', () {
      expect(AppTypography.fontFamily, equals('Inter'));
    });

    test('h1 должен быть самым крупным', () {
      expect(AppTypography.h1.fontSize, greaterThan(AppTypography.h2.fontSize!));
    });

    test('h2 должен быть крупнее h3', () {
      expect(AppTypography.h2.fontSize, greaterThan(AppTypography.h3.fontSize!));
    });

    test('h3 должен быть крупнее body', () {
      expect(AppTypography.h3.fontSize, greaterThan(AppTypography.body.fontSize!));
    });

    test('body должен быть крупнее bodySmall', () {
      expect(
        AppTypography.body.fontSize,
        greaterThan(AppTypography.bodySmall.fontSize!),
      );
    });

    test('bodySmall должен быть крупнее caption', () {
      expect(
        AppTypography.bodySmall.fontSize,
        greaterThan(AppTypography.caption.fontSize!),
      );
    });

    test('заголовки должны быть жирными', () {
      expect(AppTypography.h1.fontWeight, equals(FontWeight.bold));
      expect(AppTypography.h2.fontWeight, equals(FontWeight.w600));
      expect(AppTypography.h3.fontWeight, equals(FontWeight.w600));
    });

    test('body должен быть обычного веса', () {
      expect(AppTypography.body.fontWeight, equals(FontWeight.normal));
      expect(AppTypography.bodySmall.fontWeight, equals(FontWeight.normal));
    });

    test('все стили должны использовать цвета из AppColors', () {
      expect(AppTypography.h1.color, equals(AppColors.textPrimary));
      expect(AppTypography.h2.color, equals(AppColors.textPrimary));
      expect(AppTypography.h3.color, equals(AppColors.textPrimary));
      expect(AppTypography.body.color, equals(AppColors.textPrimary));
      expect(AppTypography.bodySmall.color, equals(AppColors.textSecondary));
      expect(AppTypography.caption.color, equals(AppColors.textTertiary));
    });

    test('все стили должны иметь line height', () {
      expect(AppTypography.h1.height, isNotNull);
      expect(AppTypography.h2.height, isNotNull);
      expect(AppTypography.h3.height, isNotNull);
      expect(AppTypography.body.height, isNotNull);
      expect(AppTypography.bodySmall.height, isNotNull);
      expect(AppTypography.caption.height, isNotNull);
    });

    test('все стили должны использовать Inter', () {
      expect(AppTypography.h1.fontFamily, equals('Inter'));
      expect(AppTypography.h2.fontFamily, equals('Inter'));
      expect(AppTypography.h3.fontFamily, equals('Inter'));
      expect(AppTypography.body.fontFamily, equals('Inter'));
      expect(AppTypography.bodySmall.fontFamily, equals('Inter'));
      expect(AppTypography.caption.fontFamily, equals('Inter'));
    });

    test('h1 и h2 должны иметь отрицательный letterSpacing', () {
      expect(AppTypography.h1.letterSpacing, equals(-0.5));
      expect(AppTypography.h2.letterSpacing, equals(-0.2));
    });

    group('Poster стили', () {
      test('posterTitle должен быть определён', () {
        expect(AppTypography.posterTitle.fontSize, equals(14));
        expect(AppTypography.posterTitle.fontWeight, equals(FontWeight.w600));
        expect(AppTypography.posterTitle.color, equals(AppColors.textPrimary));
        expect(AppTypography.posterTitle.fontFamily, equals('Inter'));
      });

      test('posterSubtitle должен быть определён', () {
        expect(AppTypography.posterSubtitle.fontSize, equals(11));
        expect(AppTypography.posterSubtitle.fontWeight, equals(FontWeight.w400));
        expect(AppTypography.posterSubtitle.color, equals(AppColors.textSecondary));
        expect(AppTypography.posterSubtitle.fontFamily, equals('Inter'));
      });
    });
  });
}
