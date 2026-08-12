import 'package:core/models/media_type.dart';
import 'package:test/test.dart';

void main() {
  group('MediaType', () {
    group('значения enum', () {
      test('should contain 10 values', () {
        expect(MediaType.values.length, 10);
      });

      test('should contain game', () {
        expect(MediaType.values.contains(MediaType.game), isTrue);
      });

      test('should contain movie', () {
        expect(MediaType.values.contains(MediaType.movie), isTrue);
      });

      test('should contain tvShow', () {
        expect(MediaType.values.contains(MediaType.tvShow), isTrue);
      });

      test('should contain animation', () {
        expect(MediaType.values.contains(MediaType.animation), isTrue);
      });

      test('should contain visualNovel', () {
        expect(MediaType.values.contains(MediaType.visualNovel), isTrue);
      });

      test('should contain manga', () {
        expect(MediaType.values.contains(MediaType.manga), isTrue);
      });

      test('should contain anime', () {
        expect(MediaType.values.contains(MediaType.anime), isTrue);
      });

      test('should contain music', () {
        expect(MediaType.values.contains(MediaType.music), isTrue);
      });
    });

    group('isTvBacked', () {
      test('true только для tvShow и animation', () {
        for (final MediaType type in MediaType.values) {
          expect(
            type.isTvBacked,
            type == MediaType.tvShow || type == MediaType.animation,
          );
        }
      });
    });

    group('isMultiSource', () {
      test('true only for manga, anime, tvShow, movie and book', () {
        for (final MediaType type in MediaType.values) {
          expect(
            type.isMultiSource,
            type == MediaType.manga ||
                type == MediaType.anime ||
                type == MediaType.tvShow ||
                type == MediaType.movie ||
                type == MediaType.book,
            reason: type.name,
          );
        }
      });

      test('animation stays single-source', () {
        expect(MediaType.animation.isMultiSource, isFalse);
      });
    });

    group('defaultSource', () {
      test('every media type resolves a fallback source', () {
        for (final MediaType type in MediaType.values) {
          expect(type.defaultSource, isNotNull, reason: type.name);
        }
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

      test('manga должен иметь значение "manga"', () {
        expect(MediaType.manga.value, 'manga');
      });

      test('anime должен иметь значение "anime"', () {
        expect(MediaType.anime.value, 'anime');
      });
    });

    group('fromString', () {
      test('should return game для "game"', () {
        final MediaType result = MediaType.fromString('game');

        expect(result, MediaType.game);
      });

      test('should return movie для "movie"', () {
        final MediaType result = MediaType.fromString('movie');

        expect(result, MediaType.movie);
      });

      test('should return tvShow для "tv_show"', () {
        final MediaType result = MediaType.fromString('tv_show');

        expect(result, MediaType.tvShow);
      });

      test('should return game для неизвестного значения', () {
        final MediaType result = MediaType.fromString('unknown');

        expect(result, MediaType.game);
      });

      test('should return game для пустой строки', () {
        final MediaType result = MediaType.fromString('');

        expect(result, MediaType.game);
      });

      test('should return game для некорректного регистра', () {
        final MediaType result = MediaType.fromString('Game');

        expect(result, MediaType.game);
      });

      test('should return animation для "animation"', () {
        final MediaType result = MediaType.fromString('animation');

        expect(result, MediaType.animation);
      });

      test('should return visualNovel для "visual_novel"', () {
        final MediaType result = MediaType.fromString('visual_novel');

        expect(result, MediaType.visualNovel);
      });

      test('should return manga для "manga"', () {
        final MediaType result = MediaType.fromString('manga');

        expect(result, MediaType.manga);
      });

      test('should return anime для "anime"', () {
        final MediaType result = MediaType.fromString('anime');

        expect(result, MediaType.anime);
      });

      test('should return music when parsing "music"', () {
        final MediaType result = MediaType.fromString('music');

        expect(result, MediaType.music);
      });
    });

    group('tryFromString', () {
      test('should return the type for every known value', () {
        for (final MediaType type in MediaType.values) {
          expect(MediaType.tryFromString(type.value), type);
        }
      });

      test('should return null for an unknown value', () {
        expect(MediaType.tryFromString('unknown'), isNull);
        expect(MediaType.tryFromString(''), isNull);
        expect(MediaType.tryFromString('Game'), isNull);
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

      test('manga должен отображаться как "Manga"', () {
        expect(MediaType.manga.displayLabel, 'Manga');
      });

      test('anime должен отображаться как "Anime"', () {
        expect(MediaType.anime.displayLabel, 'Anime');
      });

      test('should display music as "Music"', () {
        expect(MediaType.music.displayLabel, 'Music');
      });
    });
  });
}
