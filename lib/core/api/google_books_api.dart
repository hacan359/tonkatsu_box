import 'package:core/models/book.dart';
import 'package:core/models/data_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_key_initializer.dart';
import 'api_dio.dart';
import 'api_error_detail.dart';

/// Typed Google Books error carrying a user-facing [message] and a redacted
/// debug [detail] (consumed by `extractApiError`).
class GoogleBooksApiException implements Exception {
  const GoogleBooksApiException(this.message, {this.statusCode, this.detail});

  final String message;
  final int? statusCode;
  final String? detail;

  @override
  String toString() => 'GoogleBooksApiException: $message';
}

/// Wires [GoogleBooksApi] with the user's optional API key. Anonymous search
/// works under a strict shared quota, so a user key only raises the quota.
final Provider<GoogleBooksApi> googleBooksApiProvider =
    Provider<GoogleBooksApi>((Ref ref) {
  final GoogleBooksApi api = GoogleBooksApi();
  final ApiKeys keys = ref.read(apiKeysProvider);
  final String? key = keys.googleBooksApiKey;
  if (key != null && key.isNotEmpty) {
    api.setApiKey(key);
  }
  return api;
});

/// Google Books client. List rows already carry the full `volumeInfo`, so
/// [getVolume] is only needed for refetch, not to enrich search results.
class GoogleBooksApi {
  GoogleBooksApi({Dio? dio})
      : _dio = dio ??
            createApiDio(
              baseUrl: _baseUrl,
              connectTimeout: _timeout,
              receiveTimeout: _timeout,
            );

  static const String _baseUrl = 'https://www.googleapis.com/books/v1';
  static const Duration _timeout = Duration(seconds: 8);

  /// `volumes.list` caps a page at 40.
  static const int maxPageSize = 40;

  final Dio _dio;
  String? _apiKey;

  void setApiKey(String apiKey) => _apiKey = apiKey;

  void clearApiKey() => _apiKey = null;

  bool get hasApiKey => _apiKey != null && _apiKey!.isNotEmpty;

  /// Paginated volume search. `hasMore` is gated on both the estimated
  /// `totalItems` and a full page — the estimate can shrink between pages.
  Future<(List<Book> books, bool hasMore)> searchVolumes(
    String query, {
    int startIndex = 0,
    int maxResults = 20,
    String orderBy = 'relevance',
    String? langRestrict,
    String printType = 'books',
  }) async {
    final int limit = maxResults > maxPageSize ? maxPageSize : maxResults;
    final Response<dynamic> res = await _get('/volumes', <String, dynamic>{
      'q': query,
      'startIndex': startIndex,
      'maxResults': limit,
      if (orderBy.isNotEmpty) 'orderBy': orderBy,
      if (printType.isNotEmpty) 'printType': printType,
      if (langRestrict != null && langRestrict.isNotEmpty)
        'langRestrict': langRestrict,
    });
    final Map<String, dynamic> data =
        _ensureOk(res, 'Google Books search failed');
    final List<Book> books = _booksFrom(data['items']);
    final int total = (data['totalItems'] as num?)?.toInt() ?? 0;
    final bool hasMore =
        books.length >= limit && startIndex + books.length < total;
    return (books, hasMore);
  }

  /// Full volume by its `volumeId` (stored as [Book.nativeId]). Returns null
  /// when the volume is missing.
  Future<Book?> getVolume(String volumeId) async {
    final Response<dynamic> res =
        await _get('/volumes/$volumeId', const <String, dynamic>{});
    final Map<String, dynamic> data =
        _ensureOk(res, 'Google Books volume failed');
    final Object? id = data['id'];
    if (id is! String || id.isEmpty) return null;
    return Book.fromGoogleBooksVolume(data);
  }

  /// Anonymous search succeeds too, so the key is sent explicitly and a 200
  /// proves it was accepted (an invalid key returns 400).
  Future<bool> validateApiKey(String apiKey) async {
    try {
      final Response<dynamic> res = await _dio.get<dynamic>(
        '/volumes',
        queryParameters: <String, dynamic>{
          'q': 'flutter',
          'maxResults': 1,
          'key': apiKey,
        },
      );
      return res.statusCode == 200;
    } on DioException {
      return false;
    }
  }

  Future<Response<dynamic>> _get(
    String path,
    Map<String, dynamic> query,
  ) async {
    try {
      return await _dio.get<dynamic>(
        path,
        queryParameters: <String, dynamic>{
          ...query,
          if (hasApiKey) 'key': _apiKey,
        },
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Map<String, dynamic> _ensureOk(Response<dynamic> res, String message) {
    final Object? body = res.data;
    if (res.statusCode != 200 || body is! Map<String, dynamic>) {
      throw GoogleBooksApiException(message, statusCode: res.statusCode);
    }
    return body;
  }

  List<Book> _booksFrom(Object? items) {
    if (items is! List<dynamic>) return const <Book>[];
    return items
        .whereType<Map<String, dynamic>>()
        .map(Book.fromGoogleBooksVolume)
        .toList();
  }

  GoogleBooksApiException _mapDioError(DioException e) {
    final int? statusCode = e.response?.statusCode;
    final String message;
    if (statusCode == 400) {
      message = 'Invalid Google Books request or API key';
    } else if (statusCode == 403 || statusCode == 429) {
      message = 'Google Books quota exceeded';
    } else if (statusCode == 404) {
      message = 'Volume not found';
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      message = 'Connection timeout';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'No internet connection';
    } else {
      message = 'Google Books request failed';
    }
    return GoogleBooksApiException(
      message,
      statusCode: statusCode,
      detail: buildApiErrorDetail(
        apiName: DataSource.googleBooks.label,
        exception: e,
        userMessage: message,
      ),
    );
  }

  void dispose() => _dio.close();
}
