import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

/// Universal progress totals for custom items. The current position reuses
/// `current_episode` / `current_season` — no new progress columns.
class MigrationV52 extends Migration {
  @override
  int get version => 52;

  @override
  String get description => 'Custom items: unit_total and unit_group_total';

  @override
  Future<void> migrate(Database db) async {
    await Migration.addColumnIfAbsent(
      db,
      'custom_items',
      'unit_total',
      'unit_total INTEGER',
    );
    await Migration.addColumnIfAbsent(
      db,
      'custom_items',
      'unit_group_total',
      'unit_group_total INTEGER',
    );
  }
}
