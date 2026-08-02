import '../../models/item_mark.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Writes read-modify-write inside a transaction, then `INSERT OR REPLACE` or
/// delete once the mark is empty, so the table never accumulates blank rows.
class ItemMarkDao {
  /// Creates the DAO with a database accessor.
  const ItemMarkDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  /// All marks for one collection item, ordered for stable display.
  Future<List<ItemMark>> getMarksForItem(int itemId) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'item_marks',
      where: 'item_id = ?',
      whereArgs: <Object?>[itemId],
      orderBy: 'unit_type ASC, parent_number ASC, unit_number ASC',
    );
    return rows.map(ItemMark.fromDb).toList();
  }

  /// Marks for the given items in one pass (chunked queries so large
  /// collections stay under SQLite's bind-variable limit).
  Future<List<ItemMark>> getMarksForItems(List<int> itemIds) async {
    if (itemIds.isEmpty) return <ItemMark>[];
    final Database db = await _getDatabase();
    const int chunkSize = 500;
    final List<ItemMark> result = <ItemMark>[];
    for (int i = 0; i < itemIds.length; i += chunkSize) {
      final List<int> chunk = itemIds.sublist(
        i,
        (i + chunkSize < itemIds.length) ? i + chunkSize : itemIds.length,
      );
      final String placeholders =
          List<String>.filled(chunk.length, '?').join(', ');
      final List<Map<String, dynamic>> rows = await db.query(
        'item_marks',
        where: 'item_id IN ($placeholders)',
        whereArgs: chunk,
        orderBy:
            'item_id ASC, unit_type ASC, parent_number ASC, unit_number ASC',
      );
      result.addAll(rows.map(ItemMark.fromDb));
    }
    return result;
  }

  /// Sets (or clears) the like flag on a unit, merging with any existing note.
  /// Returns the merged mark, or null when the row was deleted (empty mark).
  Future<ItemMark?> setFavorite(
    int itemId,
    String unitType,
    int parent,
    int unit, {
    required bool isFavorite,
  }) async {
    final Database db = await _getDatabase();
    return db.transaction((Transaction txn) async {
      final ItemMark? existing =
          await _readInTxn(txn, itemId, unitType, parent, unit);
      final DateTime now = DateTime.now();
      final DateTime? likedAt = isFavorite
          ? (existing?.likedAt ?? now)
          : null;
      final ItemMark merged = ItemMark(
        id: existing?.id ?? 0,
        itemId: itemId,
        unitType: unitType,
        parentNumber: parent,
        unitNumber: unit,
        isFavorite: isFavorite,
        userComment: existing?.userComment,
        likedAt: likedAt,
        updatedAt: now,
      );
      return _writeInTxn(txn, merged);
    });
  }

  /// A blank comment clears the note. Returns the merged mark, or null when the
  /// row was deleted.
  Future<ItemMark?> setComment(
    int itemId,
    String unitType,
    int parent,
    int unit,
    String? comment,
  ) async {
    final String? trimmed =
        (comment == null || comment.trim().isEmpty) ? null : comment.trim();
    final Database db = await _getDatabase();
    return db.transaction((Transaction txn) async {
      final ItemMark? existing =
          await _readInTxn(txn, itemId, unitType, parent, unit);
      final ItemMark merged = ItemMark(
        id: existing?.id ?? 0,
        itemId: itemId,
        unitType: unitType,
        parentNumber: parent,
        unitNumber: unit,
        isFavorite: existing?.isFavorite ?? false,
        userComment: trimmed,
        likedAt: existing?.likedAt,
        updatedAt: DateTime.now(),
      );
      return _writeInTxn(txn, merged);
    });
  }

  /// Deletes a mark unconditionally.
  Future<void> deleteMark(
    int itemId,
    String unitType,
    int parent,
    int unit,
  ) async {
    final Database db = await _getDatabase();
    await _delete(db, itemId, unitType, parent, unit);
  }

  /// Inserts marks verbatim in one batch (import path). Each replaces any
  /// existing row with the same unique key.
  Future<void> insertMarks(List<ItemMark> marks) async {
    if (marks.isEmpty) return;
    final Database db = await _getDatabase();
    final Batch batch = db.batch();
    for (final ItemMark mark in marks) {
      batch.insert(
        'item_marks',
        mark.toDb(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Writes [mark] within [txn], deleting instead when it holds no content.
  /// Returns the written mark, or null when it was deleted.
  Future<ItemMark?> _writeInTxn(Transaction txn, ItemMark mark) async {
    if (!mark.hasContent) {
      await _delete(
        txn,
        mark.itemId,
        mark.unitType,
        mark.parentNumber,
        mark.unitNumber,
      );
      return null;
    }
    await txn.insert(
      'item_marks',
      mark.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return mark;
  }

  Future<ItemMark?> _readInTxn(
    Transaction txn,
    int itemId,
    String unitType,
    int parent,
    int unit,
  ) async {
    final List<Map<String, dynamic>> rows = await txn.query(
      'item_marks',
      where: 'item_id = ? AND unit_type = ? AND parent_number = ? '
          'AND unit_number = ?',
      whereArgs: <Object?>[itemId, unitType, parent, unit],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ItemMark.fromDb(rows.first);
  }

  Future<void> _delete(
    DatabaseExecutor db,
    int itemId,
    String unitType,
    int parent,
    int unit,
  ) async {
    await db.delete(
      'item_marks',
      where: 'item_id = ? AND unit_type = ? AND parent_number = ? '
          'AND unit_number = ?',
      whereArgs: <Object?>[itemId, unitType, parent, unit],
    );
  }
}
