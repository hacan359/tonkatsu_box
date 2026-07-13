// Imports books from a Hardcover user library via GraphQL.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../../data/repositories/collection_repository.dart';
import '../../../../data/repositories/wishlist_repository.dart';
import '../../../../shared/models/book.dart';
import '../../../../shared/models/collection.dart';
import '../../../../shared/models/collection_item.dart';
import '../../../../shared/models/data_source.dart';
import '../../../../shared/models/item_status.dart';
import '../../../../shared/models/item_status_logic.dart';
import '../../../../shared/models/media_type.dart';
import '../../../../shared/models/universal_import_result.dart';
import '../../../../shared/utils/bbcode.dart';
import '../../../api/hardcover_api.dart';
import '../../../database/database_service.dart';
import '../../../services/import_service.dart';
import '../../import_columns.dart';
import '../../import_source.dart';
import '../../import_writer.dart';
import '../anilist/anilist_import_service.dart' show ImportMode;

/// Provider for [HardcoverImportService].
final Provider<HardcoverImportService> hardcoverImportServiceProvider =
    Provider<HardcoverImportService>((Ref ref) {
  return HardcoverImportService(
    hardcoverApi: ref.watch(hardcoverApiProvider),
    database: ref.watch(databaseServiceProvider),
    repository: ref.watch(collectionRepositoryProvider),
    wishlistRepository: ref.watch(wishlistRepositoryProvider),
  );
});

class HardcoverImportOptions extends ImportOptions {
  const HardcoverImportOptions({
    required this.userName,
    required this.mode,
    required this.author,
    required this.newCollectionName,
    super.collectionId,
  });

  final String userName;
  final ImportMode mode;

  /// Author / name for a freshly created collection.
  final String author;
  final String newCollectionName;
}

/// Hardcover import on the shared import layer.
///
/// Fetches a user's library by username (public part for other users, the
/// complete library for the token owner) and writes it through [ImportWriter]
/// in one batch. Rows carry Hardcover book ids, so there is no title search
/// and no wishlist fallback. Books flagged `owned` get the global "Owned" tag.
/// Hard errors (missing token, unknown user, API failure) are thrown so the
/// UI can localize them.
class HardcoverImportService implements ImportSource {
  HardcoverImportService({
    required HardcoverApi hardcoverApi,
    required DatabaseService database,
    required CollectionRepository repository,
    required WishlistRepository wishlistRepository,
  })  : _hardcover = hardcoverApi,
        _db = database,
        _collections = repository,
        _writer = ImportWriter(
          collections: repository,
          wishlist: wishlistRepository,
        );

  static final Logger _log = Logger('HardcoverImportService');

  /// Global tag applied to books whose Hardcover record is flagged `owned`.
  static const String ownedTagName = 'Owned';

  // Hardcover status_id values.
  static const int _statusWantToRead = 1;
  static const int _statusCurrentlyReading = 2;
  static const int _statusRead = 3;
  static const int _statusPaused = 4;
  static const int _statusDidNotFinish = 5;
  static const int _statusIgnored = 6;

  final HardcoverApi _hardcover;
  final DatabaseService _db;
  final CollectionRepository _collections;
  final ImportWriter _writer;

  @override
  String get displayName => 'Hardcover';

  /// Throws [HardcoverAuthException] / [HardcoverUserNotFoundException] /
  /// [HardcoverApiException] when the Hardcover API call fails and
  /// [FormatException] when the library is empty.
  @override
  Future<UniversalImportResult> import(
    covariant HardcoverImportOptions options, {
    ImportProgressCallback? onProgress,
  }) async {
    onProgress?.call(const ImportProgress(
      stage: ImportStage.fetchingBooks,
      current: 0,
      total: 0,
    ));
    final List<HardcoverUserBookEntry> allEntries =
        await _hardcover.fetchUserBooks(
      username: options.userName,
      onProgress: (int fetched, int total) {
        onProgress?.call(ImportProgress(
          stage: ImportStage.fetchingBooks,
          current: fetched,
          total: total,
        ));
      },
    );

    final List<HardcoverUserBookEntry> entries = allEntries
        .where((HardcoverUserBookEntry e) => e.statusId != _statusIgnored)
        .toList();
    if (entries.isEmpty) {
      throw const FormatException('No books found in the Hardcover library');
    }

    await _db.bookDao.upsertBooks(<Book>[
      for (final HardcoverUserBookEntry entry in entries) entry.book,
    ]);

    // Create the collection only after a successful fetch.
    final Collection? collection = await _writer.resolveCollection(
      collectionId: options.collectionId,
      newCollectionName: options.newCollectionName,
      author: options.author,
    );
    if (collection == null) {
      return const UniversalImportResult.failure(
        sourceName: 'Hardcover',
        error: 'Collection not found',
      );
    }

    onProgress?.call(ImportProgress(
      stage: ImportStage.addingItems,
      current: 0,
      total: entries.length,
    ));

    final ImportWriteResult write = await _writer.writeItems(
      collectionId: collection.id,
      candidates: <ImportCandidate>[
        for (final HardcoverUserBookEntry entry in entries)
          _candidate(entry, options.mode),
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
        ));
      },
    );

    await _applyOwnedTag(collection.id, <int>{
      for (final HardcoverUserBookEntry entry in entries)
        if (entry.owned) entry.book.externalIdInt,
    });

    onProgress?.call(ImportProgress(
      stage: ImportStage.completed,
      current: 1,
      total: 1,
      imported: sumByType(write.importedByType),
      updated: sumByType(write.updatedByType),
    ));

    _log.info(
      'Hardcover import complete for "${options.userName}": '
      'imported ${write.importedByType}, updated ${write.updatedByType} '
      '(total ${entries.length})',
    );

    return UniversalImportResult(
      sourceName: 'Hardcover',
      success: true,
      collection: collection,
      importedByType: write.importedByType,
      updatedByType: write.updatedByType,
      skipped: write.skipped,
    );
  }

  ImportCandidate _candidate(HardcoverUserBookEntry entry, ImportMode mode) {
    final ItemStatus status = _mapStatus(entry.statusId);
    return ImportCandidate(
      mediaType: MediaType.book,
      externalId: entry.book.externalIdInt,
      platformId: null,
      label: entry.book.title,
      insertRow: _insertRow(entry, status),
      changedFields: (CollectionItem existing) => mode == ImportMode.newOnly
          ? const <String, dynamic>{}
          : _changedFields(entry, existing),
    );
  }

  Map<String, dynamic> _insertRow(
    HardcoverUserBookEntry entry,
    ItemStatus status,
  ) {
    final double? rating = _resolveRating(entry.rating);
    final _ResolvedDates dates = _resolveDates(entry, status);
    final int rereads = _rereads(entry.readCount);
    final String comment = _buildUserComment(entry);
    return <String, dynamic>{
      'media_type': MediaType.book.value,
      'external_id': entry.book.externalIdInt,
      // Books dispatch refetch / links on the item source, unlike anime/manga
      // rows that default to anilist.
      'source': DataSource.hardcover.name,
      'status': status.value,
      'user_rating': ?rating,
      'started_at': ?epochSeconds(dates.startedAt),
      'completed_at': ?epochSeconds(dates.completedAt),
      'last_activity_at': ?epochSeconds(dates.lastActivityAt),
      if (comment.isNotEmpty) 'user_comment': comment,
      if (repeatIsTracked(status, rereads)) 'rewatch_count': rereads,
      // Hardcover's own add date; the DAO keeps it (falls back to now when a
      // source sends nothing).
      'added_at': ?epochSeconds(entry.dateAdded),
    };
  }

  /// Overwrite-mode re-sync: bump status without downgrading, keep earliest
  /// start / latest completion, refresh rating, comment, rereads and the
  /// Hardcover add date.
  Map<String, dynamic> _changedFields(
    HardcoverUserBookEntry entry,
    CollectionItem existing,
  ) {
    final ItemStatus status = _mapStatus(entry.statusId);
    final Map<String, dynamic> fields = <String, dynamic>{};

    final ItemStatus? newStatus = mergeExternalStatus(
      currentStatus: existing.status,
      externalStatus: status,
    );
    if (newStatus != null) {
      fields.addAll(statusDateColumns(newStatus, existing));
    }

    final double? rating = _resolveRating(entry.rating);
    if (rating != null && rating != existing.userRating) {
      fields['user_rating'] = rating;
    }

    final _ResolvedDates remoteDates = _resolveDates(entry, status);
    DateTime? newStarted = existing.startedAt;
    DateTime? newCompleted = existing.completedAt;
    if (remoteDates.startedAt != null &&
        (newStarted == null || remoteDates.startedAt!.isBefore(newStarted))) {
      newStarted = remoteDates.startedAt;
    }
    if (remoteDates.completedAt != null &&
        (newCompleted == null ||
            remoteDates.completedAt!.isAfter(newCompleted))) {
      newCompleted = remoteDates.completedAt;
    }
    if (newStarted != existing.startedAt ||
        newCompleted != existing.completedAt) {
      if (newStarted != null) fields['started_at'] = epochSeconds(newStarted);
      if (newCompleted != null) {
        fields['completed_at'] = epochSeconds(newCompleted);
      }
      fields['last_activity_at'] =
          epochSeconds(remoteDates.lastActivityAt);
    }

    final String comment = _buildUserComment(entry);
    if (comment.isNotEmpty) fields['user_comment'] = comment;

    final int rereads = _rereads(entry.readCount);
    if (repeatIsTracked(status, rereads) &&
        rereads != existing.rewatchCount) {
      fields['rewatch_count'] = rereads;
    }

    // E.g. the item was added by hand before the import existed.
    final int? remoteAdded = epochSeconds(entry.dateAdded);
    if (remoteAdded != null &&
        remoteAdded != epochSeconds(existing.addedAt)) {
      fields['added_at'] = remoteAdded;
    }

    return fields;
  }

  /// Links the global "Owned" tag (created on demand) to the collection's
  /// books whose external id is in [ownedExternalIds]. Existing tags are
  /// preserved; a flag removed on Hardcover never removes the tag here (it
  /// may have been set by hand).
  Future<void> _applyOwnedTag(
    int collectionId,
    Set<int> ownedExternalIds,
  ) async {
    if (ownedExternalIds.isEmpty) return;

    final int tagId = await _db.globalTagDao.resolveOrCreate(ownedTagName);
    final List<int> itemIds = <int>[
      for (final CollectionItem item
          in await _collections.getItems(collectionId))
        if (item.mediaType == MediaType.book &&
            ownedExternalIds.contains(item.externalId))
          item.id,
    ];
    await _db.globalTagDao.addTagToItems(itemIds, tagId);
  }

  /// `read_count` counts completions; the local counter counts re-reads
  /// (0 = read once).
  static int _rereads(int readCount) => readCount > 1 ? readCount - 1 : 0;

  /// Normalizes a 0–5 (halves) rating to the local 1.0–10.0 scale.
  static double? _resolveRating(double? rating) {
    if (rating == null || rating <= 0) return null;
    final double normalized = rating * 2;
    if (normalized < 1.0) return 1.0;
    if (normalized > 10.0) return 10.0;
    return normalized;
  }

  _ResolvedDates _resolveDates(
    HardcoverUserBookEntry entry,
    ItemStatus status,
  ) {
    DateTime? startedAt = entry.firstStartedReadingDate;
    DateTime? completedAt = entry.lastReadDate ?? entry.firstReadDate;

    if (status == ItemStatus.completed) {
      completedAt ??= startedAt ?? entry.dateAdded ?? DateTime.now();
      startedAt ??= completedAt;
    }

    return _ResolvedDates(
      startedAt: startedAt,
      completedAt: completedAt,
      lastActivityAt:
          completedAt ?? startedAt ?? entry.dateAdded ?? DateTime.now(),
    );
  }

  /// Comment = source link + re-read count + review + private notes. The
  /// review arrives as HTML with mention spans and is stripped to plain text;
  /// private notes only exist for the token owner's own library.
  String _buildUserComment(HardcoverUserBookEntry entry) {
    final List<String> lines = <String>[];

    final String? url = entry.book.externalUrl;
    if (url != null) lines.add('[Hardcover]($url)');

    final int rereads = _rereads(entry.readCount);
    if (rereads > 0) lines.add('Reread times: $rereads');

    final String? review =
        entry.review != null ? _plainText(entry.review!) : null;
    if (review != null) {
      lines.add('');
      lines.add(review);
    }

    if (entry.privateNotes != null) {
      lines.add('');
      lines.add(entry.privateNotes!);
    }

    return lines.join('\n');
  }

  static String? _plainText(String html) {
    final String clean = stripBbCodes(html).trim();
    return clean.isEmpty ? null : clean;
  }

  static ItemStatus _mapStatus(int statusId) {
    switch (statusId) {
      case _statusWantToRead:
        return ItemStatus.planned;
      case _statusCurrentlyReading:
        return ItemStatus.inProgress;
      case _statusRead:
        return ItemStatus.completed;
      // Local dropped doubles as "paused" (pause icon), the shared mapping
      // across importers.
      case _statusPaused:
      case _statusDidNotFinish:
        return ItemStatus.dropped;
      default:
        _log.warning('Unknown Hardcover status_id: $statusId → notStarted');
        return ItemStatus.notStarted;
    }
  }
}

class _ResolvedDates {
  const _ResolvedDates({
    required this.startedAt,
    required this.completedAt,
    required this.lastActivityAt,
  });

  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime lastActivityAt;
}
