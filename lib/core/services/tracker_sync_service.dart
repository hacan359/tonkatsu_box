// Сервис синхронизации данных трекеров (RA, Steam).

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

/// Провайдер для [TrackerSyncService].
final Provider<TrackerSyncService> trackerSyncServiceProvider =
    Provider<TrackerSyncService>((Ref ref) {
  return TrackerSyncService(
    trackerDao: ref.watch(trackerDaoProvider),
    raApi: ref.watch(raApiProvider),
  );
});

/// Прогресс sync операции.
class TrackerSyncProgress {
  /// Создаёт [TrackerSyncProgress].
  const TrackerSyncProgress({
    required this.stage,
    required this.current,
    required this.total,
    this.currentName,
    this.added = 0,
    this.updated = 0,
    this.skipped = 0,
  });

  /// Стадия sync.
  final String stage;

  /// Текущий элемент.
  final int current;

  /// Всего элементов.
  final int total;

  /// Название текущего элемента.
  final String? currentName;

  /// Добавлено новых.
  final int added;

  /// Обновлено существующих.
  final int updated;

  /// Пропущено (без изменений).
  final int skipped;
}

/// Результат sync операции.
class TrackerSyncResult {
  /// Создаёт [TrackerSyncResult].
  const TrackerSyncResult({
    required this.success,
    required this.totalGames,
    this.added = 0,
    this.updated = 0,
    this.skipped = 0,
    this.error,
  });

  /// Успешность.
  final bool success;

  /// Всего игр обработано.
  final int totalGames;

  /// Добавлено новых.
  final int added;

  /// Обновлено.
  final int updated;

  /// Пропущено (без изменений).
  final int skipped;

  /// Ошибка (если !success).
  final String? error;
}

/// Сервис синхронизации данных трекеров.
///
/// Поддерживает:
/// - **Быстрый sync** — обновляет `tracker_game_data` из RA completion progress
/// - **Lazy per-game** — загружает `tracker_achievements` для конкретной игры
/// - **Профиль** — обновляет `tracker_profiles`
class TrackerSyncService {
  /// Создаёт [TrackerSyncService].
  TrackerSyncService({
    required TrackerDao trackerDao,
    required RaApi raApi,
  })  : _trackerDao = trackerDao,
        _raApi = raApi;

  static final Logger _log = Logger('TrackerSyncService');

  final TrackerDao _trackerDao;
  final RaApi _raApi;

  // ==================== RA Profile ====================

  /// Синхронизирует профиль RA и сохраняет в `tracker_profiles`.
  Future<TrackerProfile> syncRaProfile({
    int? linkedCollectionId,
  }) async {
    if (!_raApi.hasCredentials) {
      throw const RaApiException('RA credentials not set');
    }
    final String username = _raApi.username!;
    final RaUserProfile raProfile = await _raApi.getUserProfile(username);

    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Проверяем существующий профиль.
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
      totalGames: null, // заполняется при sync
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

  // ==================== RA Quick Sync ====================

  /// Быстрый sync RA: обновляет `tracker_game_data` из completion progress.
  ///
  /// Пропускает игры, где данные не изменились.
  /// Не трогает `tracker_achievements` (lazy load per-game).
  ///
  /// [igdbIdForRaGameId] — маппинг RA GameID → IGDB ID
  /// для новых игр, которых ещё нет в `tracker_game_data`.
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

      // 1. Параллельно: fetch библиотеки, существующие данные, awards.
      final (
        List<RaGameProgress> raGames,
        List<TrackerGameData> existingData,
        Map<int, DateTime> awardDates,
      ) = await (
        _raApi.getCompletedGames(username),
        _trackerDao.getAllGameData(TrackerType.ra),
        _raApi.getUserAwardDates(username),
      ).wait;

      // Фильтруем не-игры (Hubs, Events, Standalone).
      final List<RaGameProgress> realGames =
          raGames.where((RaGameProgress g) => g.isRealGame).toList();

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

        // Ищем IGDB ID.
        final int? igdbId = igdbIdForRaGameId[raGame.gameId];
        if (igdbId == null) {
          // Нет маппинга — пропускаем (нельзя привязать к games.id).
          skipped++;
          continue;
        }

        // Сравниваем с существующими данными.
        final TrackerGameData? existing = existingByRaId[raGameId];

        // Award date.
        final DateTime? awardDate = awardDates[raGame.gameId];
        final int? awardTimestamp = awardDate != null
            ? awardDate.millisecondsSinceEpoch ~/ 1000
            : null;

        // Last played.
        final int? lastPlayedTimestamp = raGame.lastPlayedAt != null
            ? raGame.lastPlayedAt!.millisecondsSinceEpoch ~/ 1000
            : null;

        if (existing != null &&
            existing.achievementsEarned == raGame.numAwarded &&
            existing.awardKind == raGame.highestAwardKind) {
          // Данные не изменились.
          skipped++;
          continue;
        }

        final TrackerGameData data = TrackerGameData(
          id: existing?.id ?? 0,
          trackerType: TrackerType.ra,
          gameId: igdbId,
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

      // 4. Batch upsert.
      await _trackerDao.upsertGameDataBatch(toUpsert);

      // 5. Обновляем профиль с общей статой.
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

  // ==================== RA Per-Game Achievements ====================

  /// Загружает достижения для конкретной RA игры.
  ///
  /// Вызывается при открытии карточки игры (lazy load).
  /// Кэширует результат в `tracker_achievements`.
  Future<List<TrackerAchievement>> loadRaGameAchievements(
    int raGameId,
  ) async {
    final RaGameFullProgress result =
        await loadRaGameFullProgress(raGameId);
    return result.achievements;
  }

  /// Загружает достижения и game-level данные (award, hardcore, lastPlayed).
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

    // Кэшируем в БД (replace all).
    await _trackerDao.replaceAchievements(
      TrackerType.ra,
      raGameIdStr,
      result,
    );

    // Парсим game-level данные.
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

    // Даты активности — из earned achievements.
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

  /// Возвращает закэшированные достижения или загружает из API.
  ///
  /// [maxCacheAgeMinutes] — макс. возраст кэша. Если кэш старше — перезагружаем.
  Future<List<TrackerAchievement>> getOrLoadRaAchievements(
    int raGameId, {
    int maxCacheAgeMinutes = 5,
  }) async {
    final String raGameIdStr = raGameId.toString();

    // Проверяем кэш и его возраст.
    final bool hasCached =
        await _trackerDao.hasAchievements(TrackerType.ra, raGameIdStr);
    if (hasCached) {
      final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final int maxAgeSeconds = maxCacheAgeMinutes * 60;

      // Проверяем возраст через tracker_game_data.last_synced_at.
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

    // Загружаем из API.
    if (!_raApi.hasCredentials) return <TrackerAchievement>[];
    return loadRaGameAchievements(raGameId);
  }
}

/// Полный результат загрузки RA игры: достижения + game-level данные.
class RaGameFullProgress {
  /// Создаёт [RaGameFullProgress].
  const RaGameFullProgress({
    required this.achievements,
    this.hardcoreEarned,
    this.awardKind,
    this.awardDate,
    this.firstPlayedAt,
    this.lastPlayedAt,
  });

  /// Список достижений.
  final List<TrackerAchievement> achievements;

  /// Hardcore earned count.
  final int? hardcoreEarned;

  /// Тип награды ('mastered-hardcore', 'beaten-softcore', etc).
  final String? awardKind;

  /// Timestamp получения award.
  final int? awardDate;

  /// Timestamp первого earned achievement (started at).
  final int? firstPlayedAt;

  /// Timestamp последней активности.
  final int? lastPlayedAt;
}
