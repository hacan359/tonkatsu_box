
class TierList {
  const TierList({
    required this.id,
    required this.name,
    required this.createdAt,
    this.collectionId,
  });

  factory TierList.fromDb(Map<String, dynamic> row) {
    return TierList(
      id: row['id'] as int,
      name: row['name'] as String,
      collectionId: row['collection_id'] as int?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (row['created_at'] as int) * 1000,
      ),
    );
  }

  final int id;

  final String name;

  /// `null` scopes the list globally, across every item.
  final int? collectionId;

  final DateTime createdAt;

  bool get isGlobal => collectionId == null;

  Map<String, dynamic> toDb() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'collection_id': collectionId,
      'created_at': createdAt.millisecondsSinceEpoch ~/ 1000,
    };
  }

  TierList copyWith({
    int? id,
    String? name,
    int? collectionId,
    bool clearCollectionId = false,
    DateTime? createdAt,
  }) {
    return TierList(
      id: id ?? this.id,
      name: name ?? this.name,
      collectionId:
          clearCollectionId ? null : (collectionId ?? this.collectionId),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TierList && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'TierList(id: $id, name: $name, collectionId: $collectionId)';
}
