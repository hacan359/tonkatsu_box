import 'package:core/database/dao/mangadex_tag_dao.dart';
import 'package:core/database/migrations/migration_v59.dart';
import 'package:core/models/mangadex_tag.dart';
import 'package:test/test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late MangaDexTagDao dao;

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        // No create*Table helper exists — v59 inlines the DDL.
        onCreate: (Database d, int _) => MigrationV59().migrate(d),
      ),
    );
    dao = MangaDexTagDao(() async => db);
  });

  tearDown(() async {
    await db.close();
  });

  group('MangaDexTagDao', () {
    group('getAll', () {
      test('returns empty on a fresh table', () async {
        expect(await dao.getAll(), isEmpty);
      });

      test('sorts by name ascending', () async {
        await dao.replaceAll(const <MangaDexTag>[
          MangaDexTag(id: 'c', name: 'Romance', group: 'genre'),
          MangaDexTag(id: 'a', name: 'Action', group: 'genre'),
          MangaDexTag(id: 'b', name: 'Mystery', group: 'theme'),
        ]);

        final List<MangaDexTag> all = await dao.getAll();
        expect(
          all.map((MangaDexTag t) => t.name),
          <String>['Action', 'Mystery', 'Romance'],
        );
      });

      test('round-trips id, name, group and updatedAt', () async {
        await dao.replaceAll(const <MangaDexTag>[
          MangaDexTag(
            id: '391b0423-d847-456f-aff0-8b0cfc03066b',
            name: 'Action',
            group: 'genre',
            updatedAt: 1700000000,
          ),
        ]);

        final MangaDexTag tag = (await dao.getAll()).single;
        expect(tag.id, '391b0423-d847-456f-aff0-8b0cfc03066b');
        expect(tag.name, 'Action');
        expect(tag.group, 'genre');
        expect(tag.updatedAt, 1700000000);
      });

      test('stamps updated_at when the tag carries none', () async {
        await dao.replaceAll(const <MangaDexTag>[
          MangaDexTag(id: 'a', name: 'Action', group: 'genre'),
        ]);

        expect((await dao.getAll()).single.updatedAt, isNotNull);
      });

      test('reads a null tag_group back as an empty group', () async {
        await db.insert('mangadex_tags', <String, Object?>{
          'id': 'a',
          'name': 'Action',
          'tag_group': null,
        });

        expect((await dao.getAll()).single.group, '');
      });
    });

    group('replaceAll', () {
      test('wipes previous rows', () async {
        await dao.replaceAll(const <MangaDexTag>[
          MangaDexTag(id: 'a', name: 'Old', group: 'genre'),
        ]);
        await dao.replaceAll(const <MangaDexTag>[
          MangaDexTag(id: 'b', name: 'New', group: 'theme'),
        ]);

        final List<MangaDexTag> all = await dao.getAll();
        expect(all, hasLength(1));
        expect(all.single.name, 'New');
      });

      test('empties the catalog when given an empty list', () async {
        await dao.replaceAll(const <MangaDexTag>[
          MangaDexTag(id: 'a', name: 'Old', group: 'genre'),
        ]);
        await dao.replaceAll(const <MangaDexTag>[]);

        expect(await dao.getAll(), isEmpty);
      });
    });
  });
}
