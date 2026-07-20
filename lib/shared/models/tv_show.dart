// TV show model shared by all show sources.

import 'dart:convert';

import 'data_source.dart';

/// A TV show with catalog metadata.
class TvShow {
  /// Creates a [TvShow].
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
    this.externalUrl,
    this.cachedAt,
    this.source = DataSource.tmdb,
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

    // Конструируем URL страницы сериала на TMDB
    final int tmdbId = json['id'] as int;

    return TvShow(
      tmdbId: tmdbId,
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
      externalUrl: 'https://www.themoviedb.org/tv/$tmdbId',
      cachedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  /// Creates a [TvShow] from a database row. A missing or unknown `source`
  /// reads as [DataSource.tmdb].
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
      externalUrl: row['external_url'] as String?,
      cachedAt: row['cached_at'] as int?,
      source: DataSource.fromNameOr(row['source'] as String?, DataSource.tmdb),
    );
  }

  /// Show id in the [source] provider's namespace.
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

  /// URL страницы сериала на TMDB.
  final String? externalUrl;

  /// Время кеширования (Unix timestamp).
  final int? cachedAt;

  /// Provider this show came from.
  final DataSource source;

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
      'external_url': externalUrl,
      'cached_at': cachedAt,
      'source': source.name,
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
    String? externalUrl,
    int? cachedAt,
    DataSource? source,
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
      externalUrl: externalUrl ?? this.externalUrl,
      cachedAt: cachedAt ?? this.cachedAt,
      source: source ?? this.source,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TvShow &&
        other.source == source &&
        other.tmdbId == tmdbId;
  }

  @override
  int get hashCode => Object.hash(source, tmdbId);

  @override
  String toString() => 'TvShow(tmdbId: $tmdbId, title: $title)';
}
