import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../schema.dart';
import 'migration.dart';

class MigrationV29 extends Migration {
  @override
  int get version => 29;

  @override
  String get description => 'Add collection_tags table and tag_id to collection_items';

  @override
  Future<void> migrate(Database db) async {
    await DatabaseSchema.createCollectionTagsTable(db);
    await db.execute(
      'ALTER TABLE collection_items ADD COLUMN tag_id INTEGER '
      'REFERENCES collection_tags(id) ON DELETE SET NULL',
    );
  }
}
