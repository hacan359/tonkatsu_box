import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tonkatsu_box/core/database/dao/global_tag_dao.dart';
import 'package:tonkatsu_box/core/database/migrations/migration_v54.dart';
import 'package:tonkatsu_box/shared/models/tag.dart';

void main() {
  sqfliteFfiInit();
  final DatabaseFactory factory = databaseFactoryFfi;

  late Database db;
  late GlobalTagDao dao;

  /// Real in-memory DB: the junction logic (transactions, OR IGNORE,
  /// chunked IN queries) is what's under test, so mocks would prove nothing.
  setUp(() async {
    db = await factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 54,
        onCreate: (Database database, int _) async {
          await database.execute('''
            CREATE TABLE collection_tags (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              collection_id INTEGER NOT NULL,
              name TEXT NOT NULL,
              color INTEGER,
              sort_order INTEGER NOT NULL DEFAULT 0,
              created_at INTEGER NOT NULL
            )
          ''');
          await database.execute('''
            CREATE TABLE collection_items (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              media_type TEXT NOT NULL,
              external_id INTEGER NOT NULL,
              tag_id INTEGER
            )
          ''');
          await MigrationV54().migrate(database);
        },
      ),
    );
    dao = GlobalTagDao(() async => db);
  });

  tearDown(() async => db.close());

  group('GlobalTagDao', () {
    group('create', () {
      test('appends to the end of the manual order', () async {
        final Tag first = await dao.create('RPG');
        final Tag second = await dao.create('Инди');
        expect(first.sortOrder, 0);
        expect(second.sortOrder, 1);
      });

      test('stores colors', () async {
        final Tag tag = await dao.create(
          'RPG',
          color: 0xFF112233,
          textColor: 0xFFFFFFFF,
        );
        final Tag? loaded = await dao.getById(tag.id);
        expect(loaded?.color, 0xFF112233);
        expect(loaded?.textColor, 0xFFFFFFFF);
      });
    });

    group('getAll', () {
      test('sorts by manual order, then name', () async {
        final Tag a = await dao.create('zzz');
        final Tag b = await dao.create('aaa');
        expect(
          (await dao.getAll()).map((Tag t) => t.id).toList(),
          <int>[a.id, b.id],
        );

        await dao.setSortOrders(<int>[b.id, a.id]);
        expect(
          (await dao.getAll()).map((Tag t) => t.id).toList(),
          <int>[b.id, a.id],
        );
      });
    });

    group('rename and colors', () {
      test('rename changes the name', () async {
        final Tag tag = await dao.create('RPG');
        await dao.rename(tag.id, 'JRPG');
        expect((await dao.getById(tag.id))?.name, 'JRPG');
      });

      test('updateColor and updateTextColor set and clear', () async {
        final Tag tag = await dao.create('RPG', color: 1, textColor: 2);
        await dao.updateColor(tag.id, null);
        await dao.updateTextColor(tag.id, 0xFF000000);
        final Tag? loaded = await dao.getById(tag.id);
        expect(loaded?.color, isNull);
        expect(loaded?.textColor, 0xFF000000);
      });
    });

    group('delete', () {
      test('removes the tag together with its item links', () async {
        final Tag tag = await dao.create('RPG');
        final Tag other = await dao.create('Инди');
        await dao.setItemTags(1, <int>{tag.id, other.id});

        await dao.delete(tag.id);

        expect(await dao.getById(tag.id), isNull);
        expect(await dao.getTagIdsByItem(1), <int>{other.id});
      });
    });

    group('resolveOrCreate', () {
      test('returns the existing id for a case-insensitive match', () async {
        final Tag tag = await dao.create('RPG');
        expect(await dao.resolveOrCreate('rpg'), tag.id);
        expect(await dao.getAll(), hasLength(1));
      });

      test('matches Cyrillic names ignoring case', () async {
        final Tag tag = await dao.create('Хоррор');
        expect(await dao.resolveOrCreate('хОррОр'), tag.id);
        expect(await dao.getAll(), hasLength(1));
      });

      test('creates a new tag when none matches', () async {
        final int id = await dao.resolveOrCreate('Инди', color: 5);
        expect((await dao.getById(id))?.color, 5);
      });
    });

    group('item links', () {
      test('setItemTags replaces the whole set', () async {
        final Tag a = await dao.create('a');
        final Tag b = await dao.create('b');
        final Tag c = await dao.create('c');
        await dao.setItemTags(1, <int>{a.id, b.id});
        await dao.setItemTags(1, <int>{c.id});
        expect(await dao.getTagIdsByItem(1), <int>{c.id});
      });

      test('setItemTags with an empty set clears the item', () async {
        final Tag a = await dao.create('a');
        await dao.setItemTags(1, <int>{a.id});
        await dao.setItemTags(1, <int>{});
        expect(await dao.getTagIdsByItem(1), isEmpty);
      });

      test('getTagIdsForItems maps only tagged items', () async {
        final Tag a = await dao.create('a');
        final Tag b = await dao.create('b');
        await dao.setItemTags(1, <int>{a.id, b.id});
        await dao.setItemTags(2, <int>{b.id});

        final Map<int, Set<int>> map =
            await dao.getTagIdsForItems(<int>[1, 2, 3]);
        expect(map, hasLength(2));
        expect(map[1], <int>{a.id, b.id});
        expect(map[2], <int>{b.id});
        expect(map.containsKey(3), isFalse);
      });

      test('getTagIdsForItems handles an empty id list', () async {
        expect(await dao.getTagIdsForItems(<int>[]), isEmpty);
      });

      test('addTagToItems links additively, keeping existing tags', () async {
        final Tag a = await dao.create('a');
        final Tag owned = await dao.create('Owned');
        await dao.setItemTags(1, <int>{a.id});

        await dao.addTagToItems(<int>[1, 2], owned.id);

        expect(await dao.getTagIdsByItem(1), <int>{a.id, owned.id});
        expect(await dao.getTagIdsByItem(2), <int>{owned.id});
      });

      test('addTagToItems is idempotent for an already linked tag', () async {
        final Tag owned = await dao.create('Owned');
        await dao.addTagToItems(<int>[1], owned.id);
        await dao.addTagToItems(<int>[1], owned.id);

        expect(await dao.getTagIdsByItem(1), <int>{owned.id});
      });

      test('addTagToItems with no items is a no-op', () async {
        final Tag owned = await dao.create('Owned');
        await dao.addTagToItems(<int>[], owned.id);

        expect(await dao.getTagIdsByItem(1), isEmpty);
      });
    });

    group('upsertAll', () {
      test('inserts and replaces by id', () async {
        final Tag tag = await dao.create('RPG', color: 1);
        await dao.upsertAll(<Tag>[
          tag.copyWith(name: 'JRPG', clearColor: true),
          const Tag(id: 99, name: 'Инди', createdAt: 1700000000),
        ]);

        final Tag? replaced = await dao.getById(tag.id);
        expect(replaced?.name, 'JRPG');
        expect(replaced?.color, isNull);
        expect((await dao.getById(99))?.name, 'Инди');
      });

      test('empty list is a no-op', () async {
        await dao.upsertAll(const <Tag>[]);
        expect(await dao.getAll(), isEmpty);
      });
    });
  });
}
