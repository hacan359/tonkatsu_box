import 'package:core/models/anime.dart';
import 'package:core/models/manga.dart';
import 'package:core/models/tv_episode.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'kitsu/kitsu_anime_api.dart';
import 'kitsu/kitsu_episode_api.dart';
import 'kitsu/kitsu_http_client.dart';
import 'kitsu/kitsu_manga_api.dart';
import 'kitsu/kitsu_mapping_api.dart';
export 'kitsu/kitsu_types.dart';

/// Kitsu JSON:API facade (`https://kitsu.io/api/edge`, no auth) — an anime +
/// manga catalog; both carry `DataSource.kitsu`.
class KitsuApi {
  KitsuApi({Dio? dio}) : _client = KitsuHttpClient(dio: dio) {
    _manga = KitsuMangaApi(_client);
    _anime = KitsuAnimeApi(_client);
    _episodes = KitsuEpisodeApi(_client);
    _mappings = KitsuMappingApi(_client);
  }

  final KitsuHttpClient _client;
  late final KitsuMangaApi _manga;
  late final KitsuAnimeApi _anime;
  late final KitsuEpisodeApi _episodes;
  late final KitsuMappingApi _mappings;

  Future<(List<Manga>, bool hasMore, int totalPages)> browseManga({
    String? query,
    String? subtype,
    String? status,
    String? sort,
    int page = 1,
    int perPage = 20,
  }) =>
      _manga.browseManga(
        query: query,
        subtype: subtype,
        status: status,
        sort: sort,
        page: page,
        perPage: perPage,
      );

  Future<Manga?> getMangaById(int id) => _manga.getById(id);

  Future<(List<Anime>, bool hasMore, int totalPages)> browseAnime({
    String? query,
    String? subtype,
    String? status,
    String? sort,
    int page = 1,
    int perPage = 20,
  }) =>
      _anime.browseAnime(
        query: query,
        subtype: subtype,
        status: status,
        sort: sort,
        page: page,
        perPage: perPage,
      );

  Future<Anime?> getAnimeById(int id) => _anime.getById(id);

  /// Cards for a list of Kitsu ids in batched requests (20 per call).
  Future<List<Anime>> getAnimeByIds(List<int> ids) => _anime.getByIds(ids);

  Future<List<TvEpisode>> getAnimeEpisodes(int id) =>
      _episodes.getAllEpisodes(id);

  Future<int?> getAnimeEpisodeCount(int id) => _episodes.getEpisodeCount(id);

  /// Resolves MyAnimeList ids to Kitsu anime (mapping + card in one call).
  Future<Map<int, Anime>> getAnimeByMalIds(List<int> malIds) =>
      _mappings.resolveAnime(
        externalSite: KitsuMappingApi.siteMyAnimeList,
        externalIds: malIds,
      );

  /// Resolves AniDB ids to Kitsu anime — the fallback when MAL ids are absent.
  Future<Map<int, Anime>> getAnimeByAnidbIds(List<int> anidbIds) =>
      _mappings.resolveAnime(
        externalSite: KitsuMappingApi.siteAniDb,
        externalIds: anidbIds,
      );

  /// Resolves AniList ids to Kitsu anime — used to show AniList-sourced
  /// recommendations as Kitsu titles (seasons + episode tracker).
  Future<Map<int, Anime>> getAnimeByAniListIds(List<int> aniListIds) =>
      _mappings.resolveAnime(
        externalSite: KitsuMappingApi.siteAniListAnime,
        externalIds: aniListIds,
      );

  /// AniList id of a Kitsu anime, or null without a mapping.
  Future<int?> getAniListAnimeId(int kitsuId) =>
      _mappings.getAniListId(kitsuId: kitsuId, manga: false);

  /// AniList id of a Kitsu manga, or null without a mapping.
  Future<int?> getAniListMangaId(int kitsuId) =>
      _mappings.getAniListId(kitsuId: kitsuId, manga: true);

  void dispose() => _client.dispose();
}

final Provider<KitsuApi> kitsuApiProvider =
    Provider<KitsuApi>((Ref ref) => KitsuApi());
