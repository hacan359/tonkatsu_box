import 'package:core/models/ra_game_progress.dart';
import 'package:core/models/ra_user_profile.dart';
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

import 'ra_http_client.dart';

/// User-scoped RetroAchievements calls: profile, completion progress, awards.
class RaUserApi {
  RaUserApi(this._client);

  final RaHttpClient _client;
  static final Logger _log = Logger('RaApi');

  Future<RaUserProfile> getUserProfile(String targetUser) async {
    _client.ensureCredentials();
    try {
      final Response<dynamic> response = await _client.get(
        '/API_GetUserProfile.php',
        queryParameters: <String, String>{'u': targetUser},
      );
      return RaUserProfile.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _client.handleError(e, 'getUserProfile');
    }
  }

  /// Pages through `API_GetUserCompletionProgress` (500 entries per page)
  /// with a 1s gap between pages — RA's documented rate limit is 1 req/s.
  Future<List<RaGameProgress>> getCompletedGames(String targetUser) async {
    _client.ensureCredentials();
    final List<RaGameProgress> allGames = <RaGameProgress>[];
    int offset = 0;
    const int pageSize = 500;

    try {
      while (true) {
        final Response<dynamic> response = await _client.get(
          '/API_GetUserCompletionProgress.php',
          queryParameters: <String, String>{
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
      throw _client.handleError(e, 'getCompletedGames');
    }

    return allGames;
  }

  /// Returns `gameId → most-recent awarded-at`. Skips site awards (only
  /// beaten/mastered counted). On failure returns an empty map — awards are
  /// nice-to-have, not a blocker.
  Future<Map<int, DateTime>> getUserAwardDates(String targetUser) async {
    _client.ensureCredentials();
    try {
      final Response<dynamic> response = await _client.get(
        '/API_GetUserAwards.php',
        queryParameters: <String, String>{'u': targetUser},
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
}
