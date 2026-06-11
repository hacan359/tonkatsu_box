import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../shared/models/ra_game_progress.dart';
import '../../shared/models/ra_user_profile.dart';
import '../../shared/models/tracker_achievement.dart';
import '../../shared/models/tracker_game_data.dart';
import '../../shared/models/tracker_profile.dart';
import '../api/ra_api.dart';
import '../database/dao/tracker_dao.dart';
import '../database/database_service.dart';
import 'ra_to_igdb_mapper.dart';

final Provider<TrackerSyncService> trackerSyncServiceProvider =
    Provider<TrackerSyncService>((Ref ref) {
  return TrackerSyncService(
    trackerDao: ref.watch(trackerDaoProvider),
    raApi: ref.watch(raApiProvider),
  );
});

class TrackerSyncProgress {
  const TrackerSyncProgress({
    required this.stage,
    required this.current,
    required this.total,
    this.currentName,
    this.added = 0,
    this.updated = 0,
    this.skipped = 0,
  });

  final String stage;

  final int current;

  final int total;

  final String? currentName;

  final int added;

  final int updated;

  /// Skipped because nothing changed.
  final int skipped;
}

class TrackerSyncResult {
  const TrackerSyncResult({
    required this.success,
    required this.totalGames,
    this.added = 0,
    this.updated = 0,
    this.skipped = 0,
    this.error,
  });

  final bool success;

  final int totalGames;

  final int added;

  final int updated;

  /// Skipped because nothing changed.
  final int skipped;

  /// Set only when `!success`.
  final String? error;
}

/// Three sync modes: quick sync updates `tracker_game_data` from RA
/// completion progress, achievements load lazily per game into
/// `tracker_achievements`, and the profile sync updates `tracker_profiles`.
class TrackerSyncService {
  TrackerSyncService({
    required TrackerDao trackerDao,
    required RaApi raApi,
  })  : _trackerDao = trackerDao,
        _raApi = raApi;

  static final Logger _log = Logger('TrackerSyncService');

  final TrackerDao _trackerDao;
  final RaApi _raApi;

  Future<TrackerProfile> syncRaProfile({
    int? linkedCollectionId,
  }) async {
    if (!_raApi.hasCredentials) {
      throw const RaApiException('RA credentials not set');
    }
    final String username = _raApi.username!;
    final RaUserProfile raProfile = await _raApi.getUserProfile(username);

    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final TrackerProfile? existing =
        await _trackerDao.getProfile(TrackerType.ra);

    int? memberSinceTimestamp;
    if (raProfile.memberSince.isNotEmpty) {
      final DateTime? parsed = DateTime.tryParse(raProfile.memberSince);
      if (parsed != null) {
        memberSinceTimestamp = parsed.millisecondsSinceEpoch ~/ 1000;
      }
    }

    final TrackerProfile profile = TrackerProfile(
      id: existing?.id ?? 0,
      trackerType: TrackerType.ra,
      userId: username,
      displayName: raProfile.user.isNotEmpty ? raProfile.user : username,
      avatarUrl: raProfile.userPicUrl,
      profileUrl:
          'https://retroachievements.org/user/$username',
      totalPoints: raProfile.totalPoints,
      totalGames: null, // filled in by quick sync
      totalAchievements: null,
      memberSince: memberSinceTimestamp,
      profileData: <String, dynamic>{
        'totalTruePoints': raProfile.totalTruePoints,
        'richPresenceMsg': raProfile.richPresenceMsg,
      },
      linkedCollectionId:
          linkedCollectionId ?? existing?.linkedCollectionId,
      lastSyncedAt: now,
      createdAt: existing?.createdAt ?? now,
    );

    return _trackerDao.upsertProfile(profile);
  }

  /// Skips games whose data did not change and never touches
  /// `tracker_achievements` (those load lazily per game). [igdbIdForRaGameId]
  /// maps RA GameID → IGDB ID for games not yet in `tracker_game_data`.
  Future<TrackerSyncResult> quickSyncRa({
    required Map<int, int> igdbIdForRaGameId,
    void Function(TrackerSyncProgress)? onProgress,
  }) async {
    try {
      final String username = _raApi.username!;

      onProgress?.call(const TrackerSyncProgress(
        stage: 'Fetching RA library...',
        current: 0,
        total: 0,
      ));

      // Fetch the library, existing data, and awards in parallel
      final (
        List<RaGameProgress> raGames,
        List<TrackerGameData> existingData,
        Map<int, DateTime> awardDates,
      ) = await (
        _raApi.getCompletedGames(username),
        _trackerDao.getAllGameData(TrackerType.ra),
        _raApi.getUserAwardDates(username),
      ).wait;

      // Drop non-game entries (Hubs, Events, Standalone)
      final List<RaGameProgress> realGames =
          raGames.where((RaGameProgress g) => g.isRealGame).toList();

      // Two RA games for the same IGDB title (PS2 + GameCube) have distinct
      // RA ids, so keying by RA id keeps each platform's row separate.
      final Map<String, TrackerGameData> existingByRaId =
          <String, TrackerGameData>{
        for (final TrackerGameData d in existingData)
          d.trackerGameId: d,
      };

      int added = 0;
      int updated = 0;
      int skipped = 0;
      final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final List<TrackerGameData> toUpsert = <TrackerGameData>[];

      for (int i = 0; i < realGames.length; i++) {
        final RaGameProgress raGame = realGames[i];
        final String raGameId = raGame.gameId.toString();

        onProgress?.call(TrackerSyncProgress(
          stage: 'Syncing',
          current: i + 1,
          total: realGames.length,
          currentName: raGame.title,
          added: added,
          updated: updated,
          skipped: skipped,
        ));

        final int? igdbId = igdbIdForRaGameId[raGame.gameId];
        if (igdbId == null) {
          // No mapping — skip (can't link to games.id)
          skipped++;
          continue;
        }

        final TrackerGameData? existing = existingByRaId[raGameId];

        final DateTime? awardDate = awardDates[raGame.gameId];
        final int? awardTimestamp = awardDate != null
            ? awardDate.millisecondsSinceEpoch ~/ 1000
            : null;

        final int? lastPlayedTimestamp = raGame.lastPlayedAt != null
            ? raGame.lastPlayedAt!.millisecondsSinceEpoch ~/ 1000
            : null;

        if (existing != null &&
            existing.achievementsEarned == raGame.numAwarded &&
            existing.awardKind == raGame.highestAwardKind) {
          skipped++;
          continue;
        }

        // Scope the row by the IGDB platform that matches RA's console so
        // PS2 progress and GameCube progress can coexist for the same IGDB
        // game.
        final int? platformId =
            RaToIgdbMapper.primaryIgdbPlatformId(raGame.consoleId);

        final TrackerGameData data = TrackerGameData(
          id: existing?.id ?? 0,
          trackerType: TrackerType.ra,
          gameId: igdbId,
          platformId: platformId,
          trackerGameId: raGameId,
          trackerGameTitle: raGame.title,
          achievementsEarned: raGame.numAwarded,
          achievementsTotal: raGame.maxPossible,
          achievementsEarnedHardcore: raGame.numAwardedHardcore,
          awardKind: raGame.highestAwardKind,
          awardDate: awardTimestamp,
          lastPlayedAt: lastPlayedTimestamp,
          lastSyncedAt: now,
        );

        toUpsert.add(data);

        if (existing != null) {
          updated++;
        } else {
          added++;
        }
      }

      await _trackerDao.upsertGameDataBatch(toUpsert);

      // Refresh the profile with aggregate stats
      final TrackerProfile? profile =
          await _trackerDao.getProfile(TrackerType.ra);
      if (profile != null) {
        int totalEarned = 0;
        for (final RaGameProgress g in realGames) {
          totalEarned += g.numAwarded;
        }
        await _trackerDao.upsertProfile(profile.copyWith(
          totalGames: realGames.length,
          totalAchievements: totalEarned,
          lastSyncedAt: now,
        ));
      }

      _log.info(
        'RA quick sync: $added added, $updated updated, $skipped skipped',
      );

      return TrackerSyncResult(
        success: true,
        totalGames: realGames.length,
        added: added,
        updated: updated,
        skipped: skipped,
      );
    } catch (e) {
      _log.severe('RA quick sync failed', e);
      return TrackerSyncResult(
        success: false,
        totalGames: 0,
        error: e.toString(),
      );
    }
  }

  /// Loads achievements for one RA game, caching them in
  /// `tracker_achievements`; called lazily when a game card is opened.
  Future<List<TrackerAchievement>> loadRaGameAchievements(
    int raGameId,
  ) async {
    final RaGameFullProgress result =
        await loadRaGameFullProgress(raGameId);
    return result.achievements;
  }

  /// Loads achievements plus game-level data (award, hardcore, lastPlayed).
  Future<RaGameFullProgress> loadRaGameFullProgress(
    int raGameId,
  ) async {
    if (!_raApi.hasCredentials) {
      return const RaGameFullProgress(
        achievements: <TrackerAchievement>[],
      );
    }
    final String username = _raApi.username!;
    final String raGameIdStr = raGameId.toString();

    final Map<String, dynamic> data =
        await _raApi.getGameInfoAndUserProgress(username, raGameId);

    final Map<String, dynamic> achievements =
        (data['Achievements'] as Map<String, dynamic>?) ??
            <String, dynamic>{};

    final List<TrackerAchievement> result = <TrackerAchievement>[];
    for (final MapEntry<String, dynamic> entry in achievements.entries) {
      final Map<String, dynamic> achJson =
          entry.value as Map<String, dynamic>;
      result.add(TrackerAchievement.fromRaJson(
        achJson,
        trackerGameId: raGameIdStr,
      ));
    }

    await _trackerDao.replaceAchievements(
      TrackerType.ra,
      raGameIdStr,
      result,
    );

    final int? hardcoreEarned = data['NumAwardedToUserHardcore'] as int?;
    final String? awardKind = data['HighestAwardKind'] as String?;
    final String? awardDateStr = data['HighestAwardDate'] as String?;
    int? awardTimestamp;
    if (awardDateStr != null) {
      final DateTime? dt = DateTime.tryParse(awardDateStr);
      if (dt != null) {
        awardTimestamp = dt.millisecondsSinceEpoch ~/ 1000;
      }
    }

    // The RA response has no direct first/last-played fields; derive them
    // from earned achievement timestamps.
    int? lastPlayedTimestamp;
    int? firstPlayedTimestamp;
    for (final TrackerAchievement ach in result) {
      if (ach.earned && ach.earnedAt != null) {
        if (lastPlayedTimestamp == null || ach.earnedAt! > lastPlayedTimestamp) {
          lastPlayedTimestamp = ach.earnedAt;
        }
        if (firstPlayedTimestamp == null || ach.earnedAt! < firstPlayedTimestamp) {
          firstPlayedTimestamp = ach.earnedAt;
        }
      }
    }

    return RaGameFullProgress(
      achievements: result,
      firstPlayedAt: firstPlayedTimestamp,
      hardcoreEarned: hardcoreEarned,
      awardKind: awardKind,
      awardDate: awardTimestamp,
      lastPlayedAt: lastPlayedTimestamp,
    );
  }

  /// Returns cached achievements, reloading from the API when the cache is
  /// older than [maxCacheAgeMinutes].
  Future<List<TrackerAchievement>> getOrLoadRaAchievements(
    int raGameId, {
    int maxCacheAgeMinutes = 5,
  }) async {
    final String raGameIdStr = raGameId.toString();

    final bool hasCached =
        await _trackerDao.hasAchievements(TrackerType.ra, raGameIdStr);
    if (hasCached) {
      final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final int maxAgeSeconds = maxCacheAgeMinutes * 60;

      // Freshness is tracked on tracker_game_data.last_synced_at, not on the
      // achievements themselves.
      final TrackerGameData? gameData =
          await _trackerDao.getGameData(TrackerType.ra, raGameId);
      final bool isFresh = gameData != null &&
          (now - gameData.lastSyncedAt) < maxAgeSeconds;

      if (isFresh) {
        final List<TrackerAchievement> cached =
            await _trackerDao.getAchievements(TrackerType.ra, raGameIdStr);
        if (cached.isNotEmpty) {
          return cached;
        }
      }
    }

    if (!_raApi.hasCredentials) return <TrackerAchievement>[];
    return loadRaGameAchievements(raGameId);
  }
}

/// Full RA game load result: achievements plus game-level data.
class RaGameFullProgress {
  const RaGameFullProgress({
    required this.achievements,
    this.hardcoreEarned,
    this.awardKind,
    this.awardDate,
    this.firstPlayedAt,
    this.lastPlayedAt,
  });

  final List<TrackerAchievement> achievements;

  /// Hardcore earned count.
  final int? hardcoreEarned;

  /// Award kind ('mastered-hardcore', 'beaten-softcore', etc).
  final String? awardKind;

  /// Timestamp the award was earned.
  final int? awardDate;

  /// Timestamp of the first earned achievement (started at).
  final int? firstPlayedAt;

  /// Timestamp of the latest activity.
  final int? lastPlayedAt;
}
