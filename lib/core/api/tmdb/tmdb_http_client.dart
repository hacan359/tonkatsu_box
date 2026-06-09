import 'package:dio/dio.dart';

import '../api_error_detail.dart';
import 'tmdb_types.dart';

// TMDB v3 transport. Owns the Dio client, the API key and the request
// language, and injects both into every request. Docs:
// https://developer.themoviedb.org/reference
class TmdbHttpClient {
  TmdbHttpClient({Dio? dio, String language = 'ru-RU'})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: _timeout,
              receiveTimeout: _timeout,
            )),
        _language = language;

  static const Duration _timeout = Duration(seconds: 5);
  static const String _baseUrl = 'https://api.themoviedb.org/3';

  final Dio _dio;

  String _language;
  String? _apiKey;

  String get language => _language;

  void setLanguage(String language) {
    _language = language;
  }

  void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  void clearApiKey() {
    _apiKey = null;
  }

  Future<bool> validateApiKey(String apiKey) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '$_baseUrl/configuration',
        queryParameters: <String, dynamic>{
          'api_key': apiKey,
        },
      );
      return response.statusCode == 200;
    } on DioException {
      return false;
    }
  }

  /// GET against [path] (relative to the base URL). The API key and request
  /// language are injected automatically; [language] overrides the stored one
  /// (reviews are pinned to en-US).
  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    String? language,
  }) {
    return _dio.get<dynamic>(
      '$_baseUrl$path',
      queryParameters: <String, dynamic>{
        'api_key': _apiKey,
        'language': language ?? _language,
        ...?queryParameters,
      },
    );
  }

  /// Unwraps the `results` array from a list endpoint as raw maps.
  List<Map<String, dynamic>> extractResults(
    Response<dynamic> response,
    String errorMessage,
  ) {
    if (response.statusCode != 200 || response.data == null) {
      throw TmdbApiException(
        errorMessage,
        statusCode: response.statusCode,
      );
    }

    final Map<String, dynamic> data = response.data as Map<String, dynamic>;
    final List<dynamic> results = data['results'] as List<dynamic>;

    return results
        .map((dynamic item) => item as Map<String, dynamic>)
        .toList();
  }

  // Maps Dio errors to user-facing messages; 401 = bad key, 429 = rate limit.
  TmdbApiException handleDioException(
    DioException e,
    String defaultMessage,
  ) {
    final int? statusCode = e.response?.statusCode;
    String message = defaultMessage;

    if (statusCode == 401) {
      message = 'Invalid API key';
    } else if (statusCode == 404) {
      message = 'Resource not found';
    } else if (statusCode == 429) {
      message = 'Rate limit exceeded. Please try again later';
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      message = 'Connection timeout';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'No internet connection';
    }

    return TmdbApiException(
      message,
      statusCode: statusCode,
      detail: buildApiErrorDetail(
        apiName: 'TMDB',
        exception: e,
        userMessage: message,
      ),
    );
  }

  void ensureApiKey() {
    if (_apiKey == null) {
      throw const TmdbApiException('API key not set');
    }
  }

  void dispose() {
    _dio.close();
  }
}
