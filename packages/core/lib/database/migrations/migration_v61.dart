import 'package:sqflite_common/sqlite_api.dart';

import 'migration.dart';

/// Hidden collections stay in the list but stop showing their content: no cover
/// mosaic on the card, no items in the All Items selection.
class MigrationV61 extends Migration {
  @override
  int get version => 61;

  @override
  String get description => 'Collections: is_hidden flag';

  @override
  Future<void> migrate(Database db) async {
    await Migration.addColumnIfAbsent(
      db,
      'collections',
      'is_hidden',
      'is_hidden INTEGER NOT NULL DEFAULT 0',
    );
  }
}
