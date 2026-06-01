// MangaBaka API client (https://api.mangabaka.org/v1/).

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/manga.dart';
import '../../shared/models/mangabaka_tag.dart';
import 'api_error_detail.dart';

/// Error from the MangaBaka API. [detail] is a redacted, copyable debug
/// string (request + status + body) consumed by `extractApiError`.
class MangaBakaApiException implements Exception {
  const MangaBakaApiException(this.message, {this.statusCode, this.detail});

  final String message;
  final int? statusCode;
  final String? detail;

  @override
  String toString() => 'MangaBakaApiException: $message (status: $statusCode)';
}

/// REST client for MangaBaka. No auth; rate-limited (429) — results are
/// cached at the repository / DB layer.
class MangaBakaApi {
  MangaBakaApi({Dio? dio})
      : _client = dio ??
            Dio(
              BaseOptions(
                // .dev is deprecated (works until 2026-08-01); .org is the
                // current host. Same schema / behaviour, shared rate limit.
                baseUrl: 'https://api.mangabaka.org/v1/',
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 20),
              ),
            );

  final Dio _client;

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
      final Response<dynamic> resp = await _client.get<dynamic>(
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
      throw _handleDioException(e, 'Failed to search MangaBaka');
    }
  }

  /// Full series record by id.
  Future<Manga?> getById(int id) async {
    try {
      final Response<dynamic> resp = await _client.get<dynamic>('series/$id');
      final Map<String, dynamic> data =
          (resp.data as Map<String, dynamic>?) ?? <String, dynamic>{};
      final Object? series = data['data'];
      if (series is! Map<String, dynamic>) return null;
      return _tryParseManga(series);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _handleDioException(e, 'Failed to load manga from MangaBaka');
    }
  }

  /// Full tag catalog (`/v1/tags`, ~2700 entries).
  Future<List<MangaBakaTag>> fetchTagCatalog() async {
    try {
      final Response<dynamic> resp = await _client.get<dynamic>('tags');
      final Map<String, dynamic> data =
          (resp.data as Map<String, dynamic>?) ?? <String, dynamic>{};
      final List<dynamic> rows =
          (data['data'] as List<dynamic>?) ?? <dynamic>[];
      final List<MangaBakaTag> tags = <MangaBakaTag>[];
      for (final Map<String, dynamic> row
          in rows.whereType<Map<String, dynamic>>()) {
        try {
          tags.add(MangaBakaTag.fromJson(row));
        } on Object {
          // Skip a malformed tag entry rather than failing the whole catalog.
        }
      }
      return tags;
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to load MangaBaka tags');
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

  MangaBakaApiException _handleDioException(
    DioException e,
    String defaultMessage,
  ) {
    final int? statusCode = e.response?.statusCode;
    String message = defaultMessage;
    if (statusCode == 429) {
      message = 'Rate limit exceeded. Please try again later';
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      message = 'Connection timeout';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'No internet connection';
    }

    return MangaBakaApiException(
      message,
      statusCode: statusCode,
      detail: buildApiErrorDetail(
        apiName: 'MangaBaka',
        exception: e,
        userMessage: message,
      ),
    );
  }
}

final Provider<MangaBakaApi> mangaBakaApiProvider =
    Provider<MangaBakaApi>((Ref ref) => MangaBakaApi());
