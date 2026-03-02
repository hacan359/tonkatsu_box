// Провайдер жанров IGDB (статические данные из БД).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_service.dart';
import '../filters/igdb_genre_filter.dart';

/// Провайдер жанров IGDB.
///
/// Загружает жанры из БД (предзаполнены миграцией v24).
final FutureProvider<List<IgdbGenre>> igdbGenresProvider =
    FutureProvider<List<IgdbGenre>>((Ref ref) async {
  final DatabaseService db = ref.watch(databaseServiceProvider);
  final List<Map<String, dynamic>> rows = await db.getIgdbGenres();
  return rows
      .map(
        (Map<String, dynamic> row) => IgdbGenre(
          id: row['id'] as int,
          name: row['name'] as String,
        ),
      )
      .toList();
});
