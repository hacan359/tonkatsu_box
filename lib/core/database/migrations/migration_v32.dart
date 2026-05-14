import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

class MigrationV32 extends Migration {
  @override
  int get version => 32;

  @override
  String get description =>
      'Add artwork_url to games, banner_url to manga_cache';

  @override
  Future<void> migrate(Database db) async {
    await db.execute('ALTER TABLE games ADD COLUMN artwork_url TEXT');
    await db.execute('ALTER TABLE manga_cache ADD COLUMN banner_url TEXT');
  }
}
