import 'package:sqflite_common_ffi/sqflite_ffi.dart';

abstract class Migration {
  int get version;
  String get description;
  Future<void> migrate(Database db);

  /// Adds [columnDef] to [table] only when [column] isn't already present.
  ///
  /// SQLite has no `ADD COLUMN IF NOT EXISTS`. Several `create*Table` helpers
  /// in `DatabaseSchema` are shared between the fresh-install schema and the
  /// migration that first introduced the table. When a later release adds a
  /// column to both that helper and a dedicated ALTER migration, a single
  /// big-jump upgrade runs the create (which now already has the column) and
  /// then the historical ALTER — which throws `duplicate column name`. This
  /// guard makes every column-add idempotent so such upgrades succeed; the
  /// resulting schema is identical, only the redundant re-add becomes a no-op.
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
