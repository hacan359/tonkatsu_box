import 'package:dio/dio.dart';

import '../api_dio.dart';
import '../api_error_detail.dart';
import 'simkl_types.dart';

/// Simkl transport (`https://api.simkl.com`).
///
/// Every request carries the app's `simkl-api-key` (the OAuth client id);
/// account requests additionally send the user's Bearer token obtained via
/// the PIN flow. The token may live only in memory — persisting it is the
/// user's opt-in choice on the import screen.
class SimklHttpClient {
  SimklHttpClient({required String clientId, Dio? dio})
      : _clientId = clientId,
        _dio = dio ??
            createApiDio(
              baseUrl: 'https://api.simkl.com/',
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
              headers: <String, String>{
                'Content-Type': 'application/json',
              },
            );

  final Dio _dio;
  String _clientId;

  String? _accessToken;

  String get clientId => _clientId;

  bool get hasClientId => _clientId.isNotEmpty;

  /// Replaces the client id (the user may bring their own key on the import
  /// screen, overriding the build-time default).
  // ignore: use_setters_to_change_properties
  void setClientId(String clientId) => _clientId = clientId;

  bool get hasAccessToken =>
      _accessToken != null && _accessToken!.isNotEmpty;

  // ignore: use_setters_to_change_properties
  void setAccessToken(String token) => _accessToken = token;

  void clearAccessToken() => _accessToken = null;

  /// GET returning a decoded JSON map.
  ///
  /// [authorized] adds the Bearer token; [tokenOverride] sends a specific
  /// token instead (used while the poll loop validates a fresh one).
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authorized = false,
    String? tokenOverride,
  }) async {
    final String? token = tokenOverride ?? (authorized ? _accessToken : null);
    if (authorized && (token == null || token.isEmpty)) {
      throw const SimklApiException('Simkl account is not connected');
    }
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        path,
        queryParameters: <String, dynamic>{
          'client_id': _clientId,
          ...?queryParameters,
        },
        options: Options(
          headers: <String, String>{
            'simkl-api-key': _clientId,
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
        ),
      );
      final Object? data = response.data;
      return data is Map<String, dynamic> ? data : <String, dynamic>{};
    } on DioException catch (e) {
      throw handleDioException(e, 'Simkl request failed');
    }
  }

  SimklApiException handleDioException(
    DioException e,
    String defaultMessage,
  ) {
    final int? statusCode = e.response?.statusCode;
    String message = defaultMessage;
    if (statusCode == 412) {
      // Simkl reports an invalid or over-quota client_id as 412, not 429.
      message = 'Simkl rejected the app key (client_id failed or rate '
          'limited). Please try again later';
    } else if (statusCode == 401 || statusCode == 403) {
      message = 'Simkl authorization failed. Reconnect the account';
    } else if (statusCode == 429) {
      message = 'Rate limit exceeded. Please try again later';
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      message = 'Connection timeout';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'No internet connection';
    }

    return SimklApiException(
      message,
      statusCode: statusCode,
      detail: buildApiErrorDetail(
        apiName: 'Simkl',
        exception: e,
        userMessage: message,
      ),
    );
  }

  void dispose() => _dio.close();
}
