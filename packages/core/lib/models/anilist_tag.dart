/// One entry from AniList's `MediaTagCollection`. Per-media tags are stored
/// by name only in `anime_cache.tags` / `manga_cache.tags`; this is the
/// structured catalog backing the picker.
class AniListTag {
  const AniListTag({
    required this.id,
    required this.name,
    this.category,
    this.description,
    this.isAdult = false,
    this.isGeneralSpoiler = false,
    this.updatedAt,
  });

  factory AniListTag.fromJson(Map<String, dynamic> json) => AniListTag(
        id: json['id'] as int,
        name: json['name'] as String,
        category: json['category'] as String?,
        description: json['description'] as String?,
        isAdult: json['isAdult'] as bool? ?? false,
        isGeneralSpoiler: json['isGeneralSpoiler'] as bool? ?? false,
      );

  factory AniListTag.fromDb(Map<String, dynamic> row) => AniListTag(
        id: row['id'] as int,
        name: row['name'] as String,
        category: row['category'] as String?,
        description: row['description'] as String?,
        isAdult: (row['is_adult'] as int) == 1,
        isGeneralSpoiler: (row['is_general_spoiler'] as int) == 1,
        updatedAt: row['updated_at'] as int?,
      );

  final int id;
  final String name;
  final String? category;
  final String? description;
  final bool isAdult;
  final bool isGeneralSpoiler;
  final int? updatedAt;

  Map<String, dynamic> toDb() => <String, dynamic>{
        'id': id,
        'name': name,
        'category': category,
        'description': description,
        'is_adult': isAdult ? 1 : 0,
        'is_general_spoiler': isGeneralSpoiler ? 1 : 0,
        'updated_at': updatedAt ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AniListTag && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'AniListTag(id: $id, name: $name)';
}
