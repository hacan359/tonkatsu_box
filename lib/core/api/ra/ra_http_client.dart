import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

import '../api_dio.dart';
import '../api_error_detail.dart';
import 'ra_types.dart';

// RetroAchievements API transport. Auth is `(username, web API key)` passed as
// `z` + `y` query params on every request.
class RaHttpClient {
  RaHttpClient({Dio? dio})
      : _dio = dio ??
            createApiDio(
              connectTimeout: _timeout,
              receiveTimeout: _timeout,
            );

  final Dio _dio;
  static const Duration _timeout = Duration(seconds: 5);
  static const String _baseUrl = 'https://retroachievements.org/API';
  static final Logger _log = Logger('RaApi');

  String? _username;
  String? _apiKey;

  String? get username => _username;

  void setCredentials({required String username, required String apiKey}) {
    _username = username;
    _apiKey = apiKey;
  }

  bool get hasCredentials =>
      _username != null &&
      _username!.isNotEmpty &&
      _apiKey != null &&
      _apiKey!.isNotEmpty;

  Future<bool> validateCredentials(String username, String apiKey) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '$_baseUrl/API_GetUserProfile.php',
        queryParameters: <String, String>{
          'z': username,
          'y': apiKey,
          'u': username,
        },
      );
      if (response.data == null) return false;
      final Map<String, dynamic> data = response.data as Map<String, dynamic>;
      return data.containsKey('User') && data['User'] != null;
    } on DioException catch (e) {
      _log.warning('validateCredentials failed: $e');
      return false;
    }
  }

  /// GET against [path] (relative to the base URL). The `z`/`y` credentials are
  /// injected automatically.
  Future<Response<dynamic>> get(
    String path, {
    Map<String, String>? queryParameters,
  }) {
    return _dio.get<dynamic>(
      '$_baseUrl$path',
      queryParameters: <String, String>{
        'z': _username!,
        'y': _apiKey!,
        ...?queryParameters,
      },
    );
  }

  void ensureCredentials() {
    if (!hasCredentials) {
      throw const RaApiException('RA credentials not set');
    }
  }

  RaApiException handleError(DioException e, String method) {
    final int? statusCode = e.response?.statusCode;
    final String message = e.message ?? 'Unknown error';
    _log.warning('$method failed ($statusCode): $message');
    return RaApiException(
      message,
      statusCode: statusCode,
      detail: buildApiErrorDetail(
        apiName: 'RetroAchievements',
        exception: e,
        userMessage: message,
      ),
    );
  }

  void dispose() {
    _dio.close();
  }
}
