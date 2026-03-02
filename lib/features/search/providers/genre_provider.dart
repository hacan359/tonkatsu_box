// Провайдеры для жанров TMDB (статические данные из БД).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/tmdb_api.dart';
import '../../../core/database/database_service.dart';
import '../../settings/providers/settings_provider.dart';

/// Провайдер маппинга ID → имя жанров фильмов.
///
/// Читает напрямую из БД (предзаполнены миграцией v24).
/// Инвалидируется при смене языка TMDB.
final FutureProvider<Map<String, String>> movieGenreMapProvider =
    FutureProvider<Map<String, String>>((Ref ref) async {
  return _loadTmdbGenreMap(ref, 'movie');
});

/// Провайдер маппинга ID → имя жанров сериалов.
///
/// Читает напрямую из БД (предзаполнены миграцией v24).
/// Инвалидируется при смене языка TMDB.
final FutureProvider<Map<String, String>> tvGenreMapProvider =
    FutureProvider<Map<String, String>>((Ref ref) async {
  return _loadTmdbGenreMap(ref, 'tv');
});

/// Провайдер жанров фильмов как список [TmdbGenre].
///
/// Использует [movieGenreMapProvider] — без дублирующего запроса к БД.
final FutureProvider<List<TmdbGenre>> movieGenresProvider =
    FutureProvider<List<TmdbGenre>>((Ref ref) async {
  final Map<String, String> genreMap =
      await ref.watch(movieGenreMapProvider.future);
  return _mapToGenreList(genreMap);
});

/// Провайдер жанров сериалов как список [TmdbGenre].
///
/// Использует [tvGenreMapProvider] — без дублирующего запроса к БД.
final FutureProvider<List<TmdbGenre>> tvGenresProvider =
    FutureProvider<List<TmdbGenre>>((Ref ref) async {
  final Map<String, String> genreMap =
      await ref.watch(tvGenreMapProvider.future);
  return _mapToGenreList(genreMap);
});

/// Загружает маппинг жанров TMDB указанного типа из БД.
Future<Map<String, String>> _loadTmdbGenreMap(Ref ref, String type) async {
  final String tmdbLanguage = ref.watch(
      settingsNotifierProvider.select((SettingsState s) => s.tmdbLanguage));
  final String lang = tmdbLanguage.startsWith('ru') ? 'ru' : 'en';
  final DatabaseService db = ref.watch(databaseServiceProvider);
  return db.getTmdbGenreMap(type, lang: lang);
}

/// Конвертирует маппинг ID→name в список [TmdbGenre].
List<TmdbGenre> _mapToGenreList(Map<String, String> genreMap) {
  return genreMap.entries
      .map((MapEntry<String, String> e) =>
          TmdbGenre(id: int.parse(e.key), name: e.value))
      .toList();
}
