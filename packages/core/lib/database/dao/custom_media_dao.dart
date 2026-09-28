import '../query_chunk.dart';
import '../../models/custom_media.dart';
import 'package:sqflite_common/sqlite_api.dart';

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

  /// Batch-inserts [items] in one transaction; returns the new row IDs in the
  /// same order. Used by the custom-cards file import.
  Future<List<int>> createAll(List<CustomMedia> items) async {
    if (items.isEmpty) return const <int>[];
    final Database db = await _getDatabase();
    final List<Object?> results =
        await db.transaction((Transaction txn) async {
      final Batch batch = txn.batch();
      for (final CustomMedia item in items) {
        final Map<String, dynamic> data = item.toDb();
        data.remove('id'); // autoincrement
        batch.insert('custom_items', data);
      }
      return batch.commit();
    });
    return results.cast<int>();
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

  /// Import keeps a card's own id while nothing here uses it, so a restore
  /// into an empty profile is lossless; a taken id gets a fresh one.
  Future<List<int>> importAll(List<CustomMedia> items) async {
    if (items.isEmpty) return const <int>[];
    final Database db = await _getDatabase();
    return db.transaction((Transaction txn) async {
      final List<int> ids = <int>[];
      for (final CustomMedia item in items) {
        final Map<String, dynamic> data = item.toDb();
        if (!await _isIdFree(txn, item.id)) data.remove('id');
        ids.add(await txn.insert('custom_items', data));
      }
      return ids;
    });
  }

  // Anything still holding the id - item, board card, grid cell - would
  // adopt the new card.
  static Future<bool> _isIdFree(DatabaseExecutor db, int id) async {
    if (id <= 0) return false;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      '''
      SELECT 1 FROM custom_items WHERE id = ?
      UNION ALL
      SELECT 1 FROM collection_items
      WHERE media_type = 'custom' AND external_id = ?
      UNION ALL
      SELECT 1 FROM canvas_items WHERE item_type = 'custom' AND item_ref_id = ?
      UNION ALL
      SELECT 1 FROM mood_grid_cells
      WHERE media_type = 'custom' AND external_id = ?
      LIMIT 1
      ''',
      <Object?>[id, id, id, id],
    );
    return rows.isEmpty;
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
