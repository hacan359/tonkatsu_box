import 'package:sqflite_common/sqlite_api.dart';

import 'migration.dart';

/// Removing items never deleted their custom cards; the leftovers are adopted
/// by any import that reuses their ids, so they go before that can happen.
class MigrationV65 extends Migration {
  @override
  int get version => 65;

  @override
  String get description =>
      'Delete custom_items no item, board card or mood grid cell points at';

  @override
  Future<void> migrate(Database db) async {
    await db.execute('''
      DELETE FROM custom_items
      WHERE NOT EXISTS (
        SELECT 1 FROM collection_items ci
        WHERE ci.media_type = 'custom' AND ci.external_id = custom_items.id
      )
      AND NOT EXISTS (
        SELECT 1 FROM canvas_items cv
        WHERE cv.item_type = 'custom' AND cv.item_ref_id = custom_items.id
      )
      AND NOT EXISTS (
        SELECT 1 FROM mood_grid_cells mg
        WHERE mg.media_type = 'custom' AND mg.external_id = custom_items.id
      )
    ''');
  }
}
