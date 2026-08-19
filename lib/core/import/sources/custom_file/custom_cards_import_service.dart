import 'dart:typed_data';

import 'package:core/database/dao/global_tag_dao.dart';
import 'package:core/models/collection.dart';
import 'package:core/models/collection_item.dart';
import 'package:core/models/custom_media.dart';
import 'package:core/models/item_status.dart';
import 'package:core/models/item_status_logic.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/platform.dart';
import 'package:core/models/universal_import_result.dart';
import 'package:core/utils/cover_image_id.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../../data/repositories/collection_repository.dart';
import '../../../database/database_service.dart';
import '../../../services/image_cache_service.dart';
import '../../import_columns.dart';
import '../../import_progress.dart';
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

/// Two phases driven by the preview UI: [parseFile] validates without
/// touching the database, [importSelected] writes only the rows the user kept.
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

  /// Parses and validates the picked file without writing anything. The
  /// bytes are read at pick time — the browser never has a path.
  List<CustomCardRow> parseFile(Uint8List bytes, {required String fileName}) {
    return const CustomCardsParser().parseBytes(bytes, fileName: fileName);
  }

  /// Rows duplicating a collection item or an earlier row, matched by title
  /// case-insensitively; a new collection reports only in-file duplicates.
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

  /// Writes [entries] into the target collection ("Custom Import" is created
  /// when [collectionId] is null), then downloads the written cards' covers.
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
      final List<int?> itemIds =
          await _repository.addItemsBatchReturningIds(collection.id, rows);
      final int inserted = itemIds.whereType<int>().length;
      await _applyTags(entries, itemIds);

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
        detail: stack.toString(),
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

  /// Missing tags are created, matched by name case-insensitively. [itemIds]
  /// is aligned with [entries]; `null` marks rows skipped as duplicates.
  Future<void> _applyTags(
    List<CustomCardEntry> entries,
    List<int?> itemIds,
  ) async {
    if (!entries.any((CustomCardEntry e) => e.tags.isNotEmpty)) return;

    final Map<String, int> tagIdByName =
        await _db.globalTagDao.resolveOrCreateAll(<TagSeed>[
      for (final CustomCardEntry entry in entries)
        for (final String name in entry.tags)
          (name: name, color: null, textColor: null),
    ]);

    for (int i = 0; i < entries.length; i++) {
      final int? itemId = itemIds[i];
      if (itemId == null || entries[i].tags.isEmpty) continue;
      await _db.globalTagDao.setItemTags(itemId, <int>{
        for (final String name in entries[i].tags)
          tagIdByName[GlobalTagDao.nameKey(name)]!,
      });
    }
  }

  /// Returns per-card notes for covers that failed to download; the card
  /// keeps its remote URL, so the UI can still resolve it later.
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
        imageId: customCoverImageId(id: customId, coverUrl: entry.coverUrl),
        remoteUrl: entry.coverUrl!,
      );
      if (!ok) {
        errors.add('Cover download failed: ${entry.title}');
      }
    }
    return errors;
  }
}
