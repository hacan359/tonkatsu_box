import 'package:core/models/data_source.dart';
import 'package:dio/dio.dart';

import '../api_dio.dart';
import '../api_error_detail.dart';
import 'musicbrainz_types.dart';

// MusicBrainz transport (https://musicbrainz.org/ws/2), keyless REST. The
// per-host queue in createApiDio keeps it under the 1 req/s service rule.
class MusicBrainzHttpClient {
  MusicBrainzHttpClient({Dio? dio})
      : _dio = dio ??
            createApiDio(
              baseUrl: 'https://musicbrainz.org/ws/2/',
              connectTimeout: const Duration(seconds: 15),
              // The server throttles instead of failing, so a held request can
              // sit for several seconds before it answers.
              receiveTimeout: const Duration(seconds: 30),
              headers: const <String, String>{'User-Agent': kAppUserAgent},
            );

  final Dio _dio;

  static const int _maxAttempts = 3;

  // MusicBrainz answers 503 for both rate limiting and a busy search index;
  // a paced retry recovers most of them instead of surfacing an error.
  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    for (int attempt = 1;; attempt++) {
      try {
        return await _dio.get<dynamic>(
          path,
          queryParameters: <String, dynamic>{
            ...?queryParameters,
            'fmt': 'json',
          },
        );
      } on DioException catch (e) {
        if (e.response?.statusCode != 503 || attempt >= _maxAttempts) rethrow;
        await Future<void>.delayed(_retryDelay(e, attempt));
      }
    }
  }

  static Duration _retryDelay(DioException e, int attempt) {
    final Object? header = e.response?.headers.value('retry-after');
    final int? seconds = header is String ? int.tryParse(header) : null;
    if (seconds != null && seconds > 0 && seconds <= 10) {
      return Duration(seconds: seconds);
    }
    return Duration(seconds: 2 * attempt);
  }

  MusicBrainzApiException handleDioException(
    DioException e,
    String defaultMessage,
  ) {
    final int? statusCode = e.response?.statusCode;
    String message = defaultMessage;
    if (statusCode == 503) {
      message = 'MusicBrainz rate limit exceeded. Please try again later';
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      message = 'Connection timeout';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'No internet connection';
    }

    return MusicBrainzApiException(
      message,
      statusCode: statusCode,
      detail: buildApiErrorDetail(
        apiName: DataSource.musicBrainz.label,
        exception: e,
        userMessage: message,
      ),
    );
  }

  void dispose() => _dio.close();
}
