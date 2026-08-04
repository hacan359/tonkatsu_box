import 'package:core/database/dao/mangabaka_tag_dao.dart';
import 'package:core/database/schema.dart';
import 'package:core/models/mangabaka_tag.dart';
import 'package:test/test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late MangaBakaTagDao dao;

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (Database d, int _) =>
            DatabaseSchema.createMangaBakaTagsTable(d),
      ),
    );
    dao = MangaBakaTagDao(() async => db);
  });

  tearDown(() async {
    await db.close();
  });

  group('MangaBakaTagDao', () {
    group('getAll', () {
      test('returns empty on a fresh table', () async {
        expect(await dao.getAll(), isEmpty);
      });

      test('sorts by name ascending', () async {
        await dao.replaceAll(const <MangaBakaTag>[
          MangaBakaTag(id: 1, name: 'Zombies'),
          MangaBakaTag(id: 2, name: 'Aliens'),
          MangaBakaTag(id: 3, name: 'Mecha'),
        ]);

        final List<MangaBakaTag> all = await dao.getAll();
        expect(
          all.map((MangaBakaTag t) => t.name),
          <String>['Aliens', 'Mecha', 'Zombies'],
        );
      });

      test('round-trips every field through the DB', () async {
        await dao.replaceAll(const <MangaBakaTag>[
          MangaBakaTag(
            id: 7,
            name: 'Isekai',
            parentId: 3,
            namePath: 'Genre / Isekai',
            description: 'Another world',
            isSpoiler: true,
            isGenre: true,
            contentRating: 'explicit',
            seriesCount: 42,
            level: 2,
            updatedAt: 1700000000,
          ),
        ]);

        final MangaBakaTag tag = (await dao.getAll()).single;
        expect(tag.id, 7);
        expect(tag.name, 'Isekai');
        expect(tag.parentId, 3);
        expect(tag.namePath, 'Genre / Isekai');
        expect(tag.description, 'Another world');
        expect(tag.isSpoiler, isTrue);
        expect(tag.isGenre, isTrue);
        expect(tag.contentRating, 'explicit');
        expect(tag.seriesCount, 42);
        expect(tag.level, 2);
        expect(tag.updatedAt, 1700000000);
      });

      test('keeps defaults for a minimally populated tag', () async {
        await dao.replaceAll(const <MangaBakaTag>[
          MangaBakaTag(id: 1, name: 'Plain'),
        ]);

        final MangaBakaTag tag = (await dao.getAll()).single;
        expect(tag.parentId, isNull);
        expect(tag.namePath, isNull);
        expect(tag.description, isNull);
        expect(tag.isSpoiler, isFalse);
        expect(tag.isGenre, isFalse);
        expect(tag.contentRating, isNull);
        expect(tag.seriesCount, 0);
        expect(tag.level, 0);
      });

      test('stamps updated_at when the tag carries none', () async {
        await dao.replaceAll(const <MangaBakaTag>[
          MangaBakaTag(id: 1, name: 'Plain'),
        ]);

        expect((await dao.getAll()).single.updatedAt, isNotNull);
      });
    });

    group('replaceAll', () {
      test('wipes previous rows', () async {
        await dao.replaceAll(const <MangaBakaTag>[
          MangaBakaTag(id: 1, name: 'Old'),
        ]);
        await dao.replaceAll(const <MangaBakaTag>[
          MangaBakaTag(id: 2, name: 'New'),
        ]);

        final List<MangaBakaTag> all = await dao.getAll();
        expect(all, hasLength(1));
        expect(all.single.name, 'New');
      });

      test('empties the catalog when given an empty list', () async {
        await dao.replaceAll(const <MangaBakaTag>[
          MangaBakaTag(id: 1, name: 'Old'),
        ]);
        await dao.replaceAll(const <MangaBakaTag>[]);

        expect(await dao.getAll(), isEmpty);
      });
    });
  });
}
