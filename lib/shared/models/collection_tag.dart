// Модель тега коллекции.

/// Тег (подкатегория) внутри коллекции.
///
/// Позволяет группировать элементы коллекции любого типа
/// (игры, фильмы, сериалы, кастомные и т.д.) по произвольным меткам.
class CollectionTag {
  /// Создаёт экземпляр [CollectionTag].
  const CollectionTag({
    required this.id,
    required this.collectionId,
    required this.name,
    required this.createdAt,
    this.color,
    this.sortOrder = 0,
  });

  /// Создаёт [CollectionTag] из записи базы данных.
  factory CollectionTag.fromDb(Map<String, dynamic> row) {
    return CollectionTag(
      id: row['id'] as int,
      collectionId: row['collection_id'] as int,
      name: row['name'] as String,
      color: row['color'] as int?,
      sortOrder: row['sort_order'] as int? ?? 0,
      createdAt: row['created_at'] as int,
    );
  }

  /// Создаёт [CollectionTag] из экспортных данных.
  factory CollectionTag.fromExport(Map<String, dynamic> json) {
    return CollectionTag(
      id: json['id'] as int? ?? 0,
      collectionId: json['collection_id'] as int? ?? 0,
      name: json['name'] as String,
      color: json['color'] as int?,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: json['created_at'] as int? ?? 0,
    );
  }

  /// Уникальный идентификатор.
  final int id;

  /// ID коллекции, которой принадлежит тег.
  final int collectionId;

  /// Название тега.
  final String name;

  /// Цвет тега (ARGB int, nullable).
  final int? color;

  /// Порядок сортировки.
  final int sortOrder;

  /// Время создания (unix timestamp в секундах).
  final int createdAt;

  /// Преобразует в Map для сохранения в базу данных.
  Map<String, dynamic> toDb() {
    return <String, dynamic>{
      'id': id,
      'collection_id': collectionId,
      'name': name,
      'color': color,
      'sort_order': sortOrder,
      'created_at': createdAt,
    };
  }

  /// Преобразует в Map для экспорта коллекции.
  Map<String, dynamic> toExport() {
    return <String, dynamic>{
      'name': name,
      'color': color,
      'sort_order': sortOrder,
    };
  }

  /// Создаёт копию с изменёнными полями.
  CollectionTag copyWith({
    int? id,
    int? collectionId,
    String? name,
    int? color,
    bool clearColor = false,
    int? sortOrder,
    int? createdAt,
  }) {
    return CollectionTag(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      name: name ?? this.name,
      color: clearColor ? null : (color ?? this.color),
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
