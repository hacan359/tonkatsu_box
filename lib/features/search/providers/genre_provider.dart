// Провайдеры для кэширования жанров из TMDB.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/tmdb_api.dart';

/// Провайдер жанров фильмов из TMDB.
///
/// Загружает список жанров один раз и кэширует в памяти.
final FutureProvider<List<TmdbGenre>> movieGenresProvider =
    FutureProvider<List<TmdbGenre>>((Ref ref) async {
  final TmdbApi api = ref.watch(tmdbApiProvider);
  return api.getMovieGenres();
});

/// Провайдер жанров сериалов из TMDB.
///
/// Загружает список жанров один раз и кэширует в памяти.
final FutureProvider<List<TmdbGenre>> tvGenresProvider =
    FutureProvider<List<TmdbGenre>>((Ref ref) async {
  final TmdbApi api = ref.watch(tmdbApiProvider);
  return api.getTvGenres();
});
