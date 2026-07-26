import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

/// `on_hold` was removed from `ItemStatus`; collapse its rows into
/// `not_started` so the loaded enum doesn't blow up on stale data.
class MigrationV20 extends Migration {
  @override
  int get version => 20;

  @override
  String get description => 'Rename on_hold status to not_started';

  @override
  Future<void> migrate(Database db) async {
    await db.execute(
      "UPDATE collection_items SET status = 'not_started' "
      "WHERE status = 'on_hold'",
    );
  }
}
