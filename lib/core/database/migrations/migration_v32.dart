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
    await Migration.addColumnIfAbsent(
      db,
      'games',
      'artwork_url',
      'artwork_url TEXT',
    );
    await Migration.addColumnIfAbsent(
      db,
      'manga_cache',
      'banner_url',
      'banner_url TEXT',
    );
  }
}
