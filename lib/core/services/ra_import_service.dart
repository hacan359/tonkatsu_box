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
import '../../shared/models/wishlist_tag.dart';
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

  /// Поиск игр в IGDB (только для игр без ручной привязки).
  searchingGames,

  /// Запись в коллекцию (добавление/обновление).
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
    required this.wishlisted,
    required this.unmatchedTitles,
    required this.collectionId,
  });

  /// Общее количество игр в RA.
  final int totalGames;

  /// Новые элементы в коллекцию.
  final int added;

  /// Обновлена мета у существующих.
  final int updated;

  /// Не найдено в IGDB и нет ручной привязки.
  final int unmatched;

  /// Фактически добавлено новых записей в вишлист в этом синке.
  /// Не включает уже существовавшие записи (они только обновляются).
  final int wishlisted;

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
      wishlistedByType: wishlisted > 0
          ? <MediaType, int>{MediaType.game: wishlisted}
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
    required TrackerDao trackerDao,
  })  : _raApi = raApi,
        _igdbApi = igdbApi,
        _db = database,
        _trackerDao = trackerDao;

  final RaApi _raApi;
  final IgdbApi _igdbApi;
  final DatabaseService _db;
  final TrackerDao _trackerDao;
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

    // Подтягиваем существующие ручные RA→IGDB привязки из tracker_game_data.
    // Если игра уже привязана юзером (через showRaLinkDialog/linkRaGame),
    // не идём в IGDB-поиск, а используем сохранённый IGDB id.
    final List<TrackerGameData> manualLinks =
        await _trackerDao.getAllGameData(TrackerType.ra);
    final Map<int, int> raIdToIgdbId = <int, int>{};
    for (final TrackerGameData d in manualLinks) {
      final int? raId = int.tryParse(d.trackerGameId);
      if (raId != null) raIdToIgdbId[raId] = d.gameId;
    }

    // IGDB-поиск нужен только для непривязанных игр.
    final List<RaGameProgress> unlinkedGames = <RaGameProgress>[
      for (final RaGameProgress g in games)
        if (!raIdToIgdbId.containsKey(g.gameId)) g,
    ];

    // Этап 1: IGDB-поиск.
    onProgress(RaImportProgress(
      stage: RaImportStage.searchingGames,
      current: 0,
      total: unlinkedGames.length,
    ));

    final Map<int, Game?> matchesByIndex = unlinkedGames.isEmpty
        ? <int, Game?>{}
        : await _batchFindGames(
            unlinkedGames,
            onBatchDone: (int processed) {
              onProgress(RaImportProgress(
                stage: RaImportStage.searchingGames,
                current: processed,
                total: unlinkedGames.length,
              ));
            },
          );

    // Индексируем по RA gameId — стабильный ключ, без позиционных кёрсоров.
    final Map<int, Game?> searchByRaId = <int, Game?>{
      for (int i = 0; i < unlinkedGames.length; i++)
        unlinkedGames[i].gameId: matchesByIndex[i],
    };

    _log.info(
      'IGDB matched ${searchByRaId.values.where((Game? g) => g != null).length}'
      '/${unlinkedGames.length} unlinked RA games '
      '(${raIdToIgdbId.length} already manually linked)',
    );

    // Этап 2: запись в коллекцию.
    int added = 0;
    int updated = 0;
    int unmatched = 0;
    int wishlisted = 0;
    final List<String> unmatchedTitles = <String>[];
    final String importTag = buildImportTag('RetroAchievements');

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

      final Game? igdbGame = await _resolveIgdbGame(
        raGame,
        linkedIgdbId: raIdToIgdbId[raGame.gameId],
        searchResult: searchByRaId[raGame.gameId],
      );

      if (igdbGame == null) {
        unmatched++;
        unmatchedTitles.add('${raGame.title} (${raGame.consoleName})');
        if (addToWishlist) {
          final bool wasAdded =
              await _addToWishlistIfNotExists(raGame, importTag);
          if (wasAdded) wishlisted++;
        }
        continue;
      }

      // Match the existing item by (collection, IGDB game, platform). The
      // RA game id is platform-specific on RA's side, so the same IGDB
      // title on a different platform must land in its own collection row
      // instead of overwriting the existing one.
      final int? raPlatformId =
          RaToIgdbMapper.primaryIgdbPlatformId(raGame.consoleId);
      final CollectionItem? existing = await _db.findCollectionItem(
        collectionId: targetCollectionId,
        mediaType: MediaType.game,
        externalId: igdbGame.id,
        platformId: raPlatformId,
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

      // Сохраняем/обновляем tracker_game_data (счётчики ачивок, даты).
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
      '$unmatched unmatched ($wishlisted newly wishlisted) '
      'out of ${games.length}',
    );

    return RaImportResult(
      totalGames: games.length,
      added: added,
      updated: updated,
      unmatched: unmatched,
      wishlisted: wishlisted,
      unmatchedTitles: unmatchedTitles,
      collectionId: targetCollectionId,
    );
  }

  /// Возвращает IGDB-игру для RA-записи: сначала по ручной привязке
  /// (через локальный кэш игр), потом — fallback на результат IGDB-поиска.
  ///
  /// Если ручная привязка указывает на IGDB id, которого нет в локальном
  /// кэше, делает дополнительный точечный поиск по названию (защита
  /// от устаревшей записи в `tracker_game_data`).
  Future<Game?> _resolveIgdbGame(
    RaGameProgress raGame, {
    required int? linkedIgdbId,
    required Game? searchResult,
  }) async {
    if (linkedIgdbId != null) {
      final Game? cached = await _db.getGameById(linkedIgdbId);
      if (cached != null) return cached;
      _log.warning(
        'Manual link for RA gameId=${raGame.gameId} → IGDB id=$linkedIgdbId, '
        'but game not found in local cache. Falling back to IGDB search.',
      );
      final RaToIgdbMapper mapper = RaToIgdbMapper(_igdbApi);
      try {
        return await mapper.findIgdbGame(raGame);
      } on IgdbApiException catch (e) {
        _log.warning('Fallback IGDB search failed: ${e.message}');
        return null;
      }
    }
    return searchResult;
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

  /// Возвращает `true` если запись действительно создана,
  /// `false` если игра уже была в вишлисте (не перезаписываем,
  /// чтобы не затереть пользовательские правки).
  Future<bool> _addToWishlistIfNotExists(
    RaGameProgress raGame,
    String importTag,
  ) async {
    final String title = '${raGame.title} (${raGame.consoleName})';
    final WishlistItem? existing = await _db.findUnresolvedWishlistItem(title);
    if (existing != null) {
      // Retro-stamp the current import tag only on previously-untagged rows
      // so legacy entries get grouped without overwriting manual tags.
      if (existing.tag == null) {
        await _db.updateWishlistItem(existing.id, tag: importTag);
      }
      return false;
    }

    await _db.addWishlistItem(
      text: title,
      mediaTypeHint: MediaType.game,
      note: 'From RetroAchievements • '
          '${raGame.numAwarded}/${raGame.maxPossible} achievements'
          '${raGame.highestAwardKind != null ? ' • ${raGame.highestAwardKind}' : ''}',
      tag: importTag,
    );
    return true;
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

  /// Saves the per-platform tracker_game_data row for an RA game. The IGDB
  /// platform id is derived from RA's console id so PS2 and GameCube
  /// installs of the same IGDB title don't overwrite each other.
  Future<void> _saveTrackerGameData(
    int igdbId,
    RaGameProgress raGame,
  ) async {
    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final int? awardTimestamp = raGame.highestAwardDate != null
        ? raGame.highestAwardDate!.millisecondsSinceEpoch ~/ 1000
        : null;
    final int? lastPlayedTimestamp = raGame.lastPlayedAt != null
        ? raGame.lastPlayedAt!.millisecondsSinceEpoch ~/ 1000
        : null;
    final int? platformId =
        RaToIgdbMapper.primaryIgdbPlatformId(raGame.consoleId);

    await _trackerDao.upsertGameData(TrackerGameData(
      id: 0,
      trackerType: TrackerType.ra,
      gameId: igdbId,
      platformId: platformId,
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
