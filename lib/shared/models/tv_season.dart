// Модель сезона сериала из TMDB.

/// Модель сезона сериала из TMDB API.
///
/// Представляет сезон сериала с метаданными.
class TvSeason {
  /// Создаёт экземпляр [TvSeason].
  const TvSeason({
    required this.tmdbShowId,
    required this.seasonNumber,
    this.name,
    this.episodeCount,
    this.posterUrl,
    this.airDate,
  });

  /// Создаёт [TvSeason] из JSON ответа TMDB API.
  factory TvSeason.fromJson(Map<String, dynamic> json, {required int showId}) {
    String? posterUrl;
    final String? posterPath = json['poster_path'] as String?;
    if (posterPath != null) {
      posterUrl = 'https://image.tmdb.org/t/p/w500$posterPath';
    }

    return TvSeason(
      tmdbShowId: showId,
      seasonNumber: json['season_number'] as int,
      name: json['name'] as String?,
      episodeCount: json['episode_count'] as int?,
      posterUrl: posterUrl,
      airDate: json['air_date'] as String?,
    );
  }

  /// Создаёт [TvSeason] из записи базы данных.
  factory TvSeason.fromDb(Map<String, dynamic> row) {
    return TvSeason(
      tmdbShowId: row['tmdb_show_id'] as int,
      seasonNumber: row['season_number'] as int,
      name: row['name'] as String?,
      episodeCount: row['episode_count'] as int?,
      posterUrl: row['poster_url'] as String?,
      airDate: row['air_date'] as String?,
    );
  }

  /// ID сериала в TMDB.
  final int tmdbShowId;

  /// Номер сезона.
  final int seasonNumber;

  /// Название сезона.
  final String? name;

  /// Количество эпизодов в сезоне.
  final int? episodeCount;

  /// URL постера сезона.
  final String? posterUrl;

  /// Дата выхода сезона (формат: "YYYY-MM-DD").
  final String? airDate;

  /// Преобразует в Map для сохранения в базу данных.
  Map<String, dynamic> toDb() {
    return <String, dynamic>{
      'tmdb_show_id': tmdbShowId,
      'season_number': seasonNumber,
      'name': name,
      'episode_count': episodeCount,
      'poster_url': posterUrl,
      'air_date': airDate,
    };
  }

  /// Создаёт копию с изменёнными полями.
  TvSeason copyWith({
    int? tmdbShowId,
    int? seasonNumber,
    String? name,
    int? episodeCount,
    String? posterUrl,
    String? airDate,
  }) {
    return TvSeason(
      tmdbShowId: tmdbShowId ?? this.tmdbShowId,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      name: name ?? this.name,
      episodeCount: episodeCount ?? this.episodeCount,
      posterUrl: posterUrl ?? this.posterUrl,
      airDate: airDate ?? this.airDate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TvSeason &&
        other.tmdbShowId == tmdbShowId &&
        other.seasonNumber == seasonNumber;
  }

  @override
  int get hashCode => Object.hash(tmdbShowId, seasonNumber);

  @override
  String toString() =>
      'TvSeason(showId: $tmdbShowId, season: $seasonNumber)';
}
