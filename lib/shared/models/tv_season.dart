// TV season model shared by all episode sources.

import 'data_source.dart';

/// One season of a TV show.
class TvSeason {
  /// Creates a [TvSeason].
  const TvSeason({
    required this.tmdbShowId,
    required this.seasonNumber,
    this.name,
    this.episodeCount,
    this.posterUrl,
    this.airDate,
    this.source = DataSource.tmdb,
  });

  /// Creates a [TvSeason] from a TMDB API JSON response.
  factory TvSeason.fromJson(Map<String, dynamic> json, {required int showId}) {
    String? posterUrl;
    final String? posterPath = json['poster_path'] as String?;
    if (posterPath != null) {
      posterUrl = 'https://image.tmdb.org/t/p/w342$posterPath';
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

  /// Creates a [TvSeason] from a database row. A missing or unknown
  /// `source` reads as [DataSource.tmdb].
  factory TvSeason.fromDb(Map<String, dynamic> row) {
    return TvSeason(
      tmdbShowId: row['tmdb_show_id'] as int,
      seasonNumber: row['season_number'] as int,
      name: row['name'] as String?,
      episodeCount: row['episode_count'] as int?,
      posterUrl: row['poster_url'] as String?,
      airDate: row['air_date'] as String?,
      source: DataSource.fromNameOr(row['source'] as String?, DataSource.tmdb),
    );
  }

  /// Show id in the [source] provider's namespace.
  final int tmdbShowId;

  /// Season number.
  final int seasonNumber;

  /// Season name.
  final String? name;

  /// Number of episodes in the season.
  final int? episodeCount;

  /// Season poster URL.
  final String? posterUrl;

  /// Air date ("YYYY-MM-DD").
  final String? airDate;

  /// Provider this season came from.
  final DataSource source;

  /// Converts to a map for database storage.
  Map<String, dynamic> toDb() {
    return <String, dynamic>{
      'tmdb_show_id': tmdbShowId,
      'season_number': seasonNumber,
      'name': name,
      'episode_count': episodeCount,
      'poster_url': posterUrl,
      'air_date': airDate,
      'source': source.name,
    };
  }

  /// Returns a copy with the given fields replaced.
  TvSeason copyWith({
    int? tmdbShowId,
    int? seasonNumber,
    String? name,
    int? episodeCount,
    String? posterUrl,
    String? airDate,
    DataSource? source,
  }) {
    return TvSeason(
      tmdbShowId: tmdbShowId ?? this.tmdbShowId,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      name: name ?? this.name,
      episodeCount: episodeCount ?? this.episodeCount,
      posterUrl: posterUrl ?? this.posterUrl,
      airDate: airDate ?? this.airDate,
      source: source ?? this.source,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TvSeason &&
        other.source == source &&
        other.tmdbShowId == tmdbShowId &&
        other.seasonNumber == seasonNumber;
  }

  @override
  int get hashCode => Object.hash(source, tmdbShowId, seasonNumber);

  @override
  String toString() =>
      'TvSeason(showId: $tmdbShowId, season: $seasonNumber)';
}
