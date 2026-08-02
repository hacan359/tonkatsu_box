/// Visual grid of category-labelled cells, each holding zero or one media
/// item. Not tied to any collection; travels only in full app backups.
class MoodGrid {
  const MoodGrid({
    required this.id,
    required this.name,
    required this.rows,
    required this.cols,
    required this.createdAt,
    required this.updatedAt,
    this.captionTemplate,
    this.cellLabelTemplate,
  });

  factory MoodGrid.fromDb(Map<String, dynamic> row) {
    return MoodGrid(
      id: row['id'] as int,
      name: row['name'] as String,
      rows: row['rows'] as int,
      cols: row['cols'] as int,
      captionTemplate: row['caption_template'] as String?,
      cellLabelTemplate: row['cell_label_template'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (row['created_at'] as int) * 1000,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (row['updated_at'] as int) * 1000,
      ),
    );
  }

  factory MoodGrid.fromExport(Map<String, dynamic> json) {
    return MoodGrid(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String,
      rows: json['rows'] as int,
      cols: json['cols'] as int,
      captionTemplate: json['caption_template'] as String?,
      cellLabelTemplate: json['cell_label_template'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        ((json['created_at'] as num?)?.toInt() ?? 0) * 1000,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        ((json['updated_at'] as num?)?.toInt() ?? 0) * 1000,
      ),
    );
  }

  final int id;

  final String name;

  /// Row count (>= 1).
  final int rows;

  /// Column count (>= 1).
  final int cols;

  final DateTime createdAt;

  final DateTime updatedAt;

  /// Right-column caption template; tokens `{{name}}`, `{{year}}`,
  /// `{{genre}}`, `{{rating}}`. Null/empty disables captions.
  final String? captionTemplate;

  /// Auto-fill template for empty cell labels on item pick. Same tokens as
  /// [captionTemplate]; null/empty disables auto-filling.
  final String? cellLabelTemplate;

  int get cellCount => rows * cols;

  Map<String, dynamic> toDb() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'rows': rows,
      'cols': cols,
      'caption_template': captionTemplate,
      'cell_label_template': cellLabelTemplate,
      'created_at': createdAt.millisecondsSinceEpoch ~/ 1000,
      'updated_at': updatedAt.millisecondsSinceEpoch ~/ 1000,
    };
  }

  Map<String, dynamic> toExport() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'rows': rows,
      'cols': cols,
      'caption_template': captionTemplate,
      'cell_label_template': cellLabelTemplate,
      'created_at': createdAt.millisecondsSinceEpoch ~/ 1000,
      'updated_at': updatedAt.millisecondsSinceEpoch ~/ 1000,
    };
  }

  /// Copy with the listed fields replaced; the `clear*Template` flags reset
  /// the matching template to null.
  MoodGrid copyWith({
    int? id,
    String? name,
    int? rows,
    int? cols,
    String? captionTemplate,
    bool clearCaptionTemplate = false,
    String? cellLabelTemplate,
    bool clearCellLabelTemplate = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MoodGrid(
      id: id ?? this.id,
      name: name ?? this.name,
      rows: rows ?? this.rows,
      cols: cols ?? this.cols,
      captionTemplate: clearCaptionTemplate
          ? null
          : (captionTemplate ?? this.captionTemplate),
      cellLabelTemplate: clearCellLabelTemplate
          ? null
          : (cellLabelTemplate ?? this.cellLabelTemplate),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MoodGrid && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'MoodGrid(id: $id, name: $name, ${rows}x$cols)';
}
