import 'package:core/models/data_source.dart';
import 'package:dio/dio.dart';

import '../api_error_detail.dart';
import 'mangabaka_types.dart';

// MangaBaka transport (https://api.mangabaka.org/v1/). No auth; rate-limited.
class MangaBakaHttpClient {
  MangaBakaHttpClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                // .dev is deprecated (works until 2026-08-01); .org is the
                // current host. Same schema / behaviour, shared rate limit.
                baseUrl: 'https://api.mangabaka.org/v1/',
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 20),
              ),
            );

  final Dio _dio;

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.get<dynamic>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  MangaBakaApiException handleDioException(
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
        apiName: DataSource.mangabaka.label,
        exception: e,
        userMessage: message,
      ),
    );
  }

  void dispose() {
    _dio.close();
  }
}
