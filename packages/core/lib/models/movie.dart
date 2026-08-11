
import 'dart:convert';

import '../utils/tvdb_json.dart';
import 'data_source.dart';

class Movie {
  const Movie({
    required this.tmdbId,
    required this.title,
    this.originalTitle,
    this.posterUrl,
    this.backdropUrl,
    this.overview,
    this.genres,
    this.releaseYear,
    this.rating,
    this.runtime,
    this.externalUrl,
    this.cachedAt,
    this.source = DataSource.tmdb,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
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

    // release_date arrives as `2010-07-16`.
    int? releaseYear;
    final String? releaseDate = json['release_date'] as String?;
    if (releaseDate != null && releaseDate.length >= 4) {
      releaseYear = int.tryParse(releaseDate.substring(0, 4));
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

    return Movie(
      tmdbId: tmdbId,
      title: json['title'] as String,
      originalTitle: json['original_title'] as String?,
      posterUrl: posterUrl,
      backdropUrl: backdropUrl,
      overview: json['overview'] as String?,
      genres: genres,
      releaseYear: releaseYear,
      rating: (json['vote_average'] as num?)?.toDouble(),
      runtime: json['runtime'] as int?,
      externalUrl: 'https://www.themoviedb.org/movie/$tmdbId',
      cachedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  /// Accepts both TheTVDB shapes: a `/search` hit and a
  /// `/movies/{id}/extended?meta=translations` record. [locale] picks the
  /// title and overview; TheTVDB exposes no user rating, so [rating] stays null.
  factory Movie.fromTvdb(
    Map<String, dynamic> json, {
    String locale = 'en',
  }) {
    final int id = tvdbNumericId(json) ?? 0;
    final ({Object? names, Object? overviews}) t =
        tvdbTranslationContainers(json);

    return Movie(
      tmdbId: id,
      title: tvdbTranslation(t.names, 'name', locale) ??
          json['name'] as String? ??
          '',
      originalTitle: json['name'] as String?,
      posterUrl: tvdbImageUrl(json['image'] ?? json['image_url']),
      overview: tvdbTranslation(t.overviews, 'overview', locale) ??
          json['overview'] as String?,
      genres: tvdbNames(json['genres']),
      releaseYear: tvdbYear(json['year']) ??
          tvdbYear((json['first_release'] as Map<String, dynamic>?)?['date']) ??
          tvdbYear(json['first_air_time']),
      runtime: json['runtime'] as int?,
      externalUrl: tvdbRecordUrl('movies', json['slug'], id),
      cachedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      source: DataSource.tvdb,
    );
  }

  factory Movie.fromDb(Map<String, dynamic> row) {
    List<String>? genres;
    if (row['genres'] != null && (row['genres'] as String).isNotEmpty) {
      genres = (jsonDecode(row['genres'] as String) as List<dynamic>)
          .map((dynamic g) => g as String)
          .toList();
    }

    return Movie(
      tmdbId: row['tmdb_id'] as int,
      title: row['title'] as String,
      originalTitle: row['original_title'] as String?,
      posterUrl: row['poster_url'] as String?,
      backdropUrl: row['backdrop_url'] as String?,
      overview: row['overview'] as String?,
      genres: genres,
      releaseYear: row['release_year'] as int?,
      rating: row['rating'] as double?,
      runtime: row['runtime'] as int?,
      externalUrl: row['external_url'] as String?,
      cachedAt: row['cached_at'] as int?,
      source: DataSource.fromNameOr(row['source'] as String?, DataSource.tmdb),
    );
  }

  /// Movie id in the [source] provider's namespace; the name is historical.
  final int tmdbId;

  final DataSource source;

  /// Localised by the TMDB request language.
  final String title;

  final String? originalTitle;

  final String? posterUrl;

  final String? backdropUrl;

  final String? overview;

  final List<String>? genres;

  final int? releaseYear;

  /// 0–10. Null for providers that expose no user rating (TheTVDB).
  final double? rating;

  final int? runtime;

  final String? externalUrl;

  /// Cache timestamp, Unix seconds.
  final int? cachedAt;

  /// w154 poster for thumbnails; TheTVDB uses a `_t` suffix instead.
  String? get posterThumbUrl {
    if (posterUrl == null) return null;
    if (source == DataSource.tvdb) return tvdbThumbUrl(posterUrl);
    return posterUrl!.replaceFirst(RegExp(r'/w\d+'), '/w154');
  }

  /// w300 backdrop for detail screens.
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
      'release_year': releaseYear,
      'rating': rating,
      'runtime': runtime,
      'external_url': externalUrl,
      'cached_at': cachedAt,
      'source': source.name,
    };
  }

  Movie copyWith({
    int? tmdbId,
    String? title,
    String? originalTitle,
    String? posterUrl,
    String? backdropUrl,
    String? overview,
    List<String>? genres,
    int? releaseYear,
    double? rating,
    int? runtime,
    String? externalUrl,
    int? cachedAt,
    DataSource? source,
  }) {
    return Movie(
      tmdbId: tmdbId ?? this.tmdbId,
      title: title ?? this.title,
      originalTitle: originalTitle ?? this.originalTitle,
      posterUrl: posterUrl ?? this.posterUrl,
      backdropUrl: backdropUrl ?? this.backdropUrl,
      overview: overview ?? this.overview,
      genres: genres ?? this.genres,
      releaseYear: releaseYear ?? this.releaseYear,
      rating: rating ?? this.rating,
      runtime: runtime ?? this.runtime,
      externalUrl: externalUrl ?? this.externalUrl,
      cachedAt: cachedAt ?? this.cachedAt,
      source: source ?? this.source,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Movie && other.tmdbId == tmdbId && other.source == source;
  }

  @override
  int get hashCode => Object.hash(tmdbId, source);

  @override
  String toString() =>
      'Movie(tmdbId: $tmdbId, title: $title, source: ${source.name})';
}
