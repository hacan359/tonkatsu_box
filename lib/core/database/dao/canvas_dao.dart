// DAO для работы с канвасом: элементы, viewport, связи, game canvas.

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// DAO для таблиц `canvas_items`, `canvas_viewport`,
/// `canvas_connections` и `game_canvas_viewport`.
class CanvasDao {
  /// Создаёт DAO с функцией получения базы данных.
  const CanvasDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  // ==================== Canvas Items ====================

  /// Возвращает все элементы канваса для коллекции.
  Future<List<Map<String, dynamic>>> getCanvasItems(int collectionId) async {
    final Database db = await _getDatabase();
    return db.query(
      'canvas_items',
      where: 'collection_id = ? AND collection_item_id IS NULL',
      whereArgs: <Object?>[collectionId],
      orderBy: 'z_index ASC',
    );
  }

  /// Вставляет элемент канваса и возвращает его ID.
  Future<int> insertCanvasItem(Map<String, dynamic> data) async {
    final Database db = await _getDatabase();
    return db.insert('canvas_items', data);
  }

  /// Обновляет элемент канваса по ID.
  Future<void> updateCanvasItem(int id, Map<String, dynamic> data) async {
    final Database db = await _getDatabase();
    await db.update(
      'canvas_items',
      data,
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Удаляет элемент канваса по ID.
  Future<void> deleteCanvasItem(int id) async {
    final Database db = await _getDatabase();
    await db.delete(
      'canvas_items',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Удаляет элемент канваса по типу и ID связанного объекта.
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

  /// Удаляет элемент канваса по collection_item_id.
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

  /// Удаляет все элементы канваса коллекции (без per-item элементов).
  Future<void> deleteCanvasItemsByCollection(int collectionId) async {
    final Database db = await _getDatabase();
    await db.delete(
      'canvas_items',
      where: 'collection_id = ? AND collection_item_id IS NULL',
      whereArgs: <Object?>[collectionId],
    );
  }

  /// Возвращает количество элементов канваса для коллекции.
  Future<int> getCanvasItemCount(int collectionId) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM canvas_items'
          ' WHERE collection_id = ? AND collection_item_id IS NULL',
      <Object?>[collectionId],
    );
    return result.first['count'] as int;
  }

  // ==================== Canvas Viewport ====================

  /// Возвращает состояние viewport канваса для коллекции.
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

  /// Сохраняет или обновляет состояние viewport канваса.
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

  // ==================== Canvas Connections ====================

  /// Возвращает связи канваса коллекции (без per-item связей).
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

  /// Вставляет связь канваса и возвращает её ID.
  Future<int> insertCanvasConnection(Map<String, dynamic> data) async {
    final Database db = await _getDatabase();
    return db.insert('canvas_connections', data);
  }

  /// Обновляет связь канваса по ID.
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

  /// Удаляет связь канваса по ID.
  Future<void> deleteCanvasConnection(int id) async {
    final Database db = await _getDatabase();
    await db.delete(
      'canvas_connections',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Удаляет связи канваса коллекции (без per-item связей).
  Future<void> deleteCanvasConnectionsByCollection(int collectionId) async {
    final Database db = await _getDatabase();
    await db.delete(
      'canvas_connections',
      where: 'collection_id = ? AND collection_item_id IS NULL',
      whereArgs: <Object?>[collectionId],
    );
  }

  // ==================== Game Canvas ====================

  /// Возвращает элементы game canvas по ID элемента коллекции.
  Future<List<Map<String, dynamic>>> getGameCanvasItems(
    int collectionItemId,
  ) async {
    final Database db = await _getDatabase();
    return db.query(
      'canvas_items',
      where: 'collection_item_id = ?',
      whereArgs: <Object?>[collectionItemId],
    );
  }

  /// Возвращает количество элементов game canvas.
  Future<int> getGameCanvasItemCount(int collectionItemId) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM canvas_items '
      'WHERE collection_item_id = ?',
      <Object?>[collectionItemId],
    );
    return result.first['cnt'] as int;
  }

  /// Возвращает связи game canvas.
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

  /// Возвращает viewport для game canvas.
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

  /// Сохраняет или обновляет viewport для game canvas.
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

  /// Удаляет все элементы game canvas по collection_item_id.
  Future<void> deleteGameCanvasItems(int collectionItemId) async {
    final Database db = await _getDatabase();
    await db.delete(
      'canvas_items',
      where: 'collection_item_id = ?',
      whereArgs: <Object?>[collectionItemId],
    );
  }

  /// Удаляет все связи game canvas по collection_item_id.
  Future<void> deleteGameCanvasConnections(int collectionItemId) async {
    final Database db = await _getDatabase();
    await db.delete(
      'canvas_connections',
      where: 'collection_item_id = ?',
      whereArgs: <Object?>[collectionItemId],
    );
  }

  /// Удаляет viewport game canvas.
  Future<void> deleteGameCanvasViewport(int collectionItemId) async {
    final Database db = await _getDatabase();
    await db.delete(
      'game_canvas_viewport',
      where: 'collection_item_id = ?',
      whereArgs: <Object?>[collectionItemId],
    );
  }
}
