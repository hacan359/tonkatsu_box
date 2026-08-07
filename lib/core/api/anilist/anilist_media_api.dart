import 'package:core/models/anilist_tag.dart';
import 'package:core/models/anime.dart';
import 'package:core/models/manga.dart';

import 'anilist_graphql_client.dart';
import 'anilist_media_parser.dart';
import 'anilist_queries.dart';
import 'anilist_types.dart';

class AniListMediaApi {
  AniListMediaApi(this._client);

  final AniListGraphQLClient _client;


  Future<(List<Manga>, bool hasMore, int totalPages)> searchManga({
    required String query,
    int page = 1,
    int perPage = 20,
  }) async {
    if (query.trim().isEmpty) {
      return (<Manga>[], false, 0);
    }
    return browseManga(query: query, page: page, perPage: perPage);
  }

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
  }) async {
    final Map<String, dynamic> variables =
        _browseVariables(page: page, perPage: perPage, sort: sort);
    if (query != null && query.trim().isNotEmpty) {
      variables['search'] = query;
    }
    if (genres != null && genres.isNotEmpty) {
      variables['genres'] = genres;
    }
    if (tags != null && tags.isNotEmpty) {
      variables['tags'] = tags;
    }
    if (format != null) variables['format'] = format;
    if (status != null) variables['status'] = status;
    _addFuzzyDateRange(variables, startYear, endYear);

    final Map<String, dynamic> body = await _client.post(
      query: AniListQueries.mangaSearch,
      variables: variables,
      errorContext: 'Failed to search manga',
    );
    return AniListMediaParser.mangaPage(_client.unwrapData(body));
  }

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
  }) async {
    final Map<String, dynamic> variables =
        _browseVariables(page: page, perPage: perPage, sort: sort);
    if (query != null && query.trim().isNotEmpty) {
      variables['search'] = query;
    }
    if (genres != null && genres.isNotEmpty) {
      variables['genres'] = genres;
    }
    if (tags != null && tags.isNotEmpty) {
      variables['tags'] = tags;
    }
    if (status != null) variables['status'] = status;
    if (format != null) variables['format'] = format;
    _addFuzzyDateRange(variables, startYear, endYear);

    final Map<String, dynamic> body = await _client.post(
      query: AniListQueries.animeSearch,
      variables: variables,
      errorContext: 'Failed to search anime',
    );
    return AniListMediaParser.animePage(_client.unwrapData(body));
  }

  Future<Manga?> getMangaById(int id) async {
    final Map<String, dynamic> body = await _client.post(
      query: AniListQueries.mangaGetById,
      variables: <String, dynamic>{'id': id},
      errorContext: 'Failed to fetch manga',
    );
    final Map<String, dynamic>? data = _client.unwrapData(body);
    final Map<String, dynamic>? media =
        data?['Media'] as Map<String, dynamic>?;
    if (media == null) return null;
    return Manga.fromJson(media);
  }

  Future<Anime?> getAnimeById(int id) async {
    final Map<String, dynamic> body = await _client.post(
      query: AniListQueries.animeGetById,
      variables: <String, dynamic>{'id': id},
      errorContext: 'Failed to fetch anime',
    );
    final Map<String, dynamic>? data = _client.unwrapData(body);
    final Map<String, dynamic>? media =
        data?['Media'] as Map<String, dynamic>?;
    if (media == null) return null;
    return Anime.fromJson(media);
  }

  // AniList caps a nested connection's perPage at 25 (50 elsewhere).
  static const int _recommendationsPerPage = 25;

  Future<List<Anime>> getAnimeRecommendations(int id) async =>
      (await getAnimeRecommendationsBatch(<int>[id]))[id] ?? const <Anime>[];

  Future<List<Manga>> getMangaRecommendations(int id) async =>
      (await getMangaRecommendationsBatch(<int>[id]))[id] ?? const <Manga>[];

  /// Recommendations for every seed in one aliased request (see
  /// [AniListQueries.recommendationsBatch]), retried on a 429.
  Future<Map<int, List<Anime>>> getAnimeRecommendationsBatch(
    List<int> ids,
  ) async {
    if (ids.isEmpty) return const <int, List<Anime>>{};
    final Map<String, dynamic>? data = await _postRecommendationsBatch(
      ids: ids,
      anime: true,
      errorContext: 'Failed to fetch anime recommendations',
    );
    return AniListMediaParser.recommendedAnimeBatch(data, ids);
  }

  Future<Map<int, List<Manga>>> getMangaRecommendationsBatch(
    List<int> ids,
  ) async {
    if (ids.isEmpty) return const <int, List<Manga>>{};
    final Map<String, dynamic>? data = await _postRecommendationsBatch(
      ids: ids,
      anime: false,
      errorContext: 'Failed to fetch manga recommendations',
    );
    return AniListMediaParser.recommendedMangaBatch(data, ids);
  }

  Future<Map<String, dynamic>?> _postRecommendationsBatch({
    required List<int> ids,
    required bool anime,
    required String errorContext,
  }) async {
    final String query =
        AniListQueries.recommendationsBatch(ids: ids, anime: anime);
    for (int attempt = 1; ; attempt++) {
      try {
        final Map<String, dynamic> body = await _client.post(
          query: query,
          variables: <String, dynamic>{'perPage': _recommendationsPerPage},
          errorContext: errorContext,
        );
        return _client.unwrapData(body);
      } on AniListRateLimitException catch (e) {
        if (attempt >= _maxRateLimitRetries) rethrow;
        await Future<void>.delayed(e.retryAfter);
      }
    }
  }

  /// Maximum retries per batch on a 429 before that batch is skipped.
  static const int _maxRateLimitRetries = 3;

  Future<List<Manga>> getMangaByIds(
    List<int> ids, {
    void Function(Duration wait, int attempt)? onRateLimit,
  }) =>
      _fetchByIdsResilient<Manga>(ids, _fetchMangaBatch, onRateLimit);

  Future<List<Anime>> getAnimeByIds(
    List<int> ids, {
    void Function(Duration wait, int attempt)? onRateLimit,
  }) =>
      _fetchByIdsResilient<Anime>(ids, _fetchAnimeBatch, onRateLimit);

  /// Batched fetch that retries a batch on a 429 and skips it on repeated
  /// failure — a large import keeps its partial result instead of nothing.
  Future<List<T>> _fetchByIdsResilient<T>(
    List<int> ids,
    Future<List<T>> Function(List<int>) fetchBatch,
    void Function(Duration wait, int attempt)? onRateLimit,
  ) async {
    if (ids.isEmpty) return <T>[];
    final List<T> result = <T>[];
    for (final List<int> batch in aniListBatches(ids)) {
      for (int attempt = 1; attempt <= _maxRateLimitRetries; attempt++) {
        try {
          result.addAll(await fetchBatch(batch));
          break;
        } on AniListRateLimitException catch (e) {
          if (attempt >= _maxRateLimitRetries) break;
          onRateLimit?.call(e.retryAfter, attempt);
          await Future<void>.delayed(e.retryAfter);
        } on AniListApiException {
          break;
        }
      }
    }
    return result;
  }

  Future<List<Manga>> _fetchMangaBatch(List<int> ids) async {
    final Map<String, dynamic> body = await _client.post(
      query: AniListQueries.mangaGetByIds,
      variables: <String, dynamic>{
        'page': 1,
        'perPage': ids.length,
        'ids': ids,
      },
      errorContext: 'Failed to fetch manga by IDs',
    );
    final (List<Manga> items, _, _) =
        AniListMediaParser.mangaPage(_client.unwrapData(body));
    return items;
  }

  Future<List<Anime>> _fetchAnimeBatch(List<int> ids) async {
    final Map<String, dynamic> body = await _client.post(
      query: AniListQueries.animeGetByIds,
      variables: <String, dynamic>{
        'page': 1,
        'perPage': ids.length,
        'ids': ids,
      },
      errorContext: 'Failed to fetch anime by IDs',
    );
    final (List<Anime> items, _, _) =
        AniListMediaParser.animePage(_client.unwrapData(body));
    return items;
  }

  /// Fetches the full tag catalog (~600 entries). Used to build the tag
  /// filter picker; cache the result in [AniListTagDao].
  Future<List<AniListTag>> fetchTagCollection() async {
    final Map<String, dynamic> body = await _client.post(
      query: AniListQueries.tagCollection,
      variables: const <String, dynamic>{},
      errorContext: 'Failed to fetch AniList tag collection',
    );
    final Map<String, dynamic>? data = _client.unwrapData(body);
    final List<dynamic>? list = data?['MediaTagCollection'] as List<dynamic>?;
    if (list == null) return const <AniListTag>[];
    return list
        .map((dynamic e) => AniListTag.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Map<String, dynamic> _browseVariables({
    required int page,
    required int perPage,
    required String sort,
  }) =>
      <String, dynamic>{
        'page': page,
        'perPage': perPage,
        'sort': <String>[sort],
      };

  // FuzzyDateInt is YYYYMMDD; a year-only range expands to Jan 1 / Dec 31.
  static void _addFuzzyDateRange(
    Map<String, dynamic> variables,
    int? startYear,
    int? endYear,
  ) {
    if (startYear != null) {
      variables['startDateGreater'] = startYear * 10000 + 101;
    }
    if (endYear != null) {
      variables['startDateLesser'] = endYear * 10000 + 1231;
    }
  }
}

