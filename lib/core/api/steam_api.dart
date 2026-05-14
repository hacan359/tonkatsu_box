import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'api_error_detail.dart';

final Provider<SteamApi> steamApiProvider = Provider<SteamApi>((Ref ref) {
  return SteamApi();
});

class SteamApiException implements Exception {
  const SteamApiException(this.message, {this.statusCode, this.detail});

  final String message;
  final int? statusCode;
  final String? detail;

  @override
  String toString() => 'SteamApiException($statusCode): $message';
}

/// Library entry returned by `GetOwnedGames`. Not persisted — Steam is
/// queried fresh on every import.
class SteamOwnedGame {
  const SteamOwnedGame({
    required this.appId,
    required this.name,
    this.playtimeMinutes = 0,
    this.lastPlayed,
  });

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

  final int appId;
  final String name;
  final int playtimeMinutes;
  final DateTime? lastPlayed;

  double get playtimeHours => playtimeMinutes / 60.0;

  /// Filters out non-game library entries (DLCs, soundtracks, demos, beta /
  /// playtest builds, dedicated servers) so they don't pollute the import.
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

class SteamApi {
  SteamApi({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: _timeout,
              receiveTimeout: _timeout,
            ));

  static final Logger _log = Logger('SteamApi');

  static const Duration _timeout = Duration(seconds: 5);

  final Dio _dio;

  /// Fetches the user's library. Requires a public Steam profile — a private
  /// profile surfaces as HTTP 500 from Steam, which we translate into a more
  /// specific error message.
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
