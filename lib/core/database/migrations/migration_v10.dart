// Миграция v10: создание таблиц tv_episodes_cache и watched_episodes.
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../schema.dart';
import 'migration.dart';

/// Миграция v10 — создание таблиц tv_episodes_cache и watched_episodes.
class MigrationV10 extends Migration {
  @override
  int get version => 10;

  @override
  String get description =>
      'Create tv_episodes_cache and watched_episodes tables';

  @override
  Future<void> migrate(Database db) async {
    await DatabaseSchema.createTvEpisodesCacheTable(db);
    await DatabaseSchema.createWatchedEpisodesTable(db);
  }
}
