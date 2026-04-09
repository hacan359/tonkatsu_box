// Сервис импорта RetroAchievements → IGDB игры.

import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../shared/models/collection.dart';
import '../../shared/models/collection_item.dart';
import '../../shared/models/game.dart';
import '../../shared/models/item_status.dart';
import '../../shared/models/media_type.dart';
import '../../shared/models/ra_game_progress.dart';
import '../../shared/models/tracker_game_data.dart';
import '../../shared/models/tracker_profile.dart';
import '../../shared/models/universal_import_result.dart';
import '../../shared/models/wishlist_item.dart';
import '../api/igdb_api.dart';
import '../api/ra_api.dart';
import '../database/dao/tracker_dao.dart';
import '../database/database_service.dart';
import 'ra_sync_helpers.dart';
import 'ra_to_igdb_mapper.dart';

// ---------------------------------------------------------------------------
// Публичные модели
// ---------------------------------------------------------------------------

/// Этап импорта RetroAchievements.
enum RaImportStage {
  /// Загрузка библиотеки из RA API.
  fetchingLibrary,

  /// Поиск игр в IGDB и добавление в коллекцию.
  matchingGames,

  /// Импорт завершён.
  completed,
}

/// Прогресс импорта RetroAchievements.
class RaImportProgress {
  /// Создаёт [RaImportProgress].
  const RaImportProgress({
    required this.stage,
    this.current = 0,
    this.total = 0,
    this.currentName,
    this.addedCount = 0,
    this.updatedCount = 0,
    this.unmatchedCount = 0,
  });

  /// Текущий этап.
  final RaImportStage stage;

  /// Текущий прогресс.
  final int current;

  /// Общее количество.
  final int total;

  /// Название текущей обрабатываемой игры.
  final String? currentName;

  /// Количество добавленных игр.
  final int addedCount;

  /// Количество обновлённых игр.
  final int updatedCount;

  /// Количество ненайденных игр.
  final int unmatchedCount;
}

/// Результат импорта RetroAchievements.
class RaImportResult {
  /// Создаёт [RaImportResult].
  const RaImportResult({
    required this.totalGames,
    required this.added,
    required this.updated,
    required this.unmatched,
    required this.unmatchedTitles,
    required this.collectionId,
  });

  /// Общее количество игр в RA.
  final int totalGames;

  /// Новые элементы в коллекцию.
  final int added;

  /// Обновлена мета у существующих.
  final int updated;

  /// Не найдено в IGDB.
  final int unmatched;

  /// Названия ненайденных игр.
  final List<String> unmatchedTitles;

  /// ID целевой коллекции.
  final int collectionId;
}

/// Расширение для преобразования в [UniversalImportResult].
extension RaImportResultToUniversal on RaImportResult {
  /// Преобразует в [UniversalImportResult] для унифицированного экрана.
  UniversalImportResult toUniversal({Collection? collection}) {
    return UniversalImportResult(
      sourceName: 'RetroAchievements',
      success: true,
      collection: collection,
      collectionId: collectionId,
      importedByType: added > 0
          ? <MediaType, int>{MediaType.game: added}
          : <MediaType, int>{},
      updatedByType: updated > 0
          ? <MediaType, int>{MediaType.game: updated}
          : <MediaType, int>{},
      wishlistedByType: unmatched > 0
          ? <MediaType, int>{MediaType.game: unmatched}
          : <MediaType, int>{},
    );
  }
}

// ---------------------------------------------------------------------------
// Сервис
// ---------------------------------------------------------------------------

/// Провайдер для RA import service.
final Provider<RaImportService> raImportServiceProvider =
    Provider<RaImportService>((Ref ref) {
  return RaImportService(
    raApi: ref.watch(raApiProvider),
    igdbApi: ref.watch(igdbApiProvider),
    database: ref.watch(databaseServiceProvider),
    trackerDao: ref.watch(trackerDaoProvider),
  );
});

/// Сервис импорта игр из RetroAchievements.
///
/// Загружает список играных игр из RA, маппит на IGDB,
/// добавляет/обновляет в целевой коллекции.
class RaImportService {
  /// Создаёт [RaImportService].
  RaImportService({
    required RaApi raApi,
    required IgdbApi igdbApi,
    required DatabaseService database,
    TrackerDao? trackerDao,
  })  : _raApi = raApi,
        _igdbApi = igdbApi,
        _db = database,
        _trackerDao = trackerDao;

  final RaApi _raApi;
  final IgdbApi _igdbApi;
  final DatabaseService _db;
  final TrackerDao? _trackerDao;
  static final Logger _log = Logger('RaImportService');

  /// Импортирует игры из RA профиля в коллекцию.
  ///
  /// [collectionId] — ID существующей коллекции.
  /// [createCollection] — callback для ленивого создания коллекции
  ///   (вызывается только после успешной загрузки библиотеки RA).
  ///   Должен быть указан либо [collectionId], либо [createCollection].
  Future<RaImportResult> importFromProfile({
    required String raUsername,
    int? collectionId,
    Future<int> Function()? createCollection,
    required bool addToWishlist,
    required void Function(RaImportProgress) onProgress,
  }) async {
    if (collectionId == null && createCollection == null) {
      throw ArgumentError(
        'Either collectionId or createCollection must be provided',
      );
    }

    onProgress(const RaImportProgress(
      stage: RaImportStage.fetchingLibrary,
    ));

    // Загружаем игры из RA.
    final List<RaGameProgress> raGames =
        await _raApi.getCompletedGames(raUsername);

    // Фильтруем не-игровые записи (Hubs, Events, Standalone).
    final List<RaGameProgress> games =
        raGames.where((RaGameProgress g) => g.isRealGame).toList();

    if (games.isEmpty) {
      throw const RaApiException('No games found in this RA profile');
    }

    // Создание коллекции — только после успешной загрузки.
    final int targetCollectionId =
        collectionId ?? await createCollection!();

    // Batch-поиск в IGDB через multiquery (по 10 игр за запрос).
    onProgress(RaImportProgress(
      stage: RaImportStage.matchingGames,
      current: 0,
      total: games.length,
    ));

    final Map<int, Game?> igdbMatches = await _batchFindGames(
      games,
      onBatchDone: (int processed) {
        onProgress(RaImportProgress(
          stage: RaImportStage.matchingGames,
          current: processed,
          total: games.length,
        ));
      },
    );

    _log.info(
      'IGDB matched ${igdbMatches.values.where((Game? g) => g != null).length}'
      '/${games.length} RA games',
    );

    // Обработка каждой игры.
    int added = 0;
    int updated = 0;
    int unmatched = 0;
    final List<String> unmatchedTitles = <String>[];

    for (int i = 0; i < games.length; i++) {
      final RaGameProgress raGame = games[i];

      onProgress(RaImportProgress(
        stage: RaImportStage.matchingGames,
        current: i + 1,
        total: games.length,
        currentName: raGame.title,
        addedCount: added,
        updatedCount: updated,
        unmatchedCount: unmatched,
      ));

      final Game? igdbGame = igdbMatches[i];

      if (igdbGame == null) {
        unmatched++;
        unmatchedTitles.add('${raGame.title} (${raGame.consoleName})');
        if (addToWishlist) {
          await _addToWishlistIfNotExists(raGame);
        }
        continue;
      }

      // Проверить дубликат ТОЛЬКО В ЦЕЛЕВОЙ КОЛЛЕКЦИИ.
      final CollectionItem? existing = await _db.findCollectionItem(
        collectionId: targetCollectionId,
        mediaType: MediaType.game,
        externalId: igdbGame.id,
      );

      final DateTime? completedAt = raGame.highestAwardDate;

      if (existing != null) {
        final bool wasUpdated = await _updateExistingItem(
          existing,
          raGame,
          completedAt: completedAt,
        );
        if (wasUpdated) updated++;
      } else {
        // Кэшировать игру и добавить в коллекцию.
        await _db.upsertGame(igdbGame);
        await _addToCollection(
          collectionId: targetCollectionId,
          game: igdbGame,
          raGame: raGame,
          completedAt: completedAt,
        );
        added++;
      }

      // Сохраняем tracker_game_data для RA секции в карточке.
      await _saveTrackerGameData(igdbGame.id, raGame);
    }

    onProgress(RaImportProgress(
      stage: RaImportStage.completed,
      current: games.length,
      total: games.length,
      addedCount: added,
      updatedCount: updated,
      unmatchedCount: unmatched,
    ));

    _log.info(
      'RA import done: $added added, $updated updated, '
      '$unmatched unmatched out of ${games.length}',
    );

    return RaImportResult(
      totalGames: games.length,
      added: added,
      updated: updated,
      unmatched: unmatched,
      unmatchedTitles: unmatchedTitles,
      collectionId: targetCollectionId,
    );
  }

  /// Batch-поиск игр в IGDB через multiquery.
  ///
  /// Возвращает маппинг: индекс в [games] → найденная Game (или null).
  /// [onBatchDone] вызывается после каждого батча с количеством
  /// обработанных игр.
  Future<Map<int, Game?>> _batchFindGames(
    List<RaGameProgress> games, {
    void Function(int processed)? onBatchDone,
  }) async {
    final Map<int, Game?> results = <int, Game?>{};
    const int batchSize = IgdbApi.maxMultiQueryBatch;

    for (int batchStart = 0;
        batchStart < games.length;
        batchStart += batchSize) {
      final int batchEnd = min(batchStart + batchSize, games.length);
      final List<RaGameProgress> batch =
          games.sublist(batchStart, batchEnd);

      // Формируем запросы с платформенным фильтром.
      final List<({String name, int? platformId})> queries = batch
          .map((RaGameProgress g) => (
                name: g.title,
                platformId: RaToIgdbMapper.primaryIgdbPlatformId(g.consoleId),
              ))
          .toList();

      Map<int, List<Game>> batchResults;
      try {
        batchResults = await _igdbApi.multiSearchGamesByName(queries);
      } on IgdbApiException catch (e) {
        _log.warning('Multiquery failed, falling back to single search', e);
        batchResults = await _fallbackSingleSearch(batch);
      }

      // Выбираем лучшее совпадение для каждой игры.
      for (int j = 0; j < batch.length; j++) {
        final List<Game> candidates = batchResults[j] ?? <Game>[];
        results[batchStart + j] =
            RaToIgdbMapper.bestMatch(batch[j].title, candidates);
      }

      onBatchDone?.call(batchEnd);

      // Rate limiting: пауза каждые 4 батча.
      final int batchIndex = batchStart ~/ batchSize;
      if (batchIndex % 4 == 3) {
        await Future<void>.delayed(const Duration(milliseconds: 1100));
      }
    }

    return results;
  }

  /// Поштучный поиск — fallback при ошибке multiquery.
  Future<Map<int, List<Game>>> _fallbackSingleSearch(
    List<RaGameProgress> batch,
  ) async {
    final RaToIgdbMapper mapper = RaToIgdbMapper(_igdbApi);
    final Map<int, List<Game>> results = <int, List<Game>>{};
    for (int i = 0; i < batch.length; i++) {
      final Game? game = await mapper.findIgdbGame(batch[i]);
      results[i] = game != null ? <Game>[game] : <Game>[];
      // findIgdbGame делает 1-2 запроса, пауза после каждого.
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    return results;
  }

  /// Обновляет мету существующего элемента: статус и даты.
  Future<bool> _updateExistingItem(
    CollectionItem existing,
    RaGameProgress raGame, {
    DateTime? completedAt,
  }) async {
    final ItemStatus? raStatus = raGame.itemStatus;
    final DateTime? lastActivity = raGame.lastPlayedAt;

    if (raStatus == null && completedAt == null && lastActivity == null) {
      return false;
    }

    await syncRaDataToCollectionItem(
      db: _db,
      itemId: existing.id,
      collectionId: existing.collectionId,
      status: raStatus,
      currentStatus: existing.status,
      lastActivityAt: lastActivity,
      completedAt: completedAt,
    );
    return true;
  }

  Future<void> _addToWishlistIfNotExists(RaGameProgress raGame) async {
    final String title = '${raGame.title} (${raGame.consoleName})';
    final WishlistItem? existing = await _db.findUnresolvedWishlistItem(title);
    if (existing != null) return;

    await _db.addWishlistItem(
      text: title,
      mediaTypeHint: MediaType.game,
      note: 'From RetroAchievements \u2022 '
          '${raGame.numAwarded}/${raGame.maxPossible} achievements'
          '${raGame.highestAwardKind != null ? ' \u2022 ${raGame.highestAwardKind}' : ''}',
    );
  }

  Future<void> _addToCollection({
    required int collectionId,
    required Game game,
    required RaGameProgress raGame,
    DateTime? completedAt,
  }) async {
    final int? platformId =
        RaToIgdbMapper.primaryIgdbPlatformId(raGame.consoleId);
    final int? itemId = await _db.addItemToCollection(
      collectionId: collectionId,
      mediaType: MediaType.game,
      externalId: game.id,
      platformId: platformId,
      status: raGame.itemStatus ?? ItemStatus.notStarted,
    );

    if (itemId != null) {
      await syncRaDataToCollectionItem(
        db: _db,
        itemId: itemId,
        collectionId: collectionId,
        status: raGame.itemStatus,
        lastActivityAt: raGame.lastPlayedAt,
        completedAt: completedAt,
      );
    }
  }

  /// Сохраняет/обновляет tracker_game_data для RA игры.
  Future<void> _saveTrackerGameData(
    int igdbId,
    RaGameProgress raGame,
  ) async {
    if (_trackerDao == null) return;
    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final int? awardTimestamp = raGame.highestAwardDate != null
        ? raGame.highestAwardDate!.millisecondsSinceEpoch ~/ 1000
        : null;
    final int? lastPlayedTimestamp = raGame.lastPlayedAt != null
        ? raGame.lastPlayedAt!.millisecondsSinceEpoch ~/ 1000
        : null;

    await _trackerDao.upsertGameData(TrackerGameData(
      id: 0,
      trackerType: TrackerType.ra,
      gameId: igdbId,
      trackerGameId: raGame.gameId.toString(),
      trackerGameTitle: raGame.title,
      achievementsEarned: raGame.numAwarded,
      achievementsTotal: raGame.maxPossible,
      achievementsEarnedHardcore: raGame.numAwardedHardcore,
      awardKind: raGame.highestAwardKind,
      awardDate: awardTimestamp,
      lastPlayedAt: lastPlayedTimestamp,
      lastSyncedAt: now,
    ));
  }
}
