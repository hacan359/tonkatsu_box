import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

/// Caches the MangaDex tag catalog, mirroring `mangabaka_tags`. `tag_group` is
/// genre / theme / format / content; `id` is the tag UUID.
class MigrationV59 extends Migration {
  @override
  int get version => 59;

  @override
  String get description => 'Add mangadex_tags catalog cache';

  @override
  Future<void> migrate(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS mangadex_tags (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        tag_group TEXT,
        updated_at INTEGER
      )
    ''');
  }
}
