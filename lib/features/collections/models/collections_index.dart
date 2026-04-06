// Модели для каталога онлайн-коллекций (index.json).

/// Платформа из каталога коллекций.
class RemotePlatform {
  /// Создаёт экземпляр [RemotePlatform].
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

  /// Создаёт [RemotePlatform] из JSON.
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

  /// Уникальный идентификатор платформы (e.g. "snes").
  final String id;

  /// Полное название платформы.
  final String name;

  /// Короткое название платформы.
  final String shortName;

  /// ID платформы в IGDB.
  final int? igdbId;

  /// Производитель.
  final String? manufacturer;

  /// Год выхода.
  final int? releaseYear;

  /// Количество коллекций для платформы.
  final int collectionsCount;

  /// Общее количество игр.
  final int gamesCount;
}

/// Тип медиа из каталога (movies, tv-shows, animation).
class RemoteMediaType {
  /// Создаёт экземпляр [RemoteMediaType].
  const RemoteMediaType({
    required this.id,
    required this.name,
    required this.shortName,
    required this.source,
    required this.collectionsCount,
    required this.itemsCount,
  });

  /// Создаёт [RemoteMediaType] из JSON.
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

  /// Уникальный идентификатор (e.g. "movies", "animation").
  final String id;

  /// Название типа медиа.
  final String name;

  /// Короткое название.
  final String shortName;

  /// Источник данных (e.g. "TMDB").
  final String source;

  /// Количество коллекций.
  final int collectionsCount;

  /// Общее количество элементов.
  final int itemsCount;
}

/// Категория коллекций (complete, curated, hidden-gems, challenge).
class CollectionCategory {
  /// Создаёт экземпляр [CollectionCategory].
  const CollectionCategory({
    required this.id,
    required this.name,
    required this.description,
  });

  /// Создаёт [CollectionCategory] из JSON.
  factory CollectionCategory.fromJson(Map<String, dynamic> json) {
    return CollectionCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
    );
  }

  /// Уникальный идентификатор.
  final String id;

  /// Название категории.
  final String name;

  /// Описание.
  final String description;
}

/// Коллекция из онлайн-каталога.
class RemoteCollection {
  /// Создаёт экземпляр [RemoteCollection].
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

  /// Создаёт [RemoteCollection] из JSON.
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
      format: json['format'] as String? ?? 'light',
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

  /// Уникальный идентификатор коллекции.
  final String id;

  /// Название коллекции.
  final String name;

  /// Описание.
  final String description;

  /// Тип медиа ("game", "movies", "animation", "tv-shows", "mixed").
  final String mediaType;

  /// ID платформы (null для не-игровых коллекций).
  final String? platform;

  /// Короткое название платформы.
  final String? platformName;

  /// Категория ("complete", "curated", "hidden-gems", "challenge").
  final String category;

  /// Количество элементов.
  final int itemsCount;

  /// Автор коллекции.
  final String author;

  /// Формат файла ("light" или "full").
  final String format;

  /// Относительный путь к файлу в репозитории.
  final String file;

  /// Дата создания.
  final DateTime? created;

  /// Размер файла в байтах.
  final int size;

  /// Является ли полным экспортом (с картинками, офлайн).
  bool get isFull => format == 'full';

  /// Человекочитаемый размер файла.
  String get sizeFormatted {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(0)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Индекс каталога коллекций (index.json).
class CollectionsIndex {
  /// Создаёт экземпляр [CollectionsIndex].
  const CollectionsIndex({
    required this.version,
    required this.totalCollections,
    required this.totalItems,
    required this.platforms,
    required this.mediaTypes,
    required this.collections,
    required this.categories,
  });

  /// Создаёт [CollectionsIndex] из JSON.
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

  /// Версия формата индекса.
  final int version;

  /// Общее количество коллекций.
  final int totalCollections;

  /// Общее количество элементов во всех коллекциях.
  final int totalItems;

  /// Доступные платформы.
  final List<RemotePlatform> platforms;

  /// Доступные типы медиа.
  final List<RemoteMediaType> mediaTypes;

  /// Все коллекции.
  final List<RemoteCollection> collections;

  /// Категории коллекций.
  final List<CollectionCategory> categories;
}
