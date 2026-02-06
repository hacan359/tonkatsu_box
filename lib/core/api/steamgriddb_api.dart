// API клиент для SteamGridDB.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/steamgriddb_game.dart';
import '../../shared/models/steamgriddb_image.dart';

/// Провайдер для SteamGridDB API клиента.
final Provider<SteamGridDbApi> steamGridDbApiProvider =
    Provider<SteamGridDbApi>((Ref ref) {
  return SteamGridDbApi();
});

/// Исключение при ошибках SteamGridDB API.
class SteamGridDbApiException implements Exception {
  /// Создаёт [SteamGridDbApiException].
  const SteamGridDbApiException(this.message, {this.statusCode});

  /// Сообщение об ошибке.
  final String message;

  /// HTTP код ответа (если есть).
  final int? statusCode;

  @override
  String toString() =>
      'SteamGridDbApiException: $message (status: $statusCode)';
}

/// Клиент для работы с SteamGridDB API v2.
///
/// Использует Bearer token для аутентификации.
/// Документация: https://www.steamgriddb.com/api/v2
class SteamGridDbApi {
  /// Создаёт экземпляр [SteamGridDbApi].
  SteamGridDbApi({Dio? dio}) : _dio = dio ?? Dio();

  static const String _baseUrl = 'https://www.steamgriddb.com/api/v2';

  final Dio _dio;

  String? _apiKey;

  /// Устанавливает API ключ для аутентификации.
  void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  /// Очищает API ключ.
  void clearApiKey() {
    _apiKey = null;
  }

  /// Ищет игры по названию.
  ///
  /// [term] — строка поиска.
  ///
  /// Возвращает список найденных игр.
  /// Throws [SteamGridDbApiException] при ошибке запроса.
  Future<List<SteamGridDbGame>> searchGames(String term) async {
    _ensureApiKey();

    if (term.trim().isEmpty) {
      return <SteamGridDbGame>[];
    }

    try {
      final String encodedTerm = Uri.encodeComponent(term.trim());
      final Response<dynamic> response = await _dio.get<dynamic>(
        '$_baseUrl/search/autocomplete/$encodedTerm',
        options: _authOptions(),
      );

      if (response.statusCode != 200 || response.data == null) {
        throw SteamGridDbApiException(
          'Failed to search games',
          statusCode: response.statusCode,
        );
      }

      final Map<String, dynamic> body =
          response.data as Map<String, dynamic>;
      final List<dynamic> data = body['data'] as List<dynamic>;

      return data
          .map((dynamic item) =>
              SteamGridDbGame.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to search games');
    }
  }

  /// Получает grid-изображения (box art) для игры.
  ///
  /// [gameId] — ID игры в SteamGridDB.
  Future<List<SteamGridDbImage>> getGrids(int gameId) async {
    return _fetchImages('grids/game', gameId);
  }

  /// Получает hero-изображения (баннеры) для игры.
  ///
  /// [gameId] — ID игры в SteamGridDB.
  Future<List<SteamGridDbImage>> getHeroes(int gameId) async {
    return _fetchImages('heroes/game', gameId);
  }

  /// Получает logo-изображения для игры.
  ///
  /// [gameId] — ID игры в SteamGridDB.
  Future<List<SteamGridDbImage>> getLogos(int gameId) async {
    return _fetchImages('logos/game', gameId);
  }

  /// Получает icon-изображения для игры.
  ///
  /// [gameId] — ID игры в SteamGridDB.
  Future<List<SteamGridDbImage>> getIcons(int gameId) async {
    return _fetchImages('icons/game', gameId);
  }

  /// Общий метод загрузки изображений.
  Future<List<SteamGridDbImage>> _fetchImages(
    String endpoint,
    int gameId,
  ) async {
    _ensureApiKey();

    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '$_baseUrl/$endpoint/$gameId',
        options: _authOptions(),
      );

      if (response.statusCode != 200 || response.data == null) {
        throw SteamGridDbApiException(
          'Failed to fetch images',
          statusCode: response.statusCode,
        );
      }

      final Map<String, dynamic> body =
          response.data as Map<String, dynamic>;
      final List<dynamic> data = body['data'] as List<dynamic>;

      return data
          .map((dynamic item) =>
              SteamGridDbImage.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to fetch images');
    }
  }

  /// Создаёт Options с заголовком авторизации.
  Options _authOptions() {
    return Options(
      headers: <String, dynamic>{
        'Authorization': 'Bearer $_apiKey',
      },
    );
  }

  /// Обрабатывает DioException и возвращает SteamGridDbApiException.
  SteamGridDbApiException _handleDioException(
    DioException e,
    String defaultMessage,
  ) {
    final int? statusCode = e.response?.statusCode;
    String message = defaultMessage;

    if (statusCode == 401) {
      message = 'Invalid or expired API key';
    } else if (statusCode == 404) {
      message = 'Game not found';
    } else if (statusCode == 429) {
      message = 'Rate limit exceeded. Please try again later';
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      message = 'Connection timeout';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'No internet connection';
    }

    return SteamGridDbApiException(message, statusCode: statusCode);
  }

  void _ensureApiKey() {
    if (_apiKey == null) {
      throw const SteamGridDbApiException('API key not set');
    }
  }

  /// Закрывает HTTP клиент.
  void dispose() {
    _dio.close();
  }
}
