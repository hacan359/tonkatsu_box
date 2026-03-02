// Миграция v14: переименование статуса playing → in_progress.
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

/// Миграция v14 — переименование статуса 'playing' в 'in_progress'
/// для единообразия.
class MigrationV14 extends Migration {
  @override
  int get version => 14;

  @override
  String get description => 'Rename playing status to in_progress';

  @override
  Future<void> migrate(Database db) async {
    await db.execute(
      "UPDATE collection_items SET status = 'in_progress' "
      "WHERE status = 'playing'",
    );
  }
}
