import 'package:sqflite_common/sqlite_api.dart';

import 'migration.dart';

// One row per (collection, source): a rerun overwrites the previous run's
// switches, there is no history to keep.
class MigrationV68 extends Migration {
  @override
  int get version => 68;

  @override
  String get description => 'Add collection_imports table';

  @override
  Future<void> migrate(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS collection_imports (
        collection_id INTEGER NOT NULL,
        source TEXT NOT NULL,
        options TEXT NOT NULL DEFAULT '{}',
        last_run_at INTEGER NOT NULL,
        PRIMARY KEY (collection_id, source),
        FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE
      )
    ''');
  }
}
