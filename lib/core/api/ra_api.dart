import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../shared/models/ra_game_progress.dart';
import '../../shared/models/ra_user_profile.dart';
import '../services/api_key_initializer.dart';
import 'api_error_detail.dart';

final Provider<RaApi> raApiProvider = Provider<RaApi>((Ref ref) {
  final RaApi api = RaApi();
  final ApiKeys keys = ref.read(apiKeysProvider);
  if (keys.raUsername != null && keys.raApiKey != null) {
    api.setCredentials(username: keys.raUsername!, apiKey: keys.raApiKey!);
  }
  return api;
});

class RaApiException implements Exception {
  const RaApiException(this.message, {this.statusCode, this.detail});

  final String message;
  final int? statusCode;
  final String? detail;

  @override
  String toString() => 'RaApiException($statusCode): $message';
}

/// RetroAchievements API client. Auth is `(username, web API key)` passed as
/// `z` + `y` query params on every request.
class RaApi {
  RaApi({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: _timeout,
              receiveTimeout: _timeout,
            ));

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

  /// Pages through `API_GetUserCompletionProgress` (500 entries per page)
  /// with a 1s gap between pages — RA's documented rate limit is 1 req/s.
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

        await Future<void>.delayed(const Duration(seconds: 1));
      }
    } on DioException catch (e) {
      throw _handleError(e, 'getCompletedGames');
    }

    return allGames;
  }

  /// Returns `gameId → most-recent awarded-at`. Skips site awards (only
  /// beaten/mastered counted). On failure returns an empty map — awards are
  /// nice-to-have, not a blocker.
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
      return <int, DateTime>{};
    }
  }

  /// Lightweight summary call (`a=0`): metadata + counters, no Achievements
  /// array. Use when opening the game card before user expands the list.
  Future<Map<String, dynamic>> getGameSummary(
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
          'a': '0',
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e, 'getGameSummary');
    }
  }

  /// Full call (`a=1`): same shape as the summary plus the full Achievements
  /// map with unlock timestamps. Lazy-fetched when the user expands the card.
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
}

class RaGameListEntry {
  const RaGameListEntry({
    required this.id,
    required this.title,
    required this.consoleId,
    required this.numAchievements,
    this.consoleName,
    this.imageIcon,
    this.points,
  });

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

  final int id;
  final String title;
  final int consoleId;
  final String? consoleName;
  final String? imageIcon;
  final int numAchievements;
  final int? points;

  String? get imageUrl => imageIcon != null
      ? 'https://media.retroachievements.org$imageIcon'
      : null;
}
