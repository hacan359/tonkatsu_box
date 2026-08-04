import 'package:sqflite_common/sqlite_api.dart';

import 'migration.dart';

/// Splits the `collection_items` unique index into media-type-aware variants so
/// multi-platform games coexist while other media dedupe without platform.
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
