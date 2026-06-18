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
import '../../../../shared/models/universal_import_result.dart';
import '../../../../shared/models/wishlist_tag.dart';
import '../../../api/igdb_api.dart';
import '../../../api/steam_api.dart';
import '../../../database/database_service.dart';
import '../../../services/import_service.dart';
import '../../import_columns.dart';
import '../../import_source.dart';
import '../../import_writer.dart';

final Provider<SteamImportService> steamImportServiceProvider =
    Provider<SteamImportService>((Ref ref) {
  return SteamImportService(
    steamApi: ref.watch(steamApiProvider),
    igdbApi: ref.watch(igdbApiProvider),
    database: ref.watch(databaseServiceProvider),
    repository: ref.watch(collectionRepositoryProvider),
    wishlistRepository: ref.watch(wishlistRepositoryProvider),
  );
});

class SteamImportOptions extends ImportOptions {
  const SteamImportOptions({
    required this.apiKey,
    required this.steamId,
    required this.author,
    super.collectionId,
  });

  final String apiKey;
  final String steamId;

  /// Author for a freshly created collection (the user's display name).
  final String author;
}

/// Imports a Steam library into a collection on the shared import layer.
///
/// Owned games are resolved to IGDB by Steam App ID in one batch lookup (no
/// per-row search); unmatched titles fall back to the text wishlist. All writes
/// go through [ImportWriter] in batches.
class SteamImportService implements ImportSource {
  SteamImportService({
    required SteamApi steamApi,
    required IgdbApi igdbApi,
    required DatabaseService database,
    required CollectionRepository repository,
    required WishlistRepository wishlistRepository,
  })  : _steamApi = steamApi,
        _igdbApi = igdbApi,
        _db = database,
        _writer = ImportWriter(
          collections: repository,
          wishlist: wishlistRepository,
        );

  static final Logger _log = Logger('SteamImportService');

  /// IGDB platform id for "PC (Microsoft Windows)".
  static const int _pcPlatformId = 6;

  final SteamApi _steamApi;
  final IgdbApi _igdbApi;
  final DatabaseService _db;
  final ImportWriter _writer;

  @override
  String get displayName => 'Steam';

  @override
  Future<UniversalImportResult> import(
    covariant SteamImportOptions options, {
    ImportProgressCallback? onProgress,
  }) async {
    try {
      onProgress?.call(const ImportProgress(
        stage: ImportStage.fetchingGames,
        current: 0,
        total: 0,
      ));

      final List<SteamOwnedGame> library = await _steamApi.getOwnedGames(
        apiKey: options.apiKey,
        steamId: options.steamId,
      );

      final List<SteamOwnedGame> games =
          library.where((SteamOwnedGame g) => !g.shouldSkip).toList();
      final int filteredCount = library.length - games.length;
      if (filteredCount > 0) {
        _log.info('Filtered $filteredCount DLC/soundtracks from '
            '${library.length} total');
      }

      if (games.isEmpty) {
        return const UniversalImportResult.failure(
          sourceName: 'Steam',
          error: 'No games found in this Steam library',
        );
      }

      onProgress?.call(ImportProgress(
        stage: ImportStage.addingItems,
        current: 0,
        total: games.length,
        message: 'Matching ${games.length} games...',
      ));

      // One batch lookup by Steam App ID resolves the whole library.
      final Map<String, Game> igdbMatches = await _igdbApi.lookupSteamGames(
        games.map((SteamOwnedGame g) => g.appId.toString()).toList(),
      );
      _log.info('IGDB matched ${igdbMatches.length}/${games.length} games');

      final List<(SteamOwnedGame, Game)> matched = <(SteamOwnedGame, Game)>[];
      final List<SteamOwnedGame> unmatched = <SteamOwnedGame>[];
      for (final SteamOwnedGame game in games) {
        final Game? match = igdbMatches[game.appId.toString()];
        if (match == null) {
          unmatched.add(game);
        } else {
          matched.add((game, match));
        }
      }

      await _upsertGames(matched);

      // Create the collection only after the library loaded successfully, so a
      // failed fetch never leaves an empty collection behind.
      final Collection? collection = await _writer.resolveCollection(
        collectionId: options.collectionId,
        newCollectionName: 'Steam Library',
        author: options.author,
      );
      if (collection == null) {
        return const UniversalImportResult.failure(
          sourceName: 'Steam',
          error: 'Collection not found',
        );
      }

      final int wishlistCount = unmatched.length;
      final ImportWriteResult write = await _writer.writeItems(
        collectionId: collection.id,
        candidates: <ImportCandidate>[
          for (final (SteamOwnedGame, Game) pair in matched)
            _candidate(pair.$1, pair.$2),
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
        entries: <WishlistCandidate>[
          for (final SteamOwnedGame game in unmatched)
            WishlistCandidate(text: game.name, mediaType: MediaType.game),
        ],
        tag: buildImportTag('Steam'),
      );

      onProgress?.call(ImportProgress(
        stage: ImportStage.completed,
        current: 1,
        total: 1,
        imported: write.importedByType[MediaType.game] ?? 0,
        updated: write.updatedByType[MediaType.game] ?? 0,
        wishlisted: wishlistedByType[MediaType.game] ?? 0,
      ));

      return UniversalImportResult(
        sourceName: 'Steam',
        success: true,
        collection: collection,
        importedByType: write.importedByType,
        updatedByType: write.updatedByType,
        wishlistedByType: wishlistedByType,
        skipped: write.skipped,
      );
    } on SteamApiException catch (e) {
      return UniversalImportResult.failure(
        sourceName: 'Steam',
        error: e.message,
      );
    } on Exception catch (e) {
      return UniversalImportResult.failure(
        sourceName: 'Steam',
        error: 'Import failed: $e',
      );
    }
  }

  /// Batch-upserts the matched games into the cache, deduped by IGDB id.
  Future<void> _upsertGames(List<(SteamOwnedGame, Game)> matched) async {
    final Map<int, Game> games = <int, Game>{};
    for (final (SteamOwnedGame, Game) pair in matched) {
      games[pair.$2.id] = pair.$2;
    }
    if (games.isNotEmpty) {
      await _db.gameDao.upsertGames(games.values.toList());
    }
  }

  ImportCandidate _candidate(SteamOwnedGame steamGame, Game match) {
    final ItemStatus status = steamGame.playtimeMinutes > 0
        ? ItemStatus.inProgress
        : ItemStatus.notStarted;
    return ImportCandidate(
      mediaType: MediaType.game,
      externalId: match.id,
      platformId: _pcPlatformId,
      label: steamGame.name,
      insertRow: _insertRow(steamGame, match, status),
      changedFields: (CollectionItem existing) =>
          _changedFields(steamGame, existing),
    );
  }

  Map<String, dynamic> _insertRow(
    SteamOwnedGame game,
    Game match,
    ItemStatus status,
  ) {
    final int? lastPlayed = (game.playtimeMinutes > 0 && game.lastPlayed != null)
        ? game.lastPlayed!.millisecondsSinceEpoch ~/ 1000
        : null;
    return <String, dynamic>{
      'media_type': MediaType.game.value,
      'external_id': match.id,
      'platform_id': _pcPlatformId,
      'status': status.value,
      if (game.playtimeMinutes > 0) 'time_spent_minutes': game.playtimeMinutes,
      'last_activity_at': ?lastPlayed,
    };
  }

  /// Re-sync policy: bump the status toward "in progress" without downgrading
  /// (local `completed` / `dropped` win), refresh play time when it changed,
  /// and stamp the Steam last-played date as the activity date.
  Map<String, dynamic> _changedFields(
    SteamOwnedGame game,
    CollectionItem existing,
  ) {
    final Map<String, dynamic> fields = <String, dynamic>{};

    if (game.playtimeMinutes > 0) {
      final ItemStatus? newStatus = mergeExternalStatus(
        currentStatus: existing.status,
        externalStatus: ItemStatus.inProgress,
      );
      if (newStatus != null) {
        fields.addAll(statusDateColumns(newStatus, existing));
      }
      if (game.playtimeMinutes != existing.timeSpentMinutes) {
        fields['time_spent_minutes'] = game.playtimeMinutes;
      }
    }

    if (game.lastPlayed != null) {
      fields['last_activity_at'] = epochSeconds(game.lastPlayed);
    }

    return fields;
  }
}
