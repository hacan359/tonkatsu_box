// DAO для работы с вишлистом.

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../shared/models/media_type.dart';
import '../../../shared/models/wishlist_item.dart';

/// DAO для таблицы `wishlist`.
class WishlistDao {
  /// Создаёт DAO с функцией получения базы данных.
  const WishlistDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  /// Добавляет элемент в вишлист.
  ///
  /// Возвращает созданный [WishlistItem] с присвоенным ID.
  Future<WishlistItem> addWishlistItem({
    required String text,
    MediaType? mediaTypeHint,
    String? note,
  }) async {
    final Database db = await _getDatabase();
    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final int id = await db.insert(
      'wishlist',
      <String, dynamic>{
        'text': text,
        'media_type_hint': mediaTypeHint?.value,
        'note': note,
        'is_resolved': 0,
        'created_at': now,
      },
    );

    return WishlistItem(
      id: id,
      text: text,
      mediaTypeHint: mediaTypeHint,
      note: note,
      createdAt: DateTime.fromMillisecondsSinceEpoch(now * 1000),
    );
  }

  /// Возвращает все элементы вишлиста.
  ///
  /// Сортировка: активные первыми (по created_at DESC),
  /// затем resolved (по resolved_at DESC).
  /// Если [includeResolved] == false, возвращает только активные.
  Future<List<WishlistItem>> getWishlistItems({
    bool includeResolved = true,
  }) async {
    final Database db = await _getDatabase();
    final String where = includeResolved ? '' : 'WHERE is_resolved = 0';
    final List<Map<String, dynamic>> rows = await db.rawQuery(
      'SELECT * FROM wishlist $where '
      'ORDER BY is_resolved ASC, created_at DESC',
    );
    return rows.map(WishlistItem.fromDb).toList();
  }

  /// Возвращает количество элементов вишлиста.
  ///
  /// Если [onlyActive] == true, считает только неразрешённые.
  Future<int> getWishlistItemCount({bool onlyActive = true}) async {
    final Database db = await _getDatabase();
    final String where = onlyActive ? 'WHERE is_resolved = 0' : '';
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM wishlist $where',
    );
    return result.first['count'] as int;
  }

  /// Обновляет элемент вишлиста.
  Future<void> updateWishlistItem(
    int id, {
    String? text,
    MediaType? mediaTypeHint,
    bool clearMediaTypeHint = false,
    String? note,
    bool clearNote = false,
  }) async {
    final Map<String, dynamic> updates = <String, dynamic>{};
    if (text != null) updates['text'] = text;
    if (clearMediaTypeHint) {
      updates['media_type_hint'] = null;
    } else if (mediaTypeHint != null) {
      updates['media_type_hint'] = mediaTypeHint.value;
    }
    if (clearNote) {
      updates['note'] = null;
    } else if (note != null) {
      updates['note'] = note;
    }
    if (updates.isEmpty) return;

    final Database db = await _getDatabase();
    await db.update(
      'wishlist',
      updates,
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Помечает элемент вишлиста как resolved.
  Future<void> resolveWishlistItem(int id) async {
    final Database db = await _getDatabase();
    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await db.update(
      'wishlist',
      <String, dynamic>{
        'is_resolved': 1,
        'resolved_at': now,
      },
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Снимает отметку resolved с элемента вишлиста.
  Future<void> unresolveWishlistItem(int id) async {
    final Database db = await _getDatabase();
    await db.update(
      'wishlist',
      <String, dynamic>{
        'is_resolved': 0,
        'resolved_at': null,
      },
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Удаляет элемент вишлиста.
  Future<void> deleteWishlistItem(int id) async {
    final Database db = await _getDatabase();
    await db.delete(
      'wishlist',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Находит активный (не resolved) элемент вишлиста по тексту.
  ///
  /// Возвращает первый найденный элемент или null.
  Future<WishlistItem?> findUnresolvedByText(String text) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'wishlist',
      where: 'text = ? AND is_resolved = 0',
      whereArgs: <Object?>[text],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return WishlistItem.fromDb(rows.first);
  }

  /// Удаляет все resolved элементы вишлиста.
  ///
  /// Возвращает количество удалённых записей.
  Future<int> clearResolvedWishlistItems() async {
    final Database db = await _getDatabase();
    return db.delete(
      'wishlist',
      where: 'is_resolved = 1',
    );
  }
}
