// Модель связи между элементами канваса.

/// Стиль линии связи.
enum ConnectionStyle {
  /// Сплошная линия.
  solid('solid'),

  /// Пунктирная линия.
  dashed('dashed'),

  /// Линия со стрелкой.
  arrow('arrow');

  const ConnectionStyle(this.value);

  /// Строковое значение для базы данных.
  final String value;

  /// Создаёт [ConnectionStyle] из строки.
  static ConnectionStyle fromString(String value) {
    return ConnectionStyle.values.firstWhere(
      (ConnectionStyle style) => style.value == value,
      orElse: () => ConnectionStyle.solid,
    );
  }
}

/// Модель связи между двумя элементами канваса.
///
/// Представляет визуальную линию от одного элемента к другому
/// с настраиваемым стилем, цветом и лейблом.
class CanvasConnection {
  /// Создаёт экземпляр [CanvasConnection].
  const CanvasConnection({
    required this.id,
    required this.collectionId,
    required this.fromItemId,
    required this.toItemId,
    required this.createdAt,
    this.label,
    this.color = '#666666',
    this.style = ConnectionStyle.solid,
  });

  /// Создаёт [CanvasConnection] из записи базы данных.
  factory CanvasConnection.fromDb(Map<String, dynamic> row) {
    return CanvasConnection(
      id: row['id'] as int,
      collectionId: row['collection_id'] as int,
      fromItemId: row['from_item_id'] as int,
      toItemId: row['to_item_id'] as int,
      label: row['label'] as String?,
      color: row['color'] as String? ?? '#666666',
      style: ConnectionStyle.fromString(row['style'] as String? ?? 'solid'),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (row['created_at'] as int) * 1000,
      ),
    );
  }

  /// Создаёт [CanvasConnection] из JSON (для импорта).
  factory CanvasConnection.fromJson(Map<String, dynamic> json) {
    return CanvasConnection(
      id: json['id'] as int? ?? 0,
      collectionId: json['collection_id'] as int? ?? 0,
      fromItemId: json['from_item_id'] as int,
      toItemId: json['to_item_id'] as int,
      label: json['label'] as String?,
      color: json['color'] as String? ?? '#666666',
      style: ConnectionStyle.fromString(json['style'] as String? ?? 'solid'),
      createdAt: json['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['created_at'] as int) * 1000,
            )
          : DateTime.now(),
    );
  }

  /// Уникальный идентификатор связи.
  final int id;

  /// ID коллекции.
  final int collectionId;

  /// ID элемента-источника.
  final int fromItemId;

  /// ID элемента-цели.
  final int toItemId;

  /// Текстовый лейбл на линии связи.
  final String? label;

  /// Цвет линии в формате hex (например, '#FF0000').
  final String color;

  /// Стиль линии.
  final ConnectionStyle style;

  /// Дата создания.
  final DateTime createdAt;

  /// Преобразует в Map для сохранения в базу данных.
  Map<String, dynamic> toDb() {
    return <String, dynamic>{
      if (id != 0) 'id': id,
      'collection_id': collectionId,
      'from_item_id': fromItemId,
      'to_item_id': toItemId,
      'label': label,
      'color': color,
      'style': style.value,
      'created_at': createdAt.millisecondsSinceEpoch ~/ 1000,
    };
  }

  /// Преобразует в JSON для экспорта.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'from_item_id': fromItemId,
      'to_item_id': toItemId,
      'label': label,
      'color': color,
      'style': style.value,
      'created_at': createdAt.millisecondsSinceEpoch ~/ 1000,
    };
  }

  /// Создаёт копию с изменёнными полями.
  ///
  /// Используйте [clearLabel] = true для сброса label в null,
  /// так как передача `label: null` оставляет текущее значение.
  CanvasConnection copyWith({
    int? id,
    int? collectionId,
    int? fromItemId,
    int? toItemId,
    String? label,
    bool clearLabel = false,
    String? color,
    ConnectionStyle? style,
    DateTime? createdAt,
  }) {
    return CanvasConnection(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      fromItemId: fromItemId ?? this.fromItemId,
      toItemId: toItemId ?? this.toItemId,
      label: clearLabel ? null : (label ?? this.label),
      color: color ?? this.color,
      style: style ?? this.style,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CanvasConnection && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'CanvasConnection(id: $id, from: $fromItemId, to: $toItemId, '
      'style: ${style.value})';
}
