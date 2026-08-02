import 'package:core/models/manga.dart';
import 'package:dio/dio.dart';

import 'kitsu_http_client.dart';

/// Manga search / detail on Kitsu (`/manga`, JSON:API).
class KitsuMangaApi {
  KitsuMangaApi(this._client);

  final KitsuHttpClient _client;

  /// Search / browse manga. Genres are related JSON:API resources and are not
  /// requested here (they'd need a separate `include`), so they stay null.
  Future<(List<Manga>, bool hasMore, int totalPages)> browseManga({
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
          await _client.get('manga', queryParameters: qp);
      final Map<String, dynamic> data =
          (resp.data as Map<String, dynamic>?) ?? <String, dynamic>{};
      final List<dynamic> rows =
          (data['data'] as List<dynamic>?) ?? <dynamic>[];
      final List<Manga> mangas = _parse(rows);

      final int total = _client.totalCount(data) ?? rows.length;
      final bool hasMore =
          _client.hasNext(data) ?? (offset + rows.length < total);
      final int totalPages = perPage > 0 ? (total / perPage).ceil() : 1;

      return (mangas, hasMore, totalPages < 1 ? 1 : totalPages);
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to search Kitsu');
    }
  }

  /// Full manga by Kitsu id.
  Future<Manga?> getById(int id) async {
    try {
      final Response<dynamic> resp = await _client.get('manga/$id');
      final Map<String, dynamic> data =
          (resp.data as Map<String, dynamic>?) ?? <String, dynamic>{};
      final Object? resource = data['data'];
      if (resource is! Map<String, dynamic>) return null;
      return _tryParse(resource);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _client.handleDioException(e, 'Failed to load manga from Kitsu');
    }
  }

  static List<Manga> _parse(List<dynamic> rows) {
    final List<Manga> out = <Manga>[];
    for (final Map<String, dynamic> row
        in rows.whereType<Map<String, dynamic>>()) {
      final Manga? manga = _tryParse(row);
      if (manga != null) out.add(manga);
    }
    return out;
  }

  static Manga? _tryParse(Map<String, dynamic> json) {
    try {
      return Manga.fromKitsu(json);
    } on Object {
      return null;
    }
  }
}
