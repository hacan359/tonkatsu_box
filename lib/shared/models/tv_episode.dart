import 'package:core/utils/html_text.dart';
import 'package:core/utils/tvmaze_json.dart';
import 'data_source.dart';

/// One episode of a TV show season.
class TvEpisode {
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

  /// A missing or unknown `source` column reads as [DataSource.tmdb].
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

  /// From a TVmaze `episode` object; null when season/episode number is missing.
  static TvEpisode? tryFromTvMaze(
    Map<String, dynamic> json, {
    required int showId,
  }) {
    final int? season = json['season'] as int?;
    final int? number = json['number'] as int?;
    if (season == null || number == null) return null;

    final String? airdate = json['airdate'] as String?;
    return TvEpisode(
      tmdbShowId: showId,
      seasonNumber: season,
      episodeNumber: number,
      name: json['name'] as String? ?? '',
      overview: stripHtmlText(json['summary'] as String?),
      airDate: (airdate == null || airdate.isEmpty) ? null : airdate,
      stillUrl: tvMazeImageUrl(json['image']),
      runtime: json['runtime'] as int?,
      source: DataSource.tvmaze,
    );
  }

  /// From a Kitsu `episodes` resource; null when the episode number is missing.
  ///
  /// Kitsu's `synopsis` is plain text, so no HTML stripping. Episodes without a
  /// `seasonNumber` fall into season 1 — the synthesized season Kitsu anime use.
  static TvEpisode? tryFromKitsu(
    Map<String, dynamic> json, {
    required int showId,
  }) {
    final Map<String, dynamic> attrs =
        (json['attributes'] as Map<String, dynamic>?) ??
            const <String, dynamic>{};

    final int? number = (attrs['number'] as num?)?.toInt();
    if (number == null) return null;

    final Map<String, dynamic> titles =
        (attrs['titles'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    final String? airdate = attrs['airdate'] as String?;
    final Map<String, dynamic>? thumbnail =
        attrs['thumbnail'] as Map<String, dynamic>?;

    return TvEpisode(
      tmdbShowId: showId,
      seasonNumber: (attrs['seasonNumber'] as num?)?.toInt() ?? 1,
      episodeNumber: number,
      name: _firstNonEmpty(<Object?>[
            attrs['canonicalTitle'],
            titles['en_us'],
            titles['en_jp'],
            titles['ja_jp'],
          ]) ??
          '',
      overview: _firstNonEmpty(<Object?>[attrs['synopsis']]),
      airDate: (airdate == null || airdate.isEmpty) ? null : airdate,
      stillUrl: _firstNonEmpty(<Object?>[thumbnail?['original']]),
      runtime: (attrs['length'] as num?)?.toInt(),
      source: DataSource.kitsu,
    );
  }

  static String? _firstNonEmpty(List<Object?> values) {
    for (final Object? value in values) {
      if (value is String && value.isNotEmpty) return value;
    }
    return null;
  }

  /// Show id in the [source] provider's namespace.
  final int tmdbShowId;

  final int seasonNumber;
  final int episodeNumber;
  final String name;
  final String? overview;

  /// "YYYY-MM-DD".
  final String? airDate;

  final String? stillUrl;

  /// Runtime in minutes.
  final int? runtime;

  final DataSource source;

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
