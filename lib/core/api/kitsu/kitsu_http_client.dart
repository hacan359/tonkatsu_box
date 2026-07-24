import 'package:dio/dio.dart';

import '../../../shared/models/data_source.dart';
import '../api_error_detail.dart';
import 'kitsu_types.dart';

// Kitsu transport (https://kitsu.io/api/edge). JSON:API; no auth.
class KitsuHttpClient {
  KitsuHttpClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://kitsu.io/api/edge/',
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 20),
                headers: <String, String>{
                  'Accept': 'application/vnd.api+json',
                },
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

  /// JSON:API total from `meta.count`.
  int? totalCount(Map<String, dynamic> data) {
    final Object? meta = data['meta'];
    return meta is Map<String, dynamic> ? (meta['count'] as num?)?.toInt() : null;
  }

  /// JSON:API "has more" from the presence of `links.next`.
  bool? hasNext(Map<String, dynamic> data) {
    final Object? links = data['links'];
    return links is Map<String, dynamic> ? links['next'] != null : null;
  }

  KitsuApiException handleDioException(
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

    return KitsuApiException(
      message,
      statusCode: statusCode,
      detail: buildApiErrorDetail(
        apiName: DataSource.kitsu.label,
        exception: e,
        userMessage: message,
      ),
    );
  }

  void dispose() {
    _dio.close();
  }
}
