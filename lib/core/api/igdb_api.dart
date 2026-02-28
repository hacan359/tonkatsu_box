import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/game.dart';
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
          data: 'fields id,name,abbreviation,platform_logo.image_id; limit $limit; offset $offset;',
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

  /// Загружает платформы по конкретным ID из IGDB.
  ///
  /// В отличие от [fetchPlatforms], загружает только указанные платформы.
  /// Throws [IgdbApiException] при ошибке запроса.
  Future<List<Platform>> fetchPlatformsByIds(List<int> ids) async {
    if (ids.isEmpty) return <Platform>[];
    _ensureCredentials();

    try {
      final String idList = ids.join(',');
      final Response<dynamic> response = await _dio.post<dynamic>(
        '$_igdbBaseUrl/platforms',
        options: Options(
          headers: <String, dynamic>{
            'Client-ID': _clientId,
            'Authorization': 'Bearer $_accessToken',
          },
        ),
        data:
            'fields id,name,abbreviation,platform_logo.image_id; where id = ($idList); limit 500;',
      );

      if (response.statusCode != 200 || response.data == null) {
        throw IgdbApiException(
          'Failed to fetch platforms by IDs',
          statusCode: response.statusCode,
        );
      }

      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((dynamic item) =>
              Platform.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final int? statusCode = e.response?.statusCode;
      String message = 'Failed to fetch platforms by IDs';

      if (statusCode == 401) {
        message = 'Invalid or expired access token';
      } else if (statusCode == 429) {
        message = 'Rate limit exceeded. Please try again later';
      }

      throw IgdbApiException(message, statusCode: statusCode);
    }
  }

  /// Поля игры для запросов к IGDB.
  static const String _gameFields = '''
    fields id, name, summary, rating, rating_count, first_release_date,
           cover.image_id, genres.name, platforms, url;
  ''';

  /// Ищет игры по названию.
  ///
  /// [query] — строка поиска.
  /// [platformIds] — опциональный фильтр по платформам (несколько).
  /// [limit] — максимальное количество результатов (по умолчанию 20).
  /// [offset] — смещение для пагинации (по умолчанию 0).
  ///
  /// Возвращает список найденных игр.
  /// Throws [IgdbApiException] при ошибке запроса.
  Future<List<Game>> searchGames({
    required String query,
    List<int>? platformIds,
    int limit = 20,
    int offset = 0,
  }) async {
    _ensureCredentials();

    if (query.trim().isEmpty) {
      return <Game>[];
    }

    try {
      // Экранируем кавычки в запросе
      final String escapedQuery = query.replaceAll('"', '\\"');

      // Формируем IGDB query в правильном порядке:
      // fields -> where -> search -> limit
      final StringBuffer body = StringBuffer(_gameFields);

      // Добавляем фильтр по платформам, если указаны
      if (platformIds != null && platformIds.isNotEmpty) {
        body.write(' where platforms = (${platformIds.join(",")});');
      }

      body.write(' search "$escapedQuery"; limit $limit;');
      if (offset > 0) {
        body.write(' offset $offset;');
      }

      final Response<dynamic> response = await _dio.post<dynamic>(
        '$_igdbBaseUrl/games',
        options: Options(
          headers: <String, dynamic>{
            'Client-ID': _clientId,
            'Authorization': 'Bearer $_accessToken',
          },
        ),
        data: body.toString(),
      );

      if (response.statusCode != 200 || response.data == null) {
        throw IgdbApiException(
          'Failed to search games',
          statusCode: response.statusCode,
        );
      }

      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((dynamic item) => Game.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to search games');
    }
  }

  /// Получает игру по ID.
  ///
  /// Возвращает игру или null, если не найдена.
  /// Throws [IgdbApiException] при ошибке запроса.
  Future<Game?> getGameById(int gameId) async {
    _ensureCredentials();

    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '$_igdbBaseUrl/games',
        options: Options(
          headers: <String, dynamic>{
            'Client-ID': _clientId,
            'Authorization': 'Bearer $_accessToken',
          },
        ),
        data: '$_gameFields where id = $gameId;',
      );

      if (response.statusCode != 200 || response.data == null) {
        throw IgdbApiException(
          'Failed to fetch game',
          statusCode: response.statusCode,
        );
      }

      final List<dynamic> data = response.data as List<dynamic>;
      if (data.isEmpty) return null;

      return Game.fromJson(data.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to fetch game');
    }
  }

  /// Получает несколько игр по списку ID.
  ///
  /// [gameIds] — список ID игр для загрузки.
  ///
  /// Возвращает список найденных игр (может быть меньше запрошенного).
  /// Throws [IgdbApiException] при ошибке запроса.
  Future<List<Game>> getGamesByIds(List<int> gameIds) async {
    _ensureCredentials();

    if (gameIds.isEmpty) {
      return <Game>[];
    }

    try {
      // IGDB ограничивает запрос 500 записями
      final List<Game> allGames = <Game>[];

      for (int i = 0; i < gameIds.length; i += 500) {
        final List<int> batch = gameIds.sublist(
          i,
          i + 500 > gameIds.length ? gameIds.length : i + 500,
        );

        final String idsString = batch.join(',');

        final Response<dynamic> response = await _dio.post<dynamic>(
          '$_igdbBaseUrl/games',
          options: Options(
            headers: <String, dynamic>{
              'Client-ID': _clientId,
              'Authorization': 'Bearer $_accessToken',
            },
          ),
          data: '$_gameFields where id = ($idsString); limit 500;',
        );

        if (response.statusCode != 200 || response.data == null) {
          throw IgdbApiException(
            'Failed to fetch games',
            statusCode: response.statusCode,
          );
        }

        final List<dynamic> data = response.data as List<dynamic>;
        final List<Game> games = data
            .map((dynamic item) => Game.fromJson(item as Map<String, dynamic>))
            .toList();

        allGames.addAll(games);
      }

      return allGames;
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to fetch games');
    }
  }

  /// Получает топ игр по платформе, отсортированных по рейтингу.
  ///
  /// [platformId] — ID платформы IGDB (например, 19 = SNES).
  /// [minRatingCount] — минимальное количество оценок (по умолчанию 20).
  /// [limit] — максимальное количество результатов (по умолчанию 50).
  ///
  /// Возвращает список игр, отсортированных по рейтингу (убывание).
  /// Throws [IgdbApiException] при ошибке запроса.
  Future<List<Game>> getTopGamesByPlatform({
    required int platformId,
    int minRatingCount = 20,
    int limit = 50,
  }) async {
    _ensureCredentials();

    try {
      final StringBuffer body = StringBuffer(_gameFields);
      body.write(
        ' where platforms = ($platformId)'
        ' & rating_count >= $minRatingCount'
        ' & rating != null;',
      );
      body.write(' sort rating desc;');
      body.write(' limit $limit;');

      final Response<dynamic> response = await _dio.post<dynamic>(
        '$_igdbBaseUrl/games',
        options: Options(
          headers: <String, dynamic>{
            'Client-ID': _clientId,
            'Authorization': 'Bearer $_accessToken',
          },
        ),
        data: body.toString(),
      );

      if (response.statusCode != 200 || response.data == null) {
        throw IgdbApiException(
          'Failed to fetch top games',
          statusCode: response.statusCode,
        );
      }

      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((dynamic item) => Game.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to fetch top games');
    }
  }

  /// Загружает список жанров из IGDB.
  ///
  /// Возвращает список жанров (обычно ~20 записей).
  /// Throws [IgdbApiException] при ошибке запроса.
  Future<List<Map<String, dynamic>>> fetchGenres() async {
    _ensureCredentials();

    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '$_igdbBaseUrl/genres',
        options: Options(
          headers: <String, dynamic>{
            'Client-ID': _clientId,
            'Authorization': 'Bearer $_accessToken',
          },
        ),
        data: 'fields id,name; limit 50; sort name asc;',
      );

      if (response.statusCode != 200 || response.data == null) {
        throw IgdbApiException(
          'Failed to fetch genres',
          statusCode: response.statusCode,
        );
      }

      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((dynamic item) => item as Map<String, dynamic>)
          .toList();
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to fetch genres');
    }
  }

  /// Просматривает игры без текстового запроса (Browse mode).
  ///
  /// Фильтрует по жанру, платформе, году/декаде.
  /// [sortBy] — строка сортировки IGDB (например 'rating desc').
  /// [minRatingCount] — минимальное количество оценок.
  /// Throws [IgdbApiException] при ошибке запроса.
  Future<List<Game>> browseGames({
    int? genreId,
    int? platformId,
    int? year,
    (int, int)? decade,
    String sortBy = 'rating desc',
    int limit = 20,
    int offset = 0,
    int minRatingCount = 10,
  }) async {
    _ensureCredentials();

    try {
      final StringBuffer where =
          StringBuffer('where rating_count > $minRatingCount');

      if (genreId != null) {
        where.write(' & genres = ($genreId)');
      }
      if (platformId != null) {
        where.write(' & platforms = ($platformId)');
      }
      if (year != null) {
        final int start =
            DateTime(year).millisecondsSinceEpoch ~/ 1000;
        final int end =
            DateTime(year + 1).millisecondsSinceEpoch ~/ 1000;
        where.write(
          ' & first_release_date >= $start & first_release_date < $end',
        );
      } else if (decade != null) {
        final int start =
            DateTime(decade.$1).millisecondsSinceEpoch ~/ 1000;
        final int end =
            DateTime(decade.$2 + 1).millisecondsSinceEpoch ~/ 1000;
        where.write(
          ' & first_release_date >= $start & first_release_date < $end',
        );
      }

      final StringBuffer body = StringBuffer(_gameFields);
      body.write(' $where;');
      body.write(' sort $sortBy;');
      body.write(' limit $limit;');
      if (offset > 0) {
        body.write(' offset $offset;');
      }

      final Response<dynamic> response = await _dio.post<dynamic>(
        '$_igdbBaseUrl/games',
        options: Options(
          headers: <String, dynamic>{
            'Client-ID': _clientId,
            'Authorization': 'Bearer $_accessToken',
          },
        ),
        data: body.toString(),
      );

      if (response.statusCode != 200 || response.data == null) {
        throw IgdbApiException(
          'Failed to browse games',
          statusCode: response.statusCode,
        );
      }

      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((dynamic item) => Game.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to browse games');
    }
  }

  /// Обрабатывает DioException и возвращает IgdbApiException.
  IgdbApiException _handleDioException(DioException e, String defaultMessage) {
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

    return IgdbApiException(message, statusCode: statusCode);
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
