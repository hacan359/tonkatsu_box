import 'collection.dart';
import 'media_type.dart';

class UniversalImportResult {
  const UniversalImportResult({
    required this.sourceName,
    required this.success,
    this.collection,
    this.collectionId,
    this.importedByType = const <MediaType, int>{},
    this.wishlistedByType = const <MediaType, int>{},
    this.updatedByType = const <MediaType, int>{},
    this.untypedImported = 0,
    this.untypedUpdated = 0,
    this.skipped = 0,
    this.errors = const <String>[],
    this.fatalError,
  });

  const UniversalImportResult.failure({
    required this.sourceName,
    required String error,
  })  : success = false,
        collection = null,
        collectionId = null,
        importedByType = const <MediaType, int>{},
        wishlistedByType = const <MediaType, int>{},
        updatedByType = const <MediaType, int>{},
        untypedImported = 0,
        untypedUpdated = 0,
        skipped = 0,
        errors = const <String>[],
        fatalError = error;

  /// Import source name: 'Steam', 'Trakt', 'Collection File'.
  final String sourceName;

  final bool success;

  final Collection? collection;

  /// Used when the Collection object is unavailable.
  final int? collectionId;

  final Map<MediaType, int> importedByType;

  final Map<MediaType, int> wishlistedByType;

  final Map<MediaType, int> updatedByType;

  /// Imported without per-type breakdown (xcoll).
  final int untypedImported;

  /// Updated without per-type breakdown (xcoll).
  final int untypedUpdated;

  final int skipped;

  /// Per-item errors.
  final List<String> errors;

  final String? fatalError;

  int get totalImported => _sumValues(importedByType) + untypedImported;

  int get totalWishlisted => _sumValues(wishlistedByType);

  int get totalUpdated => _sumValues(updatedByType) + untypedUpdated;

  bool get hasWishlistItems => totalWishlisted > 0;

  int? get effectiveCollectionId => collection?.id ?? collectionId;

  static int _sumValues(Map<MediaType, int> map) {
    int sum = 0;
    for (final int v in map.values) {
      sum += v;
    }
    return sum;
  }
}
