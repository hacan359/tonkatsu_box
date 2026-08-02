import 'dart:math' as math;

import 'package:core/models/tv_episode.dart';
import 'package:dio/dio.dart';

import 'kitsu_http_client.dart';

/// Anime episodes on Kitsu (`/anime/{id}/episodes`, JSON:API).
///
/// The endpoint caps a page at 20 items and has no season filter, so a full
/// list is the only way to get one season. Page one carries `meta.count`, the
/// remaining pages go out in parallel batches — that keeps even the outliers
/// (One Piece, ~70 pages) down to seconds instead of a serial crawl.
class KitsuEpisodeApi {
  KitsuEpisodeApi(this._client);

  /// Kitsu rejects `page[limit]` above 20 with a 400.
  static const int _pageLimit = 20;

  /// In-flight page requests per anime.
  static const int _maxConcurrentPages = 6;

  final KitsuHttpClient _client;

  /// Total episode count in one tiny request, for anime whose cached
  /// `episodeCount` is null (ongoing and unaired titles).
  Future<int?> getEpisodeCount(int animeId) async {
    try {
      final Map<String, dynamic> page = await _page(animeId, 0, limit: 1);
      return _client.totalCount(page);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _client.handleDioException(e, 'Failed to load Kitsu episodes');
    }
  }

  /// Every episode of an anime, ordered by season then episode number.
  Future<List<TvEpisode>> getAllEpisodes(int animeId) async {
    try {
      final Map<String, dynamic> firstPage = await _page(animeId, 0);
      final List<TvEpisode> episodes = _parse(firstPage, animeId);
      final int total = _client.totalCount(firstPage) ?? episodes.length;

      final List<int> offsets = <int>[
        for (int offset = _pageLimit; offset < total; offset += _pageLimit)
          offset,
      ];

      for (int i = 0; i < offsets.length; i += _maxConcurrentPages) {
        final List<int> batch = offsets.sublist(
          i,
          math.min(i + _maxConcurrentPages, offsets.length),
        );
        final List<Map<String, dynamic>> pages = await Future.wait(
          batch.map((int offset) => _page(animeId, offset)),
        );
        for (final Map<String, dynamic> page in pages) {
          episodes.addAll(_parse(page, animeId));
        }
      }

      episodes.sort((TvEpisode a, TvEpisode b) {
        final int bySeason = a.seasonNumber.compareTo(b.seasonNumber);
        return bySeason != 0
            ? bySeason
            : a.episodeNumber.compareTo(b.episodeNumber);
      });
      return episodes;
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to load Kitsu episodes');
    }
  }

  Future<Map<String, dynamic>> _page(
    int animeId,
    int offset, {
    int limit = _pageLimit,
  }) async {
    final Response<dynamic> resp = await _client.get(
      'anime/$animeId/episodes',
      queryParameters: <String, dynamic>{
        'page[limit]': limit,
        'page[offset]': offset,
      },
    );
    return (resp.data as Map<String, dynamic>?) ?? <String, dynamic>{};
  }

  static List<TvEpisode> _parse(Map<String, dynamic> page, int animeId) {
    final List<dynamic> rows = (page['data'] as List<dynamic>?) ?? <dynamic>[];
    final List<TvEpisode> out = <TvEpisode>[];
    for (final Map<String, dynamic> row
        in rows.whereType<Map<String, dynamic>>()) {
      final TvEpisode? episode =
          TvEpisode.tryFromKitsu(row, showId: animeId);
      if (episode != null) out.add(episode);
    }
    return out;
  }
}
