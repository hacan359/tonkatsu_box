import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/core/api/tmdb_api.dart';
import 'package:xerabora/shared/models/movie.dart';

void main() {
  group('TmdbPagedResult', () {
    test('creates with required fields', () {
      const TmdbPagedResult<Movie> result = TmdbPagedResult<Movie>(
        results: <Movie>[Movie(tmdbId: 1, title: 'Movie 1')],
        page: 1,
        totalPages: 5,
        totalResults: 100,
      );

      expect(result.results, hasLength(1));
      expect(result.page, 1);
      expect(result.totalPages, 5);
      expect(result.totalResults, 100);
    });

    group('hasMore', () {
      test('returns true when page is less than totalPages', () {
        const TmdbPagedResult<Movie> result = TmdbPagedResult<Movie>(
          results: <Movie>[],
          page: 1,
          totalPages: 5,
          totalResults: 100,
        );

        expect(result.hasMore, isTrue);
      });

      test('returns false when page equals totalPages', () {
        const TmdbPagedResult<Movie> result = TmdbPagedResult<Movie>(
          results: <Movie>[],
          page: 5,
          totalPages: 5,
          totalResults: 100,
        );

        expect(result.hasMore, isFalse);
      });

      test('returns false when page exceeds totalPages', () {
        const TmdbPagedResult<Movie> result = TmdbPagedResult<Movie>(
          results: <Movie>[],
          page: 6,
          totalPages: 5,
          totalResults: 100,
        );

        expect(result.hasMore, isFalse);
      });

      test('returns false for single page', () {
        const TmdbPagedResult<Movie> result = TmdbPagedResult<Movie>(
          results: <Movie>[Movie(tmdbId: 1, title: 'Movie')],
          page: 1,
          totalPages: 1,
          totalResults: 1,
        );

        expect(result.hasMore, isFalse);
      });

      test('returns false when totalPages is 0', () {
        const TmdbPagedResult<Movie> result = TmdbPagedResult<Movie>(
          results: <Movie>[],
          page: 1,
          totalPages: 0,
          totalResults: 0,
        );

        expect(result.hasMore, isFalse);
      });
    });

    test('stores results of correct type', () {
      const TmdbPagedResult<Movie> result = TmdbPagedResult<Movie>(
        results: <Movie>[
          Movie(tmdbId: 1, title: 'Movie 1'),
          Movie(tmdbId: 2, title: 'Movie 2'),
          Movie(tmdbId: 3, title: 'Movie 3'),
        ],
        page: 1,
        totalPages: 1,
        totalResults: 3,
      );

      expect(result.results, hasLength(3));
      expect(result.results[0].title, 'Movie 1');
      expect(result.results[1].title, 'Movie 2');
      expect(result.results[2].title, 'Movie 3');
    });

    test('works with empty results', () {
      const TmdbPagedResult<Movie> result = TmdbPagedResult<Movie>(
        results: <Movie>[],
        page: 1,
        totalPages: 0,
        totalResults: 0,
      );

      expect(result.results, isEmpty);
      expect(result.hasMore, isFalse);
    });
  });
}
