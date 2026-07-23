import 'package:dio/dio.dart';

import '../api_error_detail.dart';
import 'tvmaze_types.dart';

// TVmaze transport (https://api.tvmaze.com), keyless REST.
class TvMazeHttpClient {
  TvMazeHttpClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://api.tvmaze.com/',
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 20),
              ),
            );

  final Dio _dio;

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.get<dynamic>(path, queryParameters: queryParameters);
  }

  TvMazeApiException handleDioException(
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

    return TvMazeApiException(
      message,
      statusCode: statusCode,
      detail: buildApiErrorDetail(
        apiName: 'TVmaze',
        exception: e,
        userMessage: message,
      ),
    );
  }

  void dispose() => _dio.close();
}
