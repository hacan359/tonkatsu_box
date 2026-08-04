import 'dart:math' as math;

import 'package:core/models/anime.dart';
import 'package:dio/dio.dart';

import 'kitsu_http_client.dart';

/// Anime search / detail on Kitsu (`/anime`, JSON:API).
class KitsuAnimeApi {
  KitsuAnimeApi(this._client);

  final KitsuHttpClient _client;

  Future<(List<Anime>, bool hasMore, int totalPages)> browseAnime({
    String? query,
    String? subtype,
    String? status,
    String? sort,
    int page = 1,
    int perPage = 20,
  }) async {
    final int offset = (page - 1) * perPage;
    final Map<String, dynamic> qp = <String, dynamic>{
      if (query != null && query.isNotEmpty) 'filter[text]': query,
      if (subtype != null && subtype.isNotEmpty) 'filter[subtype]': subtype,
      if (status != null && status.isNotEmpty) 'filter[status]': status,
      if (sort != null && sort.isNotEmpty) 'sort': sort,
      'page[limit]': perPage,
      'page[offset]': offset,
    };

    try {
      final Response<dynamic> resp =
          await _client.get('anime', queryParameters: qp);
      final Map<String, dynamic> data =
          (resp.data as Map<String, dynamic>?) ?? <String, dynamic>{};
      final List<dynamic> rows =
          (data['data'] as List<dynamic>?) ?? <dynamic>[];
      final List<Anime> anime = _parse(rows);

      final int total = _client.totalCount(data) ?? rows.length;
      final bool hasMore =
          _client.hasNext(data) ?? (offset + rows.length < total);
      final int totalPages = perPage > 0 ? (total / perPage).ceil() : 1;

      return (anime, hasMore, totalPages < 1 ? 1 : totalPages);
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to search Kitsu');
    }
  }

  /// Kitsu rejects `page[limit]` above 20 with a 400.
  static const int _batchLimit = 20;

  /// Fetches cards for a list of Kitsu ids (`filter[id]` accepts a comma
  /// list), batched by the page cap. Unknown ids are silently absent.
  Future<List<Anime>> getByIds(List<int> ids) async {
    final List<Anime> out = <Anime>[];
    for (int i = 0; i < ids.length; i += _batchLimit) {
      final List<int> batch =
          ids.sublist(i, math.min(i + _batchLimit, ids.length));
      try {
        final Response<dynamic> resp = await _client.get(
          'anime',
          queryParameters: <String, dynamic>{
            'filter[id]': batch.join(','),
            'page[limit]': _batchLimit,
          },
        );
        final Map<String, dynamic> data =
            (resp.data as Map<String, dynamic>?) ?? <String, dynamic>{};
        out.addAll(_parse((data['data'] as List<dynamic>?) ?? <dynamic>[]));
      } on DioException catch (e) {
        throw _client.handleDioException(e, 'Failed to load anime from Kitsu');
      }
    }
    return out;
  }

  Future<Anime?> getById(int id) async {
    try {
      final Response<dynamic> resp = await _client.get('anime/$id');
      final Map<String, dynamic> data =
          (resp.data as Map<String, dynamic>?) ?? <String, dynamic>{};
      final Object? resource = data['data'];
      if (resource is! Map<String, dynamic>) return null;
      return _tryParse(resource);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _client.handleDioException(e, 'Failed to load anime from Kitsu');
    }
  }

  static List<Anime> _parse(List<dynamic> rows) {
    final List<Anime> out = <Anime>[];
    for (final Map<String, dynamic> row
        in rows.whereType<Map<String, dynamic>>()) {
      final Anime? anime = _tryParse(row);
      if (anime != null) out.add(anime);
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
