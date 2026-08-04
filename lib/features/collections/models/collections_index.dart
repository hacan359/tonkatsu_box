import 'package:core/models/xcoll_file.dart';

/// Platform from the collections catalog.
class RemotePlatform {
  const RemotePlatform({
    required this.id,
    required this.name,
    required this.shortName,
    this.igdbId,
    this.manufacturer,
    this.releaseYear,
    required this.collectionsCount,
    required this.gamesCount,
  });

  factory RemotePlatform.fromJson(Map<String, dynamic> json) {
    return RemotePlatform(
      id: json['id'] as String,
      name: json['name'] as String,
      shortName: json['shortName'] as String,
      igdbId: json['igdbId'] as int?,
      manufacturer: json['manufacturer'] as String?,
      releaseYear: json['releaseYear'] as int?,
      collectionsCount: json['collectionsCount'] as int? ?? 0,
      gamesCount: json['gamesCount'] as int? ?? 0,
    );
  }

  /// Platform id (e.g. "snes").
  final String id;

  final String name;

  final String shortName;

  final int? igdbId;

  final String? manufacturer;

  final int? releaseYear;

  final int collectionsCount;

  final int gamesCount;
}

/// Media type from the catalog (movies, tv-shows, animation).
class RemoteMediaType {
  const RemoteMediaType({
    required this.id,
    required this.name,
    required this.shortName,
    required this.source,
    required this.collectionsCount,
    required this.itemsCount,
  });

  factory RemoteMediaType.fromJson(Map<String, dynamic> json) {
    return RemoteMediaType(
      id: json['id'] as String,
      name: json['name'] as String,
      shortName: json['shortName'] as String,
      source: json['source'] as String,
      collectionsCount: json['collectionsCount'] as int? ?? 0,
      itemsCount: json['itemsCount'] as int? ?? 0,
    );
  }

  /// Catalog id (e.g. "movies", "animation").
  final String id;

  final String name;

  final String shortName;

  /// Data provider name (e.g. "TMDB").
  final String source;

  final int collectionsCount;

  final int itemsCount;
}

/// Collection category (complete, curated, hidden-gems, challenge).
class CollectionCategory {
  const CollectionCategory({
    required this.id,
    required this.name,
    required this.description,
  });

  factory CollectionCategory.fromJson(Map<String, dynamic> json) {
    return CollectionCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
    );
  }

  final String id;

  final String name;

  final String description;
}

/// Collection from the online catalog.
class RemoteCollection {
  const RemoteCollection({
    required this.id,
    required this.name,
    required this.description,
    required this.mediaType,
    this.platform,
    this.platformName,
    required this.category,
    required this.itemsCount,
    required this.author,
    required this.format,
    required this.file,
    this.created,
    required this.size,
  });

  factory RemoteCollection.fromJson(Map<String, dynamic> json) {
    return RemoteCollection(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      mediaType: json['mediaType'] as String,
      platform: json['platform'] as String?,
      platformName: json['platformName'] as String?,
      category: json['category'] as String,
      itemsCount: json['itemsCount'] as int? ?? 0,
      author: json['author'] as String? ?? 'Unknown',
      format: json['format'] as String? ?? ExportFormat.light.value,
      file: json['file'] as String,
      created: _parseDate(json['created']),
      size: json['size'] as int? ?? 0,
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  final String id;

  final String name;

  final String description;

  /// Catalog media type ("game", "movies", "animation", "tv-shows", "mixed").
  final String mediaType;

  /// Platform id (null for non-game collections).
  final String? platform;

  final String? platformName;

  /// Category id ("complete", "curated", "hidden-gems", "challenge").
  final String category;

  final int itemsCount;

  final String author;

  /// [ExportFormat] stored value.
  final String format;

  /// File path relative to the repository root.
  final String file;

  final DateTime? created;

  /// File size in bytes.
  final int size;

  /// Whether this is a full export (with images, offline-ready).
  bool get isFull => format == ExportFormat.full.value;

  /// Human-readable file size.
  String get sizeFormatted {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(0)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Collections catalog index (index.json).
class CollectionsIndex {
  const CollectionsIndex({
    required this.version,
    required this.totalCollections,
    required this.totalItems,
    required this.platforms,
    required this.mediaTypes,
    required this.collections,
    required this.categories,
  });

  factory CollectionsIndex.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawPlatforms =
        json['platforms'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> rawMediaTypes =
        json['mediaTypes'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> rawCollections =
        json['collections'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> rawCategories =
        json['categories'] as List<dynamic>? ?? <dynamic>[];

    return CollectionsIndex(
      version: json['version'] as int? ?? 1,
      totalCollections: json['totalCollections'] as int? ?? 0,
      totalItems: json['totalItems'] as int? ?? 0,
      platforms: rawPlatforms
          .map((dynamic p) =>
              RemotePlatform.fromJson(p as Map<String, dynamic>))
          .toList(),
      mediaTypes: rawMediaTypes
          .map((dynamic m) =>
              RemoteMediaType.fromJson(m as Map<String, dynamic>))
          .toList(),
      collections: rawCollections
          .map((dynamic c) =>
              RemoteCollection.fromJson(c as Map<String, dynamic>))
          .toList(),
      categories: rawCategories
          .map((dynamic c) =>
              CollectionCategory.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Index format version.
  final int version;

  final int totalCollections;

  final int totalItems;

  final List<RemotePlatform> platforms;

  final List<RemoteMediaType> mediaTypes;

  final List<RemoteCollection> collections;

  final List<CollectionCategory> categories;
}
