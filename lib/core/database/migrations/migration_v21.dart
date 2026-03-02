// Миграция v21: добавление external_url в games, movies_cache,
// tv_shows_cache.
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

/// Миграция v21 — добавление колонки external_url в таблицы games,
/// movies_cache и tv_shows_cache.
class MigrationV21 extends Migration {
  @override
  int get version => 21;

  @override
  String get description => 'Add external_url to games, movies, tv_shows';

  @override
  Future<void> migrate(Database db) async {
    await db.execute('ALTER TABLE games ADD COLUMN external_url TEXT');
    await db.execute('ALTER TABLE movies_cache ADD COLUMN external_url TEXT');
    await db.execute(
      'ALTER TABLE tv_shows_cache ADD COLUMN external_url TEXT',
    );
  }
}
