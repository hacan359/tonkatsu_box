// Тесты для модели MediaType

import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/models/media_type.dart';

void main() {
  group('MediaType', () {
    group('значения enum', () {
      test('должен содержать 5 значений', () {
        expect(MediaType.values.length, 5);
      });

      test('должен содержать game', () {
        expect(MediaType.values.contains(MediaType.game), isTrue);
      });

      test('должен содержать movie', () {
        expect(MediaType.values.contains(MediaType.movie), isTrue);
      });

      test('должен содержать tvShow', () {
        expect(MediaType.values.contains(MediaType.tvShow), isTrue);
      });

      test('должен содержать animation', () {
        expect(MediaType.values.contains(MediaType.animation), isTrue);
      });

      test('должен содержать visualNovel', () {
        expect(MediaType.values.contains(MediaType.visualNovel), isTrue);
      });
    });

    group('value', () {
      test('game должен иметь значение "game"', () {
        expect(MediaType.game.value, 'game');
      });

      test('movie должен иметь значение "movie"', () {
        expect(MediaType.movie.value, 'movie');
      });

      test('tvShow должен иметь значение "tv_show"', () {
        expect(MediaType.tvShow.value, 'tv_show');
      });

      test('animation должен иметь значение "animation"', () {
        expect(MediaType.animation.value, 'animation');
      });

      test('visualNovel должен иметь значение "visual_novel"', () {
        expect(MediaType.visualNovel.value, 'visual_novel');
      });
    });

    group('fromString', () {
      test('должен вернуть game для "game"', () {
        final MediaType result = MediaType.fromString('game');

        expect(result, MediaType.game);
      });

      test('должен вернуть movie для "movie"', () {
        final MediaType result = MediaType.fromString('movie');

        expect(result, MediaType.movie);
      });

      test('должен вернуть tvShow для "tv_show"', () {
        final MediaType result = MediaType.fromString('tv_show');

        expect(result, MediaType.tvShow);
      });

      test('должен вернуть game для неизвестного значения', () {
        final MediaType result = MediaType.fromString('unknown');

        expect(result, MediaType.game);
      });

      test('должен вернуть game для пустой строки', () {
        final MediaType result = MediaType.fromString('');

        expect(result, MediaType.game);
      });

      test('должен вернуть game для некорректного регистра', () {
        final MediaType result = MediaType.fromString('Game');

        expect(result, MediaType.game);
      });

      test('должен вернуть animation для "animation"', () {
        final MediaType result = MediaType.fromString('animation');

        expect(result, MediaType.animation);
      });

      test('должен вернуть visualNovel для "visual_novel"', () {
        final MediaType result = MediaType.fromString('visual_novel');

        expect(result, MediaType.visualNovel);
      });
    });

    group('displayLabel', () {
      test('game должен отображаться как "Game"', () {
        expect(MediaType.game.displayLabel, 'Game');
      });

      test('movie должен отображаться как "Movie"', () {
        expect(MediaType.movie.displayLabel, 'Movie');
      });

      test('tvShow должен отображаться как "TV Show"', () {
        expect(MediaType.tvShow.displayLabel, 'TV Show');
      });

      test('animation должен отображаться как "Animation"', () {
        expect(MediaType.animation.displayLabel, 'Animation');
      });

      test('visualNovel должен отображаться как "Visual Novel"', () {
        expect(MediaType.visualNovel.displayLabel, 'Visual Novel');
      });
    });
  });
}
