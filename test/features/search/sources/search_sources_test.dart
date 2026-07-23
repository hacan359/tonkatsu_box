import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/search/models/search_source.dart';
import 'package:tonkatsu_box/features/search/sources/igdb_games_source.dart';
import 'package:tonkatsu_box/features/search/sources/search_sources.dart';
import 'package:tonkatsu_box/features/search/sources/tmdb_anime_source.dart';
import 'package:tonkatsu_box/features/search/sources/tmdb_movies_source.dart';
import 'package:tonkatsu_box/features/search/sources/tmdb_tv_source.dart';
import 'package:tonkatsu_box/features/search/sources/tvmaze_tv_source.dart';
import 'package:tonkatsu_box/features/search/sources/anilist_anime_source.dart';
import 'package:tonkatsu_box/features/search/sources/anilist_manga_source.dart';
import 'package:tonkatsu_box/features/search/sources/comicvine_source.dart';
import 'package:tonkatsu_box/features/search/sources/fantlab_source.dart';
import 'package:tonkatsu_box/features/search/sources/google_books_source.dart';
import 'package:tonkatsu_box/features/search/sources/hardcover_source.dart';
import 'package:tonkatsu_box/features/search/sources/kitsu_manga_source.dart';
import 'package:tonkatsu_box/features/search/sources/mangabaka_source.dart';
import 'package:tonkatsu_box/features/search/sources/mangadex_source.dart';
import 'package:tonkatsu_box/features/search/sources/openlibrary_source.dart';
import 'package:tonkatsu_box/features/search/sources/vndb_source.dart';

void main() {
  group('searchSources', () {
    test('contains 16 sources', () {
      expect(searchSources, hasLength(16));
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

    test('fourth source is TvMazeTvSource', () {
      expect(searchSources[3], isA<TvMazeTvSource>());
    });

    test('fifth source is IgdbGamesSource', () {
      expect(searchSources[4], isA<IgdbGamesSource>());
    });

    test('sixth source is AniListAnimeSource', () {
      expect(searchSources[5], isA<AniListAnimeSource>());
    });

    test('seventh source is AniListMangaSource', () {
      expect(searchSources[6], isA<AniListMangaSource>());
    });

    test('eighth source is MangaBakaSource', () {
      expect(searchSources[7], isA<MangaBakaSource>());
    });

    test('ninth source is MangaDexSource', () {
      expect(searchSources[8], isA<MangaDexSource>());
    });

    test('tenth source is KitsuMangaSource', () {
      expect(searchSources[9], isA<KitsuMangaSource>());
    });

    test('eleventh source is VndbSource', () {
      expect(searchSources[10], isA<VndbSource>());
    });

    test('twelfth source is OpenLibrarySource', () {
      expect(searchSources[11], isA<OpenLibrarySource>());
    });

    test('thirteenth source is FantlabSource', () {
      expect(searchSources[12], isA<FantlabSource>());
    });

    test('fourteenth source is GoogleBooksSource', () {
      expect(searchSources[13], isA<GoogleBooksSource>());
    });

    test('fifteenth source is HardcoverSource', () {
      expect(searchSources[14], isA<HardcoverSource>());
    });

    test('sixteenth source is ComicVineSource', () {
      expect(searchSources[15], isA<ComicVineSource>());
    });

    test('all sources have unique ids', () {
      final Set<String> ids =
          searchSources.map((SearchSource s) => s.id).toSet();
      expect(ids.length, searchSources.length);
    });

    test('source ids match expected values', () {
      final List<String> ids =
          searchSources.map((SearchSource s) => s.id).toList();
      expect(ids, <String>[
        'movies',
        'tv',
        'anime',
        'tvmaze_tv',
        'games',
        'anilist_anime',
        'manga',
        'mangabaka',
        'mangadex',
        'kitsu_manga',
        'visual_novels',
        'openlibrary',
        'fantlab',
        'googlebooks',
        'hardcover',
        'comicvine',
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
