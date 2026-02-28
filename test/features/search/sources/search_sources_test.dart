import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/search/models/search_source.dart';
import 'package:xerabora/features/search/sources/igdb_games_source.dart';
import 'package:xerabora/features/search/sources/search_sources.dart';
import 'package:xerabora/features/search/sources/tmdb_anime_source.dart';
import 'package:xerabora/features/search/sources/tmdb_movies_source.dart';
import 'package:xerabora/features/search/sources/tmdb_tv_source.dart';

void main() {
  group('searchSources', () {
    test('contains 4 sources', () {
      expect(searchSources, hasLength(4));
    });

    test('first source is TmdbMoviesSource', () {
      expect(searchSources[0], isA<TmdbMoviesSource>());
    });

    test('second source is TmdbTvSource', () {
      expect(searchSources[1], isA<TmdbTvSource>());
    });

    test('third source is TmdbAnimeSource', () {
      expect(searchSources[2], isA<TmdbAnimeSource>());
    });

    test('fourth source is IgdbGamesSource', () {
      expect(searchSources[3], isA<IgdbGamesSource>());
    });

    test('all sources have unique ids', () {
      final Set<String> ids =
          searchSources.map((SearchSource s) => s.id).toSet();
      expect(ids.length, searchSources.length);
    });

    test('source ids match expected values', () {
      final List<String> ids =
          searchSources.map((SearchSource s) => s.id).toList();
      expect(ids, <String>['movies', 'tv', 'anime', 'games']);
    });
  });

  group('getSearchSourceById', () {
    test('returns correct source for "movies"', () {
      final SearchSource source = getSearchSourceById('movies');
      expect(source, isA<TmdbMoviesSource>());
    });

    test('returns correct source for "tv"', () {
      final SearchSource source = getSearchSourceById('tv');
      expect(source, isA<TmdbTvSource>());
    });

    test('returns correct source for "anime"', () {
      final SearchSource source = getSearchSourceById('anime');
      expect(source, isA<TmdbAnimeSource>());
    });

    test('returns correct source for "games"', () {
      final SearchSource source = getSearchSourceById('games');
      expect(source, isA<IgdbGamesSource>());
    });

    test('returns first source for unknown id', () {
      final SearchSource source = getSearchSourceById('unknown');
      expect(source, isA<TmdbMoviesSource>());
      expect(source.id, 'movies');
    });

    test('returns first source for empty string', () {
      final SearchSource source = getSearchSourceById('');
      expect(source.id, 'movies');
    });
  });
}
