import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

class MigrationV43 extends Migration {
  @override
  int get version => 43;

  @override
  String get description => 'Add caption_template to mood_grids';

  @override
  Future<void> migrate(Database db) async {
    await Migration.addColumnIfAbsent(
      db,
      'mood_grids',
      'caption_template',
      'caption_template TEXT',
    );
  }
}
