import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

class MigrationV4 extends Migration {
  @override
  int get version => 4;

  @override
  String get description => 'Add logo_image_id to platforms';

  @override
  Future<void> migrate(Database db) async {
    await Migration.addColumnIfAbsent(
      db,
      'platforms',
      'logo_image_id',
      'logo_image_id TEXT',
    );
  }
}
