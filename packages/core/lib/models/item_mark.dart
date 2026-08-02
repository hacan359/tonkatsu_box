// Universal per-unit mark (like + note) attached to a collection item unit.

/// Preset unit type: a TV / anime episode.
const String kUnitEpisode = 'episode';

/// Preset unit type: a whole season.
const String kUnitSeason = 'season';

/// Preset unit type: a manga / comic chapter.
const String kUnitChapter = 'chapter';

/// Preset unit type: a whole volume.
const String kUnitVolume = 'volume';

/// Preset unit type: a page.
const String kUnitPage = 'page';

/// Preset unit type: a part / arc.
const String kUnitPart = 'part';

/// Preset unit types offered by the "add mark" form. Users may also type an
/// arbitrary string, so this list is not exhaustive — [ItemMark.unitType] is a
/// free-form string, not a strict enum.
const List<String> kUnitPresets = <String>[
  kUnitEpisode,
  kUnitSeason,
  kUnitChapter,
  kUnitVolume,
  kUnitPage,
  kUnitPart,
];

/// Maps a single user-entered [number] to `(parent, unit)` coordinates for a
/// [unitType]: season / volume numbers live in `parent_number`, every other
/// unit's number lives in `unit_number`.
({int parent, int unit}) unitCoordsFor(String unitType, int number) {
  if (unitType == kUnitSeason || unitType == kUnitVolume) {
    return (parent: number, unit: 0);
  }
  return (parent: 0, unit: number);
}

/// A user mark on a single unit inside a collection item: a like (favorite
/// flag) and/or a free-text note. Anchored on `collection_items.id`
/// ([itemId]) so it works for every media type without duplicating the
/// item's `external_id` / `source`.
///
/// The unit is described generically by [unitType] plus two numbers:
/// [parentNumber] (season / volume, or 0 when not applicable) and
/// [unitNumber] (episode / chapter / page number, or 0 for a season/volume
/// row). See the task doc for the full mapping table.
class ItemMark {
  /// Creates an [ItemMark].
  const ItemMark({
    required this.id,
    required this.itemId,
    required this.unitType,
    required this.parentNumber,
    required this.unitNumber,
    required this.isFavorite,
    required this.updatedAt,
    this.userComment,
    this.likedAt,
  });

  /// Builds an [ItemMark] from a database row.
  factory ItemMark.fromDb(Map<String, dynamic> row) {
    final int? likedAtMs = row['liked_at'] as int?;
    return ItemMark(
      id: row['id'] as int,
      itemId: row['item_id'] as int,
      unitType: row['unit_type'] as String,
      parentNumber: (row['parent_number'] as int?) ?? 0,
      unitNumber: (row['unit_number'] as int?) ?? 0,
      isFavorite: (row['is_favorite'] as int?) == 1,
      userComment: row['user_comment'] as String?,
      likedAt: likedAtMs != null
          ? DateTime.fromMillisecondsSinceEpoch(likedAtMs)
          : null,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
    );
  }

  /// Builds an [ItemMark] from an export map (timestamps in seconds). [itemId]
  /// is supplied by the caller because export nests marks inside their item and
  /// the id is remapped on import.
  factory ItemMark.fromExport(
    Map<String, dynamic> json, {
    required int itemId,
  }) {
    final int? likedAtSec = json['liked_at'] as int?;
    final int? updatedAtSec = json['updated_at'] as int?;
    return ItemMark(
      id: 0,
      itemId: itemId,
      unitType: json['unit_type'] as String,
      parentNumber: (json['parent_number'] as int?) ?? 0,
      unitNumber: (json['unit_number'] as int?) ?? 0,
      isFavorite: (json['is_favorite'] as int?) == 1,
      userComment: json['user_comment'] as String?,
      likedAt: likedAtSec != null
          ? DateTime.fromMillisecondsSinceEpoch(likedAtSec * 1000)
          : null,
      updatedAt: updatedAtSec != null
          ? DateTime.fromMillisecondsSinceEpoch(updatedAtSec * 1000)
          : DateTime.now(),
    );
  }

  /// Row id (0 when not yet persisted).
  final int id;

  /// Owning `collection_items.id`.
  final int itemId;

  /// Free-form unit type (see [kUnitPresets]).
  final String unitType;

  /// Season / volume number, or 0 when not applicable.
  final int parentNumber;

  /// Episode / chapter / page number, or 0 for a season/volume-level mark.
  final int unitNumber;

  /// Whether the unit is liked (favorite).
  final bool isFavorite;

  /// Free-text note, or null.
  final String? userComment;

  /// When the like was set, or null.
  final DateTime? likedAt;

  /// Last modification time.
  final DateTime updatedAt;

  /// The number shown to the user: [parentNumber] for season/volume marks,
  /// [unitNumber] otherwise.
  int get displayNumber =>
      (unitType == kUnitSeason || unitType == kUnitVolume)
          ? parentNumber
          : unitNumber;

  /// The note trimmed to null when blank.
  String? get note {
    final String? trimmed = userComment?.trim();
    return (trimmed != null && trimmed.isNotEmpty) ? trimmed : null;
  }

  /// Whether the mark carries anything worth keeping. An empty mark (no like,
  /// no note) is deleted rather than stored.
  bool get hasContent => isFavorite || note != null;

  /// Serialises to a database row. [id] is intentionally omitted so upserts
  /// resolve against the `(item_id, unit_type, parent_number, unit_number)`
  /// unique key instead of the surrogate id.
  Map<String, dynamic> toDb() {
    return <String, dynamic>{
      'item_id': itemId,
      'unit_type': unitType,
      'parent_number': parentNumber,
      'unit_number': unitNumber,
      'is_favorite': isFavorite ? 1 : 0,
      'user_comment': userComment,
      'liked_at': likedAt?.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Serialises for export (timestamps in seconds, no id / item_id — the mark
  /// rides inside its item and is re-anchored on import).
  Map<String, dynamic> toExport() {
    return <String, dynamic>{
      'unit_type': unitType,
      'parent_number': parentNumber,
      'unit_number': unitNumber,
      'is_favorite': isFavorite ? 1 : 0,
      'user_comment': userComment,
      'liked_at': likedAt != null
          ? likedAt!.millisecondsSinceEpoch ~/ 1000
          : null,
      'updated_at': updatedAt.millisecondsSinceEpoch ~/ 1000,
    };
  }

  /// Returns a copy with the given fields replaced.
  ItemMark copyWith({
    int? id,
    int? itemId,
    String? unitType,
    int? parentNumber,
    int? unitNumber,
    bool? isFavorite,
    String? userComment,
    bool clearUserComment = false,
    DateTime? likedAt,
    bool clearLikedAt = false,
    DateTime? updatedAt,
  }) {
    return ItemMark(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      unitType: unitType ?? this.unitType,
      parentNumber: parentNumber ?? this.parentNumber,
      unitNumber: unitNumber ?? this.unitNumber,
      isFavorite: isFavorite ?? this.isFavorite,
      userComment:
          clearUserComment ? null : (userComment ?? this.userComment),
      likedAt: clearLikedAt ? null : (likedAt ?? this.likedAt),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ItemMark &&
        other.itemId == itemId &&
        other.unitType == unitType &&
        other.parentNumber == parentNumber &&
        other.unitNumber == unitNumber;
  }

  @override
  int get hashCode =>
      Object.hash(itemId, unitType, parentNumber, unitNumber);

  @override
  String toString() =>
      'ItemMark(item: $itemId, $unitType p$parentNumber u$unitNumber, '
      'fav: $isFavorite, note: ${userComment != null})';
}
