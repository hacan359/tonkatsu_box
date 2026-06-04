// TMDB genre providers, backed by static data in the DB.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/tmdb_api.dart';
import '../../../core/database/database_service.dart';
import '../../settings/providers/settings_provider.dart';

/// Movie genre id -> name map provider.
///
/// Reads straight from the DB (seeded by migration v24).
/// Invalidated when the TMDB language changes.
final FutureProvider<Map<String, String>> movieGenreMapProvider =
    FutureProvider<Map<String, String>>((Ref ref) async {
  return _loadTmdbGenreMap(ref, 'movie');
});

/// TV show genre id -> name map provider.
///
/// Reads straight from the DB (seeded by migration v24).
/// Invalidated when the TMDB language changes.
final FutureProvider<Map<String, String>> tvGenreMapProvider =
    FutureProvider<Map<String, String>>((Ref ref) async {
  return _loadTmdbGenreMap(ref, 'tv');
});

/// Movie genres as a list of [TmdbGenre].
///
/// Built from [movieGenreMapProvider], so it makes no extra DB query.
final FutureProvider<List<TmdbGenre>> movieGenresProvider =
    FutureProvider<List<TmdbGenre>>((Ref ref) async {
  final Map<String, String> genreMap =
      await ref.watch(movieGenreMapProvider.future);
  return _mapToGenreList(genreMap);
});

/// TV show genres as a list of [TmdbGenre].
///
/// Built from [tvGenreMapProvider], so it makes no extra DB query.
final FutureProvider<List<TmdbGenre>> tvGenresProvider =
    FutureProvider<List<TmdbGenre>>((Ref ref) async {
  final Map<String, String> genreMap =
      await ref.watch(tvGenreMapProvider.future);
  return _mapToGenreList(genreMap);
});

/// Loads the TMDB genre map of the given type from the DB.
Future<Map<String, String>> _loadTmdbGenreMap(Ref ref, String type) async {
  final String tmdbLanguage = ref.watch(
      settingsNotifierProvider.select((SettingsState s) => s.tmdbLanguage));
  final String lang = tmdbLanguage.startsWith('ru') ? 'ru' : 'en';
  final DatabaseService db = ref.watch(databaseServiceProvider);
  return db.movieDao.getTmdbGenreMap(type, lang: lang);
}

/// Converts an id -> name map into a list of [TmdbGenre].
List<TmdbGenre> _mapToGenreList(Map<String, String> genreMap) {
  return genreMap.entries
      .map((MapEntry<String, String> e) =>
          TmdbGenre(id: int.parse(e.key), name: e.value))
      .toList();
}
