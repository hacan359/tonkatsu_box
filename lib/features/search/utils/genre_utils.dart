import 'package:core/models/movie.dart';
import 'package:core/models/tv_show.dart';

import '../models/search_source.dart' show tmdbAnimationGenreId;

/// Accepts the raw id ("16"), the English name, or a localized name from
/// [genreMap]; case-insensitive, because TMDB and the DAO disagree on casing.
bool isAnimationGenre(String genre, Map<String, String> genreMap) {
  if (genre == '$tmdbAnimationGenreId') return true;
  if (genre.toLowerCase() == 'animation') return true;
  final String? localized = genreMap['$tmdbAnimationGenreId'];
  return localized != null && genre.toLowerCase() == localized.toLowerCase();
}

/// Replace numeric genre ids on each movie with localized names from [genreMap].
List<Movie> resolveMovieGenres(
  List<Movie> movies,
  Map<String, String> genreMap,
) {
  if (genreMap.isEmpty) return movies;
  return movies.map((Movie m) {
    if (m.genres == null || m.genres!.isEmpty) return m;
    final List<String> resolved =
        m.genres!.map((String id) => genreMap[id] ?? id).toList();
    return m.copyWith(genres: resolved);
  }).toList();
}

/// Replace numeric genre ids on each TV show with localized names from [genreMap].
List<TvShow> resolveTvGenres(
  List<TvShow> shows,
  Map<String, String> genreMap,
) {
  if (genreMap.isEmpty) return shows;
  return shows.map((TvShow s) {
    if (s.genres == null || s.genres!.isEmpty) return s;
    final List<String> resolved =
        s.genres!.map((String id) => genreMap[id] ?? id).toList();
    return s.copyWith(genres: resolved);
  }).toList();
}
