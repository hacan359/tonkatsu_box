import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

class MigrationV41 extends Migration {
  @override
  int get version => 41;

  @override
  String get description => 'Add tags column to anime_cache and manga_cache';

  @override
  Future<void> migrate(Database db) async {
    await Migration.addColumnIfAbsent(
      db,
      'anime_cache',
      'tags',
      'tags TEXT',
    );
    await Migration.addColumnIfAbsent(
      db,
      'manga_cache',
      'tags',
      'tags TEXT',
    );
  }
}
