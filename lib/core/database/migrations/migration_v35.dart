import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

class MigrationV35 extends Migration {
  @override
  int get version => 35;

  @override
  String get description =>
      'Add hero_image_path and description to collections';

  @override
  Future<void> migrate(Database db) async {
    await Migration.addColumnIfAbsent(
      db,
      'collections',
      'hero_image_path',
      'hero_image_path TEXT',
    );
    await Migration.addColumnIfAbsent(
      db,
      'collections',
      'description',
      'description TEXT',
    );
  }
}
