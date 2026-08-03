import 'package:core/database/dao/custom_media_dao.dart';
import 'package:core/database/migrations/migration.dart';
import 'package:core/database/migrations/migration_registry.dart';
import 'package:core/models/custom_media.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

CustomMedia _item({
  int id = 0,
  String title = 'My card',
  MediaType? displayType,
  String? altTitle,
  String? coverUrl,
  int? year,
  String? genres,
  int? platformId,
  String? format,
  int? unitTotal,
  int? unitGroupTotal,
  int? cachedAt,
}) =>
    CustomMedia(
      id: id,
      title: title,
      displayType: displayType,
      altTitle: altTitle,
      coverUrl: coverUrl,
      year: year,
      genres: genres,
      platformId: platformId,
      format: format,
      unitTotal: unitTotal,
      unitGroupTotal: unitGroupTotal,
      cachedAt: cachedAt,
    );

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late CustomMediaDao dao;

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: MigrationRegistry.all.last.version,
        onCreate: (Database d, int _) async {
          for (final Migration m in MigrationRegistry.all) {
            await m.migrate(d);
          }
        },
      ),
    );
    dao = CustomMediaDao(() async => db);
  });

  tearDown(() async {
    await db.close();
  });

  group('CustomMediaDao', () {
    group('create', () {
      test('returns an autoincrement id, ignoring the one passed in', () async {
        final int id = await dao.create(_item(id: 999, title: 'First'));

        expect(id, 1);
        expect(await dao.getById(999), isNull);
        expect((await dao.getById(1))?.title, 'First');
      });

      test('keeps ids increasing across calls', () async {
        final int first = await dao.create(_item(title: 'A'));
        final int second = await dao.create(_item(title: 'B'));

        expect(second, greaterThan(first));
      });

      test('persists every column', () async {
        final int id = await dao.create(_item(
          title: 'Deep card',
          displayType: MediaType.manga,
          altTitle: 'Original',
          coverUrl: CustomMedia.localCoverMarker,
          year: 2011,
          genres: 'RPG, Action',
          platformId: 6,
          format: 'MANHWA',
          unitTotal: 120,
          unitGroupTotal: 8,
          cachedAt: 1700000000,
        ));

        final CustomMedia? stored = await dao.getById(id);
        expect(stored, isNotNull);
        expect(stored!.title, 'Deep card');
        expect(stored.displayType, MediaType.manga);
        expect(stored.altTitle, 'Original');
        expect(stored.coverUrl, CustomMedia.localCoverMarker);
        expect(stored.year, 2011);
        expect(stored.genres, 'RPG, Action');
        expect(stored.platformId, 6);
        expect(stored.format, 'MANHWA');
        expect(stored.unitTotal, 120);
        expect(stored.unitGroupTotal, 8);
        expect(stored.cachedAt, 1700000000);
      });

      test('stamps cached_at when the item carries none', () async {
        final int id = await dao.create(_item());

        expect((await dao.getById(id))?.cachedAt, isNotNull);
      });
    });

    group('createAll', () {
      test('returns an empty list without touching the DB', () async {
        expect(await dao.createAll(const <CustomMedia>[]), isEmpty);
      });

      test('returns the new ids in input order', () async {
        final List<int> ids = await dao.createAll(<CustomMedia>[
          _item(title: 'A'),
          _item(title: 'B'),
          _item(title: 'C'),
        ]);

        expect(ids, hasLength(3));
        final List<CustomMedia> stored = await dao.getByIds(ids);
        final Map<int, String> titleById = <int, String>{
          for (final CustomMedia m in stored) m.id: m.title,
        };
        expect(<String>[
          titleById[ids[0]]!,
          titleById[ids[1]]!,
          titleById[ids[2]]!,
        ], <String>['A', 'B', 'C']);
      });

      test('ignores the incoming ids and autoincrements', () async {
        final List<int> ids = await dao.createAll(<CustomMedia>[
          _item(id: 500, title: 'A'),
          _item(id: 501, title: 'B'),
        ]);

        expect(ids, isNot(contains(500)));
        expect(ids, isNot(contains(501)));
      });
    });

    group('update', () {
      test('overwrites the stored row', () async {
        final int id = await dao.create(_item(title: 'Before', year: 2000));

        await dao.update(_item(id: id, title: 'After', year: 2020));

        final CustomMedia? stored = await dao.getById(id);
        expect(stored?.title, 'After');
        expect(stored?.year, 2020);
      });

      test('clears a column set back to null', () async {
        final int id = await dao.create(_item(title: 'X', altTitle: 'Alt'));

        await dao.update(_item(id: id, title: 'X'));

        expect((await dao.getById(id))?.altTitle, isNull);
      });

      test('is a no-op for an unknown id', () async {
        final int id = await dao.create(_item(title: 'Keep'));

        await dao.update(_item(id: id + 1000, title: 'Ghost'));

        expect((await dao.getById(id))?.title, 'Keep');
      });
    });

    group('getById', () {
      test('returns null for an unknown id', () async {
        expect(await dao.getById(404), isNull);
      });
    });

    group('getByIds', () {
      test('returns empty for an empty id list', () async {
        expect(await dao.getByIds(const <int>[]), isEmpty);
      });

      test('skips ids with no row', () async {
        final int id = await dao.create(_item(title: 'Only'));

        final List<CustomMedia> found = await dao.getByIds(<int>[id, id + 99]);

        expect(found, hasLength(1));
        expect(found.single.title, 'Only');
      });

      test('spans more ids than one IN-clause chunk holds', () async {
        final List<int> ids = await dao.createAll(<CustomMedia>[
          for (int i = 0; i < 1200; i++) _item(title: 'card$i'),
        ]);

        final List<CustomMedia> found = await dao.getByIds(ids);

        expect(found, hasLength(1200));
      });
    });

    group('upsert', () {
      test('inserts keeping the caller-supplied id', () async {
        await dao.upsert(_item(id: 77, title: 'Imported'));

        expect((await dao.getById(77))?.title, 'Imported');
      });

      test('replaces an existing row with the same id', () async {
        await dao.upsert(_item(id: 77, title: 'First'));
        await dao.upsert(_item(id: 77, title: 'Second'));

        expect((await dao.getById(77))?.title, 'Second');
        expect(await dao.getByIds(<int>[77]), hasLength(1));
      });
    });

    group('upsertAll', () {
      test('is a no-op for an empty list', () async {
        await dao.upsertAll(const <CustomMedia>[]);

        expect(await dao.getByIds(<int>[1, 2, 3]), isEmpty);
      });

      test('keeps the caller-supplied ids', () async {
        await dao.upsertAll(<CustomMedia>[
          _item(id: 10, title: 'Ten'),
          _item(id: 20, title: 'Twenty'),
        ]);

        expect((await dao.getById(10))?.title, 'Ten');
        expect((await dao.getById(20))?.title, 'Twenty');
      });

      test('replaces rows that already exist', () async {
        await dao.upsert(_item(id: 10, title: 'Old'));

        await dao.upsertAll(<CustomMedia>[
          _item(id: 10, title: 'New'),
          _item(id: 11, title: 'Fresh'),
        ]);

        expect((await dao.getById(10))?.title, 'New');
        expect((await dao.getById(11))?.title, 'Fresh');
      });
    });

    group('delete', () {
      test('removes the row', () async {
        final int id = await dao.create(_item(title: 'Doomed'));

        await dao.delete(id);

        expect(await dao.getById(id), isNull);
      });

      test('leaves other rows alone', () async {
        final int keep = await dao.create(_item(title: 'Keep'));
        final int drop = await dao.create(_item(title: 'Drop'));

        await dao.delete(drop);

        expect((await dao.getById(keep))?.title, 'Keep');
      });

      test('is a no-op for an unknown id', () async {
        final int id = await dao.create(_item(title: 'Keep'));

        await dao.delete(id + 1000);

        expect(await dao.getById(id), isNotNull);
      });
    });
  });
}
