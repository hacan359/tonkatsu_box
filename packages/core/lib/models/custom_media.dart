import 'media_type.dart';

/// A user-created item with no API behind it — the [MediaType.custom]
/// counterpart to [Game] / [Movie] / [TvShow].
class CustomMedia {
  const CustomMedia({
    required this.id,
    required this.title,
    this.displayType,
    this.altTitle,
    this.description,
    this.coverUrl,
    this.year,
    this.genres,
    this.platformName,
    this.platformId,
    this.format,
    this.unitTotal,
    this.unitGroupTotal,
    this.externalUrl,
    this.cachedAt,
  });

  factory CustomMedia.fromDb(Map<String, dynamic> row) {
    final String? displayTypeValue = row['display_type'] as String?;
    return CustomMedia(
      id: row['id'] as int,
      title: row['title'] as String,
      displayType: displayTypeValue != null
          ? MediaType.fromString(displayTypeValue)
          : null,
      altTitle: row['alt_title'] as String?,
      description: row['description'] as String?,
      coverUrl: row['cover_url'] as String?,
      year: row['year'] as int?,
      genres: row['genres'] as String?,
      platformName: row['platform_name'] as String?,
      platformId: row['platform_id'] as int?,
      format: row['format'] as String?,
      unitTotal: row['unit_total'] as int?,
      unitGroupTotal: row['unit_group_total'] as int?,
      externalUrl: row['external_url'] as String?,
      cachedAt: row['cached_at'] as int?,
    );
  }

  /// Cover picked from disk. CachedImage gets a non-empty imageUrl, finds the
  /// file already cached, and never reaches for a remote URL.
  static const String localCoverMarker = 'local://cover';

  /// Marker for a freshly picked file. [token] reaches the cache file name, so
  /// a replaced cover lands beside the old one instead of over it.
  static String localCoverMarkerFor(int token) => '$localCoverMarker/$token';

  /// Token of [localCoverMarkerFor]; null for a URL cover and for the markers
  /// written before tokens existed, whose file is named after the card id.
  static String? localCoverToken(String? url) {
    if (url == null || !url.startsWith('$localCoverMarker/')) return null;
    final String token = url.substring(localCoverMarker.length + 1);
    // The token becomes a file name — anything else would escape the folder.
    return _coverToken.hasMatch(token) ? token : null;
  }

  static final RegExp _coverToken = RegExp(r'^[0-9a-z]+$');

  static bool isLocalCover(String? url) =>
      url != null && url.startsWith('local://');

  final int id;

  final String title;

  /// Borrows another type's card styling (color, icon); `null` keeps the
  /// default custom look.
  final MediaType? displayType;

  /// Original-language title.
  final String? altTitle;

  final String? description;

  final String? coverUrl;

  final int? year;

  /// Comma-separated, e.g. `RPG, Action, Puzzle`.
  final String? genres;

  /// Free text, not an FK — a fallback for platforms absent from the catalog.
  /// Mirrored here on a catalog pick so the card renders without a join.
  final String? platformName;

  /// Platform FK value from the `platforms` catalog — only for custom games
  /// (`displayType == game`). `null` when the platform is not from the catalog.
  final int? platformId;

  /// Manga / anime format code (e.g. `MANHWA`, `OVA`) for custom cards with
  /// `displayType == manga`/`anime`. `null` for other types.
  final String? format;

  /// Episodes / chapters / pages / parts per `displayType`; the done position
  /// lives in `collection_items.current_episode`.
  final int? unitTotal;

  /// Seasons or volumes; the done position lives in
  /// `collection_items.current_season`. `null` when the type has no coarse axis.
  final int? unitGroupTotal;

  final String? externalUrl;

  /// Cache timestamp, Unix seconds.
  final int? cachedAt;

  List<String>? get genreList =>
      genres?.split(',').map((String g) => g.trim()).toList();

  Map<String, dynamic> toDb() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'display_type': displayType?.value,
      'alt_title': altTitle,
      'description': description,
      'cover_url': coverUrl,
      'year': year,
      'genres': genres,
      'platform_name': platformName,
      'platform_id': platformId,
      'format': format,
      'unit_total': unitTotal,
      'unit_group_total': unitGroupTotal,
      'external_url': externalUrl,
      'cached_at': cachedAt ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
  }

  Map<String, dynamic> toExport() {
    final Map<String, dynamic> data = toDb();
    data.remove('cached_at');
    return data;
  }

  CustomMedia copyWith({
    int? id,
    String? title,
    MediaType? displayType,
    bool clearDisplayType = false,
    String? altTitle,
    bool clearAltTitle = false,
    String? description,
    bool clearDescription = false,
    String? coverUrl,
    bool clearCoverUrl = false,
    int? year,
    bool clearYear = false,
    String? genres,
    bool clearGenres = false,
    String? platformName,
    bool clearPlatformName = false,
    int? platformId,
    bool clearPlatformId = false,
    String? format,
    bool clearFormat = false,
    int? unitTotal,
    bool clearUnitTotal = false,
    int? unitGroupTotal,
    bool clearUnitGroupTotal = false,
    String? externalUrl,
    bool clearExternalUrl = false,
  }) {
    return CustomMedia(
      id: id ?? this.id,
      title: title ?? this.title,
      displayType:
          clearDisplayType ? null : (displayType ?? this.displayType),
      altTitle: clearAltTitle ? null : (altTitle ?? this.altTitle),
      description:
          clearDescription ? null : (description ?? this.description),
      coverUrl: clearCoverUrl ? null : (coverUrl ?? this.coverUrl),
      year: clearYear ? null : (year ?? this.year),
      genres: clearGenres ? null : (genres ?? this.genres),
      platformName:
          clearPlatformName ? null : (platformName ?? this.platformName),
      platformId: clearPlatformId ? null : (platformId ?? this.platformId),
      format: clearFormat ? null : (format ?? this.format),
      unitTotal: clearUnitTotal ? null : (unitTotal ?? this.unitTotal),
      unitGroupTotal:
          clearUnitGroupTotal ? null : (unitGroupTotal ?? this.unitGroupTotal),
      externalUrl:
          clearExternalUrl ? null : (externalUrl ?? this.externalUrl),
    );
  }
}
