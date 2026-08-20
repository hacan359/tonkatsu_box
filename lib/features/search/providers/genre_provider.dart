import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/tmdb_api.dart';
import '../../../core/database/database_service.dart';
import '../../settings/providers/settings_provider.dart';

/// Reads straight from the DB (seeded by migration v24); invalidated when
/// the TMDB language changes.
final FutureProvider<Map<String, String>> movieGenreMapProvider =
    FutureProvider<Map<String, String>>((Ref ref) async {
  return _loadTmdbGenreMap(ref, 'movie');
});

/// Reads straight from the DB (seeded by migration v24); invalidated when
/// the TMDB language changes.
final FutureProvider<Map<String, String>> tvGenreMapProvider =
    FutureProvider<Map<String, String>>((Ref ref) async {
  return _loadTmdbGenreMap(ref, 'tv');
});

/// Built from [movieGenreMapProvider], so it makes no extra DB query.
final FutureProvider<List<TmdbGenre>> movieGenresProvider =
    FutureProvider<List<TmdbGenre>>((Ref ref) async {
  final Map<String, String> genreMap =
      await ref.watch(movieGenreMapProvider.future);
  return _mapToGenreList(genreMap);
});

/// Built from [tvGenreMapProvider], so it makes no extra DB query.
final FutureProvider<List<TmdbGenre>> tvGenresProvider =
    FutureProvider<List<TmdbGenre>>((Ref ref) async {
  final Map<String, String> genreMap =
      await ref.watch(tvGenreMapProvider.future);
  return _mapToGenreList(genreMap);
});

Future<Map<String, String>> _loadTmdbGenreMap(Ref ref, String type) async {
  final String tmdbLanguage = ref.watch(
      settingsNotifierProvider.select((SettingsState s) => s.tmdbLanguage));
  final String lang = tmdbLanguage.startsWith('ru') ? 'ru' : 'en';
  final DatabaseService db = ref.watch(databaseServiceProvider);
  return db.movieDao.getTmdbGenreMap(type, lang: lang);
}

List<TmdbGenre> _mapToGenreList(Map<String, String> genreMap) {
  return genreMap.entries
      .map((MapEntry<String, String> e) =>
          TmdbGenre(id: int.parse(e.key), name: e.value))
      .toList();
}
