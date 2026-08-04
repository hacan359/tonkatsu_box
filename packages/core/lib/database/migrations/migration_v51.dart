import 'package:sqflite_common/sqlite_api.dart';

import 'migration.dart';

/// Makes custom-item masquerades filterable: `platform_id` (a `platforms` FK)
/// and `format` (a manga/anime code). Free-text platform stays `platform_name`.
class MigrationV51 extends Migration {
  @override
  int get version => 51;

  @override
  String get description =>
      'Custom items: platform_id and format for filtering';

  @override
  Future<void> migrate(Database db) async {
    await Migration.addColumnIfAbsent(
      db,
      'custom_items',
      'platform_id',
      'platform_id INTEGER',
    );
    await Migration.addColumnIfAbsent(
      db,
      'custom_items',
      'format',
      'format TEXT',
    );
  }
}
