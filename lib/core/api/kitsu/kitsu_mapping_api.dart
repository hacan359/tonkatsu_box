import 'dart:math' as math;

import 'package:core/models/anime.dart';
import 'package:dio/dio.dart';

import 'kitsu_http_client.dart';

/// External-id lookup on Kitsu (`/mappings`, JSON:API): `filter[externalId]`
/// takes a comma list and `include=item` inlines the anime records.
class KitsuMappingApi {
  KitsuMappingApi(this._client);

  /// `filter[externalSite]` value for MyAnimeList anime ids.
  static const String siteMyAnimeList = 'myanimelist/anime';

  /// `filter[externalSite]` value for AniDB ids.
  static const String siteAniDb = 'anidb';

  /// `filter[externalSite]` / `externalSite` value for AniList anime ids.
  static const String siteAniListAnime = 'anilist/anime';

  /// Same for AniList manga ids.
  static const String siteAniListManga = 'anilist/manga';

  /// Kitsu rejects `page[limit]` above 20 with a 400.
  static const int _batchLimit = 20;

  final KitsuHttpClient _client;

  /// Maps each resolvable external id to its Kitsu anime. Ids without a
  /// mapping or with a stale `item` are simply absent from the result.
  Future<Map<int, Anime>> resolveAnime({
    required String externalSite,
    required List<int> externalIds,
  }) async {
    final Map<int, Anime> resolved = <int, Anime>{};
    for (int i = 0; i < externalIds.length; i += _batchLimit) {
      final List<int> batch = externalIds.sublist(
        i,
        math.min(i + _batchLimit, externalIds.length),
      );
      resolved.addAll(await _resolveBatch(externalSite, batch));
    }
    return resolved;
  }

  Future<Map<int, Anime>> _resolveBatch(
    String externalSite,
    List<int> batch,
  ) async {
    try {
      final Map<int, Anime> out = <int, Anime>{};
      int offset = 0;
      // Duplicate mapping rows can push a 20-id batch past one page.
      while (true) {
        final Response<dynamic> resp = await _client.get(
          'mappings',
          queryParameters: <String, dynamic>{
            'filter[externalSite]': externalSite,
            'filter[externalId]': batch.join(','),
            'include': 'item',
            'page[limit]': _batchLimit,
            'page[offset]': offset,
          },
        );
        final Map<String, dynamic> data =
            (resp.data as Map<String, dynamic>?) ?? <String, dynamic>{};
        out.addAll(_parsePage(data));
        if (!(_client.hasNext(data) ?? false)) break;
        offset += _batchLimit;
      }
      return out;
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to resolve Kitsu mappings');
    }
  }

  /// AniList id of a Kitsu title via its own `mappings` list, or null when
  /// the title has no AniList mapping.
  Future<int?> getAniListId({
    required int kitsuId,
    required bool manga,
  }) async {
    final String kind = manga ? 'manga' : 'anime';
    final String site = manga ? siteAniListManga : siteAniListAnime;
    try {
      final Response<dynamic> resp = await _client.get(
        '$kind/$kitsuId/mappings',
        queryParameters: <String, dynamic>{'page[limit]': _batchLimit},
      );
      final Map<String, dynamic> data =
          (resp.data as Map<String, dynamic>?) ?? <String, dynamic>{};
      for (final Map<String, dynamic> mapping
          in ((data['data'] as List<dynamic>?) ?? <dynamic>[])
              .whereType<Map<String, dynamic>>()) {
        final Map<String, dynamic>? attrs =
            mapping['attributes'] as Map<String, dynamic>?;
        if (attrs?['externalSite'] != site) continue;
        return int.tryParse((attrs?['externalId'] as String?) ?? '');
      }
      return null;
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to load Kitsu mappings');
    }
  }

  static Map<int, Anime> _parsePage(Map<String, dynamic> data) {
    // Included anime records by Kitsu id.
    final Map<String, Anime> included = <String, Anime>{};
    for (final Map<String, dynamic> resource
        in ((data['included'] as List<dynamic>?) ?? <dynamic>[])
            .whereType<Map<String, dynamic>>()) {
      if (resource['type'] != 'anime') continue;
      final Anime? anime = _tryParse(resource);
      final Object? id = resource['id'];
      if (anime != null && id is String) included[id] = anime;
    }

    final Map<int, Anime> out = <int, Anime>{};
    for (final Map<String, dynamic> mapping
        in ((data['data'] as List<dynamic>?) ?? <dynamic>[])
            .whereType<Map<String, dynamic>>()) {
      final Map<String, dynamic>? attrs =
          mapping['attributes'] as Map<String, dynamic>?;
      final int? externalId =
          int.tryParse((attrs?['externalId'] as String?) ?? '');
      if (externalId == null) continue;

      final Object? relationships = mapping['relationships'];
      final Object? item = relationships is Map<String, dynamic>
          ? relationships['item']
          : null;
      final Object? itemData =
          item is Map<String, dynamic> ? item['data'] : null;
      final String? kitsuId = itemData is Map<String, dynamic>
          ? itemData['id'] as String?
          : null;

      final Anime? anime = kitsuId != null ? included[kitsuId] : null;
      if (anime != null) out[externalId] = anime;
    }
    return out;
  }

  static Anime? _tryParse(Map<String, dynamic> json) {
    try {
      return Anime.fromKitsu(json);
    } on Object {
      return null;
    }
  }
}
