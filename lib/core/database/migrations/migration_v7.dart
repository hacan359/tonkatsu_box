// Миграция v7: создание таблиц кэша фильмов, сериалов и сезонов.
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../schema.dart';
import 'migration.dart';

/// Миграция v7 — создание таблиц movies_cache, tv_shows_cache,
/// tv_seasons_cache.
class MigrationV7 extends Migration {
  @override
  int get version => 7;

  @override
  String get description =>
      'Create movies_cache, tv_shows_cache, tv_seasons_cache tables';

  @override
  Future<void> migrate(Database db) async {
    await DatabaseSchema.createMoviesCacheTable(db);
    await DatabaseSchema.createTvShowsCacheTable(db);
    await DatabaseSchema.createTvSeasonsCacheTable(db);
  }
}
