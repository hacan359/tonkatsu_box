import '../../../shared/models/movie.dart';
import '../../../shared/models/tv_show.dart';

class TmdbPagedResult<T> {
  const TmdbPagedResult({
    required this.results,
    required this.page,
    required this.totalPages,
    required this.totalResults,
  });

  final List<T> results;
  final int page;
  final int totalPages;
  final int totalResults;

  bool get hasMore => page < totalPages;
}

/// `/find/{id}` returns both movies and TV shows because an external ID
/// (IMDB / TVDB) may belong to either type.
class TmdbFindResult {
  const TmdbFindResult({
    this.movies = const <Movie>[],
    this.tvShows = const <TvShow>[],
  });

  final List<Movie> movies;
  final List<TvShow> tvShows;

  bool get isEmpty => movies.isEmpty && tvShows.isEmpty;

  Movie? get firstMovie => movies.isNotEmpty ? movies.first : null;
  TvShow? get firstTvShow => tvShows.isNotEmpty ? tvShows.first : null;
}

class TmdbApiException implements Exception {
  const TmdbApiException(this.message, {this.statusCode, this.detail});

  final String message;
  final int? statusCode;
  final String? detail;

  @override
  String toString() => 'TmdbApiException: $message (status: $statusCode)';
}

class TmdbGenre {
  const TmdbGenre({required this.id, required this.name});

  factory TmdbGenre.fromJson(Map<String, dynamic> json) {
    return TmdbGenre(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  final int id;
  final String name;
}

enum TmdbMediaType { movie, tv }

class MultiSearchResult {
  const MultiSearchResult({
    required this.mediaType,
    this.movie,
    this.tvShow,
  });

  final TmdbMediaType mediaType;
  final Movie? movie;
  final TvShow? tvShow;
}
