// Провайдеры для tracker данных в карточке игры.

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

/// Состояние tracker данных для карточки игры.
class TrackerDetailState {
  /// Создаёт [TrackerDetailState].
  const TrackerDetailState({
    this.gameData,
    this.achievements,
    this.isLoadingAchievements = false,
  });

  /// Summary прогресса (из tracker_game_data).
  final TrackerGameData? gameData;

  /// Список достижений (lazy loaded).
  final List<TrackerAchievement>? achievements;

  /// Загружаются ли достижения.
  final bool isLoadingAchievements;

  /// Есть ли RA данные для этой игры.
  bool get hasRaData => gameData != null;
}

/// Провайдер tracker данных для конкретной игры (по IGDB ID).
///
/// AsyncNotifier — `build()` загружает данные, Riverpod управляет
/// loading/data/error. Виджет использует `asyncValue.when()`.
final AsyncNotifierProviderFamily<TrackerDetailNotifier, TrackerDetailState,
        int>
    trackerDetailProvider = AsyncNotifierProvider.family<
        TrackerDetailNotifier, TrackerDetailState, int>(
  TrackerDetailNotifier.new,
);

/// Notifier для tracker данных одной игры.
class TrackerDetailNotifier
    extends FamilyAsyncNotifier<TrackerDetailState, int> {
  static final Logger _log = Logger('TrackerDetailNotifier');

  late TrackerDao _trackerDao;
  late TrackerSyncService _syncService;
  late DatabaseService _db;
  late int _gameId;

  @override
  Future<TrackerDetailState> build(int arg) async {
    _gameId = arg;
    _trackerDao = ref.watch(trackerDaoProvider);
    _syncService = ref.watch(trackerSyncServiceProvider);
    _db = ref.watch(databaseServiceProvider);

    final TrackerGameData? data =
        await _trackerDao.getGameData(TrackerType.ra, _gameId);

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

    // Создаём запись tracker_game_data.
    final TrackerGameData data = TrackerGameData(
      id: 0,
      trackerType: TrackerType.ra,
      gameId: _gameId,
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

  /// Отвязывает игру от RA: удаляет tracker_game_data и achievements.
  Future<void> unlinkRaGame() async {
    await _trackerDao.deleteGameData(TrackerType.ra, _gameId);
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

  /// Синхронизирует даты и статус из RA во все collection_items этой игры.
  Future<void> _syncToCollectionItems({
    String? awardKind,
    int? awardDate,
    int? firstPlayedAt,
    int? lastPlayedAt,
    int earned = 0,
  }) async {
    try {
      final List<({int id, int? collectionId})> items =
          await _db.getItemIdsByExternalId(_gameId, 'game');
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

      for (final ({int id, int? collectionId}) item in items) {
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
