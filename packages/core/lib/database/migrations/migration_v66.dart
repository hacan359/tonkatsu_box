import 'package:sqflite_common/sqlite_api.dart';

import 'migration.dart';

// Lives on collection_items, like override_name, so an API refetch replacing
// the media row cannot drop the user's cover.
class MigrationV66 extends Migration {
  @override
  int get version => 66;

  @override
  String get description =>
      'Add override_cover_url column to collection_items';

  @override
  Future<void> migrate(Database db) async {
    await Migration.addColumnIfAbsent(
      db,
      'collection_items',
      'override_cover_url',
      'override_cover_url TEXT',
    );
  }
}
