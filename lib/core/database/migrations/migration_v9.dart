import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../schema.dart';
import 'migration.dart';

class MigrationV9 extends Migration {
  @override
  int get version => 9;

  @override
  String get description =>
      'Add collection_item_id to canvas tables and create '
      'game_canvas_viewport';

  @override
  Future<void> migrate(Database db) async {
    await db.execute(
      'ALTER TABLE canvas_items ADD COLUMN collection_item_id INTEGER',
    );
    await db.execute('''
      CREATE INDEX idx_canvas_items_collection_item
      ON canvas_items(collection_item_id)
    ''');

    await db.execute(
      'ALTER TABLE canvas_connections '
      'ADD COLUMN collection_item_id INTEGER',
    );
    await db.execute('''
      CREATE INDEX idx_canvas_connections_collection_item
      ON canvas_connections(collection_item_id)
    ''');

    await DatabaseSchema.createGameCanvasViewportTable(db);
  }
}
