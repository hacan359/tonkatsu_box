import 'package:dio/dio.dart';

import '../api_error_detail.dart';
import 'openlibrary_types.dart';

/// Dio transport for OpenLibrary. No auth, but a descriptive User-Agent is
/// required — anonymous bots can be blocked. Hosts both `openlibrary.org`
/// (search / works / authors) on one base URL.
class OpenLibraryHttpClient {
  OpenLibraryHttpClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: _baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 20),
                headers: <String, String>{'User-Agent': _userAgent},
              ),
            );

  static const String _baseUrl = 'https://openlibrary.org';
  static const String _userAgent =
      'TonkatsuBox/0.32 (https://github.com/hacan359/tonkatsu_box)';

  final Dio _dio;

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.get<dynamic>(path, queryParameters: queryParameters);
  }

  /// Maps Dio errors to user-facing messages; 429 = rate limit.
  OpenLibraryApiException handleDioException(
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

    return OpenLibraryApiException(
      message,
      statusCode: statusCode,
      detail: buildApiErrorDetail(
        apiName: 'OpenLibrary',
        exception: e,
        userMessage: message,
      ),
    );
  }

  void dispose() {
    _dio.close();
  }
}
