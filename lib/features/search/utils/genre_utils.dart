import '../../../shared/models/movie.dart';
import '../../../shared/models/tv_show.dart';
import '../models/search_source.dart' show tmdbAnimationGenreId;

/// True if [genre] is the TMDB animation genre. Accepts the raw id ("16"),
/// English name, and the localized name resolved via [genreMap].
///
/// Comparison is case-insensitive: TMDB returns the localized name as it
/// stored it (e.g. `"мультфильм"` for `ru-RU`), but our local DAO
/// capitalises the first letter on read — without ignoreCase the two
/// would diverge and the filter would silently drop every animation row.
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
