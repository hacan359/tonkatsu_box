// Модель сериала из TMDB.

import 'dart:convert';

/// Модель сериала из TMDB API.
///
/// Представляет сериал с метаданными из TheMovieDB.
class TvShow {
  /// Создаёт экземпляр [TvShow].
  const TvShow({
    required this.tmdbId,
    required this.title,
    this.originalTitle,
    this.posterUrl,
    this.backdropUrl,
    this.overview,
    this.genres,
    this.firstAirYear,
    this.totalSeasons,
    this.totalEpisodes,
    this.rating,
    this.status,
    this.cachedAt,
  });

  /// Создаёт [TvShow] из JSON ответа TMDB API.
  factory TvShow.fromJson(Map<String, dynamic> json) {
    // Извлекаем URL постера
    String? posterUrl;
    final String? posterPath = json['poster_path'] as String?;
    if (posterPath != null) {
      posterUrl = 'https://image.tmdb.org/t/p/w342$posterPath';
    }

    // Извлекаем URL бэкдропа
    String? backdropUrl;
    final String? backdropPath = json['backdrop_path'] as String?;
    if (backdropPath != null) {
      backdropUrl = 'https://image.tmdb.org/t/p/w780$backdropPath';
    }

    // Извлекаем год из first_air_date (формат: "2008-01-20")
    int? firstAirYear;
    final String? firstAirDate = json['first_air_date'] as String?;
    if (firstAirDate != null && firstAirDate.length >= 4) {
      firstAirYear = int.tryParse(firstAirDate.substring(0, 4));
    }

    // Извлекаем жанры
    List<String>? genres;
    if (json['genres'] != null) {
      final List<dynamic> genresList = json['genres'] as List<dynamic>;
      genres = genresList
          .map((dynamic g) => (g as Map<String, dynamic>)['name'] as String)
          .toList();
    } else if (json['genre_ids'] != null) {
      final List<dynamic> genreIds = json['genre_ids'] as List<dynamic>;
      genres = genreIds.map((dynamic id) => id.toString()).toList();
    }

    return TvShow(
      tmdbId: json['id'] as int,
      title: (json['name'] ?? json['title']) as String,
      originalTitle:
          (json['original_name'] ?? json['original_title']) as String?,
      posterUrl: posterUrl,
      backdropUrl: backdropUrl,
      overview: json['overview'] as String?,
      genres: genres,
      firstAirYear: firstAirYear,
      totalSeasons: json['number_of_seasons'] as int?,
      totalEpisodes: json['number_of_episodes'] as int?,
      rating: (json['vote_average'] as num?)?.toDouble(),
      status: json['status'] as String?,
      cachedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  /// Создаёт [TvShow] из записи базы данных.
  factory TvShow.fromDb(Map<String, dynamic> row) {
    List<String>? genres;
    if (row['genres'] != null && (row['genres'] as String).isNotEmpty) {
      genres = (jsonDecode(row['genres'] as String) as List<dynamic>)
          .map((dynamic g) => g as String)
          .toList();
    }

    return TvShow(
      tmdbId: row['tmdb_id'] as int,
      title: row['title'] as String,
      originalTitle: row['original_title'] as String?,
      posterUrl: row['poster_url'] as String?,
      backdropUrl: row['backdrop_url'] as String?,
      overview: row['overview'] as String?,
      genres: genres,
      firstAirYear: row['first_air_year'] as int?,
      totalSeasons: row['total_seasons'] as int?,
      totalEpisodes: row['total_episodes'] as int?,
      rating: row['rating'] as double?,
      status: row['status'] as String?,
      cachedAt: row['cached_at'] as int?,
    );
  }

  /// Уникальный идентификатор сериала в TMDB.
  final int tmdbId;

  /// Название сериала (локализованное).
  final String title;

  /// Оригинальное название сериала.
  final String? originalTitle;

  /// URL постера сериала.
  final String? posterUrl;

  /// URL бэкдропа сериала.
  final String? backdropUrl;

  /// Описание сериала.
  final String? overview;

  /// Список жанров.
  final List<String>? genres;

  /// Год начала показа.
  final int? firstAirYear;

  /// Общее количество сезонов.
  final int? totalSeasons;

  /// Общее количество эпизодов.
  final int? totalEpisodes;

  /// Рейтинг TMDB (0-10).
  final double? rating;

  /// Статус сериала (Returning Series, Ended, Canceled).
  final String? status;

  /// Время кеширования (Unix timestamp).
  final int? cachedAt;

  /// URL маленького постера (w154) для thumbnail-ов.
  String? get posterThumbUrl {
    if (posterUrl == null) return null;
    return posterUrl!.replaceFirst(RegExp(r'/w\d+'), '/w154');
  }

  /// URL среднего бэкдропа (w300) для экранов деталей.
  String? get backdropSmallUrl {
    if (backdropUrl == null) return null;
    return backdropUrl!.replaceFirst('/w780', '/w300');
  }

  /// Возвращает отформатированный рейтинг.
  String? get formattedRating {
    if (rating == null) return null;
    return rating!.toStringAsFixed(1);
  }

  /// Возвращает жанры в виде строки через запятую.
  String? get genresString => genres?.join(', ');

  /// Преобразует в Map для сохранения в базу данных.
  Map<String, dynamic> toDb() {
    return <String, dynamic>{
      'tmdb_id': tmdbId,
      'title': title,
      'original_title': originalTitle,
      'poster_url': posterUrl,
      'backdrop_url': backdropUrl,
      'overview': overview,
      'genres': genres != null ? jsonEncode(genres) : null,
      'first_air_year': firstAirYear,
      'total_seasons': totalSeasons,
      'total_episodes': totalEpisodes,
      'rating': rating,
      'status': status,
      'cached_at': cachedAt,
    };
  }

  /// Создаёт копию с изменёнными полями.
  TvShow copyWith({
    int? tmdbId,
    String? title,
    String? originalTitle,
    String? posterUrl,
    String? backdropUrl,
    String? overview,
    List<String>? genres,
    int? firstAirYear,
    int? totalSeasons,
    int? totalEpisodes,
    double? rating,
    String? status,
    int? cachedAt,
  }) {
    return TvShow(
      tmdbId: tmdbId ?? this.tmdbId,
      title: title ?? this.title,
      originalTitle: originalTitle ?? this.originalTitle,
      posterUrl: posterUrl ?? this.posterUrl,
      backdropUrl: backdropUrl ?? this.backdropUrl,
      overview: overview ?? this.overview,
      genres: genres ?? this.genres,
      firstAirYear: firstAirYear ?? this.firstAirYear,
      totalSeasons: totalSeasons ?? this.totalSeasons,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      rating: rating ?? this.rating,
      status: status ?? this.status,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TvShow && other.tmdbId == tmdbId;
  }

  @override
  int get hashCode => tmdbId.hashCode;

  @override
  String toString() => 'TvShow(tmdbId: $tmdbId, title: $title)';
}
