import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

/// Adds `rewatch_count` (MAL "times watched"): 0 means completed once. Nullable
/// so old rows stay unknown instead of claiming "completed once".
class MigrationV55 extends Migration {
  @override
  int get version => 55;

  @override
  String get description => 'Collection items: rewatch_count';

  @override
  Future<void> migrate(Database db) async {
    await Migration.addColumnIfAbsent(
      db,
      'collection_items',
      'rewatch_count',
      'rewatch_count INTEGER',
    );
  }
}
