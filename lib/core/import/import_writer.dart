import '../../data/repositories/collection_repository.dart';
import '../../data/repositories/wishlist_repository.dart';
import '../../shared/models/collection.dart';
import '../../shared/models/collection_item.dart';
import '../../shared/models/media_type.dart';
import '../../shared/models/wishlist_item.dart';

/// One item an adapter wants written to the target collection.
///
/// [insertRow] is the full column map for a fresh insert. [changedFields]
/// returns the columns to update when the item is already present (an empty map
/// means "leave untouched"), so each source keeps its own re-sync merge policy
/// while the batch plumbing stays shared.
class ImportCandidate {
  const ImportCandidate({
    required this.mediaType,
    required this.externalId,
    required this.platformId,
    required this.insertRow,
    required this.changedFields,
    this.label,
  });

  final MediaType mediaType;
  final int externalId;
  final int? platformId;
  final Map<String, dynamic> insertRow;
  final Map<String, dynamic> Function(CollectionItem existing) changedFields;

  /// Title shown in per-item import progress; not written to the database.
  final String? label;
}

/// Per-item progress while [ImportWriter.writeItems] classifies candidates:
/// running [imported] / [updated] tallies and the [label] just processed.
typedef ImportItemProgress = void Function(
  int processed,
  int total,
  int imported,
  int updated,
  String? label,
);

/// An unmatched title to drop into the text wishlist as a fallback.
class WishlistCandidate {
  const WishlistCandidate({
    required this.text,
    required this.mediaType,
    this.note,
  });

  final String text;
  final MediaType mediaType;
  final String? note;
}

/// Per-type tallies for one collection write.
class ImportWriteResult {
  const ImportWriteResult({
    required this.importedByType,
    required this.updatedByType,
    required this.skipped,
  });

  final Map<MediaType, int> importedByType;
  final Map<MediaType, int> updatedByType;

  /// Items dropped as in-batch duplicates or as unchanged existing items.
  final int skipped;
}

/// Shared write-side for importers: resolves the target collection,
/// batch-writes items (new inserts plus selective updates of existing ones,
/// de-duplicated within the batch), and batch-writes wishlist fallbacks.
///
/// Goes through the repositories, never the DAOs directly, so the data-access
/// boundary stays in one place (per the app's repository-as-source-of-truth
/// rule). Media-cache upsert is intentionally left to the adapter — it is
/// media-type specific (movie / tv / game / anime / manga DAOs).
class ImportWriter {
  const ImportWriter({
    required CollectionRepository collections,
    required WishlistRepository wishlist,
  })  : _collections = collections,
        _wishlist = wishlist;

  final CollectionRepository _collections;
  final WishlistRepository _wishlist;

  /// Identity of a collection item across sources: a re-import of the same
  /// logical title resolves to the same key.
  static String itemKey(MediaType type, int externalId, int? platformId) =>
      '${type.value}:$externalId:$platformId';

  /// Returns the target collection: the existing one when [collectionId] is
  /// given, otherwise a freshly created [newCollectionName] / [author] one.
  Future<Collection?> resolveCollection({
    required int? collectionId,
    required String newCollectionName,
    required String author,
  }) async {
    if (collectionId != null) {
      return _collections.getById(collectionId);
    }
    return _collections.create(name: newCollectionName, author: author);
  }

  /// Writes [candidates] to [collectionId]: new items are batch-inserted,
  /// already-present items get the fields their [ImportCandidate.changedFields]
  /// reports (skipped when empty), and in-batch duplicates are dropped.
  Future<ImportWriteResult> writeItems({
    required int collectionId,
    required List<ImportCandidate> candidates,
    ImportItemProgress? onItem,
  }) async {
    final Map<String, CollectionItem> existing = <String, CollectionItem>{};
    for (final CollectionItem item in await _collections.getItems(collectionId)) {
      existing[itemKey(item.mediaType, item.externalId, item.platformId)] = item;
    }

    final Map<MediaType, int> importedByType = <MediaType, int>{};
    final Map<MediaType, int> updatedByType = <MediaType, int>{};
    final List<Map<String, dynamic>> rows = <Map<String, dynamic>>[];
    final List<(int, Map<String, dynamic>)> updates =
        <(int, Map<String, dynamic>)>[];
    final Set<String> seen = <String>{};
    int skipped = 0;
    int importedRunning = 0;
    int updatedRunning = 0;
    int processed = 0;

    for (final ImportCandidate candidate in candidates) {
      processed++;
      final String key = itemKey(
        candidate.mediaType,
        candidate.externalId,
        candidate.platformId,
      );
      if (!seen.add(key)) {
        skipped++;
        onItem?.call(processed, candidates.length, importedRunning,
            updatedRunning, candidate.label);
        continue;
      }

      final CollectionItem? current = existing[key];
      if (current == null) {
        rows.add(candidate.insertRow);
        importedByType[candidate.mediaType] =
            (importedByType[candidate.mediaType] ?? 0) + 1;
        importedRunning++;
      } else {
        final Map<String, dynamic> changed = candidate.changedFields(current);
        if (changed.isEmpty) {
          skipped++;
        } else {
          updates.add((current.id, changed));
          updatedByType[candidate.mediaType] =
              (updatedByType[candidate.mediaType] ?? 0) + 1;
          updatedRunning++;
        }
      }

      onItem?.call(processed, candidates.length, importedRunning,
          updatedRunning, candidate.label);
    }

    await _collections.addItemsBatch(collectionId, rows);
    await _collections.updateItemFieldsBatch(updates);
    return ImportWriteResult(
      importedByType: importedByType,
      updatedByType: updatedByType,
      skipped: skipped,
    );
  }

  /// Batch-inserts [entries] into the text wishlist under a single import
  /// [tag], deduped (case-insensitively) against existing unresolved entries.
  Future<Map<MediaType, int>> writeWishlist({
    required List<WishlistCandidate> entries,
    required String tag,
  }) async {
    if (entries.isEmpty) return const <MediaType, int>{};

    final Set<String> existingTexts = <String>{};
    for (final WishlistItem item
        in await _wishlist.getAll(includeResolved: false)) {
      existingTexts.add(item.text.toLowerCase());
    }

    final Map<MediaType, int> wishlistedByType = <MediaType, int>{};
    final List<Map<String, dynamic>> rows = <Map<String, dynamic>>[];
    for (final WishlistCandidate entry in entries) {
      if (!existingTexts.add(entry.text.toLowerCase())) continue;
      rows.add(<String, dynamic>{
        'text': entry.text,
        'media_type_hint': entry.mediaType.value,
        'note': entry.note,
        'tag': tag,
      });
      wishlistedByType[entry.mediaType] =
          (wishlistedByType[entry.mediaType] ?? 0) + 1;
    }

    await _wishlist.addWishlistItemsBatch(rows);
    return wishlistedByType;
  }
}
