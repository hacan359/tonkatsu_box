import 'package:core/api/podcast_index_signature.dart';
import 'package:core/models/data_source.dart';
import 'package:dio/dio.dart';

import '../../../shared/constants/platform_features.dart';
import '../api_dio.dart';
import '../api_error_detail.dart';

/// Typed Podcast Index error carrying a user-facing [message] and a redacted
/// debug [detail] (consumed by `extractApiError`).
class PodcastIndexApiException implements Exception {
  const PodcastIndexApiException(this.message, {this.statusCode, this.detail});

  final String message;
  final int? statusCode;
  final String? detail;

  @override
  String toString() => 'PodcastIndexApiException: $message';
}

/// The signature embeds the current unix time and is valid for ±3 minutes, so
/// it has to be computed per request, not per client.
class PodcastIndexAuthInterceptor extends Interceptor {
  PodcastIndexAuthInterceptor({DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  String? _key;
  String? _secret;

  void setCredentials(String key, String secret) {
    _key = key;
    _secret = secret;
  }

  void clearCredentials() {
    _key = null;
    _secret = null;
  }

  bool get hasCredentials =>
      _key != null && _key!.isNotEmpty && _secret != null && _secret!.isNotEmpty;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // The browser never holds the secret; the selfhost proxy signs instead.
    if (!kIsWebBuild && hasCredentials) {
      final int unixTime = _now().millisecondsSinceEpoch ~/ 1000;
      options.headers['X-Auth-Date'] = '$unixTime';
      options.headers['X-Auth-Key'] = _key;
      options.headers['Authorization'] =
          podcastIndexSignature(_key!, _secret!, unixTime);
    }
    handler.next(options);
  }
}

/// Every request carries a sha1 signature; a wrong pair and a skewed system
/// clock both answer 401 with a plain-text body.
class PodcastIndexHttpClient {
  PodcastIndexHttpClient({Dio? dio, DateTime Function()? now})
      : _auth = PodcastIndexAuthInterceptor(now: now),
        _dio = dio ??
            createApiDio(
              baseUrl: 'https://api.podcastindex.org/api/1.0/',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
              headers: const <String, String>{'User-Agent': kAppUserAgent},
            ) {
    _dio.interceptors.add(_auth);
  }

  final Dio _dio;
  final PodcastIndexAuthInterceptor _auth;

  void setCredentials(String key, String secret) =>
      _auth.setCredentials(key, secret);

  void clearCredentials() => _auth.clearCredentials();

  bool get hasCredentials => _auth.hasCredentials;

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) =>
      _dio.get<dynamic>(path, queryParameters: queryParameters);

  PodcastIndexApiException handleDioException(
    DioException e,
    String defaultMessage,
  ) {
    final int? statusCode = e.response?.statusCode;
    String message = defaultMessage;
    if (statusCode == 401) {
      // Covers both a wrong key/secret and a skewed clock — the signature
      // embeds the timestamp and expires within minutes.
      message = 'Podcast Index rejected the request signature. '
          'Check the API key/secret and the system clock';
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      message = 'Connection timeout';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'No internet connection';
    }

    return PodcastIndexApiException(
      message,
      statusCode: statusCode,
      detail: buildApiErrorDetail(
        apiName: DataSource.podcastIndex.label,
        exception: e,
        userMessage: message,
      ),
    );
  }

  void dispose() => _dio.close();
}
