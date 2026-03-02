// Миграция v5: создание таблиц canvas_items и canvas_viewport.
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../schema.dart';
import 'migration.dart';

/// Миграция v5 — создание таблиц canvas_items и canvas_viewport.
class MigrationV5 extends Migration {
  @override
  int get version => 5;

  @override
  String get description => 'Create canvas_items and canvas_viewport tables';

  @override
  Future<void> migrate(Database db) async {
    await DatabaseSchema.createCanvasItemsTable(db);
    await DatabaseSchema.createCanvasViewportTable(db);
  }
}
