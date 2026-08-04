import 'package:sqflite_common/sqlite_api.dart';

abstract class Migration {
  int get version;
  String get description;
  Future<void> migrate(Database db);

  /// SQLite has no `ADD COLUMN IF NOT EXISTS`. A big-jump upgrade can run a
  /// create that already has the column, then the historical ALTER — this guards it.
  static Future<void> addColumnIfAbsent(
    Database db,
    String table,
    String column,
    String columnDef,
  ) async {
    final List<Map<String, Object?>> columns =
        await db.rawQuery('PRAGMA table_info($table)');
    final bool exists = columns.any(
      (Map<String, Object?> c) => c['name'] == column,
    );
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $columnDef');
    }
  }
}
