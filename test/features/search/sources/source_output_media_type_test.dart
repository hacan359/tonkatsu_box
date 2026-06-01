import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/search/sources/anilist_anime_source.dart';
import 'package:tonkatsu_box/features/search/sources/anilist_manga_source.dart';
import 'package:tonkatsu_box/features/search/sources/igdb_games_source.dart';
import 'package:tonkatsu_box/features/search/sources/tmdb_anime_source.dart';
import 'package:tonkatsu_box/features/search/sources/tmdb_movies_source.dart';
import 'package:tonkatsu_box/features/search/sources/tmdb_tv_source.dart';
import 'package:tonkatsu_box/features/search/sources/vndb_source.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';

void main() {
  group('SearchSource.outputMediaType', () {
    test('TmdbMoviesSource → MediaType.movie', () {
      expect(TmdbMoviesSource().outputMediaType, MediaType.movie);
    });

    test('TmdbTvSource → MediaType.tvShow', () {
      expect(TmdbTvSource().outputMediaType, MediaType.tvShow);
    });

    test('TmdbAnimeSource → MediaType.animation', () {
      expect(TmdbAnimeSource().outputMediaType, MediaType.animation);
    });

    test('IgdbGamesSource → MediaType.game', () {
      expect(IgdbGamesSource().outputMediaType, MediaType.game);
    });

    test('AniListAnimeSource → MediaType.anime', () {
      expect(AniListAnimeSource().outputMediaType, MediaType.anime);
    });

    test('AniListMangaSource → MediaType.manga', () {
      expect(AniListMangaSource().outputMediaType, MediaType.manga);
    });

    test('VndbSource → MediaType.visualNovel', () {
      expect(VndbSource().outputMediaType, MediaType.visualNovel);
    });
  });
}
