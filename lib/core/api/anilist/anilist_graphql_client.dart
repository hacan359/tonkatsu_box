import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

import '../../services/app_http_overrides.dart';
import '../api_error_detail.dart';
import 'anilist_types.dart';

class AniListGraphQLClient {
  AniListGraphQLClient({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: _timeout,
              receiveTimeout: _timeout,
              headers: <String, String>{'User-Agent': _userAgent},
            ));

  static const Duration _timeout = Duration(seconds: 5);
  static const String _endpoint = 'https://graphql.anilist.co';

  // AniList manually blocks anonymous default UAs when scrapers hide
  // behind them — "Dart/3.12 (dart:io)" is banned at the time of writing,
  // which 403s every Flutter app that does not identify itself.
  // AppHttpOverrides covers this app-wide; the explicit header here keeps
  // the API client safe even when constructed without the overrides
  // (tests, isolates).
  static const String _userAgent = AppHttpOverrides.userAgent;
  static final Logger _log = Logger('AniListApi');

  final Dio _dio;

  Future<Map<String, dynamic>> post({
    required String query,
    required Map<String, dynamic> variables,
    required String errorContext,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        _endpoint,
        data: <String, dynamic>{
          'query': query,
          'variables': variables,
        },
      );

      if (response.statusCode != 200 || response.data == null) {
        throw AniListApiException(
          errorContext,
          statusCode: response.statusCode,
        );
      }
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _mapDioException(e, errorContext);
    }
  }

  /// Returns the `data` field, or null when GraphQL errors are present.
  /// Errors are logged, not raised — callers decide whether to fail.
  Map<String, dynamic>? unwrapData(Map<String, dynamic> body) {
    final Map<String, dynamic>? data = body['data'] as Map<String, dynamic>?;
    if (data == null) {
      logErrors(body);
      return null;
    }
    return data;
  }

  void logErrors(Map<String, dynamic> body) {
    final List<dynamic>? errors = body['errors'] as List<dynamic>?;
    if (errors != null && errors.isNotEmpty) {
      final Map<String, dynamic> first = errors.first as Map<String, dynamic>;
      _log.warning(
        'AniList GraphQL error: ${first['message'] ?? 'Unknown'}',
      );
    }
  }

  void dispose() {
    _dio.close();
  }

  AniListApiException _mapDioException(
    DioException e,
    String defaultMessage,
  ) {
    final int? statusCode = e.response?.statusCode;
    String message = defaultMessage;

    if (statusCode == 429) {
      final Duration retryAfter = _parseRetryAfter(e.response?.headers.map);
      return AniListRateLimitException(
        retryAfter,
        detail: buildApiErrorDetail(
          apiName: 'AniList',
          exception: e,
          userMessage:
              'Rate limit exceeded (retry in ${retryAfter.inSeconds}s)',
        ),
      );
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      message = 'Connection timeout';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'No internet connection';
    }

    return AniListApiException(
      message,
      statusCode: statusCode,
      detail: buildApiErrorDetail(
        apiName: 'AniList',
        exception: e,
        userMessage: message,
      ),
    );
  }

  // Retry-After (seconds) → X-RateLimit-Reset (unix ts) → 60s.
  static Duration _parseRetryAfter(Map<String, List<String>>? headers) {
    if (headers == null) return const Duration(seconds: 60);

    final List<String>? retryAfter = headers['retry-after'];
    if (retryAfter != null && retryAfter.isNotEmpty) {
      final int? seconds = int.tryParse(retryAfter.first.trim());
      if (seconds != null && seconds > 0) {
        return Duration(seconds: seconds);
      }
    }

    final List<String>? reset = headers['x-ratelimit-reset'];
    if (reset != null && reset.isNotEmpty) {
      final int? ts = int.tryParse(reset.first.trim());
      if (ts != null) {
        final int nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final int diff = ts - nowSec;
        if (diff > 0) return Duration(seconds: diff);
      }
    }

    return const Duration(seconds: 60);
  }
}
