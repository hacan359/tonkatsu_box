
import 'dart:convert';

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
    );
  }

  final int tmdbId;

  /// Localised by the TMDB request language.
  final String title;

  final String? originalTitle;

  final String? posterUrl;

  final String? backdropUrl;

  final String? overview;

  final List<String>? genres;

  final int? releaseYear;

  /// TMDB scale is already 0–10.
  final double? rating;

  final int? runtime;

  final String? externalUrl;

  /// Cache timestamp, Unix seconds.
  final int? cachedAt;

  /// w154 poster for thumbnails.
  String? get posterThumbUrl {
    if (posterUrl == null) return null;
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
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Movie && other.tmdbId == tmdbId;
  }

  @override
  int get hashCode => tmdbId.hashCode;

  @override
  String toString() => 'Movie(tmdbId: $tmdbId, title: $title)';
}
