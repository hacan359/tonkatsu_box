// Утилиты для работы с жанрами в поисковых источниках.

import '../../../shared/models/movie.dart';
import '../../../shared/models/tv_show.dart';
import '../models/search_source.dart' show tmdbAnimationGenreId;

/// Проверяет, является ли строка жанра анимацией (TMDB genre ID 16).
bool isAnimationGenre(String genre) =>
    genre == '$tmdbAnimationGenreId' || genre == 'Animation';

/// Резолвит ID жанров в названия для списка фильмов.
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

/// Резолвит ID жанров в названия для списка сериалов.
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
