import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

import '../api_error_detail.dart';
import 'igdb_types.dart';

// Twitch OAuth + IGDB v4. Docs: https://api-docs.igdb.com/
class IgdbHttpClient {
  IgdbHttpClient({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: _timeout,
              receiveTimeout: _timeout,
            ));

  static final Logger _log = Logger('IgdbApi');

  static const Duration _timeout = Duration(seconds: 5);
  static const String _twitchAuthUrl = 'https://id.twitch.tv/oauth2/token';
  static const String _igdbBaseUrl = 'https://api.igdb.com/v4';

  final Dio _dio;

  String? _clientId;
  String? _clientSecret;
  String? _accessToken;

  /// Invoked on auto-refresh so callers can persist the new token.
  IgdbTokenRefreshedCallback? onTokenRefreshed;

  bool _isRefreshing = false;

  void setCredentials({
    required String clientId,
    required String accessToken,
    String? clientSecret,
  }) {
    _clientId = clientId;
    _clientSecret = clientSecret;
    _accessToken = accessToken;
  }

  void clearCredentials() {
    _clientId = null;
    _clientSecret = null;
    _accessToken = null;
  }

  Future<TwitchAuthResult> getAccessToken({
    required String clientId,
    required String clientSecret,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        _twitchAuthUrl,
        queryParameters: <String, dynamic>{
          'client_id': clientId,
          'client_secret': clientSecret,
          'grant_type': 'client_credentials',
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return TwitchAuthResult.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      throw IgdbApiException(
        'Failed to get access token',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      final int? statusCode = e.response?.statusCode;
      String message = 'Authentication failed';

      if (statusCode == 400 || statusCode == 401) {
        message = 'Invalid client ID or client secret';
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        message = 'Connection timeout';
      } else if (e.type == DioExceptionType.connectionError) {
        message = 'No internet connection';
      }

      throw IgdbApiException(
        message,
        statusCode: statusCode,
        detail: buildApiErrorDetail(
          apiName: 'IGDB Auth',
          exception: e,
          userMessage: message,
        ),
      );
    }
  }

  Future<bool> validateCredentials({
    required String clientId,
    required String clientSecret,
  }) async {
    try {
      await getAccessToken(clientId: clientId, clientSecret: clientSecret);
      return true;
    } on IgdbApiException {
      return false;
    }
  }

  // On 401, refresh the Twitch token once and retry the request.
  Future<Response<dynamic>> post(
    String endpoint, {
    required String data,
  }) async {
    try {
      return await _dio.post<dynamic>(
        '$_igdbBaseUrl$endpoint',
        options: Options(
          headers: <String, dynamic>{
            'Client-ID': _clientId,
            'Authorization': 'Bearer $_accessToken',
          },
        ),
        data: data,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 && await _tryRefreshToken()) {
        return _dio.post<dynamic>(
          '$_igdbBaseUrl$endpoint',
          options: Options(
            headers: <String, dynamic>{
              'Client-ID': _clientId,
              'Authorization': 'Bearer $_accessToken',
            },
          ),
          data: data,
        );
      }
      rethrow;
    }
  }

  // Maps Dio errors to user-facing messages; 401 = bad/expired token, 429 = rate limit.
  IgdbApiException handleDioException(DioException e, String defaultMessage) {
    final int? statusCode = e.response?.statusCode;
    String message = defaultMessage;

    if (statusCode == 401) {
      message = 'Invalid or expired access token';
    } else if (statusCode == 429) {
      message = 'Rate limit exceeded. Please try again later';
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      message = 'Connection timeout';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'No internet connection';
    }

    return IgdbApiException(
      message,
      statusCode: statusCode,
      detail: buildApiErrorDetail(
        apiName: 'IGDB',
        exception: e,
        userMessage: message,
      ),
    );
  }

  void ensureCredentials() {
    if (_clientId == null || _accessToken == null) {
      throw const IgdbApiException('API credentials not set');
    }
  }

  // Guarded by _isRefreshing to avoid concurrent refresh storms on parallel 401s.
  Future<bool> _tryRefreshToken() async {
    if (_isRefreshing) return false;
    if (_clientId == null || _clientSecret == null) return false;

    _isRefreshing = true;
    try {
      _log.info('Auto-refreshing IGDB token...');
      final TwitchAuthResult result = await getAccessToken(
        clientId: _clientId!,
        clientSecret: _clientSecret!,
      );
      _accessToken = result.accessToken;
      onTokenRefreshed?.call(result.accessToken, result.expiresAt);
      _log.info('IGDB token refreshed successfully');
      return true;
    } on IgdbApiException catch (e) {
      _log.warning('IGDB token refresh failed: $e');
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  void dispose() {
    _dio.close();
  }
}
