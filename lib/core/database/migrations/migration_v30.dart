import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

/// Splits the single `collection_items` unique index into media-type-aware
/// variants so multi-platform installs of the same game can coexist while
/// non-game media still dedupe by `(collection, type, external_id)` alone.
class MigrationV30 extends Migration {
  @override
  int get version => 30;

  @override
  String get description =>
      'Split unique indexes to allow same game on different platforms';

  @override
  Future<void> migrate(Database db) async {
    await db.execute('DROP INDEX IF EXISTS idx_ci_coll');
    await db.execute('DROP INDEX IF EXISTS idx_ci_uncat');

    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_ci_coll_game
      ON collection_items(collection_id, media_type, external_id, platform_id)
      WHERE collection_id IS NOT NULL AND media_type = 'game'
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_ci_coll_other
      ON collection_items(collection_id, media_type, external_id)
      WHERE collection_id IS NOT NULL AND media_type != 'game'
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_ci_uncat_game
      ON collection_items(media_type, external_id, platform_id)
      WHERE collection_id IS NULL AND media_type = 'game'
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_ci_uncat_other
      ON collection_items(media_type, external_id)
      WHERE collection_id IS NULL AND media_type != 'game'
    ''');
  }
}
