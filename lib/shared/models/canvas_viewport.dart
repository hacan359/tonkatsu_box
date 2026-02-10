import 'exportable.dart';

/// Модель состояния viewport канваса.
///
/// Хранит позицию камеры и уровень масштабирования
/// для восстановления при повторном открытии канваса.
class CanvasViewport with Exportable {
  /// Создаёт экземпляр [CanvasViewport].
  const CanvasViewport({
    required this.collectionId,
    this.scale = 1.0,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
  });

  /// Создаёт [CanvasViewport] из записи базы данных.
  factory CanvasViewport.fromDb(Map<String, dynamic> row) {
    return CanvasViewport(
      collectionId: row['collection_id'] as int,
      scale: (row['scale'] as num?)?.toDouble() ?? 1.0,
      offsetX: (row['offset_x'] as num?)?.toDouble() ?? 0.0,
      offsetY: (row['offset_y'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Создаёт [CanvasViewport] из экспортных данных.
  factory CanvasViewport.fromExport(
    Map<String, dynamic> json, {
    int collectionId = 0,
  }) {
    return CanvasViewport(
      collectionId: collectionId,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      offsetX: (json['offsetX'] as num?)?.toDouble() ?? 0.0,
      offsetY: (json['offsetY'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// ID коллекции.
  final int collectionId;

  /// Уровень масштабирования.
  final double scale;

  /// Смещение по X.
  final double offsetX;

  /// Смещение по Y.
  final double offsetY;

  /// Viewport по умолчанию (используется для новых канвасов).
  static const CanvasViewport defaultValue = CanvasViewport(
    collectionId: 0,
  );

  // -- Exportable контракт --

  @override
  Set<String> get internalDbFields => const <String>{'collection_id'};

  @override
  Map<String, String> get dbToExportKeyMapping =>
      const <String, String>{'offset_x': 'offsetX', 'offset_y': 'offsetY'};

  /// Преобразует в Map для сохранения в базу данных.
  @override
  Map<String, dynamic> toDb() {
    return <String, dynamic>{
      'collection_id': collectionId,
      'scale': scale,
      'offset_x': offsetX,
      'offset_y': offsetY,
    };
  }

  /// Преобразует в Map для экспорта.
  @override
  Map<String, dynamic> toExport() {
    return <String, dynamic>{
      'scale': scale,
      'offsetX': offsetX,
      'offsetY': offsetY,
    };
  }

  /// Создаёт копию с изменёнными полями.
  CanvasViewport copyWith({
    int? collectionId,
    double? scale,
    double? offsetX,
    double? offsetY,
  }) {
    return CanvasViewport(
      collectionId: collectionId ?? this.collectionId,
      scale: scale ?? this.scale,
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CanvasViewport && other.collectionId == collectionId;
  }

  @override
  int get hashCode => collectionId.hashCode;

  @override
  String toString() =>
      'CanvasViewport(collectionId: $collectionId, scale: $scale, '
      'offset: ($offsetX, $offsetY))';
}
