import '../../../../shared/models/media_type.dart';

/// Result of the create / edit custom item form.
class CustomItemData {
  const CustomItemData({
    required this.title,
    required this.mediaType,
    this.altTitle,
    this.description,
    this.year,
    this.coverUrl,
    this.localCoverPath,
    this.genres,
    this.platform,
    this.platformId,
    this.format,
    this.unitTotal,
    this.unitGroupTotal,
    this.externalUrl,
  });

  final String title;
  final String? altTitle;
  final MediaType mediaType;
  final String? description;
  final int? year;
  final String? coverUrl;
  final String? localCoverPath;
  final String? genres;

  /// Platform display name (only set for the game display type).
  final String? platform;

  /// Platform reference id from the `platforms` catalog (game display type).
  final int? platformId;

  /// Manga / anime format code (e.g. `MANHWA`, `OVA`).
  final String? format;

  /// Total fine progress units (episodes / chapters / pages / parts).
  final int? unitTotal;

  /// Total coarse progress units (seasons / volumes), when the type has them.
  final int? unitGroupTotal;

  final String? externalUrl;
}
