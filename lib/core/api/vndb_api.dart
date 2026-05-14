import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../shared/models/visual_novel.dart';
import 'api_error_detail.dart';

final Provider<VndbApi> vndbApiProvider = Provider<VndbApi>((Ref ref) {
  return VndbApi();
});

class VndbApiException implements Exception {
  const VndbApiException(this.message, {this.statusCode, this.detail});

  final String message;
  final int? statusCode;
  final String? detail;

  @override
  String toString() => 'VndbApiException: $message (status: $statusCode)';
}

/// VNDB Kana API client. No auth required.
/// Docs: https://api.vndb.org/kana
class VndbApi {
  VndbApi({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: _timeout,
              receiveTimeout: _timeout,
            ));

  // ignore: unused_field
  static final Logger _log = Logger('VndbApi');

  static const Duration _timeout = Duration(seconds: 5);
  static const String _baseUrl = 'https://api.vndb.org/kana';

  static const String _vnFields =
      'title, alttitle, description, image.url, rating, votecount, '
      'released, length_minutes, length, tags.name, tags.rating, '
      'developers.name, platforms';

  final Dio _dio;

  Future<(List<VisualNovel>, bool hasMore)> searchVn({
    required String query,
    int page = 1,
    int results = 20,
  }) async {
    if (query.trim().isEmpty) {
      return (<VisualNovel>[], false);
    }

    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '$_baseUrl/vn',
        data: <String, dynamic>{
          'filters': <dynamic>['search', '=', query],
          'fields': _vnFields,
          'sort': 'searchrank',
          'results': results,
          'page': page,
        },
      );

      return _parseVnResponse(response);
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to search visual novels');
    }
  }

  /// Browse with structured filters and no free-text query (or a mixed
  /// query+filter call). When no query is supplied, we add `votecount >= 10`
  /// to keep junk entries out of the default browse view.
  Future<(List<VisualNovel>, bool hasMore, int totalPages)> browseVn({
    String? query,
    String? tagId,
    String sort = 'rating',
    bool reverse = true,
    int page = 1,
    int results = 20,
  }) async {
    try {
      final List<dynamic> filters = <dynamic>[];

      if (query != null && query.trim().isNotEmpty) {
        filters.add(<dynamic>['search', '=', query]);
      }

      if (tagId != null) {
        filters.add(<dynamic>['tag', '=', tagId]);
      }

      if (query == null || query.trim().isEmpty) {
        filters.add(<dynamic>['votecount', '>=', 10]);
      }

      final dynamic finalFilter = filters.length == 1
          ? filters.first
          : <dynamic>['and', ...filters];

      final Map<String, dynamic> body = <String, dynamic>{
        'filters': finalFilter,
        'fields': _vnFields,
        'sort': sort,
        'reverse': reverse,
        'results': results,
        'page': page,
        'count': true,
      };

      final Response<dynamic> response = await _dio.post<dynamic>(
        '$_baseUrl/vn',
        data: body,
      );

      if (response.statusCode != 200 || response.data == null) {
        throw VndbApiException(
          'Failed to browse visual novels',
          statusCode: response.statusCode,
        );
      }

      final Map<String, dynamic> data =
          response.data as Map<String, dynamic>;
      final List<dynamic> resultsList =
          data['results'] as List<dynamic>? ?? <dynamic>[];
      final bool hasMore = data['more'] as bool? ?? false;
      final int count = data['count'] as int? ?? 0;
      final int totalPages = results > 0 ? (count / results).ceil() : 1;

      final List<VisualNovel> novels = resultsList
          .map((dynamic item) =>
              VisualNovel.fromJson(item as Map<String, dynamic>))
          .toList();

      return (novels, hasMore, totalPages);
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to browse visual novels');
    }
  }

  Future<VisualNovel?> getVnById(String id) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '$_baseUrl/vn',
        data: <String, dynamic>{
          'filters': <dynamic>['id', '=', id],
          'fields': _vnFields,
        },
      );

      if (response.statusCode != 200 || response.data == null) {
        throw VndbApiException(
          'Failed to fetch visual novel',
          statusCode: response.statusCode,
        );
      }

      final Map<String, dynamic> data =
          response.data as Map<String, dynamic>;
      final List<dynamic> results =
          data['results'] as List<dynamic>? ?? <dynamic>[];

      if (results.isEmpty) return null;

      return VisualNovel.fromJson(results.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to fetch visual novel');
    }
  }

  Future<List<VisualNovel>> getVnByIds(List<String> ids) async {
    if (ids.isEmpty) return <VisualNovel>[];

    try {
      // VNDB supports an `["or", ...ids]` shape for bulk lookups, which lets
      // us issue one request instead of one-per-id.
      final List<dynamic> idFilters = <dynamic>[
        'or',
        ...ids.map((String id) => <dynamic>['id', '=', id]),
      ];

      final Response<dynamic> response = await _dio.post<dynamic>(
        '$_baseUrl/vn',
        data: <String, dynamic>{
          'filters': idFilters,
          'fields': _vnFields,
          'results': ids.length,
        },
      );

      if (response.statusCode != 200 || response.data == null) {
        throw VndbApiException(
          'Failed to fetch visual novels by IDs',
          statusCode: response.statusCode,
        );
      }

      final Map<String, dynamic> data =
          response.data as Map<String, dynamic>;
      final List<dynamic> results =
          data['results'] as List<dynamic>? ?? <dynamic>[];

      return results
          .map((dynamic item) =>
              VisualNovel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to fetch visual novels by IDs');
    }
  }

  /// Fetches the top 100 content tags (VNDB category `cont`) sorted by usage
  /// count — these are what we surface as "genres" in the UI.
  Future<List<VndbTag>> fetchTags() async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '$_baseUrl/tag',
        data: <String, dynamic>{
          'filters': <dynamic>['category', '=', 'cont'],
          'fields': 'name',
          'results': 100,
          'sort': 'vn_count',
          'reverse': true,
        },
      );

      if (response.statusCode != 200 || response.data == null) {
        throw VndbApiException(
          'Failed to fetch tags',
          statusCode: response.statusCode,
        );
      }

      final Map<String, dynamic> data =
          response.data as Map<String, dynamic>;
      final List<dynamic> results =
          data['results'] as List<dynamic>? ?? <dynamic>[];

      return results
          .map((dynamic item) =>
              VndbTag.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to fetch tags');
    }
  }

  (List<VisualNovel>, bool hasMore) _parseVnResponse(
    Response<dynamic> response,
  ) {
    if (response.statusCode != 200 || response.data == null) {
      throw VndbApiException(
        'Unexpected response',
        statusCode: response.statusCode,
      );
    }

    final Map<String, dynamic> data =
        response.data as Map<String, dynamic>;
    final List<dynamic> results =
        data['results'] as List<dynamic>? ?? <dynamic>[];
    final bool hasMore = data['more'] as bool? ?? false;

    final List<VisualNovel> novels = results
        .map((dynamic item) =>
            VisualNovel.fromJson(item as Map<String, dynamic>))
        .toList();

    return (novels, hasMore);
  }

  VndbApiException _handleDioException(
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

    return VndbApiException(
      message,
      statusCode: statusCode,
      detail: buildApiErrorDetail(
        apiName: 'VNDB',
        exception: e,
        userMessage: message,
      ),
    );
  }

  void dispose() {
    _dio.close();
  }
}
