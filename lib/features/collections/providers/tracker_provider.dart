// Провайдеры для tracker данных в карточке игры.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../core/database/dao/tracker_dao.dart';
import '../../../core/database/database_service.dart';
import '../../../core/services/tracker_sync_service.dart';
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
  late int _gameId;

  @override
  Future<TrackerDetailState> build(int arg) async {
    _gameId = arg;
    _trackerDao = ref.watch(trackerDaoProvider);
    _syncService = ref.watch(trackerSyncServiceProvider);

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
    } catch (e) {
      _log.warning('Failed to load achievements for game $_gameId', e);
      state = AsyncData<TrackerDetailState>(TrackerDetailState(
        gameData: current.gameData,
      ));
    }
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

      // Загружаем ачивки из API.
      final List<TrackerAchievement> achievements =
          await _syncService.loadRaGameAchievements(raGameId);

      // Пустой список = нет credentials или ошибка API — не трогаем game_data.
      if (achievements.isEmpty) {
        state = AsyncData<TrackerDetailState>(TrackerDetailState(
          gameData: current.gameData,
        ));
        return;
      }

      // Обновляем game_data: earned/total берём из свежих ачивок,
      // hardcore оставляем из существующих данных (пересчёт при quickSync).
      final int earned =
          achievements.where((TrackerAchievement a) => a.earned).length;
      final int total = achievements.length;
      final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final TrackerGameData updatedData = current.gameData!.copyWith(
        achievementsEarned: earned,
        achievementsTotal: total,
        lastSyncedAt: now,
      );
      await _trackerDao.upsertGameData(updatedData);

      state = AsyncData<TrackerDetailState>(TrackerDetailState(
        gameData: updatedData,
        achievements: achievements,
      ));
    } catch (e) {
      _log.warning('Failed to refresh achievements for game $_gameId', e);
      state = AsyncData<TrackerDetailState>(TrackerDetailState(
        gameData: current.gameData,
      ));
    }
  }
}
