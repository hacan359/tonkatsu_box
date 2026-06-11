import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../shared/models/collection_item.dart';
import '../../shared/models/collection.dart';
import '../../shared/models/game.dart';
import '../../shared/models/item_status.dart';
import '../../shared/models/item_status_logic.dart';
import '../../shared/models/media_type.dart';
import '../../shared/models/universal_import_result.dart';
import '../../shared/models/wishlist_item.dart';
import '../../shared/models/wishlist_tag.dart';
import '../api/igdb_api.dart';
import '../api/steam_api.dart';
import '../database/database_service.dart';

enum SteamImportStage {
  fetchingLibrary,

  /// IGDB lookup and writing to the collection.
  matchingGames,

  completed,
}

class SteamImportProgress {
  const SteamImportProgress({
    required this.stage,
    required this.current,
    required this.total,
    this.currentName,
    this.importedCount = 0,
    this.wishlistedCount = 0,
    this.updatedCount = 0,
  });

  final SteamImportStage stage;

  final int current;

  final int total;

  final String? currentName;

  final int importedCount;

  /// Games not found in IGDB, added to the wishlist instead.
  final int wishlistedCount;

  /// Duplicates whose data was refreshed.
  final int updatedCount;

  /// Progress fraction (0.0–1.0).
  double get progress => total > 0 ? current / total : 0;
}

class SteamImportResult {
  const SteamImportResult({
    required this.imported,
    required this.wishlisted,
    required this.updated,
    required this.total,
    required this.collectionId,
  });

  final int imported;

  /// Games not found in IGDB, added to the wishlist instead.
  final int wishlisted;

  /// Duplicates whose data was refreshed.
  final int updated;

  /// Library size after DLC filtering.
  final int total;

  final int collectionId;
}

final Provider<SteamImportService> steamImportServiceProvider =
    Provider<SteamImportService>((Ref ref) {
  return SteamImportService(
    steamApi: ref.watch(steamApiProvider),
    igdbApi: ref.watch(igdbApiProvider),
    database: ref.watch(databaseServiceProvider),
  );
});

class SteamImportService {
  SteamImportService({
    required SteamApi steamApi,
    required IgdbApi igdbApi,
    required DatabaseService database,
  })  : _steamApi = steamApi,
        _igdbApi = igdbApi,
        _db = database;

  static final Logger _log = Logger('SteamImportService');

  /// IGDB platform id for "PC (Microsoft Windows)".
  static const int _pcPlatformId = 6;

  final SteamApi _steamApi;
  final IgdbApi _igdbApi;
  final DatabaseService _db;

  /// Either [collectionId] or [createCollection] must be set; the callback
  /// runs only after the library loads (no empty collection on API failure).
  Future<SteamImportResult> importLibrary({
    required String apiKey,
    required String steamId,
    int? collectionId,
    Future<int> Function()? createCollection,
    required void Function(SteamImportProgress) onProgress,
  }) async {
    if (collectionId == null && createCollection == null) {
      throw ArgumentError(
        'Either collectionId or createCollection must be provided',
      );
    }

    onProgress(const SteamImportProgress(
      stage: SteamImportStage.fetchingLibrary,
      current: 0,
      total: 0,
    ));

    final List<SteamOwnedGame> library = await _steamApi.getOwnedGames(
      apiKey: apiKey,
      steamId: steamId,
    );

    // Drop DLC/soundtracks
    final List<SteamOwnedGame> games = library
        .where((SteamOwnedGame g) => !g.shouldSkip)
        .toList();

    final int filteredCount = library.length - games.length;
    if (filteredCount > 0) {
      _log.info('Filtered $filteredCount DLC/soundtracks from '
          '${library.length} total');
    }

    final String importTag = buildImportTag('Steam');

    if (games.isEmpty) {
      throw const SteamApiException('No games found in this Steam library');
    }

    // Create the collection only after the library loaded successfully
    final int targetCollectionId =
        collectionId ?? await createCollection!();

    // Batch-resolve all games in IGDB by Steam App ID (1-2 requests)
    onProgress(SteamImportProgress(
      stage: SteamImportStage.matchingGames,
      current: 0,
      total: games.length,
    ));

    final Map<String, Game> igdbMatches = await _igdbApi.lookupSteamGames(
      games.map((SteamOwnedGame g) => g.appId.toString()).toList(),
    );

    _log.info('IGDB matched ${igdbMatches.length}/${games.length} games');

    int imported = 0;
    int wishlisted = 0;
    int updated = 0;

    for (int i = 0; i < games.length; i++) {
      final SteamOwnedGame steamGame = games[i];

      onProgress(SteamImportProgress(
        stage: SteamImportStage.matchingGames,
        current: i + 1,
        total: games.length,
        currentName: steamGame.name,
        importedCount: imported,
        wishlistedCount: wishlisted,
        updatedCount: updated,
      ));

      final Game? match = igdbMatches[steamGame.appId.toString()];

      if (match == null) {
        await _addToWishlist(steamGame, importTag);
        wishlisted++;
        _log.fine('Not found in IGDB, added to wishlist: ${steamGame.name}');
        continue;
      }

      final CollectionItem? existing = await _db.findCollectionItem(
        collectionId: targetCollectionId,
        mediaType: MediaType.game,
        externalId: match.id,
      );
      if (existing != null) {
        await _updateExistingItem(existing, steamGame);
        updated++;
        continue;
      }

      await _db.gameDao.upsertGame(match);

      final ItemStatus status = steamGame.playtimeMinutes > 0
          ? ItemStatus.inProgress
          : ItemStatus.notStarted;

      final int? itemId = await _db.addItemToCollection(
        collectionId: targetCollectionId,
        mediaType: MediaType.game,
        externalId: match.id,
        platformId: _pcPlatformId,
        status: status,
      );

      if (itemId != null && steamGame.playtimeMinutes > 0) {
        await _db.updateItemTimeSpent(itemId, steamGame.playtimeMinutes);

        if (steamGame.lastPlayed != null) {
          await _db.updateItemActivityDates(
            itemId,
            lastActivityAt: steamGame.lastPlayed,
          );
        }
      }

      imported++;
    }

    _log.info('Steam import complete: $imported imported, '
        '$wishlisted wishlisted, $updated updated');

    onProgress(SteamImportProgress(
      stage: SteamImportStage.completed,
      current: games.length,
      total: games.length,
      importedCount: imported,
      wishlistedCount: wishlisted,
      updatedCount: updated,
    ));

    return SteamImportResult(
      imported: imported,
      wishlisted: wishlisted,
      updated: updated,
      total: games.length,
      collectionId: targetCollectionId,
    );
  }

  /// Status is merged via [mergeExternalStatus] (no downgrades, local
  /// `dropped` preserved); refreshes time spent and the last-played date.
  Future<void> _updateExistingItem(
    CollectionItem existing,
    SteamOwnedGame steamGame,
  ) async {
    // Playtime on Steam means "in progress"; mergeExternalStatus won't
    // downgrade completed or touch dropped.
    if (steamGame.playtimeMinutes > 0) {
      final ItemStatus? newStatus = mergeExternalStatus(
        currentStatus: existing.status,
        externalStatus: ItemStatus.inProgress,
      );
      if (newStatus != null) {
        await _db.updateItemStatus(
          existing.id,
          newStatus,
          mediaType: MediaType.game,
        );
      }
    }

    if (steamGame.playtimeMinutes > 0 &&
        steamGame.playtimeMinutes != existing.timeSpentMinutes) {
      await _db.updateItemTimeSpent(existing.id, steamGame.playtimeMinutes);
    }

    if (steamGame.lastPlayed != null) {
      await _db.updateItemActivityDates(
        existing.id,
        lastActivityAt: steamGame.lastPlayed,
      );
    }
  }

  /// When an unresolved wishlist row with the same name already exists, it is
  /// reused instead of creating a duplicate.
  Future<void> _addToWishlist(SteamOwnedGame steamGame, String importTag) async {
    final WishlistItem? existing =
        await _db.wishlistDao.findUnresolvedByText(steamGame.name);

    if (existing != null) {
      // Stamp the current import tag only when the row was previously
      // untagged — preserve any tag the user (or an earlier import) set.
      if (existing.tag == null) {
        await _db.wishlistDao.updateWishlistItem(
          existing.id,
          tag: importTag,
        );
      }
      return;
    }

    await _db.wishlistDao.addWishlistItem(
      text: steamGame.name,
      mediaTypeHint: MediaType.game,
      tag: importTag,
    );
  }
}

extension SteamImportResultToUniversal on SteamImportResult {
  UniversalImportResult toUniversal({Collection? collection}) {
    final Map<MediaType, int> importedByType = <MediaType, int>{};
    final Map<MediaType, int> wishlistedByType = <MediaType, int>{};
    final Map<MediaType, int> updatedByType = <MediaType, int>{};

    if (imported > 0) {
      importedByType[MediaType.game] = imported;
    }
    if (wishlisted > 0) {
      wishlistedByType[MediaType.game] = wishlisted;
    }
    if (updated > 0) {
      updatedByType[MediaType.game] = updated;
    }

    return UniversalImportResult(
      sourceName: 'Steam',
      success: true,
      collection: collection,
      collectionId: collectionId,
      importedByType: importedByType,
      wishlistedByType: wishlistedByType,
      updatedByType: updatedByType,
      skipped: (total - imported - wishlisted - updated).clamp(0, total),
    );
  }
}
