import 'data_source.dart';

/// Where a collected item lives; used to mark and remove search results.
class CollectedItemInfo {
  const CollectedItemInfo({
    required this.recordId,
    required this.collectionId,
    required this.collectionName,
    this.platformId,
    this.source = DataSource.tmdb,
  });

  /// Row id in the collection_items table.
  final int recordId;

  /// Collection id (null for uncollected items).
  final int? collectionId;

  /// Collection name (null for uncollected items).
  final String? collectionName;

  /// Platform id (for games). Distinguishes versions on different platforms.
  final int? platformId;

  /// Provider the item came from (disambiguates a shared external_id).
  final DataSource source;

  @override
  String toString() =>
      'CollectedItemInfo(recordId: $recordId, '
      'collectionId: $collectionId, '
      'collectionName: $collectionName)';
}
