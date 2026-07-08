import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../../data/repositories/collection_repository.dart';
import '../../../../shared/models/collection.dart';
import '../../../../shared/models/collection_item.dart';
import '../../../../shared/models/custom_media.dart';
import '../../../../shared/models/item_status.dart';
import '../../../../shared/models/item_status_logic.dart';
import '../../../../shared/models/media_type.dart';
import '../../../../shared/models/platform.dart';
import '../../../../shared/models/tag.dart';
import '../../../../shared/models/universal_import_result.dart';
import '../../../database/database_service.dart';
import '../../../services/image_cache_service.dart';
import '../../../services/import_service.dart';
import '../../import_columns.dart';
import 'custom_card_entry.dart';
import 'custom_cards_parser.dart';

final Provider<CustomCardsImportService> customCardsImportServiceProvider =
    Provider<CustomCardsImportService>((Ref ref) {
  return CustomCardsImportService(
    database: ref.watch(databaseServiceProvider),
    repository: ref.watch(collectionRepositoryProvider),
    imageCache: ref.watch(imageCacheServiceProvider),
  );
});

/// Imports user-authored custom cards from a JSON/CSV file.
///
/// Unlike the one-shot [ImportSource] adapters this runs in two phases driven
/// by the preview UI: [parseFile] validates the whole file without touching
/// the database, then [importSelected] writes only the rows the user kept.
/// Covers are downloaded after the rows are written, only for imported cards.
class CustomCardsImportService {
  CustomCardsImportService({
    required DatabaseService database,
    required CollectionRepository repository,
    required ImageCacheService imageCache,
  })  : _db = database,
        _repository = repository,
        _imageCache = imageCache;

  static final Logger _log = Logger('CustomCardsImportService');

  static const String sourceName = 'Custom cards';

  final DatabaseService _db;
  final CollectionRepository _repository;
  final ImageCacheService _imageCache;

  /// Parses and validates [filePath] without writing anything.
  Future<List<CustomCardRow>> parseFile(String filePath) async {
    final Uint8List bytes = await File(filePath).readAsBytes();
    return const CustomCardsParser()
        .parseBytes(bytes, fileName: filePath);
  }

  /// Indexes of rows that duplicate an item already in the target collection
  /// (matched by title, case-insensitively) or an earlier row of the same
  /// file. For a new collection ([collectionId] == null) only in-file
  /// duplicates are reported.
  Future<Set<int>> duplicateRowIndexes({
    required int? collectionId,
    required List<CustomCardRow> rows,
  }) async {
    final Set<String> seen = <String>{};
    if (collectionId != null) {
      final List<CollectionItem> existing =
          await _repository.getItemsWithData(collectionId);
      for (final CollectionItem item in existing) {
        seen.add(item.itemName.trim().toLowerCase());
      }
    }

    final Set<int> duplicates = <int>{};
    for (final CustomCardRow row in rows) {
      final CustomCardEntry? entry = row.entry;
      if (entry == null) continue;
      if (!seen.add(entry.title.trim().toLowerCase())) {
        duplicates.add(row.index);
      }
    }
    return duplicates;
  }

  /// Writes [entries] as custom cards into the target collection (created as
  /// "Custom Import" when [collectionId] is null), then downloads the covers
  /// of the written cards.
  Future<UniversalImportResult> importSelected({
    required int? collectionId,
    required String author,
    required List<CustomCardEntry> entries,
    ImportProgressCallback? onProgress,
  }) async {
    try {
      if (entries.isEmpty) {
        return const UniversalImportResult.failure(
          sourceName: sourceName,
          error: 'Nothing selected to import',
        );
      }

      onProgress?.call(const ImportProgress(
        stage: ImportStage.creatingCollection,
        current: 0,
        total: 0,
      ));

      final Collection? collection = collectionId != null
          ? await _repository.getById(collectionId)
          : await _repository.create(name: 'Custom Import', author: author);
      if (collection == null) {
        return const UniversalImportResult.failure(
          sourceName: sourceName,
          error: 'Collection not found',
        );
      }

      final Map<String, Platform> platformLookup = await _platformLookup();
      final List<CustomMedia> cards = <CustomMedia>[
        for (final CustomCardEntry entry in entries)
          _card(entry, platformLookup),
      ];

      onProgress?.call(ImportProgress(
        stage: ImportStage.addingItems,
        current: 0,
        total: entries.length,
      ));

      final List<int> customIds = await _db.customMediaDao.createAll(cards);
      final List<Map<String, dynamic>> rows = <Map<String, dynamic>>[];
      for (int i = 0; i < entries.length; i++) {
        rows.add(_insertRow(entries[i], customIds[i]));
      }
      final int inserted =
          await _repository.addItemsBatch(collection.id, rows);
      await _applyTags(collection.id, entries, customIds);

      onProgress?.call(ImportProgress(
        stage: ImportStage.addingItems,
        current: entries.length,
        total: entries.length,
        imported: inserted,
      ));

      final List<String> errors =
          await _downloadCovers(entries, customIds, inserted, onProgress);

      onProgress?.call(ImportProgress(
        stage: ImportStage.completed,
        current: 1,
        total: 1,
        imported: inserted,
      ));

      return UniversalImportResult(
        sourceName: sourceName,
        success: true,
        collection: collection,
        importedByType: <MediaType, int>{MediaType.custom: inserted},
        skipped: entries.length - inserted,
        errors: errors,
      );
    } on Exception catch (e, stack) {
      _log.severe('Custom cards import failed', e, stack);
      return UniversalImportResult.failure(
        sourceName: sourceName,
        error: 'Import failed: $e',
      );
    }
  }

  /// Platform catalog keyed by lower-cased abbreviation and full name.
  Future<Map<String, Platform>> _platformLookup() async {
    final List<Platform> platforms = await _db.gameDao.getAllPlatforms();
    final Map<String, Platform> lookup = <String, Platform>{};
    for (final Platform platform in platforms) {
      lookup[platform.name.trim().toLowerCase()] = platform;
      final String? abbreviation = platform.abbreviation?.trim().toLowerCase();
      if (abbreviation != null && abbreviation.isNotEmpty) {
        lookup[abbreviation] = platform;
      }
    }
    return lookup;
  }

  CustomMedia _card(
    CustomCardEntry entry,
    Map<String, Platform> platformLookup,
  ) {
    final Platform? matched = entry.platform == null
        ? null
        : platformLookup[entry.platform!.trim().toLowerCase()];
    // The platform FK only exists for custom games (per the CustomMedia
    // contract); other types keep the text as a free-form display name.
    final bool isGame = entry.type == MediaType.game;
    return CustomMedia(
      id: 0,
      title: entry.title,
      displayType: entry.type,
      altTitle: entry.altTitle,
      description: entry.description,
      coverUrl: entry.coverUrl,
      year: entry.year,
      genres: entry.genres,
      platformName: matched?.displayName ?? entry.platform,
      platformId: isGame ? matched?.id : null,
      format: entry.format,
      unitTotal: entry.unitTotal,
      unitGroupTotal: entry.unitGroupTotal,
      externalUrl: entry.link,
    );
  }

  Map<String, dynamic> _insertRow(CustomCardEntry entry, int customId) {
    final ItemStatus status = entry.status ?? ItemStatus.notStarted;
    final Map<String, dynamic> row = <String, dynamic>{
      'media_type': MediaType.custom.value,
      'external_id': customId,
      'status': status.value,
      if (entry.rating != null) 'user_rating': entry.rating,
      if (entry.comment != null) 'user_comment': entry.comment,
      if (entry.rewatchCount != null) 'rewatch_count': entry.rewatchCount,
      if (entry.timeSpentMinutes != null)
        'time_spent_minutes': entry.timeSpentMinutes,
      if (entry.favorite != null) 'is_favorite': entry.favorite! ? 1 : 0,
      if (entry.currentEpisode != null)
        'current_episode': entry.currentEpisode,
      if (entry.currentSeason != null) 'current_season': entry.currentSeason,
    };

    if (status != ItemStatus.notStarted) {
      final StatusDatesUpdate dates = computeDatesForStatus(
        newStatus: status,
        currentStartedAt: null,
        currentCompletedAt: null,
        now: DateTime.now(),
      );
      row['started_at'] = epochSeconds(dates.startedAt);
      row['completed_at'] = epochSeconds(dates.completedAt);
      row['last_activity_at'] = epochSeconds(dates.lastActivityAt);
    }

    // Explicit file dates win over the ones the status implies.
    if (entry.startedAt != null) {
      row['started_at'] = epochSeconds(entry.startedAt);
    }
    if (entry.completedAt != null) {
      row['completed_at'] = epochSeconds(entry.completedAt);
    }
    if (entry.completedAt != null || entry.startedAt != null) {
      row['last_activity_at'] =
          epochSeconds(entry.completedAt ?? entry.startedAt);
    }

    return row;
  }

  /// Assigns global tags to the written items, creating tags that don't exist
  /// yet (matched by name, case-insensitively).
  Future<void> _applyTags(
    int collectionId,
    List<CustomCardEntry> entries,
    List<int> customIds,
  ) async {
    if (!entries.any((CustomCardEntry e) => e.tags.isNotEmpty)) return;

    final List<Tag> existing = await _db.globalTagDao.getAll();
    final Map<String, int> tagIdByName = <String, int>{
      for (final Tag tag in existing) tag.name.trim().toLowerCase(): tag.id,
    };
    for (final CustomCardEntry entry in entries) {
      for (final String name in entry.tags) {
        final String key = name.toLowerCase();
        if (tagIdByName.containsKey(key)) continue;
        final Tag created = await _db.globalTagDao.create(name);
        tagIdByName[key] = created.id;
      }
    }

    // Batch insert reports no row ids, so map items back via the unique
    // (custom) external_id.
    final Map<int, int> itemIdByExternal = <int, int>{
      for (final CollectionItem item
          in await _repository.getItemsWithData(collectionId))
        if (item.mediaType == MediaType.custom) item.externalId: item.id,
    };
    for (int i = 0; i < entries.length; i++) {
      if (entries[i].tags.isEmpty) continue;
      final int? itemId = itemIdByExternal[customIds[i]];
      if (itemId == null) continue;
      await _db.globalTagDao.setItemTags(itemId, <int>{
        for (final String name in entries[i].tags)
          tagIdByName[name.toLowerCase()]!,
      });
    }
  }

  /// Downloads the covers of the written cards; returns per-card error notes
  /// for covers that could not be fetched (the card keeps its remote URL, so
  /// the UI can still resolve it later).
  Future<List<String>> _downloadCovers(
    List<CustomCardEntry> entries,
    List<int> customIds,
    int imported,
    ImportProgressCallback? onProgress,
  ) async {
    final List<(int, CustomCardEntry)> withCovers = <(int, CustomCardEntry)>[
      for (int i = 0; i < entries.length; i++)
        if (entries[i].coverUrl != null) (customIds[i], entries[i]),
    ];
    if (withCovers.isEmpty) return const <String>[];

    final List<String> errors = <String>[];
    for (int i = 0; i < withCovers.length; i++) {
      final (int customId, CustomCardEntry entry) = withCovers[i];
      onProgress?.call(ImportProgress(
        stage: ImportStage.importingImages,
        current: i,
        total: withCovers.length,
        currentItem: entry.title,
        imported: imported,
      ));
      final bool ok = await _imageCache.downloadImage(
        type: ImageType.customCover,
        imageId: customId.toString(),
        remoteUrl: entry.coverUrl!,
      );
      if (!ok) {
        errors.add('Cover download failed: ${entry.title}');
      }
    }
    return errors;
  }
}
