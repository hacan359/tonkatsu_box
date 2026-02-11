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
        expect(AppColors.statusBacklog, isA<Color>());
        expect(AppColors.statusInProgress, isA<Color>());
        expect(AppColors.statusCompleted, isA<Color>());
        expect(AppColors.statusOnHold, isA<Color>());
        expect(AppColors.statusDropped, isA<Color>());
      });

      test('statusCompleted должен совпадать с success', () {
        expect(AppColors.statusCompleted, equals(AppColors.success));
      });

      test('statusOnHold должен совпадать с warning', () {
        expect(AppColors.statusOnHold, equals(AppColors.warning));
      });

      test('statusDropped должен совпадать с error', () {
        expect(AppColors.statusDropped, equals(AppColors.error));
      });
    });
  });
}
