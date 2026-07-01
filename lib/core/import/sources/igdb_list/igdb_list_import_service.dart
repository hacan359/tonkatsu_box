import 'dart:io';
import 'dart:typed_data';

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
import '../../../database/database_service.dart';
import '../../../services/import_service.dart';
import '../../import_columns.dart';
import '../../import_source.dart';
import '../../import_writer.dart';
import 'igdb_list_csv_parser.dart';

final Provider<IgdbListImportService> igdbListImportServiceProvider =
    Provider<IgdbListImportService>((Ref ref) {
  return IgdbListImportService(
    igdbApi: ref.watch(igdbApiProvider),
    database: ref.watch(databaseServiceProvider),
    repository: ref.watch(collectionRepositoryProvider),
    wishlistRepository: ref.watch(wishlistRepositoryProvider),
  );
});

class IgdbListImportOptions extends ImportOptions {
  const IgdbListImportOptions({
    required this.filePath,
    required this.author,
    required this.platformId,
    this.status = ItemStatus.notStarted,
    this.wishlistReason,
    super.collectionId,
  });

  final String filePath;
  final String author;

  /// Status applied to every matched game: the export carries no per-game
  /// status, only which list it came from.
  final ItemStatus status;

  /// The CSV lists all of a game's release platforms, not the one the user
  /// owns, so the platform is picked by hand and required — without it every
  /// item would render as "unknown platform".
  final int platformId;

  final String? wishlistReason;
}

/// Imports a game list exported from IGDB (CSV) into a collection. Every row
/// carries the IGDB game id, so matching is one batched id lookup with no
/// title search; ids IGDB no longer returns fall back to the text wishlist.
class IgdbListImportService implements ImportSource {
  IgdbListImportService({
    required IgdbApi igdbApi,
    required DatabaseService database,
    required CollectionRepository repository,
    required WishlistRepository wishlistRepository,
  })  : _igdbApi = igdbApi,
        _db = database,
        _writer = ImportWriter(
          collections: repository,
          wishlist: wishlistRepository,
        );

  static final Logger _log = Logger('IgdbListImportService');

  final IgdbApi _igdbApi;
  final DatabaseService _db;
  final ImportWriter _writer;

  @override
  String get displayName => 'IGDB';

  @override
  Future<UniversalImportResult> import(
    covariant IgdbListImportOptions options, {
    ImportProgressCallback? onProgress,
  }) async {
    try {
      onProgress?.call(const ImportProgress(
        stage: ImportStage.reading,
        current: 0,
        total: 0,
      ));

      final Uint8List bytes = await File(options.filePath).readAsBytes();
      final List<IgdbListEntry> entries =
          const IgdbListCsvParser().parseBytes(bytes);

      if (entries.isEmpty) {
        return const UniversalImportResult.failure(
          sourceName: 'IGDB',
          error: 'No games found in this file',
        );
      }

      // Dedup ids; keep the first name seen as the wishlist fallback label.
      final Map<int, String> nameById = <int, String>{};
      for (final IgdbListEntry entry in entries) {
        nameById.putIfAbsent(entry.id, () => entry.name);
      }

      onProgress?.call(ImportProgress(
        stage: ImportStage.fetchingGames,
        current: 0,
        total: nameById.length,
        message: 'Matching ${nameById.length} games...',
      ));

      final List<Game> games =
          await _igdbApi.getGamesByIds(nameById.keys.toList());
      final Map<int, Game> gamesById = <int, Game>{
        for (final Game game in games) game.id: game,
      };
      _log.info('IGDB matched ${gamesById.length}/${nameById.length} games');

      final List<Game> matched = <Game>[];
      final List<String> unmatched = <String>[];
      for (final MapEntry<int, String> entry in nameById.entries) {
        final Game? game = gamesById[entry.key];
        if (game == null) {
          unmatched.add(entry.value);
        } else {
          matched.add(game);
        }
      }

      await _upsertGames(matched);

      // Created only after a successful parse, so a failure leaves no empty
      // collection behind.
      final Collection? collection = await _writer.resolveCollection(
        collectionId: options.collectionId,
        newCollectionName: 'IGDB Import',
        author: options.author,
      );
      if (collection == null) {
        return const UniversalImportResult.failure(
          sourceName: 'IGDB',
          error: 'Collection not found',
        );
      }

      final int wishlistCount = unmatched.length;
      final ImportWriteResult write = await _writer.writeItems(
        collectionId: collection.id,
        candidates: <ImportCandidate>[
          for (final Game game in matched) _candidate(game, options),
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
          for (final String name in unmatched)
            WishlistCandidate(
              text: name,
              mediaType: MediaType.game,
              note: options.wishlistReason,
            ),
        ],
        tag: buildImportTag('IGDB'),
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
        sourceName: 'IGDB',
        success: true,
        collection: collection,
        importedByType: write.importedByType,
        updatedByType: write.updatedByType,
        wishlistedByType: wishlistedByType,
        skipped: write.skipped,
      );
    } on IgdbApiException catch (e) {
      return UniversalImportResult.failure(
        sourceName: 'IGDB',
        error: e.message,
      );
    } on IgdbListParseException catch (e) {
      return UniversalImportResult.failure(
        sourceName: 'IGDB',
        error: e.message,
      );
    } on Exception catch (e) {
      return UniversalImportResult.failure(
        sourceName: 'IGDB',
        error: 'Import failed: $e',
      );
    }
  }

  Future<void> _upsertGames(List<Game> matched) async {
    if (matched.isEmpty) return;
    await _db.gameDao.upsertGames(matched);
  }

  ImportCandidate _candidate(Game game, IgdbListImportOptions options) {
    return ImportCandidate(
      mediaType: MediaType.game,
      externalId: game.id,
      platformId: options.platformId,
      label: game.name,
      insertRow: _insertRow(game, options),
      changedFields: (CollectionItem existing) =>
          _changedFields(options, existing),
    );
  }

  Map<String, dynamic> _insertRow(Game game, IgdbListImportOptions options) {
    final Map<String, dynamic> row = <String, dynamic>{
      'media_type': MediaType.game.value,
      'external_id': game.id,
      'platform_id': options.platformId,
      'status': options.status.value,
    };

    if (options.status != ItemStatus.notStarted) {
      final StatusDatesUpdate dates = computeDatesForStatus(
        newStatus: options.status,
        currentStartedAt: null,
        currentCompletedAt: null,
        now: DateTime.now(),
      );
      row['started_at'] = epochSeconds(dates.startedAt);
      row['completed_at'] = epochSeconds(dates.completedAt);
      row['last_activity_at'] = epochSeconds(dates.lastActivityAt);
    }

    return row;
  }

  /// Re-sync policy: an "unset" import never disturbs an existing item; a
  /// chosen status is merged upward (local `completed` / `dropped` win) without
  /// downgrading the user's own decision.
  Map<String, dynamic> _changedFields(
    IgdbListImportOptions options,
    CollectionItem existing,
  ) {
    if (options.status == ItemStatus.notStarted) {
      return const <String, dynamic>{};
    }
    final ItemStatus? merged = mergeExternalStatus(
      currentStatus: existing.status,
      externalStatus: options.status,
    );
    if (merged == null) return const <String, dynamic>{};
    return statusDateColumns(merged, existing);
  }
}
