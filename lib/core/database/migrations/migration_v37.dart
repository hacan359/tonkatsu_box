import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

class MigrationV37 extends Migration {
  @override
  int get version => 37;

  @override
  String get description =>
      'Per-platform tracker_game_data: add platform_id column + unique index';

  @override
  Future<void> migrate(Database db) async {
    await db.execute(
      'ALTER TABLE tracker_game_data ADD COLUMN platform_id INTEGER',
    );
    await db.execute('DROP INDEX IF EXISTS idx_tracker_game_data_unique');
    // COALESCE pins NULL to -1 so two NULL platform_ids collide on upsert;
    // bare NULLs are treated as distinct in SQLite unique indexes.
    await db.execute('''
      CREATE UNIQUE INDEX idx_tracker_game_data_unique
      ON tracker_game_data(tracker_type, game_id, COALESCE(platform_id, -1))
    ''');
  }
}
