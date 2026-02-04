/// Модель игры из IGDB.
///
/// Представляет игру с метаданными из IGDB API.
class Game {
  /// Создаёт экземпляр [Game].
  const Game({
    required this.id,
    required this.name,
    this.summary,
    this.coverUrl,
    this.releaseDate,
    this.rating,
    this.ratingCount,
    this.genres,
    this.platformIds,
    this.cachedAt,
  });

  /// Создаёт [Game] из JSON ответа IGDB API.
  factory Game.fromJson(Map<String, dynamic> json) {
    // Извлекаем URL обложки из вложенного объекта cover
    String? coverUrl;
    if (json['cover'] != null) {
      final Map<String, dynamic> cover = json['cover'] as Map<String, dynamic>;
      final String? imageId = cover['image_id'] as String?;
      if (imageId != null) {
        // Используем размер cover_big (264x374)
        coverUrl = 'https://images.igdb.com/igdb/image/upload/t_cover_big/$imageId.jpg';
      }
    }

    // Извлекаем список жанров
    List<String>? genres;
    if (json['genres'] != null) {
      final List<dynamic> genresList = json['genres'] as List<dynamic>;
      genres = genresList
          .map((dynamic g) => (g as Map<String, dynamic>)['name'] as String)
          .toList();
    }

    // Извлекаем список платформ (только ID)
    List<int>? platformIds;
    if (json['platforms'] != null) {
      final List<dynamic> platformsList = json['platforms'] as List<dynamic>;
      platformIds = platformsList.map((dynamic p) => p as int).toList();
    }

    // Конвертируем Unix timestamp в DateTime
    DateTime? releaseDate;
    if (json['first_release_date'] != null) {
      releaseDate = DateTime.fromMillisecondsSinceEpoch(
        (json['first_release_date'] as int) * 1000,
      );
    }

    return Game(
      id: json['id'] as int,
      name: json['name'] as String,
      summary: json['summary'] as String?,
      coverUrl: coverUrl,
      releaseDate: releaseDate,
      rating: (json['rating'] as num?)?.toDouble(),
      ratingCount: json['rating_count'] as int?,
      genres: genres,
      platformIds: platformIds,
      cachedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  /// Создаёт [Game] из записи базы данных.
  factory Game.fromDb(Map<String, dynamic> row) {
    // Парсим JSON строки для списков
    List<String>? genres;
    if (row['genres'] != null && (row['genres'] as String).isNotEmpty) {
      genres = (row['genres'] as String).split('|');
    }

    List<int>? platformIds;
    if (row['platform_ids'] != null &&
        (row['platform_ids'] as String).isNotEmpty) {
      platformIds = (row['platform_ids'] as String)
          .split(',')
          .map((String s) => int.parse(s))
          .toList();
    }

    DateTime? releaseDate;
    if (row['release_date'] != null) {
      releaseDate = DateTime.fromMillisecondsSinceEpoch(
        (row['release_date'] as int) * 1000,
      );
    }

    return Game(
      id: row['id'] as int,
      name: row['name'] as String,
      summary: row['summary'] as String?,
      coverUrl: row['cover_url'] as String?,
      releaseDate: releaseDate,
      rating: row['rating'] as double?,
      ratingCount: row['rating_count'] as int?,
      genres: genres,
      platformIds: platformIds,
      cachedAt: row['cached_at'] as int?,
    );
  }

  /// Уникальный идентификатор игры в IGDB.
  final int id;

  /// Название игры.
  final String name;

  /// Краткое описание игры.
  final String? summary;

  /// URL обложки игры.
  final String? coverUrl;

  /// Дата первого релиза.
  final DateTime? releaseDate;

  /// Рейтинг IGDB (0-100).
  final double? rating;

  /// Количество оценок.
  final int? ratingCount;

  /// Список жанров.
  final List<String>? genres;

  /// Список ID платформ.
  final List<int>? platformIds;

  /// Время кеширования (Unix timestamp).
  final int? cachedAt;

  /// Возвращает год релиза или null.
  int? get releaseYear => releaseDate?.year;

  /// Возвращает отформатированный рейтинг (0-10).
  String? get formattedRating {
    if (rating == null) return null;
    return (rating! / 10).toStringAsFixed(1);
  }

  /// Возвращает жанры в виде строки через запятую.
  String? get genresString => genres?.join(', ');

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Game && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Game(id: $id, name: $name)';

  /// Преобразует в Map для сохранения в базу данных.
  Map<String, dynamic> toDb() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'summary': summary,
      'cover_url': coverUrl,
      'release_date': releaseDate != null
          ? releaseDate!.millisecondsSinceEpoch ~/ 1000
          : null,
      'rating': rating,
      'rating_count': ratingCount,
      'genres': genres?.join('|'),
      'platform_ids': platformIds?.join(','),
      'cached_at': cachedAt,
    };
  }

  /// Преобразует в JSON для API.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'summary': summary,
      'cover_url': coverUrl,
      'release_date': releaseDate != null
          ? releaseDate!.millisecondsSinceEpoch ~/ 1000
          : null,
      'rating': rating,
      'rating_count': ratingCount,
      'genres': genres,
      'platform_ids': platformIds,
    };
  }

  /// Создаёт копию с изменёнными полями.
  Game copyWith({
    int? id,
    String? name,
    String? summary,
    String? coverUrl,
    DateTime? releaseDate,
    double? rating,
    int? ratingCount,
    List<String>? genres,
    List<int>? platformIds,
    int? cachedAt,
  }) {
    return Game(
      id: id ?? this.id,
      name: name ?? this.name,
      summary: summary ?? this.summary,
      coverUrl: coverUrl ?? this.coverUrl,
      releaseDate: releaseDate ?? this.releaseDate,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      genres: genres ?? this.genres,
      platformIds: platformIds ?? this.platformIds,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }
}
