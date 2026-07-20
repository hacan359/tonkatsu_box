// TV episode model shared by all episode sources.

import 'data_source.dart';

/// One episode of a TV show season.
class TvEpisode {
  /// Creates a [TvEpisode].
  const TvEpisode({
    required this.tmdbShowId,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.name,
    this.overview,
    this.airDate,
    this.stillUrl,
    this.runtime,
    this.source = DataSource.tmdb,
  });

  /// Creates a [TvEpisode] from a TMDB API JSON response.
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

  /// Creates a [TvEpisode] from a database row. A missing or unknown
  /// `source` reads as [DataSource.tmdb].
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
      source: DataSource.fromNameOr(row['source'] as String?, DataSource.tmdb),
    );
  }

  /// Show id in the [source] provider's namespace.
  final int tmdbShowId;

  /// Season number.
  final int seasonNumber;

  /// Episode number within the season.
  final int episodeNumber;

  /// Episode title.
  final String name;

  /// Episode overview.
  final String? overview;

  /// Air date ("YYYY-MM-DD").
  final String? airDate;

  /// Still image URL.
  final String? stillUrl;

  /// Runtime in minutes.
  final int? runtime;

  /// Provider this episode came from.
  final DataSource source;

  /// Converts to a map for database storage.
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
      'source': source.name,
      'cached_at': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Returns a copy with the given fields replaced.
  TvEpisode copyWith({
    int? tmdbShowId,
    int? seasonNumber,
    int? episodeNumber,
    String? name,
    String? overview,
    String? airDate,
    String? stillUrl,
    int? runtime,
    DataSource? source,
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
      source: source ?? this.source,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TvEpisode &&
        other.source == source &&
        other.tmdbShowId == tmdbShowId &&
        other.seasonNumber == seasonNumber &&
        other.episodeNumber == episodeNumber;
  }

  @override
  int get hashCode =>
      Object.hash(source, tmdbShowId, seasonNumber, episodeNumber);

  @override
  String toString() =>
      'TvEpisode(showId: $tmdbShowId, S${seasonNumber}E$episodeNumber: $name)';
}
