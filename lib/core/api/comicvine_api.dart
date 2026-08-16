import 'package:core/models/book.dart';
import 'package:core/models/data_source.dart';
import 'package:core/utils/bbcode.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_key_initializer.dart';
import 'api_dio.dart';
import 'api_error_detail.dart';

/// Typed ComicVine error carrying a user-facing [message] and a redacted debug
/// [detail] (consumed by `extractApiError`).
class ComicVineApiException implements Exception {
  const ComicVineApiException(this.message, {this.statusCode, this.detail});

  final String message;
  final int? statusCode;
  final String? detail;

  @override
  String toString() => 'ComicVineApiException: $message';
}

/// Wires [ComicVineApi] with the user's API key. There is no built-in key, so
/// requests throw [ComicVineApiException] until one is entered in Credentials.
final Provider<ComicVineApi> comicVineApiProvider =
    Provider<ComicVineApi>((Ref ref) {
  final ComicVineApi api = ComicVineApi();
  final ApiKeys keys = ref.read(apiKeysProvider);
  final String? key = keys.comicVineApiKey;
  if (key != null && key.isNotEmpty) {
    api.setApiKey(key);
  }
  return api;
});

/// ComicVine client. Quirks: the API rejects Dio's default `User-Agent`,
/// detail paths take the `4050-{id}` form, rate limit is 200 req/hour.
class ComicVineApi {
  ComicVineApi({Dio? dio})
      : _dio = dio ??
            createApiDio(
              baseUrl: _baseUrl,
              connectTimeout: _timeout,
              receiveTimeout: _timeout,
              headers: const <String, String>{'User-Agent': _userAgent},
            );

  static const String _baseUrl = 'https://comicvine.gamespot.com/api';
  static const String _userAgent = 'TonkatsuBox/1.0 (Flutter app)';
  static const Duration _timeout = Duration(seconds: 8);

  /// Volume fields shared by search / browse / detail responses.
  static const String _volumeFields = 'id,name,start_year,count_of_issues,'
      'publisher,image,site_detail_url,description,deck';

  /// `people`, `characters` and `first_issue` are absent from `/search` and
  /// `/volumes` list rows, so they are requested only on `/volume`.
  static const String _volumeDetailFields =
      '$_volumeFields,people,characters,first_issue';

  final Dio _dio;
  String? _apiKey;

  void setApiKey(String apiKey) => _apiKey = apiKey;

  void clearApiKey() => _apiKey = null;

  bool get hasApiKey => _apiKey != null && _apiKey!.isNotEmpty;

  /// Relevance-ranked volume search. `/search` ignores `offset`, so this
  /// returns a single page (up to [limit], capped at 100 by the API).
  Future<List<Book>> searchVolumes(String query, {int limit = 100}) async {
    final Response<dynamic> res = await _get('/search/', <String, dynamic>{
      'query': query,
      'resources': 'volume',
      'limit': limit,
      'field_list': _volumeFields,
    });
    return _parseList(res, 'ComicVine search failed');
  }

  /// Unlike `/search`, `/volumes` honours `offset` and `sort` — but only
  /// `name`, `date_added`, `date_last_updated`; other sorts silently ignored.
  Future<(List<Book> books, bool hasMore)> browseVolumes({
    String? nameFilter,
    String sort = 'date_last_updated:desc',
    int page = 1,
    int perPage = 24,
  }) async {
    final int offset = (page - 1) * perPage;
    final String? name = nameFilter?.trim();
    final Response<dynamic> res = await _get('/volumes/', <String, dynamic>{
      if (sort.isNotEmpty) 'sort': sort,
      if (name != null && name.isNotEmpty) 'filter': 'name:$name',
      'limit': perPage,
      'offset': offset,
      'field_list': _volumeFields,
    });
    final Map<String, dynamic> data = _ensureOk(res, 'ComicVine browse failed');
    final List<Book> books = _booksFrom(data);
    final int total = (data['number_of_total_results'] as num?)?.toInt() ?? 0;
    return (books, offset + books.length < total);
  }

  /// Volume-level descriptions are frequently empty, so an empty one falls
  /// back to the first issue's synopsis — one extra request, only when needed.
  Future<Book?> getVolume(String nativeId) async {
    final Response<dynamic> res =
        await _get('/volume/$nativeId/', <String, dynamic>{
      'field_list': _volumeDetailFields,
    });
    final Map<String, dynamic> data = _ensureOk(res, 'ComicVine volume failed');
    final Object? results = data['results'];
    if (results is! Map<String, dynamic>) return null;
    final Book book = Book.fromComicVineVolume(results);
    if (book.description != null) return book;
    final String? fallback = await _firstIssueDescription(results['first_issue']);
    return fallback == null ? book : book.copyWith(description: fallback);
  }

  /// Best-effort synopsis from a volume's `first_issue`. Null on any failure —
  /// enrichment must never sink the volume fetch.
  Future<String?> _firstIssueDescription(Object? firstIssue) async {
    if (firstIssue is! Map<String, dynamic>) return null;
    final int? issueId = (firstIssue['id'] as num?)?.toInt();
    if (issueId == null) return null;
    try {
      final Response<dynamic> res =
          await _get('/issue/4000-$issueId/', <String, dynamic>{
        'field_list': 'description,deck',
      });
      final Map<String, dynamic> data = _ensureOk(res, 'ComicVine issue failed');
      final Object? r = data['results'];
      if (r is! Map<String, dynamic>) return null;
      final Object? raw = r['description'] ?? r['deck'];
      if (raw is! String || raw.isEmpty) return null;
      final String clean = stripBbCodes(raw).trim();
      return clean.isEmpty ? null : clean;
    } on ComicVineApiException {
      return null;
    }
  }

  /// Lightweight key check for the Credentials "test" button.
  Future<bool> validateApiKey(String apiKey) async {
    try {
      final Response<dynamic> res = await _dio.get<dynamic>(
        '/search/',
        queryParameters: <String, dynamic>{
          'api_key': apiKey,
          'format': 'json',
          'query': 'batman',
          'resources': 'volume',
          'limit': 1,
          'field_list': 'id',
        },
      );
      final Object? body = res.data;
      return res.statusCode == 200 &&
          body is Map<String, dynamic> &&
          ((body['status_code'] as num?)?.toInt() ?? 0) == 1;
    } on DioException {
      return false;
    }
  }

  Future<Response<dynamic>> _get(
    String path,
    Map<String, dynamic> query,
  ) async {
    if (!hasApiKey) {
      throw const ComicVineApiException('ComicVine API key not set');
    }
    try {
      return await _dio.get<dynamic>(
        path,
        queryParameters: <String, dynamic>{
          'api_key': _apiKey,
          'format': 'json',
          ...query,
        },
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// Validates the HTTP status and ComicVine envelope (`status_code == 1`),
  /// returning the decoded body map.
  Map<String, dynamic> _ensureOk(Response<dynamic> res, String message) {
    final Object? body = res.data;
    if (res.statusCode != 200 || body is! Map<String, dynamic>) {
      throw ComicVineApiException(message, statusCode: res.statusCode);
    }
    final int status = (body['status_code'] as num?)?.toInt() ?? 0;
    if (status != 1) {
      final Object? error = body['error'];
      final String detail =
          (error is String && error.isNotEmpty && error != 'OK')
              ? error
              : message;
      throw ComicVineApiException(detail, statusCode: res.statusCode);
    }
    return body;
  }

  List<Book> _parseList(Response<dynamic> res, String message) =>
      _booksFrom(_ensureOk(res, message));

  List<Book> _booksFrom(Map<String, dynamic> data) {
    final Object? results = data['results'];
    if (results is! List<dynamic>) return const <Book>[];
    return results
        .whereType<Map<String, dynamic>>()
        .map(Book.fromComicVineVolume)
        .toList();
  }

  ComicVineApiException _mapDioError(DioException e) {
    final int? statusCode = e.response?.statusCode;
    final String message;
    if (statusCode == 401 || statusCode == 420) {
      message = 'Invalid ComicVine API key';
    } else if (statusCode == 404) {
      message = 'Resource not found';
    } else if (statusCode == 429) {
      message = 'ComicVine rate limit exceeded (200/hour)';
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      message = 'Connection timeout';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'No internet connection';
    } else {
      message = 'ComicVine request failed';
    }
    return ComicVineApiException(
      message,
      statusCode: statusCode,
      detail: buildApiErrorDetail(
        apiName: DataSource.comicVine.label,
        exception: e,
        userMessage: message,
      ),
    );
  }

  void dispose() => _dio.close();
}
