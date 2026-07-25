import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../schema.dart';
import 'migration.dart';

class MigrationV36 extends Migration {
  @override
  int get version => 36;

  @override
  String get description => 'Add mood_grids and mood_grid_cells tables';

  @override
  Future<void> migrate(Database db) async {
    await db.execute('''
      CREATE TABLE mood_grids (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        rows INTEGER NOT NULL DEFAULT 1,
        cols INTEGER NOT NULL DEFAULT 5,
        created_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),
        updated_at INTEGER NOT NULL DEFAULT (strftime('%s','now'))
      )
    ''');
    await DatabaseSchema.createMoodGridCellsTable(db);
  }
}
