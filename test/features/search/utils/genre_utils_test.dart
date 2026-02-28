import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/search/utils/genre_utils.dart';
import 'package:xerabora/shared/models/movie.dart';
import 'package:xerabora/shared/models/tv_show.dart';

void main() {
  group('isAnimationGenre', () {
    test('returns true for genre ID "16"', () {
      expect(isAnimationGenre('16'), isTrue);
    });

    test('returns true for genre name "Animation"', () {
      expect(isAnimationGenre('Animation'), isTrue);
    });

    test('returns false for other genre ID', () {
      expect(isAnimationGenre('28'), isFalse);
    });

    test('returns false for other genre name', () {
      expect(isAnimationGenre('Action'), isFalse);
    });

    test('returns false for empty string', () {
      expect(isAnimationGenre(''), isFalse);
    });

    test('returns false for partial match "16-something"', () {
      expect(isAnimationGenre('16-something'), isFalse);
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
