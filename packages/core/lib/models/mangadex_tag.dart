// One entry from the MangaDex tag catalog (`/manga/tag`).

/// Tag from MangaDex's tag catalog. [group] is one of
/// `genre` / `theme` / `format` / `content`; the genre-group entries feed the
/// genre filter. [id] is the tag UUID passed to `includedTags[]`. Cached in the
/// `mangadex_tags` table and refreshed on demand.
class MangaDexTag {
  const MangaDexTag({
    required this.id,
    required this.name,
    required this.group,
    this.updatedAt,
  });

  factory MangaDexTag.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> attrs =
        (json['attributes'] as Map<String, dynamic>?) ??
            const <String, dynamic>{};
    final Map<String, dynamic> name =
        (attrs['name'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    String label = name['en'] as String? ?? '';
    if (label.isEmpty) {
      for (final Object? v in name.values) {
        if (v is String && v.isNotEmpty) {
          label = v;
          break;
        }
      }
    }
    return MangaDexTag(
      id: json['id'] as String,
      name: label,
      group: attrs['group'] as String? ?? '',
    );
  }

  factory MangaDexTag.fromDb(Map<String, dynamic> row) => MangaDexTag(
        id: row['id'] as String,
        name: row['name'] as String,
        group: row['tag_group'] as String? ?? '',
        updatedAt: row['updated_at'] as int?,
      );

  final String id;
  final String name;
  final String group;
  final int? updatedAt;

  Map<String, dynamic> toDb() => <String, dynamic>{
        'id': id,
        'name': name,
        'tag_group': group,
        'updated_at': updatedAt ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      };
}
