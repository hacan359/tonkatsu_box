// Миграция v18: обновление UNIQUE индексов с учётом platform_id.
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

/// Миграция v18 — обновление UNIQUE индексов на collection_items,
/// включая platform_id через COALESCE.
class MigrationV18 extends Migration {
  @override
  int get version => 18;

  @override
  String get description =>
      'Update unique indexes to include platform_id via COALESCE';

  @override
  Future<void> migrate(Database db) async {
    await db.execute('DROP INDEX IF EXISTS idx_ci_coll');
    await db.execute('DROP INDEX IF EXISTS idx_ci_uncat');
    await db.execute('''
      CREATE UNIQUE INDEX idx_ci_coll
      ON collection_items(
        collection_id, media_type, external_id, COALESCE(platform_id, -1)
      )
      WHERE collection_id IS NOT NULL
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX idx_ci_uncat
      ON collection_items(media_type, external_id, COALESCE(platform_id, -1))
      WHERE collection_id IS NULL
    ''');
  }
}
