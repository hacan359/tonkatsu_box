import 'package:core/models/data_source.dart';
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

import '../../services/app_http_overrides.dart';
import '../api_dio.dart';
import '../api_error_detail.dart';
import 'hardcover_types.dart';

/// Transport for the Hardcover GraphQL API (Hasura, single POST endpoint).
///
/// Auth is a personal Bearer token the user copies from
/// `hardcover.app/account/api` — without it the API rejects every request,
/// so [post] throws [HardcoverAuthException] when no token is set. Limits:
/// 60 requests/min (429 → [HardcoverRateLimitException]), 30 s per query.
class HardcoverGraphQLClient {
  HardcoverGraphQLClient({Dio? dio})
      : _dio = dio ??
            createApiDio(
              connectTimeout: _connectTimeout,
              receiveTimeout: _receiveTimeout,
              headers: const <String, String>{
                'User-Agent': AppHttpOverrides.userAgent,
              },
            );

  static const Duration _connectTimeout = Duration(seconds: 8);

  // Hardcover's own per-query timeout is 30 s.
  static const Duration _receiveTimeout = Duration(seconds: 30);
  static const String _endpoint = 'https://api.hardcover.app/v1/graphql';
  static final Logger _log = Logger('HardcoverApi');

  final Dio _dio;
  String? _token;

  void setToken(String token) => _token = token;

  void clearToken() => _token = null;

  bool get hasToken => _token != null && _token!.isNotEmpty;

  Future<Map<String, dynamic>> post({
    required String query,
    required Map<String, dynamic> variables,
    required String errorContext,
    String? tokenOverride,
  }) async {
    final String? token = tokenOverride ?? _token;
    if (token == null || token.isEmpty) {
      throw const HardcoverAuthException();
    }
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        _endpoint,
        data: <String, dynamic>{
          'query': query,
          'variables': variables,
        },
        options: Options(headers: <String, String>{
          'authorization': 'Bearer $token',
        }),
      );

      final Object? body = response.data;
      if (response.statusCode != 200 || body is! Map<String, dynamic>) {
        throw HardcoverApiException(
          errorContext,
          statusCode: response.statusCode,
        );
      }
      return body;
    } on DioException catch (e) {
      throw _mapDioException(e, errorContext);
    }
  }

  /// Returns the `data` field or throws with the first GraphQL error message
  /// (GraphQL errors arrive with HTTP 200).
  Map<String, dynamic> ensureData(
    Map<String, dynamic> body,
    String errorContext,
  ) {
    final Map<String, dynamic>? data = body['data'] as Map<String, dynamic>?;
    if (data != null) return data;

    final List<dynamic>? errors = body['errors'] as List<dynamic>?;
    String message = errorContext;
    if (errors != null && errors.isNotEmpty) {
      final Map<String, dynamic> first = errors.first as Map<String, dynamic>;
      final String raw = first['message'] as String? ?? '';
      if (raw.isNotEmpty) message = raw;
      _log.warning('Hardcover GraphQL error: $raw');
    }
    throw HardcoverApiException(message);
  }

  void dispose() => _dio.close();

  HardcoverApiException _mapDioException(
    DioException e,
    String defaultMessage,
  ) {
    final int? statusCode = e.response?.statusCode;
    String message = defaultMessage;

    if (statusCode == 401) {
      return HardcoverAuthException(
        detail: buildApiErrorDetail(
          apiName: DataSource.hardcover.label,
          exception: e,
          userMessage: 'Token rejected (401)',
        ),
      );
    } else if (statusCode == 429) {
      return HardcoverRateLimitException(
        detail: buildApiErrorDetail(
          apiName: DataSource.hardcover.label,
          exception: e,
          userMessage: 'Throttled (60 requests/min)',
        ),
      );
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      message = 'Connection timeout';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'No internet connection';
    }

    return HardcoverApiException(
      message,
      statusCode: statusCode,
      detail: buildApiErrorDetail(
        apiName: DataSource.hardcover.label,
        exception: e,
        userMessage: message,
      ),
    );
  }
}
