// Провайдер для кэширования жанров IGDB.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/igdb_api.dart';
import '../../../core/database/database_service.dart';
import '../../settings/providers/settings_provider.dart';
import '../filters/igdb_genre_filter.dart';

/// Провайдер жанров IGDB.
///
/// Загружает жанры из БД-кэша. Если кэш пуст — загружает из IGDB API и сохраняет.
final FutureProvider<List<IgdbGenre>> igdbGenresProvider =
    FutureProvider<List<IgdbGenre>>((Ref ref) async {
  // Пересчитать при смене учётных данных IGDB
  ref.watch(
    settingsNotifierProvider.select((SettingsState s) => s.accessToken),
  );

  final DatabaseService db = ref.watch(databaseServiceProvider);
  final IgdbApi igdb = ref.watch(igdbApiProvider);

  // Пробуем загрузить из БД-кэша
  final List<Map<String, dynamic>> cached = await db.getIgdbGenres();
  if (cached.isNotEmpty) {
    return cached
        .map(
          (Map<String, dynamic> row) => IgdbGenre(
            id: row['id'] as int,
            name: row['name'] as String,
          ),
        )
        .toList();
  }

  // Кэш пуст — загружаем из API
  final List<Map<String, dynamic>> genresJson = await igdb.fetchGenres();

  if (genresJson.isNotEmpty) {
    await db.cacheIgdbGenres(genresJson);
  }

  return genresJson.map(IgdbGenre.fromJson).toList();
});
