// Тир-лист — сущность для ранжирования элементов коллекции.

/// Тир-лист.
///
/// Может быть глобальным (все элементы) или привязанным к коллекции.
class TierList {
  /// Создаёт [TierList].
  const TierList({
    required this.id,
    required this.name,
    required this.createdAt,
    this.collectionId,
  });

  /// Создаёт [TierList] из записи базы данных.
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

  /// Уникальный идентификатор.
  final int id;

  /// Название тир-листа.
  final String name;

  /// ID коллекции (null = глобальный, все элементы).
  final int? collectionId;

  /// Дата создания.
  final DateTime createdAt;

  /// Глобальный тир-лист (не привязан к коллекции).
  bool get isGlobal => collectionId == null;

  /// Преобразует в Map для сохранения в базу данных.
  Map<String, dynamic> toDb() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'collection_id': collectionId,
      'created_at': createdAt.millisecondsSinceEpoch ~/ 1000,
    };
  }

  /// Создаёт копию с изменёнными полями.
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
