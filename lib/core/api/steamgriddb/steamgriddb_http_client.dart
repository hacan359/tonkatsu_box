import 'package:dio/dio.dart';

import '../api_dio.dart';
import '../api_error_detail.dart';
import 'steamgriddb_types.dart';

// SteamGridDB API v2 transport. Bearer token.
// Docs: https://www.steamgriddb.com/api/v2
class SteamGridDbHttpClient {
  SteamGridDbHttpClient({Dio? dio})
      : _dio = dio ??
            createApiDio(
              connectTimeout: _timeout,
              receiveTimeout: _timeout,
            );

  static const Duration _timeout = Duration(seconds: 5);
  static const String _baseUrl = 'https://www.steamgriddb.com/api/v2';

  final Dio _dio;

  String? _apiKey;

  void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  void clearApiKey() {
    _apiKey = null;
  }

  Future<bool> validateApiKey(String apiKey) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '$_baseUrl/search/autocomplete/test',
        options: Options(
          headers: <String, dynamic>{
            'Authorization': 'Bearer $apiKey',
          },
        ),
      );
      return response.statusCode == 200;
    } on DioException {
      return false;
    }
  }

  /// GET against [path] (relative to the base URL), authenticated with the
  /// stored Bearer token.
  Future<Response<dynamic>> get(String path) {
    return _dio.get<dynamic>('$_baseUrl$path', options: _authOptions());
  }

  Options _authOptions() {
    return Options(
      headers: <String, dynamic>{
        'Authorization': 'Bearer $_apiKey',
      },
    );
  }

  SteamGridDbApiException handleDioException(
    DioException e,
    String defaultMessage,
  ) {
    final int? statusCode = e.response?.statusCode;
    String message = defaultMessage;

    if (statusCode == 401) {
      message = 'Invalid or expired API key';
    } else if (statusCode == 404) {
      message = 'Game not found';
    } else if (statusCode == 429) {
      message = 'Rate limit exceeded. Please try again later';
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      message = 'Connection timeout';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'No internet connection';
    }

    return SteamGridDbApiException(
      message,
      statusCode: statusCode,
      detail: buildApiErrorDetail(
        apiName: 'SteamGridDB',
        exception: e,
        userMessage: message,
      ),
    );
  }

  void ensureApiKey() {
    if (_apiKey == null) {
      throw const SteamGridDbApiException('API key not set');
    }
  }

  void dispose() {
    _dio.close();
  }
}
