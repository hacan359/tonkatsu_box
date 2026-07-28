import 'package:core/utils/tvmaze_json.dart';
import 'data_source.dart';

/// One season of a TV show.
class TvSeason {
  const TvSeason({
    required this.tmdbShowId,
    required this.seasonNumber,
    this.name,
    this.episodeCount,
    this.posterUrl,
    this.airDate,
    this.source = DataSource.tmdb,
  });

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

  /// From a TVmaze `season` object (`/shows/{id}/seasons`).
  factory TvSeason.fromTvMaze(Map<String, dynamic> json, {required int showId}) {
    final String? rawName = json['name'] as String?;
    return TvSeason(
      tmdbShowId: showId,
      seasonNumber: json['number'] as int,
      name: (rawName == null || rawName.isEmpty) ? null : rawName,
      episodeCount: json['episodeOrder'] as int?,
      posterUrl: tvMazeImageUrl(json['image']),
      airDate: json['premiereDate'] as String?,
      source: DataSource.tvmaze,
    );
  }

  /// A missing or unknown `source` column reads as [DataSource.tmdb].
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

  final int seasonNumber;
  final String? name;
  final int? episodeCount;
  final String? posterUrl;

  /// "YYYY-MM-DD".
  final String? airDate;

  final DataSource source;

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
