/// Places a collection item in a tier and fixes its order there.
class TierListEntry {
  const TierListEntry({
    required this.collectionItemId,
    required this.tierKey,
    required this.sortOrder,
  });

  factory TierListEntry.fromDb(Map<String, dynamic> row) {
    return TierListEntry(
      collectionItemId: row['collection_item_id'] as int,
      tierKey: row['tier_key'] as String,
      sortOrder: row['sort_order'] as int,
    );
  }

  factory TierListEntry.fromExport(Map<String, dynamic> json) {
    return TierListEntry(
      collectionItemId: json['collection_item_id'] as int,
      tierKey: json['tier_key'] as String,
      sortOrder: json['sort_order'] as int,
    );
  }

  final int collectionItemId;

  final String tierKey;

  /// Position inside the tier; 0 is first.
  final int sortOrder;

  Map<String, dynamic> toDb(int tierListId) {
    return <String, dynamic>{
      'tier_list_id': tierListId,
      'collection_item_id': collectionItemId,
      'tier_key': tierKey,
      'sort_order': sortOrder,
    };
  }

  Map<String, dynamic> toExport() {
    return <String, dynamic>{
      'collection_item_id': collectionItemId,
      'tier_key': tierKey,
      'sort_order': sortOrder,
    };
  }

  TierListEntry copyWith({
    int? collectionItemId,
    String? tierKey,
    int? sortOrder,
  }) {
    return TierListEntry(
      collectionItemId: collectionItemId ?? this.collectionItemId,
      tierKey: tierKey ?? this.tierKey,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TierListEntry &&
        other.collectionItemId == collectionItemId &&
        other.tierKey == tierKey;
  }

  @override
  int get hashCode => Object.hash(collectionItemId, tierKey);

  @override
  String toString() =>
      'TierListEntry(itemId: $collectionItemId, tier: $tierKey, order: $sortOrder)';
}
