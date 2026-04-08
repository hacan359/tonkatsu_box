// DAO для работы с тегами коллекций.

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../shared/models/collection_tag.dart';

/// DAO для таблицы `collection_tags` и колонки `tag_id` в `collection_items`.
class TagDao {
  /// Создаёт DAO с функцией получения базы данных.
  const TagDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  // ==================== Tags CRUD ====================

  /// Возвращает все теги коллекции, отсортированные по sort_order и имени.
  Future<List<CollectionTag>> getTagsByCollection(int collectionId) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'collection_tags',
      where: 'collection_id = ?',
      whereArgs: <Object?>[collectionId],
      orderBy: 'sort_order ASC, name ASC',
    );
    return rows.map(CollectionTag.fromDb).toList();
  }

  /// Возвращает тег по ID.
  Future<CollectionTag?> getTagById(int id) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'collection_tags',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return CollectionTag.fromDb(rows.first);
  }

  /// Создаёт тег и возвращает его.
  Future<CollectionTag> createTag(
    int collectionId,
    String name, {
    int? color,
  }) async {
    final Database db = await _getDatabase();
    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final int id = await db.insert(
      'collection_tags',
      <String, dynamic>{
        'collection_id': collectionId,
        'name': name,
        'color': color,
        'sort_order': 0,
        'created_at': now,
      },
    );
    return CollectionTag(
      id: id,
      collectionId: collectionId,
      name: name,
      color: color,
      createdAt: now,
    );
  }

  /// Переименовывает тег.
  Future<void> renameTag(int id, String name) async {
    final Database db = await _getDatabase();
    await db.update(
      'collection_tags',
      <String, dynamic>{'name': name},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Обновляет цвет тега.
  Future<void> updateTagColor(int id, int? color) async {
    final Database db = await _getDatabase();
    await db.update(
      'collection_tags',
      <String, dynamic>{'color': color},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Удаляет тег. ON DELETE SET NULL обнуляет tag_id у элементов.
  Future<void> deleteTag(int id) async {
    final Database db = await _getDatabase();
    await db.delete(
      'collection_tags',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Возвращает все теги из всех коллекций.
  Future<List<CollectionTag>> getAll() async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'collection_tags',
      orderBy: 'sort_order ASC, name ASC',
    );
    return rows.map(CollectionTag.fromDb).toList();
  }

  // ==================== Item tag assignment ====================

  /// Назначает тег элементу коллекции.
  Future<void> setItemTag(int collectionItemId, int? tagId) async {
    final Database db = await _getDatabase();
    await db.update(
      'collection_items',
      <String, dynamic>{'tag_id': tagId},
      where: 'id = ?',
      whereArgs: <Object?>[collectionItemId],
    );
  }

  /// Обнуляет tag_id у всех элементов с указанным тегом.
  Future<void> clearTagFromItems(int tagId) async {
    final Database db = await _getDatabase();
    await db.update(
      'collection_items',
      <String, dynamic>{'tag_id': null},
      where: 'tag_id = ?',
      whereArgs: <Object?>[tagId],
    );
  }

  /// Сохраняет или обновляет список тегов (для импорта).
  Future<void> upsertAll(List<CollectionTag> tags) async {
    if (tags.isEmpty) return;
    final Database db = await _getDatabase();
    final Batch batch = db.batch();
    for (final CollectionTag tag in tags) {
      batch.insert(
        'collection_tags',
        tag.toDb(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }
}
