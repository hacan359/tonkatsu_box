import 'dart:convert';

import 'data_source.dart';
import '../utils/html_text.dart';
import '../utils/tvdb_json.dart';
import '../utils/tvmaze_json.dart';

/// A TV show with catalog metadata.
class TvShow {
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

  factory TvShow.fromJson(Map<String, dynamic> json) {
    String? posterUrl;
    final String? posterPath = json['poster_path'] as String?;
    if (posterPath != null) {
      posterUrl = 'https://image.tmdb.org/t/p/w342$posterPath';
    }

    String? backdropUrl;
    final String? backdropPath = json['backdrop_path'] as String?;
    if (backdropPath != null) {
      backdropUrl = 'https://image.tmdb.org/t/p/w780$backdropPath';
    }

    // first_air_date is "YYYY-MM-DD".
    int? firstAirYear;
    final String? firstAirDate = json['first_air_date'] as String?;
    if (firstAirDate != null && firstAirDate.length >= 4) {
      firstAirYear = int.tryParse(firstAirDate.substring(0, 4));
    }

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

  /// From a TVmaze `show` object (search result or `/shows/{id}`).
  factory TvShow.fromTvMaze(Map<String, dynamic> json) {
    final int id = json['id'] as int;

    List<String>? genres;
    final Object? rawGenres = json['genres'];
    if (rawGenres is List<dynamic>) {
      genres = rawGenres.whereType<String>().toList();
      if (genres.isEmpty) genres = null;
    }

    int? firstAirYear;
    final String? premiered = json['premiered'] as String?;
    if (premiered != null && premiered.length >= 4) {
      firstAirYear = int.tryParse(premiered.substring(0, 4));
    }

    int? totalSeasons;
    int? totalEpisodes;
    final Object? embedded = json['_embedded'];
    if (embedded is Map<String, dynamic>) {
      final Object? seasons = embedded['seasons'];
      if (seasons is List<dynamic>) {
        totalSeasons = seasons.length;
        int episodes = 0;
        for (final dynamic s in seasons) {
          if (s is Map<String, dynamic>) {
            // `episodeOrder` is null for a currently-airing season, so the
            // total undercounts until the season finishes.
            episodes += (s['episodeOrder'] as int?) ?? 0;
          }
        }
        if (episodes > 0) totalEpisodes = episodes;
      }
    }

    return TvShow(
      tmdbId: id,
      title: json['name'] as String,
      posterUrl: tvMazeImageUrl(json['image']),
      overview: stripHtmlText(json['summary'] as String?),
      genres: genres,
      firstAirYear: firstAirYear,
      totalSeasons: totalSeasons,
      totalEpisodes: totalEpisodes,
      rating: tvMazeRating(json['rating']),
      status: json['status'] as String?,
      externalUrl: json['url'] as String?,
      cachedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      source: DataSource.tvmaze,
    );
  }

  /// Accepts both TheTVDB shapes. TheTVDB has only a popularity score and no
  /// user rating, so [rating] stays null.
  factory TvShow.fromTvdb(
    Map<String, dynamic> json, {
    String locale = 'en',
  }) {
    final int id = tvdbNumericId(json) ?? 0;
    final ({Object? names, Object? overviews}) t =
        tvdbTranslationContainers(json);

    final Object? rawStatus = json['status'];
    final String? status = rawStatus is Map<String, dynamic>
        ? rawStatus['name'] as String?
        : rawStatus as String?;

    final Object? seasons = json['seasons'];
    int? totalSeasons;
    if (seasons is List<dynamic>) {
      // Season 0 is the specials bucket and is not a season of the show.
      totalSeasons = seasons
          .whereType<Map<String, dynamic>>()
          .where((Map<String, dynamic> s) =>
              (s['type'] as Map<String, dynamic>?)?['id'] == 1 &&
              (s['number'] as int? ?? 0) > 0)
          .length;
      if (totalSeasons == 0) totalSeasons = null;
    }

    return TvShow(
      tmdbId: id,
      title: tvdbTranslation(t.names, 'name', locale) ??
          json['name'] as String? ??
          '',
      originalTitle: json['name'] as String?,
      posterUrl: tvdbImageUrl(json['image'] ?? json['image_url']),
      overview: tvdbTranslation(t.overviews, 'overview', locale) ??
          json['overview'] as String?,
      genres: tvdbNames(json['genres']),
      firstAirYear:
          tvdbYear(json['year']) ?? tvdbYear(json['firstAired']) ??
              tvdbYear(json['first_air_time']),
      totalSeasons: totalSeasons,
      status: status,
      externalUrl: tvdbRecordUrl('series', json['slug'], id),
      cachedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      source: DataSource.tvdb,
    );
  }

  /// A missing or unknown `source` column reads as [DataSource.tmdb].
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

  final String title;

  final String? originalTitle;

  final String? posterUrl;

  final String? backdropUrl;

  final String? overview;

  final List<String>? genres;

  final int? firstAirYear;

  final int? totalSeasons;

  final int? totalEpisodes;

  /// 0-10.
  final double? rating;

  /// TMDB value: "Returning Series", "Ended", "Canceled".
  final String? status;

  final String? externalUrl;

  /// Unix millis.
  final int? cachedAt;

  final DataSource source;

  /// w154 variant for thumbnails.
  String? get posterThumbUrl {
    if (posterUrl == null) return null;
    return posterUrl!.replaceFirst(RegExp(r'/w\d+'), '/w154');
  }

  /// w300 variant for detail screens.
  String? get backdropSmallUrl {
    if (backdropUrl == null) return null;
    return backdropUrl!.replaceFirst('/w780', '/w300');
  }

  String? get formattedRating {
    if (rating == null) return null;
    return rating!.toStringAsFixed(1);
  }

  String? get genresString => genres?.join(', ');

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
