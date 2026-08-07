import 'package:core/models/anilist_tag.dart';
import 'package:core/models/anime.dart';
import 'package:core/models/manga.dart';
import 'package:core/models/media_type.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'anilist/anilist_graphql_client.dart';
import 'anilist/anilist_mal_lookup_api.dart';
import 'anilist/anilist_media_api.dart';
import 'anilist/anilist_types.dart';
import 'anilist/anilist_user_list_api.dart';

export 'anilist/anilist_mal_lookup_api.dart'
    show AniListRateLimitCallback, AniListBatchProgressCallback;
export 'anilist/anilist_types.dart';

final Provider<AniListApi> aniListApiProvider =
    Provider<AniListApi>((Ref ref) {
  return AniListApi();
});

/// AniList GraphQL facade. See `anilist/README.md` for the layer breakdown.
class AniListApi {
  AniListApi({Dio? dio}) : _client = AniListGraphQLClient(dio: dio) {
    _media = AniListMediaApi(_client);
    _mal = AniListMalLookupApi(_client);
    _userList = AniListUserListApi(_client);
  }

  final AniListGraphQLClient _client;
  late final AniListMediaApi _media;
  late final AniListMalLookupApi _mal;
  late final AniListUserListApi _userList;

  static const int maxRateLimitRetries = AniListMalLookupApi.maxRateLimitRetries;

  Future<(List<Manga>, bool hasMore, int totalPages)> searchManga({
    required String query,
    int page = 1,
    int perPage = 20,
  }) =>
      _media.searchManga(query: query, page: page, perPage: perPage);

  Future<(List<Manga>, bool hasMore, int totalPages)> browseManga({
    String? query,
    List<String>? genres,
    List<String>? tags,
    String? format,
    String? status,
    int? startYear,
    int? endYear,
    String sort = 'SCORE_DESC',
    int page = 1,
    int perPage = 20,
  }) =>
      _media.browseManga(
        query: query,
        genres: genres,
        tags: tags,
        format: format,
        status: status,
        startYear: startYear,
        endYear: endYear,
        sort: sort,
        page: page,
        perPage: perPage,
      );

  Future<(List<Anime>, bool hasMore, int totalPages)> browseAnime({
    String? query,
    List<String>? genres,
    List<String>? tags,
    String? status,
    String? format,
    int? startYear,
    int? endYear,
    String sort = 'POPULARITY_DESC',
    int page = 1,
    int perPage = 20,
  }) =>
      _media.browseAnime(
        query: query,
        genres: genres,
        tags: tags,
        status: status,
        format: format,
        startYear: startYear,
        endYear: endYear,
        sort: sort,
        page: page,
        perPage: perPage,
      );

  Future<List<AniListTag>> fetchTagCollection() => _media.fetchTagCollection();

  Future<Manga?> getMangaById(int id) => _media.getMangaById(id);

  Future<Anime?> getAnimeById(int id) => _media.getAnimeById(id);

  /// Titles similar to [id] via `Media.recommendations`, rating-sorted,
  /// seed excluded server-side. Keyless; up to 25 entries.
  Future<List<Anime>> getAnimeRecommendations(int id) =>
      _media.getAnimeRecommendations(id);

  Future<List<Manga>> getMangaRecommendations(int id) =>
      _media.getMangaRecommendations(id);

  /// Per-seed recommendations for a whole seed set in one aliased request.
  Future<Map<int, List<Anime>>> getAnimeRecommendationsBatch(List<int> ids) =>
      _media.getAnimeRecommendationsBatch(ids);

  Future<Map<int, List<Manga>>> getMangaRecommendationsBatch(List<int> ids) =>
      _media.getMangaRecommendationsBatch(ids);

  Future<List<Manga>> getMangaByIds(
    List<int> ids, {
    void Function(Duration wait, int attempt)? onRateLimit,
  }) =>
      _media.getMangaByIds(ids, onRateLimit: onRateLimit);

  Future<List<Anime>> getAnimeByIds(
    List<int> ids, {
    void Function(Duration wait, int attempt)? onRateLimit,
  }) =>
      _media.getAnimeByIds(ids, onRateLimit: onRateLimit);

  Future<Map<int, Anime>> getAnimeByMalIds(List<int> malIds) =>
      _mal.getAnimeByMalIds(malIds);

  Future<Map<int, Manga>> getMangaByMalIds(List<int> malIds) =>
      _mal.getMangaByMalIds(malIds);

  Future<AniListMalLookupResult<Anime>> getAnimeByMalIdsTolerant(
    List<int> malIds, {
    AniListRateLimitCallback? onRateLimit,
    AniListBatchProgressCallback? onBatchProgress,
  }) =>
      _mal.getAnimeByMalIdsTolerant(
        malIds,
        onRateLimit: onRateLimit,
        onBatchProgress: onBatchProgress,
      );

  Future<AniListMalLookupResult<Manga>> getMangaByMalIdsTolerant(
    List<int> malIds, {
    AniListRateLimitCallback? onRateLimit,
    AniListBatchProgressCallback? onBatchProgress,
  }) =>
      _mal.getMangaByMalIdsTolerant(
        malIds,
        onRateLimit: onRateLimit,
        onBatchProgress: onBatchProgress,
      );

  Future<List<AniListListEntry>> fetchUserMediaList({
    required String userName,
    required MediaType type,
  }) =>
      _userList.fetchUserMediaList(userName: userName, type: type);

  void dispose() => _client.dispose();
}

