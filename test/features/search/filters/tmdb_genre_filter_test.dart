import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/search/filters/tmdb_genre_filter.dart';
import 'package:xerabora/features/search/models/search_source.dart';

void main() {
  group('TmdbGenreFilter', () {
    test('key is "genre"', () {
      final TmdbGenreFilter filter = TmdbGenreFilter(type: 'movie');

      expect(filter.key, 'genre');
    });

    test('stores type field', () {
      final TmdbGenreFilter movieFilter = TmdbGenreFilter(type: 'movie');
      final TmdbGenreFilter tvFilter = TmdbGenreFilter(type: 'tv');

      expect(movieFilter.type, 'movie');
      expect(tvFilter.type, 'tv');
    });

    test('allOption has id "any" and null value', () {
      final TmdbGenreFilter filter = TmdbGenreFilter(type: 'movie');
      final FilterOption all = filter.allOption;

      expect(all.id, 'any');
      expect(all.label, 'All');
      expect(all.value, isNull);
    });

    test('different types create distinct instances', () {
      final TmdbGenreFilter a = TmdbGenreFilter(type: 'movie');
      final TmdbGenreFilter b = TmdbGenreFilter(type: 'tv');

      // Same key but different type
      expect(a.key, b.key);
      expect(a.type, isNot(b.type));
    });

    test('cacheKey includes type suffix', () {
      final TmdbGenreFilter movieFilter = TmdbGenreFilter(type: 'movie');
      final TmdbGenreFilter tvFilter = TmdbGenreFilter(type: 'tv');

      expect(movieFilter.cacheKey, 'genre_movie');
      expect(tvFilter.cacheKey, 'genre_tv');
    });

    test('cacheKey differs between movie and tv', () {
      final TmdbGenreFilter movieFilter = TmdbGenreFilter(type: 'movie');
      final TmdbGenreFilter tvFilter = TmdbGenreFilter(type: 'tv');

      expect(movieFilter.cacheKey, isNot(tvFilter.cacheKey));
    });
  });
}
