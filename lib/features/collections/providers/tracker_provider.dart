import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../core/database/dao/tracker_dao.dart';
import '../../../core/database/database_service.dart';
import '../../../core/services/ra_sync_helpers.dart';
import 'collections_provider.dart';
import '../../../core/services/tracker_sync_service.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/item_status.dart';
import '../../../shared/models/ra_game_progress.dart';
import '../../../shared/models/tracker_achievement.dart';
import '../../../shared/models/tracker_game_data.dart';
import '../../../shared/models/tracker_profile.dart';

/// Composite key for the tracker provider family — IGDB game id plus the
/// optional platform that scopes the row. A `null` platformId points at the
/// legacy platform-agnostic record so old data keeps rendering.
typedef TrackerKey = ({int gameId, int? platformId});

class TrackerDetailState {
  const TrackerDetailState({
    this.gameData,
    this.achievements,
    this.isLoadingAchievements = false,
  });

  final TrackerGameData? gameData;
  final List<TrackerAchievement>? achievements;
  final bool isLoadingAchievements;

  bool get hasRaData => gameData != null;
}

/// Tracker data for one (IGDB game, platform) pair.
final AsyncNotifierProviderFamily<TrackerDetailNotifier, TrackerDetailState,
        TrackerKey>
    trackerDetailProvider = AsyncNotifierProvider.family<
        TrackerDetailNotifier, TrackerDetailState, TrackerKey>(
  TrackerDetailNotifier.new,
);

class TrackerDetailNotifier
    extends FamilyAsyncNotifier<TrackerDetailState, TrackerKey> {
  static final Logger _log = Logger('TrackerDetailNotifier');

  late TrackerDao _trackerDao;
  late TrackerSyncService _syncService;
  late DatabaseService _db;
  late int _gameId;
  int? _platformId;

  @override
  Future<TrackerDetailState> build(TrackerKey arg) async {
    _gameId = arg.gameId;
    _platformId = arg.platformId;
    _trackerDao = ref.watch(trackerDaoProvider);
    _syncService = ref.watch(trackerSyncServiceProvider);
    _db = ref.watch(databaseServiceProvider);

    TrackerGameData? data = await _trackerDao.getGameData(
      TrackerType.ra,
      _gameId,
      platformId: _platformId,
    );
    // Fallback to the legacy platform-agnostic row when no per-platform row
    // exists yet — keeps pre-v37 collections rendering without re-sync.
    if (data == null && _platformId != null) {
      data = await _trackerDao.getGameData(TrackerType.ra, _gameId);
    }

    return TrackerDetailState(gameData: data);
  }

  /// Загружает достижения из кэша или API.
  Future<void> loadAchievements() async {
    final TrackerDetailState current = state.valueOrNull ??
        const TrackerDetailState();
    if (current.gameData == null) return;
    if (current.isLoadingAchievements) return;

    state = AsyncData<TrackerDetailState>(TrackerDetailState(
      gameData: current.gameData,
      isLoadingAchievements: true,
    ));

    try {
      final int raGameId =
          int.tryParse(current.gameData!.trackerGameId) ?? 0;
      if (raGameId == 0) {
        state = AsyncData<TrackerDetailState>(TrackerDetailState(
          gameData: current.gameData,
        ));
        return;
      }

      final List<TrackerAchievement> achievements =
          await _syncService.getOrLoadRaAchievements(raGameId);

      state = AsyncData<TrackerDetailState>(TrackerDetailState(
        gameData: current.gameData,
        achievements: achievements,
      ));

      // Синкаем даты из achievements в collection_items.
      int? firstEarned;
      int? lastEarned;
      int earnedCount = 0;
      for (final TrackerAchievement ach in achievements) {
        if (ach.earned && ach.earnedAt != null) {
          earnedCount++;
          if (firstEarned == null || ach.earnedAt! < firstEarned) {
            firstEarned = ach.earnedAt;
          }
          if (lastEarned == null || ach.earnedAt! > lastEarned) {
            lastEarned = ach.earnedAt;
          }
        }
      }
      if (firstEarned != null) {
        await _syncToCollectionItems(
          awardKind: current.gameData!.awardKind,
          awardDate: current.gameData!.awardDate,
          firstPlayedAt: firstEarned,
          lastPlayedAt: lastEarned,
          earned: earnedCount,
        );
      }
    } catch (e) {
      _log.warning('Failed to load achievements for game $_gameId', e);
      state = AsyncData<TrackerDetailState>(TrackerDetailState(
        gameData: current.gameData,
      ));
    }
  }

  /// Привязывает игру к RA: создаёт tracker_game_data и загружает достижения.
  Future<void> linkRaGame({
    required int raGameId,
    required String raTitle,
    required int achievementsTotal,
  }) async {
    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final TrackerGameData data = TrackerGameData(
      id: 0,
      trackerType: TrackerType.ra,
      gameId: _gameId,
      platformId: _platformId,
      trackerGameId: raGameId.toString(),
      trackerGameTitle: raTitle,
      achievementsTotal: achievementsTotal,
      lastSyncedAt: now,
    );
    await _trackerDao.upsertGameData(data);

    // Обновляем state — теперь hasRaData = true.
    state = AsyncData<TrackerDetailState>(TrackerDetailState(gameData: data));

    // Загружаем достижения и прогресс из API.
    await refreshAchievements();
  }

  /// Drops the per-platform RA link and its achievements. Other platform
  /// installs of the same IGDB game keep their data.
  Future<void> unlinkRaGame() async {
    await _trackerDao.deleteGameData(
      TrackerType.ra,
      _gameId,
      platformId: _platformId,
    );
    state = const AsyncData<TrackerDetailState>(TrackerDetailState());
  }

  /// Принудительная перезагрузка достижений и game data из API.
  Future<void> refreshAchievements() async {
    final TrackerDetailState current = state.valueOrNull ??
        const TrackerDetailState();
    if (current.gameData == null) return;

    state = AsyncData<TrackerDetailState>(TrackerDetailState(
      gameData: current.gameData,
      isLoadingAchievements: true,
    ));

    try {
      final int raGameId =
          int.tryParse(current.gameData!.trackerGameId) ?? 0;
      if (raGameId == 0) return;

      // Загружаем полные данные из API.
      final RaGameFullProgress progress =
          await _syncService.loadRaGameFullProgress(raGameId);

      // Пустой список = нет credentials или ошибка API — не трогаем game_data.
      if (progress.achievements.isEmpty) {
        state = AsyncData<TrackerDetailState>(TrackerDetailState(
          gameData: current.gameData,
        ));
        return;
      }

      final int earned = progress.achievements
          .where((TrackerAchievement a) => a.earned)
          .length;
      final int total = progress.achievements.length;
      final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final TrackerGameData updatedData = current.gameData!.copyWith(
        achievementsEarned: earned,
        achievementsTotal: total,
        achievementsEarnedHardcore: progress.hardcoreEarned,
        awardKind: progress.awardKind,
        awardDate: progress.awardDate,
        lastPlayedAt: progress.lastPlayedAt,
        lastSyncedAt: now,
      );
      await _trackerDao.upsertGameData(updatedData);

      state = AsyncData<TrackerDetailState>(TrackerDetailState(
        gameData: updatedData,
        achievements: progress.achievements,
      ));

      // Синк дат и статуса в collection_items.
      await _syncToCollectionItems(
        awardKind: progress.awardKind,
        awardDate: progress.awardDate,
        firstPlayedAt: progress.firstPlayedAt,
        lastPlayedAt: progress.lastPlayedAt,
        earned: earned,
      );
    } catch (e) {
      _log.warning('Failed to refresh achievements for game $_gameId', e);
      state = AsyncData<TrackerDetailState>(TrackerDetailState(
        gameData: current.gameData,
      ));
    }
  }

  /// Propagates RA dates/status into every CollectionItem that points at
  /// this `(IGDB game, platform)` pair. Other platform installs of the same
  /// IGDB game are intentionally left alone.
  Future<void> _syncToCollectionItems({
    String? awardKind,
    int? awardDate,
    int? firstPlayedAt,
    int? lastPlayedAt,
    int earned = 0,
  }) async {
    try {
      final List<({int id, int? collectionId, int? platformId})> items =
          await _db.getItemIdsByExternalId(
        _gameId,
        'game',
        platformId: _platformId,
        filterByPlatform: true,
      );
      if (items.isEmpty) return;

      final DateTime? startedAt = firstPlayedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(firstPlayedAt * 1000)
          : null;
      final DateTime? lastActivity = lastPlayedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(lastPlayedAt * 1000)
          : null;
      final DateTime? completedAt =
          awardKind != null && awardDate != null
              ? DateTime.fromMillisecondsSinceEpoch(awardDate * 1000)
              : null;

      final ItemStatus? raStatus = RaGameProgress.statusFromAward(
        awardKind: awardKind,
        numAwarded: earned,
        lastPlayedAt: lastActivity,
      );

      for (final ({int id, int? collectionId, int? platformId}) item
          in items) {
        // Текущий статус для проверки правила dropped.
        final CollectionItem? current = ref
            .read(collectionItemsNotifierProvider(item.collectionId))
            .valueOrNull
            ?.cast<CollectionItem?>()
            .firstWhere(
              (CollectionItem? ci) => ci?.id == item.id,
              orElse: () => null,
            );

        await syncRaDataToCollectionItem(
          db: _db,
          ref: ref,
          itemId: item.id,
          collectionId: item.collectionId,
          status: raStatus,
          currentStatus: current?.status,
          startedAt: startedAt,
          lastActivityAt: lastActivity,
          completedAt: completedAt,
        );
      }
    } catch (e) {
      _log.warning('Failed to sync collection item dates for $_gameId', e);
    }
  }
}
