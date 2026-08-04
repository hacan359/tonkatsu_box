import 'package:sqflite_common/sqlite_api.dart';

import 'migration.dart';

/// Global `tags` plus the `item_tags` junction. Name matching happens in Dart —
/// SQLite `LOWER()` is ASCII-only and tag names can be Cyrillic.
class MigrationV54 extends Migration {
  @override
  int get version => 54;

  @override
  String get description => 'global tags: tags + item_tags, merge collection_tags';

  @override
  Future<void> migrate(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color INTEGER,
        text_color INTEGER,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_tags_name ON tags(name)',
    );
    await db.execute('''
      CREATE TABLE IF NOT EXISTS item_tags (
        item_id INTEGER NOT NULL,
        tag_id INTEGER NOT NULL,
        PRIMARY KEY (item_id, tag_id),
        FOREIGN KEY (item_id) REFERENCES collection_items(id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_item_tags_tag ON item_tags(tag_id)',
    );

    // Guards re-runs (interrupted upgrade retried later): the merge below is
    // only meaningful into an empty global set.
    final List<Map<String, Object?>> existing =
        await db.rawQuery('SELECT COUNT(*) AS c FROM tags');
    if ((existing.first['c'] as int? ?? 0) > 0) return;

    final List<Map<String, Object?>> source = await db.rawQuery('''
      SELECT ct.id, ct.name, ct.color, ct.created_at, COUNT(ci.id) AS usage
      FROM collection_tags ct
      LEFT JOIN collection_items ci ON ci.tag_id = ct.id
      GROUP BY ct.id
    ''');
    if (source.isEmpty) return;

    // Group case-insensitively; the most-used source tag (ties: earliest
    // created, then lowest id) donates its exact name casing and color.
    final Map<String, List<Map<String, Object?>>> groups =
        <String, List<Map<String, Object?>>>{};
    for (final Map<String, Object?> row in source) {
      final String key = (row['name']! as String).toLowerCase();
      groups.putIfAbsent(key, () => <Map<String, Object?>>[]).add(row);
    }

    final List<String> orderedKeys = groups.keys.toList()..sort();
    final Map<int, int> oldToNew = <int, int>{};
    int sortOrder = 0;
    for (final String key in orderedKeys) {
      final List<Map<String, Object?>> group = groups[key]!
        ..sort((Map<String, Object?> a, Map<String, Object?> b) {
          final int byUsage =
              (b['usage']! as int).compareTo(a['usage']! as int);
          if (byUsage != 0) return byUsage;
          final int byCreated =
              (a['created_at']! as int).compareTo(b['created_at']! as int);
          if (byCreated != 0) return byCreated;
          return (a['id']! as int).compareTo(b['id']! as int);
        });
      final Map<String, Object?> winner = group.first;
      final int? color = winner['color'] as int? ??
          group
              .map((Map<String, Object?> r) => r['color'] as int?)
              .firstWhere((int? c) => c != null, orElse: () => null);
      final int createdAt = group
          .map((Map<String, Object?> r) => r['created_at']! as int)
          .reduce((int a, int b) => a < b ? a : b);

      final int newId = await db.insert('tags', <String, Object?>{
        'name': winner['name'],
        'color': color,
        'text_color': null,
        'sort_order': sortOrder++,
        'created_at': createdAt,
      });
      for (final Map<String, Object?> row in group) {
        oldToNew[row['id']! as int] = newId;
      }
    }

    final List<Map<String, Object?>> links = await db.rawQuery(
      'SELECT id, tag_id FROM collection_items WHERE tag_id IS NOT NULL',
    );
    final Batch batch = db.batch();
    for (final Map<String, Object?> link in links) {
      final int? newTagId = oldToNew[link['tag_id']! as int];
      if (newTagId == null) continue;
      batch.rawInsert(
        'INSERT OR IGNORE INTO item_tags (item_id, tag_id) VALUES (?, ?)',
        <Object?>[link['id'], newTagId],
      );
    }
    await batch.commit(noResult: true);
  }
}
