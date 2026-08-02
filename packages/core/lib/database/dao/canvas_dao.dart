import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class CanvasDao {
  const CanvasDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  /// Joined `override_name` is the rename on the matching `collection_items`
  /// row; it is per-collection, so any per-platform row will do.
  Future<List<Map<String, dynamic>>> getCanvasItems(int collectionId) async {
    final Database db = await _getDatabase();
    return db.rawQuery(
      '''
      SELECT ci.*, (
        SELECT col.override_name
        FROM collection_items col
        WHERE col.collection_id = ci.collection_id
          AND col.media_type = ci.item_type
          AND col.external_id = ci.item_ref_id
        LIMIT 1
      ) AS override_name
      FROM canvas_items ci
      WHERE ci.collection_id = ? AND ci.collection_item_id IS NULL
      ORDER BY ci.z_index ASC
      ''',
      <Object?>[collectionId],
    );
  }

  Future<int> insertCanvasItem(Map<String, dynamic> data) async {
    final Database db = await _getDatabase();
    return db.insert('canvas_items', data);
  }

  Future<void> updateCanvasItem(int id, Map<String, dynamic> data) async {
    final Database db = await _getDatabase();
    await db.update(
      'canvas_items',
      data,
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> deleteCanvasItem(int id) async {
    final Database db = await _getDatabase();
    await db.delete(
      'canvas_items',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> deleteCanvasItemByRef(
    int collectionId,
    String itemType,
    int itemRefId,
  ) async {
    final Database db = await _getDatabase();
    await db.delete(
      'canvas_items',
      where: 'collection_id = ? AND item_type = ? AND item_ref_id = ?'
          ' AND collection_item_id IS NULL',
      whereArgs: <Object?>[collectionId, itemType, itemRefId],
    );
  }

  Future<void> deleteCanvasItemByCollectionItemId(
    int collectionId,
    int collectionItemId,
  ) async {
    final Database db = await _getDatabase();
    await db.delete(
      'canvas_items',
      where: 'collection_id = ? AND collection_item_id = ?',
      whereArgs: <Object?>[collectionId, collectionItemId],
    );
  }

  Future<void> deleteCanvasItemsByCollection(int collectionId) async {
    final Database db = await _getDatabase();
    await db.delete(
      'canvas_items',
      where: 'collection_id = ? AND collection_item_id IS NULL',
      whereArgs: <Object?>[collectionId],
    );
  }

  Future<int> getCanvasItemCount(int collectionId) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM canvas_items'
          ' WHERE collection_id = ? AND collection_item_id IS NULL',
      <Object?>[collectionId],
    );
    return result.first['count'] as int;
  }

  Future<List<int>> insertCanvasItemsBatch(
    List<Map<String, dynamic>> items,
  ) async {
    if (items.isEmpty) return <int>[];

    final Database db = await _getDatabase();
    return db.transaction((Transaction txn) async {
      final Batch batch = txn.batch();
      for (final Map<String, dynamic> item in items) {
        batch.insert('canvas_items', item);
      }
      final List<Object?> results = await batch.commit();
      return results.cast<int>();
    });
  }

  Future<void> deleteCanvasItemsBatch(List<int> ids) async {
    if (ids.isEmpty) return;

    final Database db = await _getDatabase();
    await db.transaction((Transaction txn) async {
      final Batch batch = txn.batch();
      for (final int id in ids) {
        batch.delete(
          'canvas_items',
          where: 'id = ?',
          whereArgs: <Object?>[id],
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<Map<String, dynamic>?> getCanvasViewport(int collectionId) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'canvas_viewport',
      where: 'collection_id = ?',
      whereArgs: <Object?>[collectionId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<void> upsertCanvasViewport({
    required int collectionId,
    required double scale,
    required double offsetX,
    required double offsetY,
  }) async {
    final Database db = await _getDatabase();
    await db.insert(
      'canvas_viewport',
      <String, dynamic>{
        'collection_id': collectionId,
        'scale': scale,
        'offset_x': offsetX,
        'offset_y': offsetY,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getCanvasConnections(
    int collectionId,
  ) async {
    final Database db = await _getDatabase();
    return db.query(
      'canvas_connections',
      where: 'collection_id = ? AND collection_item_id IS NULL',
      whereArgs: <Object?>[collectionId],
    );
  }

  Future<int> insertCanvasConnection(Map<String, dynamic> data) async {
    final Database db = await _getDatabase();
    return db.insert('canvas_connections', data);
  }

  Future<void> updateCanvasConnection(
    int id,
    Map<String, dynamic> data,
  ) async {
    final Database db = await _getDatabase();
    await db.update(
      'canvas_connections',
      data,
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> deleteCanvasConnection(int id) async {
    final Database db = await _getDatabase();
    await db.delete(
      'canvas_connections',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> deleteCanvasConnectionsByCollection(int collectionId) async {
    final Database db = await _getDatabase();
    await db.delete(
      'canvas_connections',
      where: 'collection_id = ? AND collection_item_id IS NULL',
      whereArgs: <Object?>[collectionId],
    );
  }

  /// Mirrors `getCanvasItems`, so per-item board titles inherit the
  /// per-collection rename.
  Future<List<Map<String, dynamic>>> getGameCanvasItems(
    int collectionItemId,
  ) async {
    final Database db = await _getDatabase();
    return db.rawQuery(
      '''
      SELECT ci.*, (
        SELECT col.override_name
        FROM collection_items col
        WHERE col.collection_id = ci.collection_id
          AND col.media_type = ci.item_type
          AND col.external_id = ci.item_ref_id
        LIMIT 1
      ) AS override_name
      FROM canvas_items ci
      WHERE ci.collection_item_id = ?
      ''',
      <Object?>[collectionItemId],
    );
  }

  Future<int> getGameCanvasItemCount(int collectionItemId) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM canvas_items '
      'WHERE collection_item_id = ?',
      <Object?>[collectionItemId],
    );
    return result.first['cnt'] as int;
  }

  Future<List<Map<String, dynamic>>> getGameCanvasConnections(
    int collectionItemId,
  ) async {
    final Database db = await _getDatabase();
    return db.query(
      'canvas_connections',
      where: 'collection_item_id = ?',
      whereArgs: <Object?>[collectionItemId],
    );
  }

  Future<Map<String, dynamic>?> getGameCanvasViewport(
    int collectionItemId,
  ) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'game_canvas_viewport',
      where: 'collection_item_id = ?',
      whereArgs: <Object?>[collectionItemId],
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<void> upsertGameCanvasViewport({
    required int collectionItemId,
    required double scale,
    required double offsetX,
    required double offsetY,
  }) async {
    final Database db = await _getDatabase();
    await db.execute(
      'INSERT OR REPLACE INTO game_canvas_viewport '
      '(collection_item_id, scale, offset_x, offset_y) '
      'VALUES (?, ?, ?, ?)',
      <Object?>[collectionItemId, scale, offsetX, offsetY],
    );
  }

  Future<void> deleteGameCanvasItems(int collectionItemId) async {
    final Database db = await _getDatabase();
    await db.delete(
      'canvas_items',
      where: 'collection_item_id = ?',
      whereArgs: <Object?>[collectionItemId],
    );
  }

  Future<void> deleteGameCanvasConnections(int collectionItemId) async {
    final Database db = await _getDatabase();
    await db.delete(
      'canvas_connections',
      where: 'collection_item_id = ?',
      whereArgs: <Object?>[collectionItemId],
    );
  }

  Future<void> deleteGameCanvasViewport(int collectionItemId) async {
    final Database db = await _getDatabase();
    await db.delete(
      'game_canvas_viewport',
      where: 'collection_item_id = ?',
      whereArgs: <Object?>[collectionItemId],
    );
  }
}
