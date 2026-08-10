import 'package:core/models/data_source.dart';
import 'package:dio/dio.dart';

import '../api_dio.dart';
import '../api_error_detail.dart';
import 'tvdb_types.dart';

// TheTVDB v4 transport. Unlike every other client here the key is not sent per
// request: it is exchanged for a bearer token that lives a month.
// Docs: https://thetvdb.github.io/v4-api/
class TvdbHttpClient {
  TvdbHttpClient({Dio? dio})
      : _dio = dio ??
            createApiDio(
              baseUrl: 'https://api4.thetvdb.com/v4/',
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 20),
            );

  final Dio _dio;

  String? _apiKey;
  String? _token;
  Future<String>? _loginInFlight;

  bool get hasApiKey => _apiKey != null && _apiKey!.isNotEmpty;

  /// Drops the cached token — it was minted for the previous key.
  void setApiKey(String apiKey) {
    _apiKey = apiKey;
    _token = null;
    _loginInFlight = null;
  }

  void clearApiKey() {
    _apiKey = null;
    _token = null;
    _loginInFlight = null;
  }

  /// A successful login is the validation: the endpoint rejects a bad key.
  Future<bool> validateApiKey(String apiKey) async {
    try {
      await _login(apiKey);
      return true;
    } on Object {
      return false;
    }
  }

  Future<String> _login(String apiKey) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      'login',
      data: <String, dynamic>{'apikey': apiKey},
    );
    final Object? body = response.data;
    Object? token;
    if (body is Map<String, dynamic>) {
      final Object? data = body['data'];
      if (data is Map<String, dynamic>) token = data['token'];
    }
    if (token is! String || token.isEmpty) {
      throw const TvdbApiException('TheTVDB login returned no token');
    }
    return token;
  }

  /// GET with the bearer attached. A 401 means the month-old token expired, so
  /// re-login once and retry; a second 401 is a real failure.
  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final String? apiKey = _apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw const TvdbApiException('TheTVDB API key is not set');
    }

    _token ??= await _sharedLogin(apiKey);
    try {
      return await _send(path, queryParameters);
    } on DioException catch (e) {
      if (e.response?.statusCode != 401) rethrow;
      _token = await _login(apiKey);
      return _send(path, queryParameters);
    }
  }

  // Concurrent first requests (movies + series browse) must share one
  // /login round-trip — the endpoint is rate-limited.
  Future<String> _sharedLogin(String apiKey) {
    return _loginInFlight ??= _login(apiKey).whenComplete(() {
      _loginInFlight = null;
    });
  }

  Future<Response<dynamic>> _send(
    String path,
    Map<String, dynamic>? queryParameters,
  ) {
    return _dio.get<dynamic>(
      path,
      queryParameters: queryParameters,
      options: Options(
        headers: <String, String>{'Authorization': 'Bearer $_token'},
      ),
    );
  }

  /// `data` of a successful envelope, or null when the record is absent.
  Map<String, dynamic>? dataObject(Response<dynamic> response) {
    final Object? body = response.data;
    if (body is! Map<String, dynamic>) return null;
    final Object? data = body['data'];
    return data is Map<String, dynamic> ? data : null;
  }

  List<Map<String, dynamic>> dataList(Response<dynamic> response) {
    final Object? body = response.data;
    if (body is! Map<String, dynamic>) return const <Map<String, dynamic>>[];
    final Object? data = body['data'];
    if (data is! List<dynamic>) return const <Map<String, dynamic>>[];
    return <Map<String, dynamic>>[
      for (final dynamic item in data)
        if (item is Map<String, dynamic>) item,
    ];
  }

  TvdbApiException handleDioException(
    DioException e,
    String defaultMessage,
  ) {
    final int? statusCode = e.response?.statusCode;
    String message = defaultMessage;
    if (statusCode == 401) {
      message = 'TheTVDB rejected the API key';
    } else if (statusCode == 429) {
      message = 'Rate limit exceeded. Please try again later';
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      message = 'Connection timeout';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'No internet connection';
    }

    return TvdbApiException(
      message,
      statusCode: statusCode,
      detail: buildApiErrorDetail(
        apiName: DataSource.tvdb.label,
        exception: e,
        userMessage: message,
      ),
    );
  }

  void dispose() => _dio.close();
}
