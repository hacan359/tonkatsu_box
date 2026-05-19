import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/search/utils/genre_utils.dart';
import 'package:xerabora/shared/models/movie.dart';
import 'package:xerabora/shared/models/tv_show.dart';

void main() {
  group('isAnimationGenre', () {
    const Map<String, String> empty = <String, String>{};
    const Map<String, String> ru = <String, String>{'16': 'Мультфильм'};

    test('returns true for genre ID "16"', () {
      expect(isAnimationGenre('16', empty), isTrue);
    });

    test('returns true for genre name "Animation"', () {
      expect(isAnimationGenre('Animation', empty), isTrue);
    });

    test('returns true for the localized name from the genre map', () {
      expect(isAnimationGenre('Мультфильм', ru), isTrue);
    });

    // The local DAO capitalises stored names on read, while TMDB API
    // returns them as-stored (lowercase for `ru-RU`). The filter must
    // match across that case mismatch or every animation row gets dropped.
    test('matches case-insensitively against the localized name', () {
      expect(isAnimationGenre('мультфильм', ru), isTrue);
      expect(isAnimationGenre('МУЛЬТФИЛЬМ', ru), isTrue);
    });

    test('matches English name case-insensitively', () {
      expect(isAnimationGenre('animation', empty), isTrue);
      expect(isAnimationGenre('ANIMATION', empty), isTrue);
    });

    test('still accepts English name even when localized map provided', () {
      expect(isAnimationGenre('Animation', ru), isTrue);
    });

    test('returns false for other genre ID', () {
      expect(isAnimationGenre('28', empty), isFalse);
    });

    test('returns false for other genre name', () {
      expect(isAnimationGenre('Action', empty), isFalse);
    });

    test('returns false for the localized name without the genre map', () {
      expect(isAnimationGenre('Мультфильм', empty), isFalse);
    });

    test('returns false for empty string', () {
      expect(isAnimationGenre('', empty), isFalse);
    });

    test('returns false for partial match "16-something"', () {
      expect(isAnimationGenre('16-something', empty), isFalse);
    });
  });

  group('resolveMovieGenres', () {
    test('returns same list when genreMap is empty', () {
      const List<Movie> movies = <Movie>[
        Movie(tmdbId: 1, title: 'A', genres: <String>['28']),
      ];

      final List<Movie> result =
          resolveMovieGenres(movies, const <String, String>{});
      expect(result, same(movies));
    });

    test('resolves genre IDs to names', () {
      const List<Movie> movies = <Movie>[
        Movie(tmdbId: 1, title: 'A', genres: <String>['28', '12']),
      ];
      const Map<String, String> genreMap = <String, String>{
        '28': 'Action',
        '12': 'Adventure',
      };

      final List<Movie> result = resolveMovieGenres(movies, genreMap);
      expect(result[0].genres, <String>['Action', 'Adventure']);
    });

    test('keeps original ID when no mapping found', () {
      const List<Movie> movies = <Movie>[
        Movie(tmdbId: 1, title: 'A', genres: <String>['28', '999']),
      ];
      const Map<String, String> genreMap = <String, String>{
        '28': 'Action',
      };

      final List<Movie> result = resolveMovieGenres(movies, genreMap);
      expect(result[0].genres, <String>['Action', '999']);
    });

    test('skips movies with null genres', () {
      const List<Movie> movies = <Movie>[
        Movie(tmdbId: 1, title: 'A'),
      ];
      const Map<String, String> genreMap = <String, String>{
        '28': 'Action',
      };

      final List<Movie> result = resolveMovieGenres(movies, genreMap);
      expect(result[0].genres, isNull);
    });

    test('skips movies with empty genres', () {
      const List<Movie> movies = <Movie>[
        Movie(tmdbId: 1, title: 'A', genres: <String>[]),
      ];
      const Map<String, String> genreMap = <String, String>{
        '28': 'Action',
      };

      final List<Movie> result = resolveMovieGenres(movies, genreMap);
      expect(result[0].genres, isEmpty);
    });

    test('handles multiple movies', () {
      const List<Movie> movies = <Movie>[
        Movie(tmdbId: 1, title: 'A', genres: <String>['28']),
        Movie(tmdbId: 2, title: 'B', genres: <String>['12']),
        Movie(tmdbId: 3, title: 'C'),
      ];
      const Map<String, String> genreMap = <String, String>{
        '28': 'Action',
        '12': 'Adventure',
      };

      final List<Movie> result = resolveMovieGenres(movies, genreMap);
      expect(result, hasLength(3));
      expect(result[0].genres, <String>['Action']);
      expect(result[1].genres, <String>['Adventure']);
      expect(result[2].genres, isNull);
    });
  });

  group('resolveTvGenres', () {
    test('returns same list when genreMap is empty', () {
      const List<TvShow> shows = <TvShow>[
        TvShow(tmdbId: 1, title: 'A', genres: <String>['18']),
      ];

      final List<TvShow> result =
          resolveTvGenres(shows, const <String, String>{});
      expect(result, same(shows));
    });

    test('resolves genre IDs to names', () {
      const List<TvShow> shows = <TvShow>[
        TvShow(tmdbId: 1, title: 'A', genres: <String>['18', '10765']),
      ];
      const Map<String, String> genreMap = <String, String>{
        '18': 'Drama',
        '10765': 'Sci-Fi & Fantasy',
      };

      final List<TvShow> result = resolveTvGenres(shows, genreMap);
      expect(result[0].genres, <String>['Drama', 'Sci-Fi & Fantasy']);
    });

    test('skips shows with null genres', () {
      const List<TvShow> shows = <TvShow>[
        TvShow(tmdbId: 1, title: 'A'),
      ];
      const Map<String, String> genreMap = <String, String>{
        '18': 'Drama',
      };

      final List<TvShow> result = resolveTvGenres(shows, genreMap);
      expect(result[0].genres, isNull);
    });

    test('skips shows with empty genres', () {
      const List<TvShow> shows = <TvShow>[
        TvShow(tmdbId: 1, title: 'A', genres: <String>[]),
      ];
      const Map<String, String> genreMap = <String, String>{
        '18': 'Drama',
      };

      final List<TvShow> result = resolveTvGenres(shows, genreMap);
      expect(result[0].genres, isEmpty);
    });

    test('keeps original ID when no mapping found', () {
      const List<TvShow> shows = <TvShow>[
        TvShow(tmdbId: 1, title: 'A', genres: <String>['18', '999']),
      ];
      const Map<String, String> genreMap = <String, String>{
        '18': 'Drama',
      };

      final List<TvShow> result = resolveTvGenres(shows, genreMap);
      expect(result[0].genres, <String>['Drama', '999']);
    });
  });
}
