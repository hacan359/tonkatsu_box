import 'package:core/models/manga.dart';
import 'package:dio/dio.dart';

import 'mangabaka_http_client.dart';

/// Manga series: search / browse and detail by id (`/series`).
class MangaBakaMangaApi {
  MangaBakaMangaApi(this._client);

  final MangaBakaHttpClient _client;

  /// Search / browse manga. Filters combine as AND.
  ///
  /// MangaBaka has no server-side sort, so results come back in the API's
  /// relevance order.
  Future<(List<Manga>, bool hasMore, int totalPages)> browseManga({
    String? query,
    String? type,
    String? status,
    List<String>? genres,
    List<String>? tags,
    String? contentRating,
    int page = 1,
    int perPage = 20,
  }) async {
    final Map<String, dynamic> qp = <String, dynamic>{
      if (query != null && query.isNotEmpty) 'q': query,
      if (type != null && type.isNotEmpty) 'type': type,
      if (status != null && status.isNotEmpty) 'status': status,
      if (contentRating != null && contentRating.isNotEmpty)
        'content_rating': contentRating,
      // genre: repeated key (genre=a&genre=b)
      if (genres != null && genres.isNotEmpty) 'genre': genres,
      // tag: comma-joined (tag=a,b)
      if (tags != null && tags.isNotEmpty) 'tag': tags.join(','),
      'page': page,
      'limit': perPage,
    };

    try {
      final Response<dynamic> resp = await _client.get(
        'series/search',
        queryParameters: qp,
        // multi → `genre=a&genre=b` (repeated key). multiCompatible would emit
        // `genre[]=a`, which MangaBaka rejects with a 400.
        options: Options(listFormat: ListFormat.multi),
      );
      final Map<String, dynamic> data =
          (resp.data as Map<String, dynamic>?) ?? <String, dynamic>{};
      final List<dynamic> rows =
          (data['data'] as List<dynamic>?) ?? <dynamic>[];
      final List<Manga> mangas = _parseSeries(rows);

      final Map<String, dynamic>? pagination =
          data['pagination'] as Map<String, dynamic>?;
      final bool hasMore = pagination?['next'] != null;
      final int count = (pagination?['count'] as num?)?.toInt() ?? rows.length;
      final int limit = (pagination?['limit'] as num?)?.toInt() ?? perPage;
      final int totalPages = limit > 0 ? (count / limit).ceil() : 1;

      return (mangas, hasMore, totalPages < 1 ? 1 : totalPages);
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to search MangaBaka');
    }
  }

  /// Series similar to [seedId] via MangaBaka's `/series/mix`, which blends
  /// shared tags, authors and relations. The seed itself is excluded
  /// server-side; each result carries a full series object we reuse as-is.
  Future<List<Manga>> getRecommendations(int seedId, {int limit = 20}) async {
    try {
      final Response<dynamic> resp = await _client.get(
        'series/mix',
        queryParameters: <String, dynamic>{'series': seedId, 'limit': limit},
      );
      final Map<String, dynamic> data =
          (resp.data as Map<String, dynamic>?) ?? <String, dynamic>{};
      final List<dynamic> rows =
          (data['data'] as List<dynamic>?) ?? <dynamic>[];

      final List<Manga> out = <Manga>[];
      for (final Map<String, dynamic> row
          in rows.whereType<Map<String, dynamic>>()) {
        final Object? series = row['series'];
        if (series is! Map<String, dynamic>) continue;
        final Manga? manga = _tryParseManga(series);
        if (manga != null && manga.id != seedId) out.add(manga);
      }
      return out;
    } on DioException catch (e) {
      throw _client.handleDioException(
        e,
        'Failed to load MangaBaka recommendations',
      );
    }
  }

  /// Full series record by id.
  Future<Manga?> getById(int id) async {
    try {
      final Response<dynamic> resp = await _client.get('series/$id');
      final Map<String, dynamic> data =
          (resp.data as Map<String, dynamic>?) ?? <String, dynamic>{};
      final Object? series = data['data'];
      if (series is! Map<String, dynamic>) return null;
      return _tryParseManga(series);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _client.handleDioException(e, 'Failed to load manga from MangaBaka');
    }
  }

  /// Parses the `data[]` series list, skipping any malformed entry so one bad
  /// record can't take down the whole page (a parse error is an `Error`, not
  /// an `Exception`, so it would otherwise escape the provider's catch).
  static List<Manga> _parseSeries(List<dynamic> rows) {
    final List<Manga> out = <Manga>[];
    for (final Map<String, dynamic> row
        in rows.whereType<Map<String, dynamic>>()) {
      final Manga? manga = _tryParseManga(row);
      if (manga != null) out.add(manga);
    }
    return out;
  }

  static Manga? _tryParseManga(Map<String, dynamic> json) {
    try {
      return Manga.fromMangaBaka(json);
    } on Object {
      return null;
    }
  }
}
