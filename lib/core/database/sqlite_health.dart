import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Shared between StorageRoot.validateDataDir and
// DbSyncService.inspectSnapshot so the two validation paths cannot drift.

/// Reads `PRAGMA user_version` of an open database.
Future<int> readUserVersion(Database db) async {
  final List<Map<String, Object?>> rows =
      await db.rawQuery('PRAGMA user_version');
  return rows.isNotEmpty ? rows.first.values.first as int? ?? 0 : 0;
}

/// Whether `PRAGMA quick_check` reports a healthy database.
Future<bool> quickCheckOk(Database db) async {
  final List<Map<String, Object?>> rows =
      await db.rawQuery('PRAGMA quick_check');
  return rows.isNotEmpty && rows.first.values.first == 'ok';
}
