import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../shared/models/tag.dart';
import '../query_chunk.dart';

/// Name + colors for a tag to resolve or create in
/// [GlobalTagDao.resolveOrCreateAll].
typedef TagSeed = ({String name, int? color, int? textColor});

/// DAO for the global `tags` table and the `item_tags` junction.
///
/// Deletions clean `item_tags` explicitly instead of leaning on the
/// `ON DELETE CASCADE` clause, so they behave the same on connections
/// opened without `PRAGMA foreign_keys = ON`.
class GlobalTagDao {
  const GlobalTagDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  /// Sorted by manual order, then by name.
  Future<List<Tag>> getAll() async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'tags',
      orderBy: 'sort_order ASC, name ASC',
    );
    return rows.map(Tag.fromDb).toList();
  }

  Future<Tag?> getById(int id) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'tags',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Tag.fromDb(rows.first);
  }

  /// Appends the new tag to the end of the manual order.
  Future<Tag> create(String name, {int? color, int? textColor}) async {
    final Database db = await _getDatabase();
    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final List<Map<String, Object?>> maxRow =
        await db.rawQuery('SELECT MAX(sort_order) AS m FROM tags');
    final int sortOrder = (maxRow.first['m'] as int? ?? -1) + 1;
    final int id = await db.insert('tags', <String, dynamic>{
      'name': name,
      'color': color,
      'text_color': textColor,
      'sort_order': sortOrder,
      'created_at': now,
    });
    return Tag(
      id: id,
      name: name,
      color: color,
      textColor: textColor,
      sortOrder: sortOrder,
      createdAt: now,
    );
  }

  Future<void> rename(int id, String name) async {
    final Database db = await _getDatabase();
    await db.update(
      'tags',
      <String, dynamic>{'name': name},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> updateColor(int id, int? color) async {
    final Database db = await _getDatabase();
    await db.update(
      'tags',
      <String, dynamic>{'color': color},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> updateTextColor(int id, int? textColor) async {
    final Database db = await _getDatabase();
    await db.update(
      'tags',
      <String, dynamic>{'text_color': textColor},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Deletes the tag together with its item links.
  Future<void> delete(int id) async {
    final Database db = await _getDatabase();
    await db.transaction((Transaction txn) async {
      await txn.delete(
        'item_tags',
        where: 'tag_id = ?',
        whereArgs: <Object?>[id],
      );
      await txn.delete('tags', where: 'id = ?', whereArgs: <Object?>[id]);
    });
  }

  /// Canonical case-insensitive key for matching tag names.
  static String nameKey(String name) => name.trim().toLowerCase();

  /// Finds a tag by name (case-insensitive) and returns its id,
  /// creating a new tag with the given colors when none exists.
  Future<int> resolveOrCreate(String name, {int? color, int? textColor}) async {
    final Map<String, int> ids = await resolveOrCreateAll(
      <TagSeed>[(name: name, color: color, textColor: textColor)],
    );
    return ids[nameKey(name)]!;
  }

  /// Batch resolve-or-create against one snapshot of the table: existing
  /// names keep their local settings, missing seeds are created with their
  /// colors. Returns a [nameKey] → id map covering every seed.
  Future<Map<String, int>> resolveOrCreateAll(Iterable<TagSeed> seeds) async {
    final Map<String, int> byKey = <String, int>{
      for (final Tag tag in await getAll()) nameKey(tag.name): tag.id,
    };
    for (final TagSeed seed in seeds) {
      final String key = nameKey(seed.name);
      if (byKey.containsKey(key)) continue;
      final Tag created =
          await create(seed.name, color: seed.color, textColor: seed.textColor);
      byKey[key] = created.id;
    }
    return byKey;
  }

  Future<Set<int>> getTagIdsByItem(int itemId) async {
    final Database db = await _getDatabase();
    final List<Map<String, Object?>> rows = await db.query(
      'item_tags',
      columns: <String>['tag_id'],
      where: 'item_id = ?',
      whereArgs: <Object?>[itemId],
    );
    return rows.map((Map<String, Object?> r) => r['tag_id']! as int).toSet();
  }

  /// Tag ids for many items at once (list rendering / filtering).
  /// Items without tags are absent from the map.
  Future<Map<int, Set<int>>> getTagIdsForItems(List<int> itemIds) async {
    final Database db = await _getDatabase();
    final List<Map<String, Object?>> rows = await queryByIdsInChunks(
      itemIds,
      (List<int> chunk) => db.query(
        'item_tags',
        where: 'item_id IN (${List<String>.filled(chunk.length, '?').join(', ')})',
        whereArgs: chunk,
      ),
    );
    final Map<int, Set<int>> result = <int, Set<int>>{};
    for (final Map<String, Object?> row in rows) {
      result
          .putIfAbsent(row['item_id']! as int, () => <int>{})
          .add(row['tag_id']! as int);
    }
    return result;
  }

  /// The whole junction as a map — items without tags are absent.
  Future<Map<int, Set<int>>> getAllItemTags() async {
    final Database db = await _getDatabase();
    final List<Map<String, Object?>> rows = await db.query('item_tags');
    final Map<int, Set<int>> result = <int, Set<int>>{};
    for (final Map<String, Object?> row in rows) {
      result
          .putIfAbsent(row['item_id']! as int, () => <int>{})
          .add(row['tag_id']! as int);
    }
    return result;
  }

  /// Replaces the item's tag set with [tagIds].
  Future<void> setItemTags(int itemId, Set<int> tagIds) async {
    final Database db = await _getDatabase();
    await db.transaction((Transaction txn) async {
      await txn.delete(
        'item_tags',
        where: 'item_id = ?',
        whereArgs: <Object?>[itemId],
      );
      for (final int tagId in tagIds) {
        await txn.rawInsert(
          'INSERT OR IGNORE INTO item_tags (item_id, tag_id) VALUES (?, ?)',
          <Object?>[itemId, tagId],
        );
      }
    });
  }

  /// Links [tagId] to every item in [itemIds] in one batch. Additive —
  /// existing links stay, unlike the replace-set [setItemTags].
  Future<void> addTagToItems(List<int> itemIds, int tagId) async {
    if (itemIds.isEmpty) return;
    final Database db = await _getDatabase();
    final Batch batch = db.batch();
    for (final int itemId in itemIds) {
      batch.rawInsert(
        'INSERT OR IGNORE INTO item_tags (item_id, tag_id) VALUES (?, ?)',
        <Object?>[itemId, tagId],
      );
    }
    await batch.commit(noResult: true);
  }

  /// Persists a manual reorder: [orderedIds] in their new display order.
  Future<void> setSortOrders(List<int> orderedIds) async {
    if (orderedIds.isEmpty) return;
    final Database db = await _getDatabase();
    final Batch batch = db.batch();
    for (int i = 0; i < orderedIds.length; i++) {
      batch.update(
        'tags',
        <String, dynamic>{'sort_order': i},
        where: 'id = ?',
        whereArgs: <Object?>[orderedIds[i]],
      );
    }
    await batch.commit(noResult: true);
  }

  /// Upsert keeping the original IDs — used by import.
  Future<void> upsertAll(List<Tag> tags) async {
    if (tags.isEmpty) return;
    final Database db = await _getDatabase();
    final Batch batch = db.batch();
    for (final Tag tag in tags) {
      batch.insert(
        'tags',
        tag.toDb(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }
}
