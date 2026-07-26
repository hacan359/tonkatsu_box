import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

/// Initial schema — the `platforms` table.
class MigrationV1 extends Migration {
  @override
  int get version => 1;

  @override
  String get description => 'Initial schema: platforms';

  @override
  Future<void> migrate(Database db) async {
    await db.execute('''
      CREATE TABLE platforms (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        abbreviation TEXT,
        synced_at INTEGER
      )
    ''');
  }
}
