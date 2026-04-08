// RetroAchievements API клиент.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../shared/models/ra_game_progress.dart';
import '../../shared/models/ra_user_profile.dart';
import '../services/api_key_initializer.dart';

/// Провайдер для RA API клиента.
final Provider<RaApi> raApiProvider = Provider<RaApi>((Ref ref) {
  final RaApi api = RaApi();
  final ApiKeys keys = ref.read(apiKeysProvider);
  if (keys.raUsername != null && keys.raApiKey != null) {
    api.setCredentials(username: keys.raUsername!, apiKey: keys.raApiKey!);
  }
  return api;
});

/// Ошибка RetroAchievements API.
class RaApiException implements Exception {
  /// Создаёт [RaApiException].
  const RaApiException(this.message, {this.statusCode});

  /// Сообщение об ошибке.
  final String message;

  /// HTTP код ответа (если есть).
  final int? statusCode;

  @override
  String toString() => 'RaApiException($statusCode): $message';
}

/// Клиент для RetroAchievements API.
///
/// Публичный API, аутентификация через username + Web API key
/// в query-параметрах каждого запроса.
class RaApi {
  /// Создаёт [RaApi].
  RaApi({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  static const String _baseUrl = 'https://retroachievements.org/API';
  static final Logger _log = Logger('RaApi');

  String? _username;
  String? _apiKey;

  /// Текущий username (null если не задан).
  String? get username => _username;

  /// Устанавливает credentials.
  void setCredentials({required String username, required String apiKey}) {
    _username = username;
    _apiKey = apiKey;
  }

  /// Есть ли credentials.
  bool get hasCredentials =>
      _username != null &&
      _username!.isNotEmpty &&
      _apiKey != null &&
      _apiKey!.isNotEmpty;

  /// Проверяет credentials, загружая профиль.
  ///
  /// Возвращает `true` если credentials валидны.
  Future<bool> validateCredentials(
    String username,
    String apiKey,
  ) async {
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

  /// Загружает профиль пользователя.
  Future<RaUserProfile> getUserProfile(String targetUser) async {
    _ensureCredentials();
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '$_baseUrl/API_GetUserProfile.php',
        queryParameters: <String, String>{
          ..._authParams(),
          'u': targetUser,
        },
      );
      return RaUserProfile.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e, 'getUserProfile');
    }
  }

  /// Загружает список всех играных игр с прогрессом.
  ///
  /// Использует `API_GetUserCompletionProgress` с пагинацией (500 за запрос).
  /// Возвращает полный список без дублей.
  Future<List<RaGameProgress>> getCompletedGames(String targetUser) async {
    _ensureCredentials();
    final List<RaGameProgress> allGames = <RaGameProgress>[];
    int offset = 0;
    const int pageSize = 500;

    try {
      while (true) {
        final Response<dynamic> response = await _dio.get<dynamic>(
          '$_baseUrl/API_GetUserCompletionProgress.php',
          queryParameters: <String, String>{
            ..._authParams(),
            'u': targetUser,
            'c': pageSize.toString(),
            'o': offset.toString(),
          },
        );
        final Map<String, dynamic> data =
            response.data as Map<String, dynamic>;
        final List<dynamic> results = data['Results'] as List<dynamic>;
        final int total = data['Total'] as int? ?? 0;

        for (final dynamic item in results) {
          allGames
              .add(RaGameProgress.fromJson(item as Map<String, dynamic>));
        }

        offset += results.length;
        if (offset >= total || results.isEmpty) break;

        // Rate limit: 1 запрос/сек.
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    } on DioException catch (e) {
      throw _handleError(e, 'getCompletedGames');
    }

    return allGames;
  }

  /// Загружает награды пользователя (beaten/mastered даты).
  ///
  /// Возвращает Map (GameID → AwardedAt) для быстрого lookup.
  Future<Map<int, DateTime>> getUserAwardDates(String targetUser) async {
    _ensureCredentials();
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '$_baseUrl/API_GetUserAwards.php',
        queryParameters: <String, String>{
          ..._authParams(),
          'u': targetUser,
        },
      );
      final Map<String, dynamic> data =
          response.data as Map<String, dynamic>;
      final List<dynamic> awards =
          data['VisibleUserAwards'] as List<dynamic>? ?? <dynamic>[];

      final Map<int, DateTime> result = <int, DateTime>{};
      for (final dynamic award in awards) {
        final Map<String, dynamic> a = award as Map<String, dynamic>;
        final String? awardType = a['AwardType'] as String?;
        // Только game awards (beaten/mastered), не site awards.
        if (awardType == null ||
            (!awardType.contains('Beaten') &&
                !awardType.contains('Mastery'))) {
          continue;
        }
        final int? gameId = a['AwardData'] as int?;
        final String? awardedAt = a['AwardedAt'] as String?;
        if (gameId != null && awardedAt != null) {
          final DateTime? date = DateTime.tryParse(awardedAt);
          if (date != null) {
            // Если игра уже есть — оставляем более позднюю дату.
            final DateTime? existing = result[gameId];
            if (existing == null || date.isAfter(existing)) {
              result[gameId] = date;
            }
          }
        }
      }
      return result;
    } on DioException catch (e) {
      _log.warning('getUserAwardDates failed: $e');
      // Не критично — возвращаем пустой map.
      return <int, DateTime>{};
    }
  }

  /// Загружает детали достижений для конкретной игры.
  ///
  /// Возвращает Map всех достижений (earned + locked) с датами разблокировки.
  /// Используется для lazy-загрузки при открытии карточки игры.
  Future<Map<String, dynamic>> getGameInfoAndUserProgress(
    String targetUser,
    int raGameId,
  ) async {
    _ensureCredentials();
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '$_baseUrl/API_GetGameInfoAndUserProgress.php',
        queryParameters: <String, String>{
          ..._authParams(),
          'u': targetUser,
          'g': raGameId.toString(),
          'a': '1',
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e, 'getGameInfoAndUserProgress');
    }
  }

  /// Загружает список всех игр для консоли.
  ///
  /// Возвращает список с ID, Title, NumAchievements, ImageIcon.
  /// Кэшируется на стороне вызывающего.
  Future<List<RaGameListEntry>> getGameList(int consoleId) async {
    _ensureCredentials();
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '$_baseUrl/API_GetGameList.php',
        queryParameters: <String, String>{
          ..._authParams(),
          'i': consoleId.toString(),
        },
      );
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((dynamic item) =>
              RaGameListEntry.fromJson(item as Map<String, dynamic>))
          .where((RaGameListEntry g) => g.numAchievements > 0)
          .toList();
    } on DioException catch (e) {
      throw _handleError(e, 'getGameList');
    }
  }

  Map<String, String> _authParams() => <String, String>{
        'z': _username!,
        'y': _apiKey!,
      };

  void _ensureCredentials() {
    if (!hasCredentials) {
      throw const RaApiException('RA credentials not set');
    }
  }

  RaApiException _handleError(DioException e, String method) {
    final int? statusCode = e.response?.statusCode;
    final String message = e.message ?? 'Unknown error';
    _log.warning('$method failed ($statusCode): $message');
    return RaApiException(message, statusCode: statusCode);
  }
}

/// Запись из списка игр консоли RA.
class RaGameListEntry {
  /// Создаёт [RaGameListEntry].
  const RaGameListEntry({
    required this.id,
    required this.title,
    required this.consoleId,
    required this.numAchievements,
    this.consoleName,
    this.imageIcon,
    this.points,
  });

  /// Создаёт из JSON ответа API.
  factory RaGameListEntry.fromJson(Map<String, dynamic> json) {
    return RaGameListEntry(
      id: json['ID'] as int,
      title: json['Title'] as String,
      consoleId: json['ConsoleID'] as int,
      consoleName: json['ConsoleName'] as String?,
      imageIcon: json['ImageIcon'] as String?,
      numAchievements: json['NumAchievements'] as int? ?? 0,
      points: json['Points'] as int? ?? 0,
    );
  }

  /// RA Game ID.
  final int id;

  /// Название игры.
  final String title;

  /// RA Console ID.
  final int consoleId;

  /// Название консоли.
  final String? consoleName;

  /// Путь к иконке (относительный).
  final String? imageIcon;

  /// Количество достижений.
  final int numAchievements;

  /// Очки.
  final int? points;

  /// Полный URL иконки.
  String? get imageUrl => imageIcon != null
      ? 'https://media.retroachievements.org$imageIcon'
      : null;
}
