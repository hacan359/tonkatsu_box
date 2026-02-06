import 'dart:convert';

import 'game.dart';

/// Тип элемента на канвасе.
enum CanvasItemType {
  /// Карточка игры.
  game('game'),

  /// Текстовый блок.
  text('text'),

  /// Изображение.
  image('image'),

  /// Ссылка.
  link('link');

  const CanvasItemType(this.value);

  /// Строковое значение для базы данных.
  final String value;

  /// Создаёт [CanvasItemType] из строки.
  static CanvasItemType fromString(String value) {
    return CanvasItemType.values.firstWhere(
      (CanvasItemType type) => type.value == value,
      orElse: () => CanvasItemType.game,
    );
  }
}

/// Модель элемента на канвасе коллекции.
///
/// Представляет любой объект, размещённый на канвасе:
/// игровую карточку, текст, изображение или ссылку.
class CanvasItem {
  /// Создаёт экземпляр [CanvasItem].
  const CanvasItem({
    required this.id,
    required this.collectionId,
    required this.itemType,
    required this.x,
    required this.y,
    required this.createdAt,
    this.itemRefId,
    this.width,
    this.height,
    this.zIndex = 0,
    this.data,
    this.game,
  });

  /// Создаёт [CanvasItem] из записи базы данных.
  factory CanvasItem.fromDb(Map<String, dynamic> row) {
    final String? dataString = row['data'] as String?;
    Map<String, dynamic>? parsedData;
    if (dataString != null && dataString.isNotEmpty) {
      parsedData =
          json.decode(dataString) as Map<String, dynamic>;
    }

    return CanvasItem(
      id: row['id'] as int,
      collectionId: row['collection_id'] as int,
      itemType: CanvasItemType.fromString(row['item_type'] as String),
      itemRefId: row['item_ref_id'] as int?,
      x: (row['x'] as num).toDouble(),
      y: (row['y'] as num).toDouble(),
      width: (row['width'] as num?)?.toDouble(),
      height: (row['height'] as num?)?.toDouble(),
      zIndex: row['z_index'] as int? ?? 0,
      data: parsedData,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (row['created_at'] as int) * 1000,
      ),
    );
  }

  /// Создаёт [CanvasItem] из JSON (для импорта).
  factory CanvasItem.fromJson(Map<String, dynamic> json) {
    return CanvasItem(
      id: json['id'] as int? ?? 0,
      collectionId: json['collection_id'] as int? ?? 0,
      itemType: CanvasItemType.fromString(json['type'] as String? ?? 'game'),
      itemRefId: json['refId'] as int?,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      zIndex: json['z_index'] as int? ?? 0,
      data: json['data'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['created_at'] as int) * 1000,
            )
          : DateTime.now(),
    );
  }

  /// Уникальный идентификатор элемента.
  final int id;

  /// ID коллекции.
  final int collectionId;

  /// Тип элемента.
  final CanvasItemType itemType;

  /// ID связанного объекта (igdb_id для game, null для остальных).
  final int? itemRefId;

  /// Позиция X на канвасе.
  final double x;

  /// Позиция Y на канвасе.
  final double y;

  /// Ширина элемента.
  final double? width;

  /// Высота элемента.
  final double? height;

  /// Слой отображения (z-index).
  final int zIndex;

  /// Дополнительные данные (JSON).
  final Map<String, dynamic>? data;

  /// Дата создания.
  final DateTime createdAt;

  /// Данные игры (joined, не сохраняются в БД).
  final Game? game;

  /// Преобразует в Map для сохранения в базу данных.
  Map<String, dynamic> toDb() {
    return <String, dynamic>{
      if (id != 0) 'id': id,
      'collection_id': collectionId,
      'item_type': itemType.value,
      'item_ref_id': itemRefId,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'z_index': zIndex,
      'data': data != null ? json.encode(data) : null,
      'created_at': createdAt.millisecondsSinceEpoch ~/ 1000,
    };
  }

  /// Преобразует в JSON для экспорта.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'type': itemType.value,
      'refId': itemRefId,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'z_index': zIndex,
      'data': data,
      'created_at': createdAt.millisecondsSinceEpoch ~/ 1000,
    };
  }

  /// Создаёт копию с изменёнными полями.
  CanvasItem copyWith({
    int? id,
    int? collectionId,
    CanvasItemType? itemType,
    int? itemRefId,
    double? x,
    double? y,
    double? width,
    double? height,
    int? zIndex,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    Game? game,
  }) {
    return CanvasItem(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      itemType: itemType ?? this.itemType,
      itemRefId: itemRefId ?? this.itemRefId,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      zIndex: zIndex ?? this.zIndex,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      game: game ?? this.game,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CanvasItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'CanvasItem(id: $id, type: ${itemType.value}, x: $x, y: $y)';
}
