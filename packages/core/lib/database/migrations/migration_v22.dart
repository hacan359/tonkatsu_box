import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

/// SQL is inlined: the original migration never routed through schema.dart,
/// so historical installs run this exact statement — don't refactor.
class MigrationV22 extends Migration {
  @override
  int get version => 22;

  @override
  String get description => 'Create igdb_genres table';

  @override
  Future<void> migrate(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS igdb_genres (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL
      )
    ''');
  }
}
