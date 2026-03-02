// Миграция v6: создание таблицы canvas_connections.
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../schema.dart';
import 'migration.dart';

/// Миграция v6 — создание таблицы canvas_connections.
class MigrationV6 extends Migration {
  @override
  int get version => 6;

  @override
  String get description => 'Create canvas_connections table';

  @override
  Future<void> migrate(Database db) async {
    await DatabaseSchema.createCanvasConnectionsTable(db);
  }
}
