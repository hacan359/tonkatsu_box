import 'exportable.dart';

enum ConnectionStyle {
  solid('solid'),

  dashed('dashed'),

  arrow('arrow');

  const ConnectionStyle(this.value);

  /// Value stored in the database.
  final String value;

  static ConnectionStyle fromString(String value) {
    return ConnectionStyle.values.firstWhere(
      (ConnectionStyle style) => style.value == value,
      orElse: () => ConnectionStyle.solid,
    );
  }
}

class CanvasConnection with Exportable {
  const CanvasConnection({
    required this.id,
    required this.collectionId,
    required this.fromItemId,
    required this.toItemId,
    required this.createdAt,
    this.collectionItemId,
    this.label,
    this.color = '#666666',
    this.style = ConnectionStyle.solid,
  });

  factory CanvasConnection.fromDb(Map<String, dynamic> row) {
    return CanvasConnection(
      id: row['id'] as int,
      collectionId: row['collection_id'] as int,
      collectionItemId: row['collection_item_id'] as int?,
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

  factory CanvasConnection.fromExport(
    Map<String, dynamic> json, {
    int collectionId = 0,
  }) {
    return CanvasConnection(
      id: json['id'] as int? ?? 0,
      collectionId: collectionId,
      collectionItemId: json['collection_item_id'] as int?,
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

  final int id;

  final int collectionId;

  /// Set for a per-item canvas; `null` for a collection-level one.
  final int? collectionItemId;

  final int fromItemId;

  final int toItemId;

  final String? label;

  /// Hex color, e.g. `#FF0000`.
  final String color;

  final ConnectionStyle style;

  final DateTime createdAt;


  @override
  Set<String> get internalDbFields => const <String>{'collection_id'};

  @override
  Map<String, dynamic> toDb() {
    return <String, dynamic>{
      if (id != 0) 'id': id,
      'collection_id': collectionId,
      'collection_item_id': collectionItemId,
      'from_item_id': fromItemId,
      'to_item_id': toItemId,
      'label': label,
      'color': color,
      'style': style.value,
      'created_at': createdAt.millisecondsSinceEpoch ~/ 1000,
    };
  }

  @override
  Map<String, dynamic> toExport() {
    return <String, dynamic>{
      'id': id,
      'collection_item_id': collectionItemId,
      'from_item_id': fromItemId,
      'to_item_id': toItemId,
      'label': label,
      'color': color,
      'style': style.value,
      'created_at': createdAt.millisecondsSinceEpoch ~/ 1000,
    };
  }

  /// [clearLabel] erases the label; `label: null` keeps the current one.
  CanvasConnection copyWith({
    int? id,
    int? collectionId,
    int? collectionItemId,
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
      collectionItemId: collectionItemId ?? this.collectionItemId,
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
