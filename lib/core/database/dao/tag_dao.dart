import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../shared/models/collection_tag.dart';

/// DAO for the `collection_tags` table and the `tag_id` column in
/// `collection_items`.
class TagDao {
  const TagDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  /// Sorted by sort_order, then by name.
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

  Future<void> renameTag(int id, String name) async {
    final Database db = await _getDatabase();
    await db.update(
      'collection_tags',
      <String, dynamic>{'name': name},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> updateTagColor(int id, int? color) async {
    final Database db = await _getDatabase();
    await db.update(
      'collection_tags',
      <String, dynamic>{'color': color},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// ON DELETE SET NULL clears tag_id on the items.
  Future<void> deleteTag(int id) async {
    final Database db = await _getDatabase();
    await db.delete(
      'collection_tags',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Case-insensitive name lookup done in Dart via [String.toLowerCase],
  /// because SQLite `LOWER()` only lowercases ASCII by default while tag
  /// names can be in any language (e.g. Cyrillic).
  Future<CollectionTag?> findTagByNameCaseInsensitive(
    int collectionId,
    String name,
  ) async {
    final String needle = name.toLowerCase();
    final List<CollectionTag> tags = await getTagsByCollection(collectionId);
    for (final CollectionTag tag in tags) {
      if (tag.name.toLowerCase() == needle) return tag;
    }
    return null;
  }

  /// Finds a tag by name (case-insensitive) and returns its id,
  /// creating a new tag with the given color when none exists.
  Future<int> resolveOrCreateInCollection(
    int collectionId,
    String name, {
    int? color,
  }) async {
    final CollectionTag? existing =
        await findTagByNameCaseInsensitive(collectionId, name);
    if (existing != null) return existing.id;
    final CollectionTag created =
        await createTag(collectionId, name, color: color);
    return created.id;
  }

  Future<List<CollectionTag>> getAll() async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'collection_tags',
      orderBy: 'sort_order ASC, name ASC',
    );
    return rows.map(CollectionTag.fromDb).toList();
  }

  Future<void> setItemTag(int collectionItemId, int? tagId) async {
    final Database db = await _getDatabase();
    await db.update(
      'collection_items',
      <String, dynamic>{'tag_id': tagId},
      where: 'id = ?',
      whereArgs: <Object?>[collectionItemId],
    );
  }

  /// Clears tag_id on all items carrying the given tag.
  Future<void> clearTagFromItems(int tagId) async {
    final Database db = await _getDatabase();
    await db.update(
      'collection_items',
      <String, dynamic>{'tag_id': null},
      where: 'tag_id = ?',
      whereArgs: <Object?>[tagId],
    );
  }

  /// Upsert keeping the original IDs — used by import.
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
