/// Visual grid of category-labelled cells, each holding zero or one media item.
///
/// Second subtype of the Tier Lists feature, alongside the ranked S/A/B/C tier
/// list. A mood grid is not tied to any collection and is not part of `.xcoll`
/// exports — it lives independently and only travels in full app backups.
class MoodGrid {
  /// Creates a [MoodGrid].
  const MoodGrid({
    required this.id,
    required this.name,
    required this.rows,
    required this.cols,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Reconstructs a [MoodGrid] from a row of `mood_grids`.
  factory MoodGrid.fromDb(Map<String, dynamic> row) {
    return MoodGrid(
      id: row['id'] as int,
      name: row['name'] as String,
      rows: row['rows'] as int,
      cols: row['cols'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (row['created_at'] as int) * 1000,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (row['updated_at'] as int) * 1000,
      ),
    );
  }

  /// Reconstructs from a backup export entry.
  factory MoodGrid.fromExport(Map<String, dynamic> json) {
    return MoodGrid(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String,
      rows: json['rows'] as int,
      cols: json['cols'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        ((json['created_at'] as num?)?.toInt() ?? 0) * 1000,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        ((json['updated_at'] as num?)?.toInt() ?? 0) * 1000,
      ),
    );
  }

  /// Primary key.
  final int id;

  /// User-defined title.
  final String name;

  /// Row count (>= 1).
  final int rows;

  /// Column count (>= 1).
  final int cols;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Last update timestamp.
  final DateTime updatedAt;

  /// Total cell count.
  int get cellCount => rows * cols;

  /// Maps to the `mood_grids` row representation.
  Map<String, dynamic> toDb() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'rows': rows,
      'cols': cols,
      'created_at': createdAt.millisecondsSinceEpoch ~/ 1000,
      'updated_at': updatedAt.millisecondsSinceEpoch ~/ 1000,
    };
  }

  /// Maps to the backup JSON shape.
  Map<String, dynamic> toExport() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'rows': rows,
      'cols': cols,
      'created_at': createdAt.millisecondsSinceEpoch ~/ 1000,
      'updated_at': updatedAt.millisecondsSinceEpoch ~/ 1000,
    };
  }

  /// Returns a copy with the listed fields replaced.
  MoodGrid copyWith({
    int? id,
    String? name,
    int? rows,
    int? cols,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MoodGrid(
      id: id ?? this.id,
      name: name ?? this.name,
      rows: rows ?? this.rows,
      cols: cols ?? this.cols,
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
