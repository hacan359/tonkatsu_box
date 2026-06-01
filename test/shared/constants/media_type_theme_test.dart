import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/constants/media_type_theme.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';
import 'package:tonkatsu_box/shared/theme/app_colors.dart';

void main() {
  group('MediaTypeTheme', () {
    group('colorFor', () {
      test('should return синий для игр', () {
        expect(
          MediaTypeTheme.colorFor(MediaType.game),
          MediaTypeTheme.gameColor,
        );
      });

      test('should return красный для фильмов', () {
        expect(
          MediaTypeTheme.colorFor(MediaType.movie),
          MediaTypeTheme.movieColor,
        );
      });

      test('should return зелёный для сериалов', () {
        expect(
          MediaTypeTheme.colorFor(MediaType.tvShow),
          MediaTypeTheme.tvShowColor,
        );
      });

      test('should return фиолетовый для анимации', () {
        expect(
          MediaTypeTheme.colorFor(MediaType.animation),
          MediaTypeTheme.animationColor,
        );
      });

      test('каждый тип должен иметь уникальный цвет', () {
        final Set<Color> colors = <Color>{
          MediaTypeTheme.gameColor,
          MediaTypeTheme.movieColor,
          MediaTypeTheme.tvShowColor,
          MediaTypeTheme.animationColor,
        };
        expect(colors.length, 4);
      });
    });

    group('iconFor', () {
      test('should return videogame_asset для игр', () {
        expect(
          MediaTypeTheme.iconFor(MediaType.game),
          Icons.videogame_asset,
        );
      });

      test('should return movie для фильмов', () {
        expect(
          MediaTypeTheme.iconFor(MediaType.movie),
          Icons.movie,
        );
      });

      test('should return tv для сериалов', () {
        expect(
          MediaTypeTheme.iconFor(MediaType.tvShow),
          Icons.tv,
        );
      });

      test('should return animation для анимации', () {
        expect(
          MediaTypeTheme.iconFor(MediaType.animation),
          Icons.animation,
        );
      });
    });

    group('константы цветов', () {
      test('gameColor должен быть AppColors.gameAccent', () {
        expect(MediaTypeTheme.gameColor, AppColors.gameAccent);
      });

      test('movieColor должен быть AppColors.movieAccent', () {
        expect(MediaTypeTheme.movieColor, AppColors.movieAccent);
      });

      test('tvShowColor должен быть AppColors.tvShowAccent', () {
        expect(MediaTypeTheme.tvShowColor, AppColors.tvShowAccent);
      });

      test('animationColor должен быть AppColors.animationAccent', () {
        expect(MediaTypeTheme.animationColor, AppColors.animationAccent);
      });
    });
  });
}
