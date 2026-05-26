import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

class MigrationV41 extends Migration {
  @override
  int get version => 41;

  @override
  String get description => 'Add tags column to anime_cache and manga_cache';

  @override
  Future<void> migrate(Database db) async {
    await db.execute('ALTER TABLE anime_cache ADD COLUMN tags TEXT');
    await db.execute('ALTER TABLE manga_cache ADD COLUMN tags TEXT');
  }
}
