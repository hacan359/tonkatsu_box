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

enum RaImportStage {
  fetchingLibrary,

  /// IGDB lookup (only for games without a manual link).
  searchingGames,

  /// Writing to the collection (add/update).
  matchingGames,

  completed,
}

class RaImportProgress {
  const RaImportProgress({
    required this.stage,
    this.current = 0,
    this.total = 0,
    this.currentName,
    this.addedCount = 0,
    this.updatedCount = 0,
    this.unmatchedCount = 0,
  });

  final RaImportStage stage;

  final int current;

  final int total;

  final String? currentName;

  final int addedCount;

  final int updatedCount;

  final int unmatchedCount;
}

class RaImportResult {
  const RaImportResult({
    required this.totalGames,
    required this.added,
    required this.updated,
    required this.unmatched,
    required this.wishlisted,
    required this.unmatchedTitles,
    required this.collectionId,
  });

  final int totalGames;

  final int added;

  final int updated;

  /// Not found in IGDB and no manual link.
  final int unmatched;

  /// Wishlist rows actually created during this sync; rows that already
  /// existed (and were only updated) are not counted.
  final int wishlisted;

  final List<String> unmatchedTitles;

  final int collectionId;
}

extension RaImportResultToUniversal on RaImportResult {
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

final Provider<RaImportService> raImportServiceProvider =
    Provider<RaImportService>((Ref ref) {
  return RaImportService(
    raApi: ref.watch(raApiProvider),
    igdbApi: ref.watch(igdbApiProvider),
    database: ref.watch(databaseServiceProvider),
    trackerDao: ref.watch(trackerDaoProvider),
  );
});

/// Imports the played-games library from RetroAchievements: maps RA entries
/// to IGDB and adds/updates them in the target collection.
class RaImportService {
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

  /// Either [collectionId] or [createCollection] must be provided;
  /// [createCollection] runs lazily, only after the RA library loads.
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

    final List<RaGameProgress> raGames =
        await _raApi.getCompletedGames(raUsername);

    // Drop non-game entries (Hubs, Events, Standalone)
    final List<RaGameProgress> games =
        raGames.where((RaGameProgress g) => g.isRealGame).toList();

    if (games.isEmpty) {
      throw const RaApiException('No games found in this RA profile');
    }

    // Create the collection only after the library loaded successfully
    final int targetCollectionId =
        collectionId ?? await createCollection!();

    // Manual RA→IGDB links from tracker_game_data: already-linked games skip
    // the IGDB search and use the stored IGDB id.
    final List<TrackerGameData> manualLinks =
        await _trackerDao.getAllGameData(TrackerType.ra);
    final Map<int, int> raIdToIgdbId = <int, int>{};
    for (final TrackerGameData d in manualLinks) {
      final int? raId = int.tryParse(d.trackerGameId);
      if (raId != null) raIdToIgdbId[raId] = d.gameId;
    }

    final List<RaGameProgress> unlinkedGames = <RaGameProgress>[
      for (final RaGameProgress g in games)
        if (!raIdToIgdbId.containsKey(g.gameId)) g,
    ];

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

    // Index by RA gameId — a stable key, no positional cursors
    final Map<int, Game?> searchByRaId = <int, Game?>{
      for (int i = 0; i < unlinkedGames.length; i++)
        unlinkedGames[i].gameId: matchesByIndex[i],
    };

    _log.info(
      'IGDB matched ${searchByRaId.values.where((Game? g) => g != null).length}'
      '/${unlinkedGames.length} unlinked RA games '
      '(${raIdToIgdbId.length} already manually linked)',
    );

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
        await _db.gameDao.upsertGame(igdbGame);
        await _addToCollection(
          collectionId: targetCollectionId,
          game: igdbGame,
          raGame: raGame,
          completedAt: completedAt,
        );
        added++;
      }

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

  /// Manual link first, then the IGDB search result. A link to an id missing
  /// from the local cache falls back to a title search (stale-link guard).
  Future<Game?> _resolveIgdbGame(
    RaGameProgress raGame, {
    required int? linkedIgdbId,
    required Game? searchResult,
  }) async {
    if (linkedIgdbId != null) {
      final Game? cached = await _db.gameDao.getGameById(linkedIgdbId);
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

  /// Returns index in [games] → matched Game (or null). [onBatchDone] fires
  /// after each batch with the number of games processed so far.
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

      for (int j = 0; j < batch.length; j++) {
        final List<Game> candidates = batchResults[j] ?? <Game>[];
        results[batchStart + j] =
            RaToIgdbMapper.bestMatch(batch[j].title, candidates);
      }

      onBatchDone?.call(batchEnd);

      // Rate limiting: pause every 4 batches
      final int batchIndex = batchStart ~/ batchSize;
      if (batchIndex % 4 == 3) {
        await Future<void>.delayed(const Duration(milliseconds: 1100));
      }
    }

    return results;
  }

  Future<Map<int, List<Game>>> _fallbackSingleSearch(
    List<RaGameProgress> batch,
  ) async {
    final RaToIgdbMapper mapper = RaToIgdbMapper(_igdbApi);
    final Map<int, List<Game>> results = <int, List<Game>>{};
    for (int i = 0; i < batch.length; i++) {
      final Game? game = await mapper.findIgdbGame(batch[i]);
      results[i] = game != null ? <Game>[game] : <Game>[];
      // findIgdbGame issues 1-2 requests; pause after each one
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    return results;
  }

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

  /// Returns `true` only when a new row was created; existing wishlist rows
  /// are left alone so user edits are not overwritten.
  Future<bool> _addToWishlistIfNotExists(
    RaGameProgress raGame,
    String importTag,
  ) async {
    final String title = '${raGame.title} (${raGame.consoleName})';
    final WishlistItem? existing = await _db.wishlistDao.findUnresolvedByText(title);
    if (existing != null) {
      // Retro-stamp the current import tag only on previously-untagged rows
      // so legacy entries get grouped without overwriting manual tags.
      if (existing.tag == null) {
        await _db.wishlistDao.updateWishlistItem(existing.id, tag: importTag);
      }
      return false;
    }

    await _db.wishlistDao.addWishlistItem(
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
