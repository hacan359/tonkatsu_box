import 'package:core/models/data_source.dart';
import 'package:dio/dio.dart';

import '../api_error_detail.dart';
import 'vndb_types.dart';

// VNDB Kana API transport. No auth. Docs: https://api.vndb.org/kana
class VndbHttpClient {
  VndbHttpClient({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: _timeout,
              receiveTimeout: _timeout,
            ));

  static const Duration _timeout = Duration(seconds: 5);
  static const String _baseUrl = 'https://api.vndb.org/kana';

  final Dio _dio;

  Future<Response<dynamic>> post(
    String endpoint, {
    required Map<String, dynamic> data,
  }) {
    return _dio.post<dynamic>('$_baseUrl$endpoint', data: data);
  }

  VndbApiException handleDioException(
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
        apiName: DataSource.vndb.label,
        exception: e,
        userMessage: message,
      ),
    );
  }

  void dispose() {
    _dio.close();
  }
}
