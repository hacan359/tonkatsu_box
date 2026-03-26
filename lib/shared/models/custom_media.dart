// Модель кастомного медиа-элемента (созданного пользователем).

/// Кастомный медиа-элемент.
///
/// Представляет элемент, созданный пользователем вручную — без API.
/// Аналог [Game], [Movie], [TvShow] для типа [MediaType.custom].
class CustomMedia {
  /// Создаёт экземпляр [CustomMedia].
  const CustomMedia({
    required this.id,
    required this.title,
    this.altTitle,
    this.description,
    this.coverUrl,
    this.year,
    this.genres,
    this.platformName,
    this.externalUrl,
    this.cachedAt,
  });

  /// Создаёт [CustomMedia] из записи базы данных.
  factory CustomMedia.fromDb(Map<String, dynamic> row) {
    return CustomMedia(
      id: row['id'] as int,
      title: row['title'] as String,
      altTitle: row['alt_title'] as String?,
      description: row['description'] as String?,
      coverUrl: row['cover_url'] as String?,
      year: row['year'] as int?,
      genres: row['genres'] as String?,
      platformName: row['platform_name'] as String?,
      externalUrl: row['external_url'] as String?,
      cachedAt: row['cached_at'] as int?,
    );
  }

  /// Уникальный идентификатор.
  final int id;

  /// Основное название.
  final String title;

  /// Альтернативное название (оригинальный язык).
  final String? altTitle;

  /// Описание.
  final String? description;

  /// URL обложки.
  final String? coverUrl;

  /// Год выпуска.
  final int? year;

  /// Жанры через запятую (напр. "RPG, Action, Puzzle").
  final String? genres;

  /// Название платформы (свободный текст, не FK).
  final String? platformName;

  /// URL внешней страницы.
  final String? externalUrl;

  /// Время кэширования (unix timestamp).
  final int? cachedAt;

  /// Список жанров.
  List<String>? get genreList =>
      genres?.split(',').map((String g) => g.trim()).toList();

  /// Преобразует в Map для сохранения в базу данных.
  Map<String, dynamic> toDb() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'alt_title': altTitle,
      'description': description,
      'cover_url': coverUrl,
      'year': year,
      'genres': genres,
      'platform_name': platformName,
      'external_url': externalUrl,
      'cached_at': cachedAt ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
  }

  /// Преобразует в Map для экспорта коллекции.
  Map<String, dynamic> toExport() {
    final Map<String, dynamic> data = toDb();
    data.remove('cached_at');
    return data;
  }

  /// Создаёт копию с изменёнными полями.
  CustomMedia copyWith({
    int? id,
    String? title,
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
    String? externalUrl,
    bool clearExternalUrl = false,
  }) {
    return CustomMedia(
      id: id ?? this.id,
      title: title ?? this.title,
      altTitle: clearAltTitle ? null : (altTitle ?? this.altTitle),
      description:
          clearDescription ? null : (description ?? this.description),
      coverUrl: clearCoverUrl ? null : (coverUrl ?? this.coverUrl),
      year: clearYear ? null : (year ?? this.year),
      genres: clearGenres ? null : (genres ?? this.genres),
      platformName:
          clearPlatformName ? null : (platformName ?? this.platformName),
      externalUrl:
          clearExternalUrl ? null : (externalUrl ?? this.externalUrl),
    );
  }
}
