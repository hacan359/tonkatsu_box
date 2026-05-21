import 'package:logging/logging.dart';

import '../../../shared/models/anime.dart';
import '../../../shared/models/manga.dart';
import 'anilist_graphql_client.dart';
import 'anilist_queries.dart';
import 'anilist_types.dart';

typedef AniListRateLimitCallback = void Function(Duration wait, int attempt);
typedef AniListBatchProgressCallback = void Function(int done, int total);

class AniListMalLookupApi {
  AniListMalLookupApi(this._client);

  final AniListGraphQLClient _client;
  static final Logger _log = Logger('AniListApi');

  static const int maxRateLimitRetries = 3;

  Future<Map<int, Anime>> getAnimeByMalIds(List<int> malIds) async {
    if (malIds.isEmpty) return <int, Anime>{};
    final Map<int, Anime> result = <int, Anime>{};
    for (final List<int> batch in aniListBatches(malIds)) {
      result.addAll(await _fetchAnimeByMalBatch(batch));
    }
    return result;
  }

  Future<Map<int, Manga>> getMangaByMalIds(List<int> malIds) async {
    if (malIds.isEmpty) return <int, Manga>{};
    final Map<int, Manga> result = <int, Manga>{};
    for (final List<int> batch in aniListBatches(malIds)) {
      result.addAll(await _fetchMangaByMalBatch(batch));
    }
    return result;
  }

  /// Retries each batch up to [maxRateLimitRetries] on 429; non-rate-limit
  /// failures record the batch as failed and move on. Non-empty [failedIds]
  /// is how the caller distinguishes "AniList errored" from "AniList has no
  /// record" — the latter is just absence from [resolved].
  Future<AniListMalLookupResult<Anime>> getAnimeByMalIdsTolerant(
    List<int> malIds, {
    AniListRateLimitCallback? onRateLimit,
    AniListBatchProgressCallback? onBatchProgress,
  }) async {
    return _lookupTolerant<Anime>(
      malIds: malIds,
      fetchBatch: _fetchAnimeByMalBatch,
      onRateLimit: onRateLimit,
      onBatchProgress: onBatchProgress,
      label: 'anime',
    );
  }

  Future<AniListMalLookupResult<Manga>> getMangaByMalIdsTolerant(
    List<int> malIds, {
    AniListRateLimitCallback? onRateLimit,
    AniListBatchProgressCallback? onBatchProgress,
  }) async {
    return _lookupTolerant<Manga>(
      malIds: malIds,
      fetchBatch: _fetchMangaByMalBatch,
      onRateLimit: onRateLimit,
      onBatchProgress: onBatchProgress,
      label: 'manga',
    );
  }

  Future<AniListMalLookupResult<T>> _lookupTolerant<T>({
    required List<int> malIds,
    required Future<Map<int, T>> Function(List<int>) fetchBatch,
    required String label,
    AniListRateLimitCallback? onRateLimit,
    AniListBatchProgressCallback? onBatchProgress,
  }) async {
    final Map<int, T> resolved = <int, T>{};
    final List<int> failed = <int>[];

    if (malIds.isEmpty) {
      return AniListMalLookupResult<T>(resolved: resolved, failedIds: failed);
    }

    final int total = malIds.length;
    int processed = 0;

    for (final List<int> batch in aniListBatches(malIds)) {
      final Map<int, T>? batchResult = await _runBatchWithRetry<T>(
        batch: batch,
        fetchBatch: fetchBatch,
        label: label,
        onRateLimit: onRateLimit,
      );
      if (batchResult != null) {
        resolved.addAll(batchResult);
      } else {
        failed.addAll(batch);
      }
      processed += batch.length;
      onBatchProgress?.call(processed, total);
    }

    return AniListMalLookupResult<T>(resolved: resolved, failedIds: failed);
  }

  Future<Map<int, T>?> _runBatchWithRetry<T>({
    required List<int> batch,
    required Future<Map<int, T>> Function(List<int>) fetchBatch,
    required String label,
    AniListRateLimitCallback? onRateLimit,
  }) async {
    for (int attempt = 1; attempt <= maxRateLimitRetries; attempt++) {
      try {
        return await fetchBatch(batch);
      } on AniListRateLimitException catch (e) {
        if (attempt >= maxRateLimitRetries) {
          _log.warning(
            '$label batch hit rate limit, giving up after $attempt attempts',
          );
          return null;
        }
        onRateLimit?.call(e.retryAfter, attempt);
        _log.info(
          '$label batch rate-limited, waiting ${e.retryAfter.inSeconds}s '
          '(attempt $attempt/$maxRateLimitRetries)',
        );
        await Future<void>.delayed(e.retryAfter);
      } on AniListApiException catch (e) {
        _log.warning('$label batch failed: ${e.message}');
        return null;
      }
    }
    return null;
  }

  Future<Map<int, Anime>> _fetchAnimeByMalBatch(List<int> malIds) async {
    final Map<String, dynamic> body = await _client.post(
      query: AniListQueries.animeGetByMalIds,
      variables: _malBatchVars(malIds),
      errorContext: 'Failed to fetch anime by MAL IDs',
    );
    return _indexByMalId<Anime>(
      _client.unwrapData(body),
      (Map<String, dynamic> json) => Anime.fromJson(json),
    );
  }

  Future<Map<int, Manga>> _fetchMangaByMalBatch(List<int> malIds) async {
    final Map<String, dynamic> body = await _client.post(
      query: AniListQueries.mangaGetByMalIds,
      variables: _malBatchVars(malIds),
      errorContext: 'Failed to fetch manga by MAL IDs',
    );
    return _indexByMalId<Manga>(
      _client.unwrapData(body),
      (Map<String, dynamic> json) => Manga.fromJson(json),
    );
  }

  static Map<String, dynamic> _malBatchVars(List<int> malIds) =>
      <String, dynamic>{
        'page': 1,
        'perPage': malIds.length,
        'malIds': malIds,
      };

  static Map<int, T> _indexByMalId<T>(
    Map<String, dynamic>? data,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final Map<int, T> map = <int, T>{};
    if (data == null) return map;
    final Map<String, dynamic>? page =
        data['Page'] as Map<String, dynamic>?;
    if (page == null) return map;

    final List<dynamic> media = page['media'] as List<dynamic>? ?? <dynamic>[];
    for (final dynamic item in media) {
      final Map<String, dynamic> json = item as Map<String, dynamic>;
      final int? malId = json['idMal'] as int?;
      if (malId == null) continue;
      map[malId] = fromJson(json);
    }
    return map;
  }

}
