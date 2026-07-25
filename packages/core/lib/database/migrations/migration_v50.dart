import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

/// Adds the user-set `is_favorite` flag to `collection_items`. Per-item and
/// per-collection: the same title in two collections has independent flags.
/// Existing rows default to not-favorite (0).
class MigrationV50 extends Migration {
  @override
  int get version => 50;

  @override
  String get description => 'Collection items: is_favorite flag';

  @override
  Future<void> migrate(Database db) async {
    await Migration.addColumnIfAbsent(
      db,
      'collection_items',
      'is_favorite',
      'is_favorite INTEGER NOT NULL DEFAULT 0',
    );
  }
}
