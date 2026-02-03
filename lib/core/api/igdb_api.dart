import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/platform.dart';

/// Провайдер для IGDB API клиента.
final Provider<IgdbApi> igdbApiProvider = Provider<IgdbApi>((Ref ref) {
  return IgdbApi();
});

/// Результат аутентификации в Twitch OAuth.
class TwitchAuthResult {
  /// Создаёт экземпляр [TwitchAuthResult].
  const TwitchAuthResult({
    required this.accessToken,
    required this.expiresIn,
    required this.tokenType,
  });

  /// Создаёт [TwitchAuthResult] из JSON.
  factory TwitchAuthResult.fromJson(Map<String, dynamic> json) {
    return TwitchAuthResult(
      accessToken: json['access_token'] as String,
      expiresIn: json['expires_in'] as int,
      tokenType: json['token_type'] as String,
    );
  }

  /// OAuth access token.
  final String accessToken;

  /// Время жизни токена в секундах.
  final int expiresIn;

  /// Тип токена (обычно "bearer").
  final String tokenType;

  /// Время истечения токена (Unix timestamp).
  int get expiresAt {
    return DateTime.now().millisecondsSinceEpoch ~/ 1000 + expiresIn;
  }
}

/// Исключение при ошибках IGDB API.
class IgdbApiException implements Exception {
  /// Создаёт [IgdbApiException].
  const IgdbApiException(this.message, {this.statusCode});

  /// Сообщение об ошибке.
  final String message;

  /// HTTP код ответа (если есть).
  final int? statusCode;

  @override
  String toString() => 'IgdbApiException: $message (status: $statusCode)';
}

/// Клиент для работы с IGDB API.
///
/// Использует Twitch OAuth для аутентификации.
/// Документация: https://api-docs.igdb.com/
class IgdbApi {
  /// Создаёт экземпляр [IgdbApi].
  IgdbApi({Dio? dio}) : _dio = dio ?? Dio();

  static const String _twitchAuthUrl = 'https://id.twitch.tv/oauth2/token';
  static const String _igdbBaseUrl = 'https://api.igdb.com/v4';

  final Dio _dio;

  String? _clientId;
  String? _accessToken;

  /// Устанавливает учётные данные для API.
  void setCredentials({
    required String clientId,
    required String accessToken,
  }) {
    _clientId = clientId;
    _accessToken = accessToken;
  }

  /// Очищает учётные данные.
  void clearCredentials() {
    _clientId = null;
    _accessToken = null;
  }

  /// Получает OAuth токен от Twitch.
  ///
  /// Throws [IgdbApiException] при ошибке аутентификации.
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

      throw IgdbApiException(message, statusCode: statusCode);
    }
  }

  /// Проверяет валидность учётных данных.
  ///
  /// Возвращает true, если учётные данные корректны.
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

  /// Загружает список всех платформ из IGDB.
  ///
  /// Возвращает список платформ (обычно ~200 записей).
  /// Throws [IgdbApiException] при ошибке запроса.
  Future<List<Platform>> fetchPlatforms() async {
    _ensureCredentials();

    try {
      final List<Platform> allPlatforms = <Platform>[];
      int offset = 0;
      const int limit = 500;

      while (true) {
        final Response<dynamic> response = await _dio.post<dynamic>(
          '$_igdbBaseUrl/platforms',
          options: Options(
            headers: <String, dynamic>{
              'Client-ID': _clientId,
              'Authorization': 'Bearer $_accessToken',
            },
          ),
          data: 'fields id,name,abbreviation; limit $limit; offset $offset;',
        );

        if (response.statusCode != 200 || response.data == null) {
          throw IgdbApiException(
            'Failed to fetch platforms',
            statusCode: response.statusCode,
          );
        }

        final List<dynamic> data = response.data as List<dynamic>;
        if (data.isEmpty) break;

        final List<Platform> platforms = data
            .map((dynamic item) =>
                Platform.fromJson(item as Map<String, dynamic>))
            .toList();

        allPlatforms.addAll(platforms);

        if (data.length < limit) break;
        offset += limit;
      }

      return allPlatforms;
    } on DioException catch (e) {
      final int? statusCode = e.response?.statusCode;
      String message = 'Failed to fetch platforms';

      if (statusCode == 401) {
        message = 'Invalid or expired access token';
      } else if (statusCode == 429) {
        message = 'Rate limit exceeded. Please try again later';
      }

      throw IgdbApiException(message, statusCode: statusCode);
    }
  }

  void _ensureCredentials() {
    if (_clientId == null || _accessToken == null) {
      throw const IgdbApiException('API credentials not set');
    }
  }

  /// Закрывает HTTP клиент.
  void dispose() {
    _dio.close();
  }
}
