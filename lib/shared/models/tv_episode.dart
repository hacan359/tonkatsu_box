// Модель эпизода сериала из TMDB.

/// Модель эпизода сериала из TMDB API.
///
/// Представляет один эпизод конкретного сезона сериала.
class TvEpisode {
  /// Создаёт экземпляр [TvEpisode].
  const TvEpisode({
    required this.tmdbShowId,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.name,
    this.overview,
    this.airDate,
    this.stillUrl,
    this.runtime,
  });

  /// Создаёт [TvEpisode] из JSON ответа TMDB API.
  factory TvEpisode.fromJson(
    Map<String, dynamic> json, {
    required int showId,
    required int season,
  }) {
    String? stillUrl;
    final String? stillPath = json['still_path'] as String?;
    if (stillPath != null) {
      stillUrl = 'https://image.tmdb.org/t/p/w300$stillPath';
    }

    return TvEpisode(
      tmdbShowId: showId,
      seasonNumber: season,
      episodeNumber: json['episode_number'] as int,
      name: json['name'] as String? ?? '',
      overview: json['overview'] as String?,
      airDate: json['air_date'] as String?,
      stillUrl: stillUrl,
      runtime: json['runtime'] as int?,
    );
  }

  /// Создаёт [TvEpisode] из записи базы данных.
  factory TvEpisode.fromDb(Map<String, dynamic> row) {
    return TvEpisode(
      tmdbShowId: row['tmdb_show_id'] as int,
      seasonNumber: row['season_number'] as int,
      episodeNumber: row['episode_number'] as int,
      name: row['name'] as String? ?? '',
      overview: row['overview'] as String?,
      airDate: row['air_date'] as String?,
      stillUrl: row['still_url'] as String?,
      runtime: row['runtime'] as int?,
    );
  }

  /// ID сериала в TMDB.
  final int tmdbShowId;

  /// Номер сезона.
  final int seasonNumber;

  /// Номер эпизода.
  final int episodeNumber;

  /// Название эпизода.
  final String name;

  /// Описание эпизода.
  final String? overview;

  /// Дата выхода (формат: "YYYY-MM-DD").
  final String? airDate;

  /// URL кадра из эпизода (still image).
  final String? stillUrl;

  /// Длительность эпизода в минутах.
  final int? runtime;

  /// Преобразует в Map для сохранения в базу данных.
  Map<String, dynamic> toDb() {
    return <String, dynamic>{
      'tmdb_show_id': tmdbShowId,
      'season_number': seasonNumber,
      'episode_number': episodeNumber,
      'name': name,
      'overview': overview,
      'air_date': airDate,
      'still_url': stillUrl,
      'runtime': runtime,
      'cached_at': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Создаёт копию с изменёнными полями.
  TvEpisode copyWith({
    int? tmdbShowId,
    int? seasonNumber,
    int? episodeNumber,
    String? name,
    String? overview,
    String? airDate,
    String? stillUrl,
    int? runtime,
  }) {
    return TvEpisode(
      tmdbShowId: tmdbShowId ?? this.tmdbShowId,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      name: name ?? this.name,
      overview: overview ?? this.overview,
      airDate: airDate ?? this.airDate,
      stillUrl: stillUrl ?? this.stillUrl,
      runtime: runtime ?? this.runtime,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TvEpisode &&
        other.tmdbShowId == tmdbShowId &&
        other.seasonNumber == seasonNumber &&
        other.episodeNumber == episodeNumber;
  }

  @override
  int get hashCode =>
      Object.hash(tmdbShowId, seasonNumber, episodeNumber);

  @override
  String toString() =>
      'TvEpisode(showId: $tmdbShowId, S${seasonNumber}E$episodeNumber: $name)';
}
