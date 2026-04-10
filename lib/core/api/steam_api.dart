// Steam Web API клиент для импорта библиотеки.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'api_error_detail.dart';

/// Провайдер для Steam API клиента.
final Provider<SteamApi> steamApiProvider = Provider<SteamApi>((Ref ref) {
  return SteamApi();
});

/// Ошибка Steam API.
class SteamApiException implements Exception {
  /// Создаёт [SteamApiException].
  const SteamApiException(this.message, {this.statusCode, this.detail});

  /// Сообщение об ошибке.
  final String message;

  /// HTTP код ответа (если есть).
  final int? statusCode;

  /// Подробная отладочная информация (URL, метод, причина).
  final String? detail;

  @override
  String toString() => 'SteamApiException($statusCode): $message';
}

/// Игра из библиотеки Steam (DTO, не кэшируется).
class SteamOwnedGame {
  /// Создаёт [SteamOwnedGame].
  const SteamOwnedGame({
    required this.appId,
    required this.name,
    this.playtimeMinutes = 0,
    this.lastPlayed,
  });

  /// Создаёт [SteamOwnedGame] из JSON ответа Steam API.
  factory SteamOwnedGame.fromJson(Map<String, dynamic> json) {
    final int rtimeLastPlayed = (json['rtime_last_played'] as int?) ?? 0;
    return SteamOwnedGame(
      appId: json['appid'] as int,
      name: json['name'] as String,
      playtimeMinutes: (json['playtime_forever'] as int?) ?? 0,
      lastPlayed: rtimeLastPlayed > 0
          ? DateTime.fromMillisecondsSinceEpoch(rtimeLastPlayed * 1000)
          : null,
    );
  }

  /// Steam App ID.
  final int appId;

  /// Название игры.
  final String name;

  /// Время в игре в минутах.
  final int playtimeMinutes;

  /// Дата последнего запуска.
  final DateTime? lastPlayed;

  /// Время в игре в часах.
  double get playtimeHours => playtimeMinutes / 60.0;

  /// Пропустить ли эту запись (DLC, саундтреки и т.п.).
  bool get shouldSkip {
    final String lower = name.toLowerCase();
    return lower.contains('soundtrack') ||
        lower.contains(' ost') ||
        lower.contains('demo') ||
        lower.contains('beta') ||
        lower.contains('test server') ||
        lower.contains('dedicated server') ||
        lower.contains('playtest');
  }
}

/// Клиент Steam Web API.
///
/// Минимальный клиент — только получение библиотеки пользователя.
class SteamApi {
  /// Создаёт [SteamApi].
  SteamApi({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: _timeout,
              receiveTimeout: _timeout,
            ));

  static final Logger _log = Logger('SteamApi');

  static const Duration _timeout = Duration(seconds: 5);

  final Dio _dio;

  /// Получить библиотеку пользователя.
  ///
  /// Требует публичный профиль Steam.
  /// Throws [SteamApiException] при ошибке запроса.
  Future<List<SteamOwnedGame>> getOwnedGames({
    required String apiKey,
    required String steamId,
  }) async {
    try {
      final Response<Map<String, dynamic>> response =
          await _dio.get<Map<String, dynamic>>(
        'https://api.steampowered.com/IPlayerService/GetOwnedGames/v1/',
        queryParameters: <String, dynamic>{
          'key': apiKey,
          'steamid': steamId,
          'include_appinfo': '1',
          'include_played_free_games': '1',
          'format': 'json',
        },
      );

      final Map<String, dynamic>? data =
          response.data?['response'] as Map<String, dynamic>?;
      if (data == null || data['games'] == null) {
        return <SteamOwnedGame>[];
      }

      final List<dynamic> games = data['games'] as List<dynamic>;
      _log.info('Fetched ${games.length} games from Steam library');
      return games
          .map((dynamic g) =>
              SteamOwnedGame.fromJson(g as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final int? statusCode = e.response?.statusCode;
      String message;
      if (statusCode == 401 || statusCode == 403) {
        message = 'Invalid API key';
      } else if (statusCode == 500) {
        message = 'Steam ID not found or profile is private';
      } else {
        message = e.message ?? 'Network error';
      }
      _log.warning('Steam API error: $message', e);
      throw SteamApiException(
        message,
        statusCode: statusCode,
        detail: buildApiErrorDetail(
          apiName: 'Steam',
          exception: e,
          userMessage: message,
        ),
      );
    }
  }
}
