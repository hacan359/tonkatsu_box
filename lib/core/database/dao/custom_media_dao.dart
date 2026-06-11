import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../shared/models/custom_media.dart';
import '../query_chunk.dart';

/// DAO for the `custom_items` table.
class CustomMediaDao {
  const CustomMediaDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  /// Returns the new row ID.
  Future<int> create(CustomMedia item) async {
    final Database db = await _getDatabase();
    final Map<String, dynamic> data = item.toDb();
    data.remove('id'); // autoincrement
    return db.insert('custom_items', data);
  }

  Future<void> update(CustomMedia item) async {
    final Database db = await _getDatabase();
    await db.update(
      'custom_items',
      item.toDb(),
      where: 'id = ?',
      whereArgs: <Object?>[item.id],
    );
  }

  Future<CustomMedia?> getById(int id) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'custom_items',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return CustomMedia.fromDb(rows.first);
  }

  Future<List<CustomMedia>> getByIds(List<int> ids) async {
    final Database db = await _getDatabase();
    return queryByIdsInChunks(ids, (List<int> chunk) async {
      final String placeholders =
          List<String>.filled(chunk.length, '?').join(',');
      final List<Map<String, dynamic>> rows = await db.rawQuery(
        'SELECT * FROM custom_items WHERE id IN ($placeholders)',
        chunk,
      );
      return rows.map(CustomMedia.fromDb).toList();
    });
  }

  /// Upsert keeping the original ID — used by import.
  Future<void> upsert(CustomMedia item) async {
    final Database db = await _getDatabase();
    await db.insert(
      'custom_items',
      item.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Upsert keeping the original IDs — used by import.
  Future<void> upsertAll(List<CustomMedia> items) async {
    if (items.isEmpty) return;
    final Database db = await _getDatabase();
    final Batch batch = db.batch();
    for (final CustomMedia item in items) {
      batch.insert(
        'custom_items',
        item.toDb(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> delete(int id) async {
    final Database db = await _getDatabase();
    await db.delete(
      'custom_items',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }
}
