import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

/// Migration v37: per-platform tracker_game_data.
///
/// The original unique index `(tracker_type, game_id)` collapses a single
/// IGDB game across platforms — syncing RetroAchievements progress for the
/// GameCube edition would overwrite the PS2 record. Adding `platform_id`
/// (nullable) and including it in the unique index lets each platform
/// variant keep its own row. Existing rows stay with NULL platform_id.
class MigrationV37 extends Migration {
  @override
  int get version => 37;

  @override
  String get description =>
      'Per-platform tracker_game_data: add platform_id column + unique index';

  @override
  Future<void> migrate(Database db) async {
    // Idempotent: an interim build briefly shipped `platform_id` in the
    // CREATE TABLE before this migration was registered, so some user DBs
    // already have the column. Re-running ALTER TABLE would crash with
    // "duplicate column name".
    if (!await _hasColumn(db, 'tracker_game_data', 'platform_id')) {
      await db.execute(
        'ALTER TABLE tracker_game_data ADD COLUMN platform_id INTEGER',
      );
    }
    await db.execute('DROP INDEX IF EXISTS idx_tracker_game_data_unique');
    // SQLite indexes can include expressions, so wrap platform_id in
    // COALESCE to give NULL a deterministic key — without it two NULLs
    // would be treated as distinct and we'd lose the upsert guarantee.
    await db.execute('''
      CREATE UNIQUE INDEX idx_tracker_game_data_unique
      ON tracker_game_data(tracker_type, game_id, COALESCE(platform_id, -1))
    ''');
  }

  Future<bool> _hasColumn(Database db, String table, String column) async {
    final List<Map<String, Object?>> rows =
        await db.rawQuery('PRAGMA table_info($table)');
    return rows.any((Map<String, Object?> r) => r['name'] == column);
  }
}
