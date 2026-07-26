import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../schema.dart';
import 'migration.dart';

/// Adds the `calendar_entries` table for manual calendar entries (any item
/// with a start date and recurrence).
class MigrationV46 extends Migration {
  @override
  int get version => 46;

  @override
  String get description => 'Manual calendar entries: calendar_entries table';

  @override
  Future<void> migrate(Database db) async {
    await DatabaseSchema.createCalendarEntriesTable(db);
  }
}
