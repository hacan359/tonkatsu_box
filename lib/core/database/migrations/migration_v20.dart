// Миграция v20: переименование статуса on_hold → not_started.
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

/// Миграция v20 — переименование статуса 'on_hold' в 'not_started'
/// (on_hold удалён из ItemStatus).
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
