/// Shared by all collections; items link through the `item_tags` junction, so
/// an item carries any number of tags.
class Tag {
  const Tag({
    required this.id,
    required this.name,
    required this.createdAt,
    this.color,
    this.textColor,
    this.sortOrder = 0,
  });

  factory Tag.fromDb(Map<String, dynamic> row) {
    return Tag(
      id: row['id'] as int,
      name: row['name'] as String,
      color: row['color'] as int?,
      textColor: row['text_color'] as int?,
      sortOrder: row['sort_order'] as int? ?? 0,
      createdAt: row['created_at'] as int,
    );
  }

  factory Tag.fromExport(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String,
      color: json['color'] as int?,
      textColor: json['text_color'] as int?,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: json['created_at'] as int? ?? 0,
    );
  }

  /// Unique identifier.
  final int id;

  /// Tag name (unique app-wide, case-insensitively in Dart).
  final String name;

  /// Background color (ARGB int, nullable).
  final int? color;

  /// Explicit label text color (ARGB int); `null` means default/auto.
  final int? textColor;

  /// Manual ordering in the tag manager.
  final int sortOrder;

  /// Creation time (unix timestamp in seconds).
  final int createdAt;

  /// Converts to a Map for database storage.
  Map<String, dynamic> toDb() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'color': color,
      'text_color': textColor,
      'sort_order': sortOrder,
      'created_at': createdAt,
    };
  }

  /// Converts to a Map for collection export.
  Map<String, dynamic> toExport() {
    return <String, dynamic>{
      'name': name,
      'color': color,
      'text_color': textColor,
      'sort_order': sortOrder,
    };
  }

  /// Case-insensitive match done in Dart via [String.toLowerCase], because
  /// SQLite `LOWER()` only lowercases ASCII while tag names can be Cyrillic.
  static Tag? findByNameCaseInsensitive(Iterable<Tag> tags, String name) {
    final String needle = name.toLowerCase();
    for (final Tag tag in tags) {
      if (tag.name.toLowerCase() == needle) return tag;
    }
    return null;
  }

  /// Trims [parts] into a tag-name list, dropping empties and deduping
  /// case-insensitively (first spelling wins).
  static List<String> dedupeNames(Iterable<String> parts) {
    final Set<String> seen = <String>{};
    final List<String> names = <String>[];
    for (final String part in parts) {
      final String name = part.trim();
      if (name.isEmpty) continue;
      if (seen.add(name.toLowerCase())) names.add(name);
    }
    return names;
  }

  /// [clearColor] / [clearTextColor] reset the nullable colors to `null`.
  Tag copyWith({
    int? id,
    String? name,
    int? color,
    bool clearColor = false,
    int? textColor,
    bool clearTextColor = false,
    int? sortOrder,
    int? createdAt,
  }) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      color: clearColor ? null : (color ?? this.color),
      textColor: clearTextColor ? null : (textColor ?? this.textColor),
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Shared "item's tags" projections so every surface derives the same order.
/// [ids] already arrive in display order from the DAO, and win over this list.
extension TagListProjection on List<Tag> {
  Map<int, Tag> get byId => <int, Tag>{for (final Tag t in this) t.id: t};

  /// The tags of [ids] resolved against this list, keeping [ids] order.
  List<Tag> orderedFor(List<int>? ids) => byId.orderedFor(ids);

  /// The first tag of [ids] resolvable in this list, or `null` when untagged.
  Tag? primaryFor(List<int>? ids) => byId.primaryFor(ids);
}

/// Same projections over a prebuilt map. Hoist [TagListProjection.byId] out of
/// loops — the list helpers rebuild the map on every call.
extension TagMapProjection on Map<int, Tag> {
  List<Tag> orderedFor(List<int>? ids) {
    if (ids == null || ids.isEmpty) return const <Tag>[];
    return <Tag>[
      for (final int id in ids)
        if (this[id] case final Tag tag) tag,
    ];
  }

  Tag? primaryFor(List<int>? ids) {
    if (ids == null || ids.isEmpty) return null;
    for (final int id in ids) {
      final Tag? tag = this[id];
      if (tag != null) return tag;
    }
    return null;
  }
}
