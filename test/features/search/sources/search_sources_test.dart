import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/search/models/search_source.dart';
import 'package:tonkatsu_box/features/search/sources/igdb_games_source.dart';
import 'package:tonkatsu_box/features/search/sources/search_sources.dart';
import 'package:tonkatsu_box/features/search/sources/tmdb_anime_source.dart';
import 'package:tonkatsu_box/features/search/sources/tmdb_movies_source.dart';
import 'package:tonkatsu_box/features/search/sources/tmdb_tv_source.dart';
import 'package:tonkatsu_box/features/search/sources/anilist_manga_source.dart';
import 'package:tonkatsu_box/features/search/sources/comicvine_source.dart';
import 'package:tonkatsu_box/features/search/sources/hardcover_source.dart';
import 'package:tonkatsu_box/features/search/sources/vndb_source.dart';

void main() {
  group('searchSources', () {
    test('all sources have unique ids', () {
      final Set<String> ids =
          searchSources.map((SearchSource s) => s.id).toSet();
      expect(ids.length, searchSources.length);
    });

    /// Registration order is load-bearing: it drives per-type primary and
    /// fallback resolution.
    test('source ids match expected values', () {
      final List<String> ids =
          searchSources.map((SearchSource s) => s.id).toList();
      expect(ids, <String>[
        'movies',
        'tv',
        'anime',
        'tvmaze_tv',
        'tvdb_movies',
        'tvdb_series',
        'games',
        'anilist_anime',
        'manga',
        'mangabaka',
        'mangadex',
        'kitsu_anime',
        'kitsu_manga',
        'visual_novels',
        'openlibrary',
        'fantlab',
        'googlebooks',
        'hardcover',
        'comicvine',
        'musicbrainz',
      ]);
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

    test('returns correct source for "manga"', () {
      final SearchSource source = getSearchSourceById('manga');
      expect(source, isA<AniListMangaSource>());
    });

    test('returns correct source for "visual_novels"', () {
      final SearchSource source = getSearchSourceById('visual_novels');
      expect(source, isA<VndbSource>());
    });

    test('returns correct source for "hardcover"', () {
      final SearchSource source = getSearchSourceById('hardcover');
      expect(source, isA<HardcoverSource>());
    });

    test('returns correct source for "comicvine"', () {
      final SearchSource source = getSearchSourceById('comicvine');
      expect(source, isA<ComicVineSource>());
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
