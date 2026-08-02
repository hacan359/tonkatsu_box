// One entry from the MangaBaka tag catalog (`/v1/tags`).

/// Tag from MangaBaka's tag catalog. The catalog is hierarchical
/// ([parentId] / [level] / [namePath]); genres are a subset flagged with
/// [isGenre]. Cached in the `mangabaka_tags` table and refreshed on demand.
class MangaBakaTag {
  const MangaBakaTag({
    required this.id,
    required this.name,
    this.parentId,
    this.namePath,
    this.description,
    this.isSpoiler = false,
    this.isGenre = false,
    this.contentRating,
    this.seriesCount = 0,
    this.level = 0,
    this.updatedAt,
  });

  factory MangaBakaTag.fromJson(Map<String, dynamic> json) => MangaBakaTag(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        parentId: (json['parent_id'] as num?)?.toInt(),
        namePath: json['name_path'] as String?,
        description: json['description'] as String?,
        isSpoiler: json['is_spoiler'] as bool? ?? false,
        isGenre: json['is_genre'] as bool? ?? false,
        contentRating: json['content_rating'] as String?,
        seriesCount: (json['series_count'] as num?)?.toInt() ?? 0,
        level: (json['level'] as num?)?.toInt() ?? 0,
      );

  factory MangaBakaTag.fromDb(Map<String, dynamic> row) => MangaBakaTag(
        id: row['id'] as int,
        name: row['name'] as String,
        parentId: row['parent_id'] as int?,
        namePath: row['name_path'] as String?,
        description: row['description'] as String?,
        isSpoiler: (row['is_spoiler'] as int? ?? 0) == 1,
        isGenre: (row['is_genre'] as int? ?? 0) == 1,
        contentRating: row['content_rating'] as String?,
        seriesCount: row['series_count'] as int? ?? 0,
        level: row['level'] as int? ?? 0,
        updatedAt: row['updated_at'] as int?,
      );

  final int id;
  final String name;
  final int? parentId;
  final String? namePath;
  final String? description;
  final bool isSpoiler;
  final bool isGenre;
  final String? contentRating;
  final int seriesCount;
  final int level;
  final int? updatedAt;

  /// `true` for tags MangaBaka marks adult/explicit — hidden by default in
  /// the picker.
  bool get isAdult => contentRating == 'explicit' || contentRating == 'erotica';

  Map<String, dynamic> toDb() => <String, dynamic>{
        'id': id,
        'name': name,
        'parent_id': parentId,
        'name_path': namePath,
        'description': description,
        'is_spoiler': isSpoiler ? 1 : 0,
        'is_genre': isGenre ? 1 : 0,
        'content_rating': contentRating,
        'series_count': seriesCount,
        'level': level,
        'updated_at':
            updatedAt ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MangaBakaTag && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'MangaBakaTag(id: $id, name: $name)';
}
