import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

class MigrationV34 extends Migration {
  @override
  int get version => 34;

  @override
  String get description => 'Add time_spent_minutes to collection_items';

  @override
  Future<void> migrate(Database db) async {
    await Migration.addColumnIfAbsent(
      db,
      'collection_items',
      'time_spent_minutes',
      'time_spent_minutes INTEGER NOT NULL DEFAULT 0',
    );
  }
}
