import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../schema.dart';
import 'migration.dart';

class MigrationV27 extends Migration {
  @override
  int get version => 27;

  @override
  String get description => 'Add custom_items table';

  @override
  Future<void> migrate(Database db) async {
    await DatabaseSchema.createCustomItemsTable(db);
  }
}
