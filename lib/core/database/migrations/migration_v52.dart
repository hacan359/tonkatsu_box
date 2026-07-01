import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

/// Custom items get a universal progress tracker mirroring manga / anime: a
/// total count for the fine unit (episodes / chapters / pages / parts) and an
/// optional total for the coarse unit (seasons / volumes). The "current"
/// position reuses `collection_items.current_episode` / `current_season`, the
/// same slots manga and TV already use — no new progress columns.
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
