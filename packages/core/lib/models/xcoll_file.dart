import 'dart:convert';

/// Format version written on export.
const int xcollFormatVersion = 3;

/// v2 and v3 differ only in `user_rating` (int vs double), read via `as num?`.
const int xcollMinReadableVersion = 2;

enum ExportFormat {
  /// Light export — metadata and item ids only.
  light('light'),

  /// Full export — metadata + canvas + base64 images.
  full('full');

  const ExportFormat(this.value);

  final String value;

  static ExportFormat fromString(String value) {
    return ExportFormat.values.firstWhere(
      (ExportFormat f) => f.value == value,
      orElse: () => ExportFormat.light,
    );
  }
}

/// Canvas data (viewport, items, connections) for export.
class ExportCanvas {
  const ExportCanvas({
    this.viewport,
    this.items = const <Map<String, dynamic>>[],
    this.connections = const <Map<String, dynamic>>[],
  });

  factory ExportCanvas.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawItems =
        json['items'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> rawConnections =
        json['connections'] as List<dynamic>? ?? <dynamic>[];

    return ExportCanvas(
      viewport: json['viewport'] as Map<String, dynamic>?,
      items: rawItems
          .map((dynamic item) => item as Map<String, dynamic>)
          .toList(),
      connections: rawConnections
          .map((dynamic conn) => conn as Map<String, dynamic>)
          .toList(),
    );
  }

  final Map<String, dynamic>? viewport;
  final List<Map<String, dynamic>> items;
  final List<Map<String, dynamic>> connections;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (viewport != null) 'viewport': viewport,
      'items': items,
      'connections': connections,
    };
  }
}

/// `.xcoll` is a light export (metadata + item ids); `.xcollx` is full
/// (+ canvas + base64 images).
class XcollFile {
  const XcollFile({
    required this.version,
    required this.name,
    required this.author,
    required this.created,
    this.format = ExportFormat.light,
    this.description,
    this.includesUserData = false,
    this.items = const <Map<String, dynamic>>[],
    this.canvas,
    this.images = const <String, String>{},
    this.media = const <String, dynamic>{},
    this.tierLists,
    this.tags,
    this.trackerData,
  });

  /// Throws [FormatException] on invalid JSON.
  factory XcollFile.fromJsonString(String jsonString) {
    try {
      final Map<String, dynamic> json =
          jsonDecode(jsonString) as Map<String, dynamic>;
      return XcollFile.fromJson(json);
    } on FormatException {
      throw const FormatException('Invalid JSON format');
    } on TypeError catch (e) {
      throw FormatException('Invalid file structure: $e');
    }
  }

  /// Throws [FormatException] when the file version is unsupported.
  factory XcollFile.fromJson(Map<String, dynamic> json) {
    final int version = json['version'] as int? ?? 1;

    if (version < xcollMinReadableVersion) {
      throw FormatException(
        'Unsupported file version: $version. '
        'Minimum supported: $xcollMinReadableVersion',
      );
    }

    if (version > xcollFormatVersion) {
      throw FormatException(
        'Unsupported file version: $version. '
        'Maximum supported: $xcollFormatVersion',
      );
    }

    final String name = json['name'] as String? ?? 'Unnamed Collection';
    final String author = json['author'] as String? ?? 'Unknown';
    final String? description = json['description'] as String?;
    final DateTime created = _parseCreatedDate(json['created']);

    return _parseV2(json, version, name, author, created, description);
  }

  static XcollFile _parseV2(
    Map<String, dynamic> json,
    int version,
    String name,
    String author,
    DateTime created,
    String? description,
  ) {
    final ExportFormat format = ExportFormat.fromString(
      json['format'] as String? ?? ExportFormat.light.value,
    );

    // Items
    final List<dynamic> rawItems =
        json['items'] as List<dynamic>? ?? <dynamic>[];
    final List<Map<String, dynamic>> items = rawItems
        .map((dynamic item) => item as Map<String, dynamic>)
        .toList();

    // Canvas (optional, full export only)
    ExportCanvas? canvas;
    final Map<String, dynamic>? canvasJson =
        json['canvas'] as Map<String, dynamic>?;
    if (canvasJson != null) {
      canvas = ExportCanvas.fromJson(canvasJson);
    }

    // Images (optional, full export only)
    final Map<String, dynamic>? rawImages =
        json['images'] as Map<String, dynamic>?;
    final Map<String, String> images = rawImages != null
        ? rawImages
            .map((String key, dynamic value) =>
                MapEntry<String, String>(key, value as String))
        : const <String, String>{};

    // Media data (optional, full export only)
    final Map<String, dynamic> media =
        json['media'] as Map<String, dynamic>? ?? const <String, dynamic>{};

    // Tier lists (optional, full export only)
    final List<dynamic>? rawTierLists =
        json['tier_lists'] as List<dynamic>?;
    final List<Map<String, dynamic>>? tierLists = rawTierLists
        ?.map((dynamic tl) => tl as Map<String, dynamic>)
        .toList();

    // Tags (optional, full export only)
    final List<dynamic>? rawTags = json['tags'] as List<dynamic>?;
    final List<Map<String, dynamic>>? tags = rawTags
        ?.map((dynamic t) => t as Map<String, dynamic>)
        .toList();

    // Tracker data (optional, full export + user data only)
    final List<dynamic>? rawTrackerData =
        json['tracker_data'] as List<dynamic>?;
    final List<Map<String, dynamic>>? trackerData = rawTrackerData
        ?.map((dynamic td) => td as Map<String, dynamic>)
        .toList();

    final bool includesUserData = json['user_data'] as bool? ?? false;

    return XcollFile(
      version: version,
      format: format,
      name: name,
      author: author,
      created: created,
      description: description,
      includesUserData: includesUserData,
      items: items,
      canvas: canvas,
      images: images,
      media: media,
      tierLists: tierLists,
      tags: tags,
      trackerData: trackerData,
    );
  }

  static DateTime _parseCreatedDate(Object? value) {
    if (value is String) {
      try {
        return DateTime.parse(value);
      } on FormatException {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  final int version;
  final ExportFormat format;
  final String name;
  final String author;
  final DateTime created;
  final String? description;

  /// Whether the export carries personal data (status, dates, notes,
  /// episode progress).
  final bool includesUserData;

  final List<Map<String, dynamic>> items;

  /// Full export only.
  final ExportCanvas? canvas;

  /// Base64 cover images (full export only). Key is
  /// `{ImageType.folder}/{imageId}` (e.g. `game_covers/12345`).
  final Map<String, String> images;

  /// Full media objects, full export only: `{games: [...], movies: [...], ...}`,
  /// each entry a model's `toDb()` map.
  final Map<String, dynamic> media;

  /// Full export only.
  final List<Map<String, dynamic>>? tierLists;

  /// Collection tags with item bindings (full export only).
  final List<Map<String, dynamic>>? tags;

  /// Tracker (RA progress) data for games (full export + user data only).
  final List<Map<String, dynamic>>? trackerData;

  bool get isFull => format == ExportFormat.full;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'version': version,
      'format': format.value,
      'name': name,
      'author': author,
      'created': created.toUtc().toIso8601String(),
      if (description != null) 'description': description,
      if (includesUserData) 'user_data': true,
      'items': items,
      if (canvas != null) 'canvas': canvas!.toJson(),
      if (images.isNotEmpty) 'images': images,
      if (media.isNotEmpty) 'media': media,
      if (tierLists != null) 'tier_lists': tierLists,
      if (tags != null) 'tags': tags,
      if (trackerData != null) 'tracker_data': trackerData,
    };
  }

  String toJsonString() {
    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(toJson());
  }
}
