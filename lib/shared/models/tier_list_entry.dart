// Привязка элемента коллекции к тиру в тир-листе.

/// Запись элемента в тире.
///
/// Связывает элемент коллекции с конкретным тиром и определяет порядок.
class TierListEntry {
  /// Создаёт [TierListEntry].
  const TierListEntry({
    required this.collectionItemId,
    required this.tierKey,
    required this.sortOrder,
  });

  /// Создаёт [TierListEntry] из записи базы данных.
  factory TierListEntry.fromDb(Map<String, dynamic> row) {
    return TierListEntry(
      collectionItemId: row['collection_item_id'] as int,
      tierKey: row['tier_key'] as String,
      sortOrder: row['sort_order'] as int,
    );
  }

  /// Создаёт [TierListEntry] из экспортированных данных.
  factory TierListEntry.fromExport(Map<String, dynamic> json) {
    return TierListEntry(
      collectionItemId: json['collection_item_id'] as int,
      tierKey: json['tier_key'] as String,
      sortOrder: json['sort_order'] as int,
    );
  }

  /// ID элемента коллекции.
  final int collectionItemId;

  /// Ключ тира, к которому привязан элемент.
  final String tierKey;

  /// Порядок внутри тира (0 = первый).
  final int sortOrder;

  /// Преобразует в Map для сохранения в базу данных.
  Map<String, dynamic> toDb(int tierListId) {
    return <String, dynamic>{
      'tier_list_id': tierListId,
      'collection_item_id': collectionItemId,
      'tier_key': tierKey,
      'sort_order': sortOrder,
    };
  }

  /// Преобразует в Map для экспорта.
  Map<String, dynamic> toExport() {
    return <String, dynamic>{
      'collection_item_id': collectionItemId,
      'tier_key': tierKey,
      'sort_order': sortOrder,
    };
  }

  /// Создаёт копию с изменёнными полями.
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
