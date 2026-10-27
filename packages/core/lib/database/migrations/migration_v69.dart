import 'package:sqflite_common/sqlite_api.dart';

import 'migration.dart';

// A season rating rides on the season's mark: the seasons cache is shared by
// every copy of the title and rebuilt from the source, so it cannot hold it.
class MigrationV69 extends Migration {
  @override
  int get version => 69;

  @override
  String get description => 'Add item_marks.user_rating';

  @override
  Future<void> migrate(Database db) async {
    await Migration.addColumnIfAbsent(
      db,
      'item_marks',
      'user_rating',
      'user_rating REAL',
    );
  }
}
