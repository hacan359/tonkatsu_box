import 'package:core/database/migrations/migration_v54.dart';
import 'package:test/test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  final DatabaseFactory factory = databaseFactoryFfi;

  /// A pre-v54 database with the legacy tag structures: `collection_tags`
  /// and the `tag_id` column on a minimal `collection_items`.
  Future<Database> openOldDb() async {
    return factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 53,
        onCreate: (Database db, int _) async {
          await db.execute('''
            CREATE TABLE collection_tags (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              collection_id INTEGER NOT NULL,
              name TEXT NOT NULL,
              color INTEGER,
              sort_order INTEGER NOT NULL DEFAULT 0,
              created_at INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE collection_items (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              media_type TEXT NOT NULL,
              external_id INTEGER NOT NULL,
              tag_id INTEGER
            )
          ''');
        },
      ),
    );
  }

  Future<void> seedTag(
    Database db, {
    required int id,
    required int collectionId,
    required String name,
    int? color,
    int createdAt = 1700000000,
  }) async {
    await db.insert('collection_tags', <String, Object?>{
      'id': id,
      'collection_id': collectionId,
      'name': name,
      'color': color,
      'sort_order': 0,
      'created_at': createdAt,
    });
  }

  Future<void> seedItem(Database db, {required int id, int? tagId}) async {
    await db.insert('collection_items', <String, Object?>{
      'id': id,
      'media_type': 'game',
      'external_id': id,
      'tag_id': tagId,
    });
  }

  Future<bool> hasTable(Database db, String table) async {
    final List<Map<String, Object?>> rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      <Object?>[table],
    );
    return rows.isNotEmpty;
  }

  Future<bool> hasIndex(Database db, String index) async {
    final List<Map<String, Object?>> rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='index' AND name=?",
      <Object?>[index],
    );
    return rows.isNotEmpty;
  }

  Future<List<Map<String, Object?>>> globalTags(Database db) =>
      db.query('tags', orderBy: 'sort_order ASC');

  Future<Set<int>> itemTagIds(Database db, int itemId) async {
    final List<Map<String, Object?>> rows = await db.query(
      'item_tags',
      where: 'item_id = ?',
      whereArgs: <Object?>[itemId],
    );
    return rows.map((Map<String, Object?> r) => r['tag_id']! as int).toSet();
  }

  group('MigrationV54', () {
    late Database db;

    setUp(() async => db = await openOldDb());

    tearDown(() async => db.close());

    test('creates tags and item_tags with their indexes', () async {
      await MigrationV54().migrate(db);
      expect(await hasTable(db, 'tags'), isTrue);
      expect(await hasTable(db, 'item_tags'), isTrue);
      expect(await hasIndex(db, 'idx_tags_name'), isTrue);
      expect(await hasIndex(db, 'idx_item_tags_tag'), isTrue);
    });

    test('tags table has the text_color column, empty after migration',
        () async {
      await MigrationV54().migrate(db);
      final List<Map<String, Object?>> columns =
          await db.rawQuery('PRAGMA table_info(tags)');
      expect(
        columns.map((Map<String, Object?> c) => c['name']),
        contains('text_color'),
      );
    });

    test('merges same-name tags case-insensitively, including Cyrillic',
        () async {
      await seedTag(db, id: 1, collectionId: 1, name: 'RPG');
      await seedTag(db, id: 2, collectionId: 2, name: 'rpg');
      await seedTag(db, id: 3, collectionId: 1, name: 'Хоррор');
      await seedTag(db, id: 4, collectionId: 3, name: 'хоррор');
      await seedTag(db, id: 5, collectionId: 2, name: 'Инди');
      await MigrationV54().migrate(db);

      final List<Map<String, Object?>> tags = await globalTags(db);
      expect(tags, hasLength(3));
      final Set<String> lower = tags
          .map((Map<String, Object?> t) => (t['name']! as String).toLowerCase())
          .toSet();
      expect(lower, <String>{'rpg', 'хоррор', 'инди'});
    });

    test('most-used source tag donates name casing and color', () async {
      await seedTag(db, id: 1, collectionId: 1, name: 'RPG', color: 0xFFFF0000);
      await seedTag(db, id: 2, collectionId: 2, name: 'rpg', color: 0xFF0000FF);
      await seedItem(db, id: 1, tagId: 2);
      await seedItem(db, id: 2, tagId: 2);
      await seedItem(db, id: 3, tagId: 1);
      await MigrationV54().migrate(db);

      final List<Map<String, Object?>> tags = await globalTags(db);
      expect(tags, hasLength(1));
      expect(tags.first['name'], 'rpg');
      expect(tags.first['color'], 0xFF0000FF);
    });

    test('falls back to any non-null color when the winner has none',
        () async {
      await seedTag(db, id: 1, collectionId: 1, name: 'Инди');
      await seedTag(db, id: 2, collectionId: 2, name: 'инди', color: 0xFF00FF00);
      await seedItem(db, id: 1, tagId: 1);
      await seedItem(db, id: 2, tagId: 1);
      await MigrationV54().migrate(db);

      final List<Map<String, Object?>> tags = await globalTags(db);
      expect(tags.first['color'], 0xFF00FF00);
    });

    test('keeps the earliest created_at across the merged group', () async {
      await seedTag(
          db, id: 1, collectionId: 1, name: 'RPG', createdAt: 1700000500);
      await seedTag(
          db, id: 2, collectionId: 2, name: 'rpg', createdAt: 1700000100);
      await seedItem(db, id: 1, tagId: 1);
      await seedItem(db, id: 2, tagId: 1);
      await MigrationV54().migrate(db);

      final List<Map<String, Object?>> tags = await globalTags(db);
      expect(tags.first['created_at'], 1700000100);
    });

    test('carries every tag_id link into item_tags, merged tags included',
        () async {
      await seedTag(db, id: 1, collectionId: 1, name: 'RPG');
      await seedTag(db, id: 2, collectionId: 2, name: 'rpg');
      await seedTag(db, id: 3, collectionId: 1, name: 'Инди');
      await seedItem(db, id: 10, tagId: 1);
      await seedItem(db, id: 11, tagId: 2);
      await seedItem(db, id: 12, tagId: 3);
      await seedItem(db, id: 13);
      await MigrationV54().migrate(db);

      final List<Map<String, Object?>> tags = await globalTags(db);
      final int rpgId = tags.firstWhere((Map<String, Object?> t) =>
          (t['name']! as String).toLowerCase() == 'rpg')['id']! as int;
      final int indieId = tags.firstWhere((Map<String, Object?> t) =>
          (t['name']! as String).toLowerCase() == 'инди')['id']! as int;

      expect(await itemTagIds(db, 10), <int>{rpgId});
      expect(await itemTagIds(db, 11), <int>{rpgId});
      expect(await itemTagIds(db, 12), <int>{indieId});
      expect(await itemTagIds(db, 13), isEmpty);
    });

    test('assigns sort_order alphabetically by lowercased name', () async {
      await seedTag(db, id: 1, collectionId: 1, name: 'zzz');
      await seedTag(db, id: 2, collectionId: 1, name: 'AAA');
      await MigrationV54().migrate(db);

      final List<Map<String, Object?>> tags = await globalTags(db);
      expect(tags.first['name'], 'AAA');
      expect(tags.first['sort_order'], 0);
      expect(tags.last['name'], 'zzz');
      expect(tags.last['sort_order'], 1);
    });

    test('re-run is a no-op — no duplicated tags or links', () async {
      await seedTag(db, id: 1, collectionId: 1, name: 'RPG');
      await seedItem(db, id: 1, tagId: 1);
      await MigrationV54().migrate(db);
      await MigrationV54().migrate(db);

      expect(await globalTags(db), hasLength(1));
      final List<Map<String, Object?>> links = await db.query('item_tags');
      expect(links, hasLength(1));
    });

    test('empty collection_tags migrates to an empty global set', () async {
      await MigrationV54().migrate(db);
      expect(await globalTags(db), isEmpty);
      expect(await db.query('item_tags'), isEmpty);
    });

    test('leaves the legacy structures untouched', () async {
      await seedTag(db, id: 1, collectionId: 1, name: 'RPG');
      await seedTag(db, id: 2, collectionId: 2, name: 'rpg');
      await seedItem(db, id: 1, tagId: 1);
      await MigrationV54().migrate(db);

      expect(await db.query('collection_tags'), hasLength(2));
      final List<Map<String, Object?>> items = await db.query(
        'collection_items',
        where: 'id = ?',
        whereArgs: <Object?>[1],
      );
      expect(items.first['tag_id'], 1);
    });
  });
}
