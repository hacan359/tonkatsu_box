import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

/// Adds `item_tags.position` for manual per-item order. `NULL` keeps following
/// the global sort and displays after the positioned links.
class MigrationV56 extends Migration {
  @override
  int get version => 56;

  @override
  String get description => 'Item tags: per-item manual position';

  @override
  Future<void> migrate(Database db) async {
    await Migration.addColumnIfAbsent(
      db,
      'item_tags',
      'position',
      'position INTEGER',
    );
  }
}
