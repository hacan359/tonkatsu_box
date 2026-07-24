import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../shared/models/data_source.dart';
import '../api_error_detail.dart';
import 'fantlab_types.dart';

/// Dio transport for Fantlab (`https://api.fantlab.ru`). No auth; a descriptive
/// User-Agent is sent as a courtesy. The API is beta v0.9 and its Perl backend
/// is loosely typed — numbers can arrive as strings, which the parsers handle.
class FantlabHttpClient {
  FantlabHttpClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: _baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 20),
                headers: <String, String>{'User-Agent': _userAgent},
                // Fantlab sends `Content-Type: application/json; charset=utf-8;`
                // (note the trailing `;`), which Dio's JSON sniffing rejects —
                // it would hand back the raw body as a String. Read everything
                // as plain text and decode it ourselves via [decodeBody].
                responseType: ResponseType.plain,
              ),
            );

  static const String _baseUrl = 'https://api.fantlab.ru';
  static const String _userAgent =
      'TonkatsuBox/0.32 (https://github.com/hacan359/tonkatsu_box)';

  final Dio _dio;

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.get<dynamic>(path, queryParameters: queryParameters);
  }

  /// Decodes a response body to a Map / List. Tolerates both an already-parsed
  /// object (mocks / a well-behaved transformer) and the raw JSON String the
  /// `ResponseType.plain` transport returns. A blank or malformed body → null.
  static Object? decodeBody(Object? data) {
    if (data is String) {
      if (data.trim().isEmpty) return null;
      try {
        return jsonDecode(data);
      } on FormatException {
        return null;
      }
    }
    return data;
  }

  /// Maps Dio errors to user-facing messages; 429 = rate limit.
  FantlabApiException handleDioException(
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

    return FantlabApiException(
      message,
      statusCode: statusCode,
      detail: buildApiErrorDetail(
        apiName: DataSource.fantlab.label,
        exception: e,
        userMessage: message,
      ),
    );
  }

  void dispose() {
    _dio.close();
  }
}
