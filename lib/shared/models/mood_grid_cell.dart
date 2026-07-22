import 'data_source.dart';
import 'media_type.dart';

/// Cell of a [MoodGrid]: optional [label] plus a denormalised media reference
/// with no FK — survives item removal, renders from `*_cache`.
class MoodGridCell {
  const MoodGridCell({
    required this.id,
    required this.gridId,
    required this.position,
    this.label,
    this.mediaType,
    this.externalId,
    this.platformId,
    this.source,
  });

  factory MoodGridCell.fromDb(Map<String, dynamic> row) {
    final String? rawType = row['media_type'] as String?;
    return MoodGridCell(
      id: row['id'] as int,
      gridId: row['grid_id'] as int,
      position: row['position'] as int,
      label: row['label'] as String?,
      mediaType: rawType == null ? null : MediaType.fromString(rawType),
      externalId: row['external_id'] as int?,
      platformId: row['platform_id'] as int?,
      source: row['source'] != null
          ? DataSource.fromName(row['source'] as String?)
          : null,
    );
  }

  factory MoodGridCell.fromExport(Map<String, dynamic> json) {
    final String? rawType = json['media_type'] as String?;
    return MoodGridCell(
      id: json['id'] as int? ?? 0,
      gridId: json['grid_id'] as int? ?? 0,
      position: json['position'] as int,
      label: json['label'] as String?,
      mediaType: rawType == null ? null : MediaType.fromString(rawType),
      externalId: (json['external_id'] as num?)?.toInt(),
      platformId: (json['platform_id'] as num?)?.toInt(),
      source: json['source'] != null
          ? DataSource.fromName(json['source'] as String?)
          : null,
    );
  }

  final int id;

  final int gridId;

  /// Zero-based row-major index: `row * cols + col`.
  final int position;

  /// Category label shown under the cover. `null` means no caption.
  final String? label;

  /// Media type of the picked item. `null` means the cell is empty.
  final MediaType? mediaType;

  /// External id of the picked item (IGDB / TMDB / AniList / etc.).
  final int? externalId;

  /// Optional platform id for games. `null` for non-game cells.
  final int? platformId;

  /// Provider for manga cells ([DataSource.anilist] / [DataSource.mangabaka]);
  /// `null` for other media types. Disambiguates a shared manga `externalId`.
  final DataSource? source;

  bool get isEmpty => mediaType == null || externalId == null;

  Map<String, dynamic> toDb() {
    return <String, dynamic>{
      'id': id,
      'grid_id': gridId,
      'position': position,
      'label': label,
      'media_type': mediaType?.value,
      'external_id': externalId,
      'platform_id': platformId,
      'source': source?.name,
    };
  }

  /// Maps to the backup JSON shape (without ids — the importer recreates them).
  Map<String, dynamic> toExport() {
    return <String, dynamic>{
      'position': position,
      'label': label,
      'media_type': mediaType?.value,
      'external_id': externalId,
      'platform_id': platformId,
      if (source != null) 'source': source!.name,
    };
  }

  MoodGridCell copyWith({
    int? id,
    int? gridId,
    int? position,
    String? label,
    bool clearLabel = false,
    MediaType? mediaType,
    int? externalId,
    int? platformId,
    DataSource? source,
    bool clearItem = false,
  }) {
    return MoodGridCell(
      id: id ?? this.id,
      gridId: gridId ?? this.gridId,
      position: position ?? this.position,
      label: clearLabel ? null : (label ?? this.label),
      mediaType: clearItem ? null : (mediaType ?? this.mediaType),
      externalId: clearItem ? null : (externalId ?? this.externalId),
      platformId: clearItem ? null : (platformId ?? this.platformId),
      source: clearItem ? null : (source ?? this.source),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MoodGridCell && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'MoodGridCell(id: $id, grid: $gridId, pos: $position, '
      'label: $label, item: $mediaType/$externalId)';
}
