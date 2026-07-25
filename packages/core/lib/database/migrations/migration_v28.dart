import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

class MigrationV28 extends Migration {
  @override
  int get version => 28;

  @override
  String get description => 'Add display_type column to custom_items';

  @override
  Future<void> migrate(Database db) async {
    await Migration.addColumnIfAbsent(
      db,
      'custom_items',
      'display_type',
      'display_type TEXT',
    );
  }
}
