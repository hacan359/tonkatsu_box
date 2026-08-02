import 'exportable.dart';

/// Camera position and zoom, restored when the canvas reopens.
class CanvasViewport with Exportable {
  const CanvasViewport({
    required this.collectionId,
    this.scale = 1.0,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
  });

  factory CanvasViewport.fromDb(Map<String, dynamic> row) {
    return CanvasViewport(
      collectionId: row['collection_id'] as int,
      scale: (row['scale'] as num?)?.toDouble() ?? 1.0,
      offsetX: (row['offset_x'] as num?)?.toDouble() ?? 0.0,
      offsetY: (row['offset_y'] as num?)?.toDouble() ?? 0.0,
    );
  }

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

  final int collectionId;

  final double scale;

  final double offsetX;

  final double offsetY;

  /// Default for a new canvas.
  static const CanvasViewport defaultValue = CanvasViewport(
    collectionId: 0,
  );


  @override
  Set<String> get internalDbFields => const <String>{'collection_id'};

  @override
  Map<String, String> get dbToExportKeyMapping =>
      const <String, String>{'offset_x': 'offsetX', 'offset_y': 'offsetY'};

  @override
  Map<String, dynamic> toDb() {
    return <String, dynamic>{
      'collection_id': collectionId,
      'scale': scale,
      'offset_x': offsetX,
      'offset_y': offsetY,
    };
  }

  @override
  Map<String, dynamic> toExport() {
    return <String, dynamic>{
      'scale': scale,
      'offsetX': offsetX,
      'offsetY': offsetY,
    };
  }

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
