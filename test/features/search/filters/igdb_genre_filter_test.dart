import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/search/filters/igdb_genre_filter.dart';
import 'package:xerabora/features/search/filters/tmdb_genre_filter.dart';
import 'package:xerabora/features/search/models/search_source.dart';

void main() {
  group('IgdbGenre', () {
    test('creates from constructor', () {
      const IgdbGenre genre = IgdbGenre(id: 12, name: 'Role-playing (RPG)');

      expect(genre.id, 12);
      expect(genre.name, 'Role-playing (RPG)');
    });

    test('creates from JSON', () {
      final IgdbGenre genre = IgdbGenre.fromJson(<String, dynamic>{
        'id': 5,
        'name': 'Shooter',
      });

      expect(genre.id, 5);
      expect(genre.name, 'Shooter');
    });

    test('fromJson handles different id types', () {
      final IgdbGenre genre = IgdbGenre.fromJson(<String, dynamic>{
        'id': 31,
        'name': 'Adventure',
      });

      expect(genre.id, 31);
    });
  });

  group('IgdbGenreFilter', () {
    late IgdbGenreFilter filter;

    setUp(() {
      filter = IgdbGenreFilter();
    });

    test('key is "genre"', () {
      expect(filter.key, 'genre');
    });

    test('allOption has id "any" and null value', () {
      final FilterOption all = filter.allOption;

      expect(all.id, 'any');
      expect(all.label, 'All');
      expect(all.value, isNull);
    });

    test('cacheKey is "genre_igdb"', () {
      expect(filter.cacheKey, 'genre_igdb');
    });

    test('cacheKey differs from TmdbGenreFilter', () {
      final TmdbGenreFilter tmdbFilter = TmdbGenreFilter(type: 'movie');

      expect(filter.cacheKey, isNot(tmdbFilter.cacheKey));
    });
  });
}
