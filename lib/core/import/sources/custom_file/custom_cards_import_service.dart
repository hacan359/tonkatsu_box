import 'dart:typed_data';

import 'package:core/database/dao/global_tag_dao.dart';
import 'package:core/models/collection.dart';
import 'package:core/models/collection_item.dart';
import 'package:core/models/custom_media.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/item_status.dart';
import 'package:core/models/item_status_logic.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/platform.dart';
import 'package:core/models/universal_import_result.dart';
import 'package:core/utils/cover_image_id.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../../data/repositories/collection_repository.dart';
import '../../../../data/repositories/wishlist_repository.dart';
import '../../../database/database_service.dart';
import '../../../services/image_cache_service.dart';
import '../../import_columns.dart';
import '../../import_progress.dart';
import '../../import_writer.dart';
import '../../media_cache_writer.dart';
import '../../title_lookup/lookup_candidate.dart';
import '../../title_lookup/lookup_chains.dart';
import '../../title_lookup/title_resolver.dart';
import 'custom_card_entry.dart';
import 'custom_cards_parser.dart';

final Provider<CustomCardsImportService> customCardsImportServiceProvider =
    Provider<CustomCardsImportService>((Ref ref) {
  return CustomCardsImportService(
    database: ref.watch(databaseServiceProvider),
    repository: ref.watch(collectionRepositoryProvider),
    imageCache: ref.watch(imageCacheServiceProvider),
    writer: ImportWriter(
      collections: ref.watch(collectionRepositoryProvider),
      wishlist: ref.watch(wishlistRepositoryProvider),
    ),
    resolver: TitleResolver(ref.watch(lookupChainsProvider)),
    mediaCache: ref.watch(mediaCacheWriterProvider),
  );
});

/// A file row paired with the source record it resolved to.
typedef _Resolved = ({CustomCardEntry entry, ResolvedMatch match});

typedef _Split = ({
  List<_Resolved> resolved,
  List<CustomCardEntry> custom,
  List<String> ambiguousTitles,
});

/// Two phases driven by the preview UI: [parseFile] validates without
/// touching the database, [importSelected] writes only the rows the user kept.
class CustomCardsImportService {
  CustomCardsImportService({
    required DatabaseService database,
    required CollectionRepository repository,
    required ImageCacheService imageCache,
    required ImportWriter writer,
    required TitleResolver resolver,
    required MediaCacheWriter mediaCache,
  })  : _db = database,
        _repository = repository,
        _imageCache = imageCache,
        _writer = writer,
        _resolver = resolver,
        _mediaCache = mediaCache;

  static final Logger _log = Logger('CustomCardsImportService');

  static const String sourceName = 'Custom cards';

  final DatabaseService _db;
  final CollectionRepository _repository;
  final ImageCacheService _imageCache;
  final ImportWriter _writer;
  final TitleResolver _resolver;
  final MediaCacheWriter _mediaCache;

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

  /// A null [collectionId] creates "Custom Import". With [resolveFromSources]
  /// a row with exactly one source match becomes a real item, the rest custom.
  Future<UniversalImportResult> importSelected({
    required int? collectionId,
    required String author,
    required List<CustomCardEntry> entries,
    bool resolveFromSources = false,
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
      final _Split split = resolveFromSources
          ? await _resolveAll(entries, platformLookup, onProgress)
          : (
              resolved: const <_Resolved>[],
              custom: entries,
              ambiguousTitles: const <String>[],
            );

      final List<(CustomCardEntry, int?)> tagTargets =
          <(CustomCardEntry, int?)>[];
      ImportWriteResult? written;
      if (split.resolved.isNotEmpty) {
        await _mediaCache.upsertAll(<Object>[
          for (final _Resolved r in split.resolved) r.match.candidate.media,
        ]);
        written = await _writer.writeItems(
          collectionId: collection.id,
          candidates: <ImportCandidate>[
            for (final _Resolved r in split.resolved) _candidate(r),
          ],
        );
        for (final _Resolved r in split.resolved) {
          final LookupCandidate c = r.match.candidate;
          tagTargets.add((
            r.entry,
            written.idFor(
              c.mediaType,
              c.externalId,
              r.match.platformId,
              c.source,
            ),
          ));
        }
      }

      final int resolvedImported =
          written?.importedByType.values.fold<int>(0, (int a, int b) => a + b) ??
              0;
      onProgress?.call(ImportProgress(
        stage: ImportStage.addingItems,
        current: 0,
        total: split.custom.length,
        imported: resolvedImported,
      ));

      final List<CustomMedia> cards = <CustomMedia>[
        for (final CustomCardEntry entry in split.custom)
          _card(entry, platformLookup),
      ];
      final List<int> customIds =
          cards.isEmpty ? <int>[] : await _db.customMediaDao.createAll(cards);
      final List<Map<String, dynamic>> rows = <Map<String, dynamic>>[];
      for (int i = 0; i < split.custom.length; i++) {
        rows.add(_insertRow(split.custom[i], customIds[i]));
      }
      final List<int?> itemIds = rows.isEmpty
          ? <int?>[]
          : await _repository.addItemsBatchReturningIds(collection.id, rows);
      final int insertedCustom = itemIds.whereType<int>().length;
      for (int i = 0; i < split.custom.length; i++) {
        tagTargets.add((split.custom[i], itemIds[i]));
      }
      await _applyTags(tagTargets);

      final int imported = resolvedImported + insertedCustom;
      onProgress?.call(ImportProgress(
        stage: ImportStage.addingItems,
        current: split.custom.length,
        total: split.custom.length,
        imported: imported,
      ));

      final List<String> errors = await _downloadCovers(
        split.custom,
        customIds,
        imported,
        onProgress,
      );

      onProgress?.call(ImportProgress(
        stage: ImportStage.completed,
        current: 1,
        total: 1,
        imported: imported,
      ));

      return UniversalImportResult(
        sourceName: sourceName,
        success: true,
        collection: collection,
        importedByType: <MediaType, int>{
          ...?written?.importedByType,
          MediaType.custom: insertedCustom,
        },
        skipped: (written?.skipped ?? 0) +
            (split.custom.length - insertedCustom),
        errors: errors,
        unresolvedTitles: split.ambiguousTitles,
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

  /// Asks the sources row by row; `custom` and `audio` rows skip the lookup
  /// by contract, everything unresolved joins them as a custom card.
  Future<_Split> _resolveAll(
    List<CustomCardEntry> entries,
    Map<String, Platform> platformLookup,
    ImportProgressCallback? onProgress,
  ) async {
    final List<_Resolved> resolved = <_Resolved>[];
    final List<CustomCardEntry> custom = <CustomCardEntry>[];
    final List<String> ambiguousTitles = <String>[];

    void report(int index, CustomCardEntry entry, {DataSource? source}) {
      onProgress?.call(ImportProgress(
        stage: ImportStage.resolvingTitles,
        current: index,
        total: entries.length,
        currentItem: entry.title,
        source: source,
        imported: resolved.length,
        customCards: custom.length,
        ambiguous: ambiguousTitles.length,
      ));
    }

    for (int i = 0; i < entries.length; i++) {
      final CustomCardEntry entry = entries[i];
      if (entry.type == MediaType.custom || entry.type == MediaType.audio) {
        custom.add(entry);
        continue;
      }
      report(i, entry);
      final Platform? matched = _matchPlatform(entry, platformLookup);
      final ResolveOutcome outcome = await _resolver.resolve(
        entry.type,
        TitleQuery(
          title: entry.title,
          altTitle: entry.altTitle,
          year: entry.year,
          platformId: matched?.id,
        ),
        platformUnknown: entry.platform != null && matched == null,
        onSource: (DataSource source) => report(i, entry, source: source),
      );
      switch (outcome) {
        case ResolvedMatch():
          resolved.add((entry: entry, match: outcome));
        case ResolvedAmbiguous():
          ambiguousTitles.add(entry.title);
          custom.add(entry);
        case ResolvedNotFound():
          custom.add(entry);
      }
    }
    if (entries.isNotEmpty) {
      report(entries.length, entries.last);
    }
    return (
      resolved: resolved,
      custom: custom,
      ambiguousTitles: ambiguousTitles,
    );
  }

  /// A real item: media identity from the source, personal columns from the
  /// file. The file cover survives only as an override when the source has none.
  ImportCandidate _candidate(_Resolved r) {
    final LookupCandidate c = r.match.candidate;
    return ImportCandidate(
      mediaType: c.mediaType,
      externalId: c.externalId,
      platformId: r.match.platformId,
      source: c.source,
      label: r.entry.title,
      insertRow: <String, dynamic>{
        'media_type': c.mediaType.value,
        'external_id': c.externalId,
        'platform_id': r.match.platformId,
        'source': c.source.name,
        ..._personalFields(r.entry),
        if (c.coverUrl == null && r.entry.coverUrl != null)
          'override_cover_url': r.entry.coverUrl,
      },
      // Already in the collection means the user's own data stays as is.
      changedFields: (CollectionItem _) => const <String, dynamic>{},
    );
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
    final Platform? matched = _matchPlatform(entry, platformLookup);
    // The platform FK only exists for custom games (per the CustomMedia
    // contract); other types keep the text as a free-form display name.
    final bool isGame = entry.type == MediaType.game;
    return CustomMedia(
      id: 0,
      title: entry.title,
      displayType: entry.type == MediaType.custom ? null : entry.type,
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

  Platform? _matchPlatform(
    CustomCardEntry entry,
    Map<String, Platform> platformLookup,
  ) {
    final String? platform = entry.platform;
    return platform == null ? null : platformLookup[platform.trim().toLowerCase()];
  }

  Map<String, dynamic> _insertRow(CustomCardEntry entry, int customId) =>
      <String, dynamic>{
        'media_type': MediaType.custom.value,
        'external_id': customId,
        ..._personalFields(entry),
      };

  /// Personal columns of a file row, shared by custom cards and resolved items.
  Map<String, dynamic> _personalFields(CustomCardEntry entry) {
    final ItemStatus status = entry.status ?? ItemStatus.notStarted;
    final Map<String, dynamic> row = <String, dynamic>{
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

  /// Additive: a resolved row can land on an item already in the collection,
  /// whose own tags must survive. A `null` item id marks a row not written.
  Future<void> _applyTags(List<(CustomCardEntry, int?)> targets) async {
    if (!targets.any(((CustomCardEntry, int?) t) => t.$1.tags.isNotEmpty)) {
      return;
    }

    final Map<String, int> tagIdByName =
        await _db.globalTagDao.resolveOrCreateAll(<TagSeed>[
      for (final (CustomCardEntry entry, _) in targets)
        for (final String name in entry.tags)
          (name: name, color: null, textColor: null),
    ]);

    for (final (CustomCardEntry entry, int? itemId) in targets) {
      if (itemId == null || entry.tags.isEmpty) continue;
      await _db.globalTagDao.addTagsToItems(<int>[itemId], <int>{
        for (final String name in entry.tags)
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
