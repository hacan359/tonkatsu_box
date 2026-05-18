// DAO для работы с вишлистом.

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../shared/models/media_type.dart';
import '../../../shared/models/wishlist_item.dart';
import '../../../shared/models/wishlist_tag.dart';

/// Aggregate of a single wishlist-tag bucket. `null` [tag] is the
/// "Untagged" pseudo-bucket for items with no tag.
class WishlistTagCount {
  /// Creates a [WishlistTagCount].
  const WishlistTagCount({
    required this.tag,
    required this.activeCount,
    required this.totalCount,
  });

  /// Raw tag value (`null` means "untagged" bucket).
  final String? tag;

  /// Count of items where `is_resolved = 0`.
  final int activeCount;

  /// Count of items including resolved ones.
  final int totalCount;
}

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
    String? tag,
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
        'tag': tag,
      },
    );

    return WishlistItem(
      id: id,
      text: text,
      mediaTypeHint: mediaTypeHint,
      note: note,
      createdAt: DateTime.fromMillisecondsSinceEpoch(now * 1000),
      tag: tag,
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
    String? tag,
    bool clearTag = false,
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
    if (clearTag) {
      updates['tag'] = null;
    } else if (tag != null) {
      updates['tag'] = tag;
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

  /// Возвращает элементы вишлиста с применением [tagFilter].
  Future<List<WishlistItem>> getWishlistItemsFiltered({
    bool includeResolved = true,
    WishlistTagFilter tagFilter = const WishlistTagFilter.all(),
  }) async {
    final Database db = await _getDatabase();
    final List<String> conditions = <String>[];
    final List<Object?> args = <Object?>[];

    if (!includeResolved) {
      conditions.add('is_resolved = 0');
    }
    switch (tagFilter) {
      case WishlistTagFilterAll():
        break;
      case WishlistTagFilterUntagged():
        conditions.add('tag IS NULL');
      case WishlistTagFilterNamed(:final String tag):
        conditions.add('tag = ?');
        args.add(tag);
    }

    final String where = conditions.isEmpty
        ? ''
        : 'WHERE ${conditions.join(' AND ')}';

    final List<Map<String, dynamic>> rows = await db.rawQuery(
      'SELECT * FROM wishlist $where '
      'ORDER BY is_resolved ASC, created_at DESC',
      args,
    );
    return rows.map(WishlistItem.fromDb).toList();
  }

  /// Удаляет все записи с указанным тегом. NULL = «без тега».
  ///
  /// Возвращает количество удалённых записей.
  Future<int> deleteWishlistItemsByTag(String? tag) async {
    final Database db = await _getDatabase();
    if (tag == null) {
      return db.delete('wishlist', where: 'tag IS NULL');
    }
    return db.delete(
      'wishlist',
      where: 'tag = ?',
      whereArgs: <Object?>[tag],
    );
  }

  /// Переименовывает тег у всех носителей. Возвращает количество
  /// обновлённых записей. NULL в [from] позволяет проставить тег
  /// для ранее untagged записей.
  Future<int> renameWishlistTag(String? from, String to) async {
    final Database db = await _getDatabase();
    if (from == null) {
      return db.update(
        'wishlist',
        <String, dynamic>{'tag': to},
        where: 'tag IS NULL',
      );
    }
    return db.update(
      'wishlist',
      <String, dynamic>{'tag': to},
      where: 'tag = ?',
      whereArgs: <Object?>[from],
    );
  }
}
