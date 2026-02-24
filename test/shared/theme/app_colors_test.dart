// Тесты для AppColors.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/theme/app_colors.dart';

void main() {
  group('AppColors', () {
    group('Фоны', () {
      test('background должен быть тёмным', () {
        expect(AppColors.background, isA<Color>());
        expect(AppColors.background.a, 1.0);
      });

      test('surface должен быть светлее background', () {
        expect(
          AppColors.surface.computeLuminance(),
          greaterThan(AppColors.background.computeLuminance()),
        );
      });

      test('surfaceLight должен быть светлее surface', () {
        expect(
          AppColors.surfaceLight.computeLuminance(),
          greaterThan(AppColors.surface.computeLuminance()),
        );
      });

      test('surfaceBorder должен быть определён', () {
        expect(AppColors.surfaceBorder, isA<Color>());
      });
    });

    group('Текст', () {
      test('textPrimary должен быть самым светлым', () {
        expect(
          AppColors.textPrimary.computeLuminance(),
          greaterThan(AppColors.textSecondary.computeLuminance()),
        );
      });

      test('textSecondary должен быть светлее textTertiary', () {
        expect(
          AppColors.textSecondary.computeLuminance(),
          greaterThan(AppColors.textTertiary.computeLuminance()),
        );
      });
    });

    group('Акценты по типам медиа', () {
      test('gameAccent должен быть определён', () {
        expect(AppColors.gameAccent, isA<Color>());
      });

      test('movieAccent должен быть определён', () {
        expect(AppColors.movieAccent, isA<Color>());
      });

      test('tvShowAccent должен быть определён', () {
        expect(AppColors.tvShowAccent, isA<Color>());
      });

      test('все акценты должны быть разными', () {
        expect(AppColors.gameAccent, isNot(equals(AppColors.movieAccent)));
        expect(AppColors.gameAccent, isNot(equals(AppColors.tvShowAccent)));
        expect(AppColors.movieAccent, isNot(equals(AppColors.tvShowAccent)));
      });
    });

    group('Семантические цвета', () {
      test('success должен быть определён', () {
        expect(AppColors.success, isA<Color>());
      });

      test('warning должен быть определён', () {
        expect(AppColors.warning, isA<Color>());
      });

      test('error должен быть определён', () {
        expect(AppColors.error, isA<Color>());
      });
    });

    group('Статусы', () {
      test('все статусные цвета должны быть определены', () {
        expect(AppColors.statusInProgress, isA<Color>());
        expect(AppColors.statusCompleted, isA<Color>());
        expect(AppColors.statusDropped, isA<Color>());
      });

      test('statusCompleted должен совпадать с success', () {
        expect(AppColors.statusCompleted, equals(AppColors.success));
      });

      test('statusDropped должен совпадать с error', () {
        expect(AppColors.statusDropped, equals(AppColors.error));
      });

      test('statusPlanned должен быть определён', () {
        expect(AppColors.statusPlanned, isA<Color>());
      });

      test('statusPlanned должен отличаться от других статусов', () {
        expect(
          AppColors.statusPlanned,
          isNot(equals(AppColors.statusInProgress)),
        );
        expect(
          AppColors.statusPlanned,
          isNot(equals(AppColors.statusCompleted)),
        );
      });
    });

    group('Рейтинги', () {
      test('ratingHigh должен быть определён', () {
        expect(AppColors.ratingHigh, isA<Color>());
      });

      test('ratingMedium должен быть определён', () {
        expect(AppColors.ratingMedium, isA<Color>());
      });

      test('ratingLow должен быть определён', () {
        expect(AppColors.ratingLow, isA<Color>());
      });

      test('все рейтинговые цвета должны быть разными', () {
        expect(AppColors.ratingHigh, isNot(equals(AppColors.ratingMedium)));
        expect(AppColors.ratingHigh, isNot(equals(AppColors.ratingLow)));
        expect(AppColors.ratingMedium, isNot(equals(AppColors.ratingLow)));
      });
    });

    group('Конкретные значения цветов', () {
      test('background должен быть #0A0A0A', () {
        expect(AppColors.background, equals(const Color(0xFF0A0A0A)));
      });

      test('surface должен быть #141414', () {
        expect(AppColors.surface, equals(const Color(0xFF141414)));
      });

      test('textPrimary должен быть белым', () {
        expect(AppColors.textPrimary, equals(const Color(0xFFFFFFFF)));
      });
    });
  });
}
