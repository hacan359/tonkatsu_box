import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

class MigrationV28 extends Migration {
  @override
  int get version => 28;

  @override
  String get description => 'Add display_type column to custom_items';

  @override
  Future<void> migrate(Database db) async {
    try {
      await db.execute(
        'ALTER TABLE custom_items ADD COLUMN display_type TEXT',
      );
    } on DatabaseException {
      // Column already present on installs that picked it up via _onCreate.
    }
  }
}
