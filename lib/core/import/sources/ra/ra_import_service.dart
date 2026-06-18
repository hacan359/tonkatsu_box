import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../../data/repositories/collection_repository.dart';
import '../../../../data/repositories/wishlist_repository.dart';
import '../../../../shared/models/collection.dart';
import '../../../../shared/models/collection_item.dart';
import '../../../../shared/models/game.dart';
import '../../../../shared/models/item_status.dart';
import '../../../../shared/models/item_status_logic.dart';
import '../../../../shared/models/media_type.dart';
import '../../../../shared/models/ra_game_progress.dart';
import '../../../../shared/models/tracker_game_data.dart';
import '../../../../shared/models/tracker_profile.dart';
import '../../../../shared/models/universal_import_result.dart';
import '../../../../shared/models/wishlist_tag.dart';
import '../../../api/igdb_api.dart';
import '../../../api/ra_api.dart';
import '../../../database/dao/tracker_dao.dart';
import '../../../database/database_service.dart';
import '../../../services/import_service.dart';
import '../../../services/ra_to_igdb_mapper.dart';
import '../../import_columns.dart';
import '../../import_source.dart';
import '../../import_writer.dart';

final Provider<RaImportService> raImportServiceProvider =
    Provider<RaImportService>((Ref ref) {
  return RaImportService(
    raApi: ref.watch(raApiProvider),
    igdbApi: ref.watch(igdbApiProvider),
    database: ref.watch(databaseServiceProvider),
    trackerDao: ref.watch(trackerDaoProvider),
    repository: ref.watch(collectionRepositoryProvider),
    wishlistRepository: ref.watch(wishlistRepositoryProvider),
  );
});

class RaImportOptions extends ImportOptions {
  const RaImportOptions({
    required this.raUsername,
    required this.author,
    required this.newCollectionName,
    this.addToWishlist = true,
    super.collectionId,
  });

  final String raUsername;

  /// Author / name for a freshly created collection.
  final String author;
  final String newCollectionName;

  /// Drop IGDB-unmatched games into the text wishlist.
  final bool addToWishlist;
}

/// A resolved RA game ready to write: the RA progress, the matched IGDB game,
/// the platform derived from the RA console, and the achievement award date.
typedef _MatchedGame = ({
  RaGameProgress ra,
  Game game,
  int? platformId,
  DateTime? completedAt,
});

/// Imports a RetroAchievements profile on the shared import layer.
///
/// Already-linked games skip the IGDB search; the rest are searched by name in
/// throttled batches. Matched games are written through [ImportWriter] (RA is
/// the authoritative progress source, so status downgrades are allowed), then
/// each one gets its `tracker_game_data` row written in a post-write pass
/// (keyed by IGDB id + platform, which [ImportWriter] does not cover).
class RaImportService implements ImportSource {
  RaImportService({
    required RaApi raApi,
    required IgdbApi igdbApi,
    required DatabaseService database,
    required TrackerDao trackerDao,
    required CollectionRepository repository,
    required WishlistRepository wishlistRepository,
  })  : _raApi = raApi,
        _igdbApi = igdbApi,
        _db = database,
        _trackerDao = trackerDao,
        _writer = ImportWriter(
          collections: repository,
          wishlist: wishlistRepository,
        );

  final RaApi _raApi;
  final IgdbApi _igdbApi;
  final DatabaseService _db;
  final TrackerDao _trackerDao;
  final ImportWriter _writer;
  static final Logger _log = Logger('RaImportService');

  @override
  String get displayName => 'RetroAchievements';

  /// Throws [RaApiException] when the profile has no games.
  @override
  Future<UniversalImportResult> import(
    covariant RaImportOptions options, {
    ImportProgressCallback? onProgress,
  }) async {
    onProgress?.call(const ImportProgress(
      stage: ImportStage.reading,
      current: 0,
      total: 0,
    ));

    final List<RaGameProgress> raGames =
        await _raApi.getCompletedGames(options.raUsername);

    // Drop non-game entries (Hubs, Events, Standalone).
    final List<RaGameProgress> games =
        raGames.where((RaGameProgress g) => g.isRealGame).toList();
    if (games.isEmpty) {
      throw const RaApiException('No games found in this RA profile');
    }

    // Manual RA→IGDB links from tracker_game_data: already-linked games skip the
    // IGDB search and use the stored IGDB id.
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

    onProgress?.call(ImportProgress(
      stage: ImportStage.fetchingGames,
      current: 0,
      total: unlinkedGames.length,
    ));

    final Map<int, Game?> matchesByIndex = unlinkedGames.isEmpty
        ? <int, Game?>{}
        : await _batchFindGames(
            unlinkedGames,
            onBatchDone: (int processed) {
              onProgress?.call(ImportProgress(
                stage: ImportStage.fetchingGames,
                current: processed,
                total: unlinkedGames.length,
              ));
            },
          );

    final Map<int, Game?> searchByRaId = <int, Game?>{
      for (int i = 0; i < unlinkedGames.length; i++)
        unlinkedGames[i].gameId: matchesByIndex[i],
    };

    _log.info(
      'IGDB matched ${searchByRaId.values.where((Game? g) => g != null).length}'
      '/${unlinkedGames.length} unlinked RA games '
      '(${raIdToIgdbId.length} already manually linked)',
    );

    final String importTag = buildImportTag('RetroAchievements');
    final List<_MatchedGame> matched = <_MatchedGame>[];
    final List<WishlistCandidate> wishlist = <WishlistCandidate>[];

    for (final RaGameProgress raGame in games) {
      final Game? igdbGame = await _resolveIgdbGame(
        raGame,
        linkedIgdbId: raIdToIgdbId[raGame.gameId],
        searchResult: searchByRaId[raGame.gameId],
      );

      if (igdbGame == null) {
        if (options.addToWishlist) {
          wishlist.add(WishlistCandidate(
            text: '${raGame.title} (${raGame.consoleName})',
            mediaType: MediaType.game,
            note: _wishlistNote(raGame),
          ));
        }
        continue;
      }

      matched.add((
        ra: raGame,
        game: igdbGame,
        platformId: RaToIgdbMapper.primaryIgdbPlatformId(raGame.consoleId),
        completedAt: raGame.highestAwardDate,
      ));
    }

    final Map<int, Game> uniqueGames = <int, Game>{
      for (final _MatchedGame m in matched) m.game.id: m.game,
    };
    if (uniqueGames.isNotEmpty) {
      await _db.gameDao.upsertGames(uniqueGames.values.toList());
    }

    // Create the collection only after the library loaded successfully.
    final Collection? collection = await _writer.resolveCollection(
      collectionId: options.collectionId,
      newCollectionName: options.newCollectionName,
      author: options.author,
    );
    if (collection == null) {
      return const UniversalImportResult.failure(
        sourceName: 'RetroAchievements',
        error: 'Collection not found',
      );
    }

    onProgress?.call(ImportProgress(
      stage: ImportStage.addingItems,
      current: 0,
      total: matched.length,
    ));

    final int wishlistCount = wishlist.length;
    final ImportWriteResult write = await _writer.writeItems(
      collectionId: collection.id,
      candidates: <ImportCandidate>[
        for (final _MatchedGame m in matched) _candidate(m),
      ],
      onItem: (int processed, int total, int imported, int updated,
          String? label) {
        onProgress?.call(ImportProgress(
          stage: ImportStage.addingItems,
          current: processed,
          total: total,
          currentItem: label,
          imported: imported,
          updated: updated,
          wishlisted: wishlistCount,
        ));
      },
    );
    final Map<MediaType, int> wishlistedByType = await _writer.writeWishlist(
      entries: wishlist,
      tag: importTag,
    );

    // tracker_game_data is per (IGDB id, platform) and lives outside the
    // collection_items table, so it is batch-written after the items.
    await _trackerDao.upsertGameDataBatch(<TrackerGameData>[
      for (final _MatchedGame m in matched) _trackerGameData(m.game.id, m.ra),
    ]);

    onProgress?.call(ImportProgress(
      stage: ImportStage.completed,
      current: games.length,
      total: games.length,
      imported: sumByType(write.importedByType),
      updated: sumByType(write.updatedByType),
      wishlisted: sumByType(wishlistedByType),
    ));

    _log.info(
      'RA import done: ${sumByType(write.importedByType)} added, '
      '${sumByType(write.updatedByType)} updated, '
      '${sumByType(wishlistedByType)} newly wishlisted out of ${games.length}',
    );

    return UniversalImportResult(
      sourceName: 'RetroAchievements',
      success: true,
      collection: collection,
      importedByType: write.importedByType,
      updatedByType: write.updatedByType,
      wishlistedByType: wishlistedByType,
      skipped: write.skipped,
    );
  }

  ImportCandidate _candidate(_MatchedGame m) {
    return ImportCandidate(
      mediaType: MediaType.game,
      externalId: m.game.id,
      platformId: m.platformId,
      label: m.ra.title,
      insertRow: _insertRow(m),
      changedFields: (CollectionItem existing) => _changedFields(m, existing),
    );
  }

  /// New-item columns: the RA status (or `notStarted`) with the dates the
  /// transition implies, then the RA last-played / award dates stamped on top.
  Map<String, dynamic> _insertRow(_MatchedGame m) {
    final ItemStatus base = m.ra.itemStatus ?? ItemStatus.notStarted;
    final Map<String, dynamic> row = <String, dynamic>{
      'media_type': MediaType.game.value,
      'external_id': m.game.id,
      'platform_id': m.platformId,
      'status': base.value,
    };
    if (m.ra.itemStatus != null) {
      final StatusDatesUpdate dates = computeDatesForStatus(
        newStatus: m.ra.itemStatus!,
        currentStartedAt: null,
        currentCompletedAt: null,
        now: DateTime.now(),
      );
      row['started_at'] = dates.clearStartedAt ? null : epochSeconds(dates.startedAt);
      row['completed_at'] =
          dates.clearCompletedAt ? null : epochSeconds(dates.completedAt);
      row['last_activity_at'] = epochSeconds(dates.lastActivityAt);
    }
    if (m.ra.lastPlayedAt != null) {
      row['last_activity_at'] = epochSeconds(m.ra.lastPlayedAt);
    }
    if (m.completedAt != null) {
      row['completed_at'] = epochSeconds(m.completedAt);
    }
    return row;
  }

  /// Re-sync of an existing item. RA is the authoritative progress source, so
  /// status downgrades are allowed (mirrors the old `syncRaDataToCollectionItem`).
  Map<String, dynamic> _changedFields(_MatchedGame m, CollectionItem existing) {
    final ItemStatus? raStatus = m.ra.itemStatus;
    final DateTime? lastActivity = m.ra.lastPlayedAt;
    final DateTime? completedAt = m.completedAt;
    if (raStatus == null && completedAt == null && lastActivity == null) {
      return const <String, dynamic>{};
    }

    final Map<String, dynamic> fields = <String, dynamic>{};
    final ItemStatus? effectiveStatus = raStatus == null
        ? null
        : mergeExternalStatus(
            currentStatus: existing.status,
            externalStatus: raStatus,
            allowDowngrade: true,
          );
    if (effectiveStatus != null) {
      final StatusDatesUpdate dates = computeDatesForStatus(
        newStatus: effectiveStatus,
        currentStartedAt: existing.startedAt,
        currentCompletedAt: existing.completedAt,
        now: DateTime.now(),
      );
      fields['status'] = dates.status.value;
      fields['started_at'] = dates.clearStartedAt ? null : epochSeconds(dates.startedAt);
      fields['completed_at'] =
          dates.clearCompletedAt ? null : epochSeconds(dates.completedAt);
      fields['last_activity_at'] = epochSeconds(dates.lastActivityAt);
    }
    if (lastActivity != null) {
      fields['last_activity_at'] = epochSeconds(lastActivity);
    }
    if (completedAt != null) {
      fields['completed_at'] = epochSeconds(completedAt);
    }
    return fields;
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
      final List<RaGameProgress> batch = games.sublist(batchStart, batchEnd);

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

      // Rate limiting: pause every 4 batches.
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
      // findIgdbGame issues 1-2 requests; pause after each one.
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    return results;
  }

  String _wishlistNote(RaGameProgress raGame) =>
      'From RetroAchievements • '
      '${raGame.numAwarded}/${raGame.maxPossible} achievements'
      '${raGame.highestAwardKind != null ? ' • ${raGame.highestAwardKind}' : ''}';

  /// Builds the per-platform tracker_game_data row for an RA game. The IGDB
  /// platform id is derived from RA's console id so PS2 and GameCube installs
  /// of the same IGDB title don't overwrite each other.
  TrackerGameData _trackerGameData(int igdbId, RaGameProgress raGame) {
    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final int? awardTimestamp = raGame.highestAwardDate != null
        ? raGame.highestAwardDate!.millisecondsSinceEpoch ~/ 1000
        : null;
    final int? lastPlayedTimestamp = raGame.lastPlayedAt != null
        ? raGame.lastPlayedAt!.millisecondsSinceEpoch ~/ 1000
        : null;
    final int? platformId =
        RaToIgdbMapper.primaryIgdbPlatformId(raGame.consoleId);

    return TrackerGameData(
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
    );
  }
}
