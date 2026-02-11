// Провайдеры для кэширования жанров из TMDB.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/tmdb_api.dart';
import '../../../core/database/database_service.dart';

/// Провайдер жанров фильмов из TMDB.
///
/// Загружает жанры из БД-кэша. Если кэш пуст — загружает из API и сохраняет.
final FutureProvider<List<TmdbGenre>> movieGenresProvider =
    FutureProvider<List<TmdbGenre>>((Ref ref) async {
  final DatabaseService db = ref.watch(databaseServiceProvider);
  final TmdbApi api = ref.watch(tmdbApiProvider);
  return _loadGenres(db, api, 'movie', api.getMovieGenres);
});

/// Провайдер жанров сериалов из TMDB.
///
/// Загружает жанры из БД-кэша. Если кэш пуст — загружает из API и сохраняет.
final FutureProvider<List<TmdbGenre>> tvGenresProvider =
    FutureProvider<List<TmdbGenre>>((Ref ref) async {
  final DatabaseService db = ref.watch(databaseServiceProvider);
  final TmdbApi api = ref.watch(tmdbApiProvider);
  return _loadGenres(db, api, 'tv', api.getTvGenres);
});

/// Провайдер маппинга ID → имя жанров фильмов.
///
/// Удобен для быстрого резолвинга genre_ids без создания промежуточных объектов.
final FutureProvider<Map<String, String>> movieGenreMapProvider =
    FutureProvider<Map<String, String>>((Ref ref) async {
  final List<TmdbGenre> genres = await ref.watch(movieGenresProvider.future);
  return <String, String>{
    for (final TmdbGenre g in genres) g.id.toString(): g.name,
  };
});

/// Провайдер маппинга ID → имя жанров сериалов.
final FutureProvider<Map<String, String>> tvGenreMapProvider =
    FutureProvider<Map<String, String>>((Ref ref) async {
  final List<TmdbGenre> genres = await ref.watch(tvGenresProvider.future);
  return <String, String>{
    for (final TmdbGenre g in genres) g.id.toString(): g.name,
  };
});

/// Загружает жанры: сначала из БД, если пусто — из API с сохранением в БД.
Future<List<TmdbGenre>> _loadGenres(
  DatabaseService db,
  TmdbApi api,
  String type,
  Future<List<TmdbGenre>> Function() fetchFromApi,
) async {
  // Пробуем загрузить из БД-кэша
  final Map<String, String> cached = await db.getTmdbGenreMap(type);
  if (cached.isNotEmpty) {
    return cached.entries
        .where((MapEntry<String, String> e) => int.tryParse(e.key) != null)
        .map((MapEntry<String, String> e) =>
            TmdbGenre(id: int.parse(e.key), name: e.value))
        .toList();
  }

  // Кэш пуст — загружаем из API
  final List<TmdbGenre> genres = await fetchFromApi();

  // Сохраняем в БД
  if (genres.isNotEmpty) {
    await db.cacheTmdbGenres(
      type,
      genres
          .map((TmdbGenre g) => <String, dynamic>{'id': g.id, 'name': g.name})
          .toList(),
    );
  }

  return genres;
}
