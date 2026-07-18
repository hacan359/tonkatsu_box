import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

/// Adds `item_tags.position` — manual per-item tag order.
///
/// `NULL` means "no manual order yet": such links keep following the global
/// tag sort. Reordering chips in the item card writes positions for all of
/// the item's links; newly attached tags stay `NULL` and display after the
/// positioned ones.
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
