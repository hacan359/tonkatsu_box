import 'dart:typed_data';

import 'package:core/models/media_type.dart';

/// Result of the create / edit custom item form.
class CustomItemData {
  const CustomItemData({
    required this.title,
    required this.mediaType,
    this.altTitle,
    this.description,
    this.year,
    this.coverUrl,
    this.coverBytes,
    this.genres,
    this.platform,
    this.platformId,
    this.format,
    this.unitTotal,
    this.unitGroupTotal,
    this.externalUrl,
    this.comment,
    this.tags = const <String>[],
  });

  final String title;
  final String? altTitle;
  final MediaType mediaType;
  final String? description;
  final int? year;
  final String? coverUrl;

  /// A cover picked as a file, read at pick time. Written into the cover
  /// cache (local on desktop, the server's on web) by the caller.
  final Uint8List? coverBytes;
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

  /// Personal note (`user_comment` on the collection item, not the card).
  /// Only produced by the create flow; the edit flow leaves it null.
  final String? comment;

  /// Global tag names to attach to the created item; missing tags are
  /// created automatically. Only produced by the create flow.
  final List<String> tags;
}
