import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tonkatsu_box/core/database/dao/anilist_tag_dao.dart';
import 'package:tonkatsu_box/core/database/schema.dart';
import 'package:tonkatsu_box/shared/models/anilist_tag.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late AniListTagDao dao;

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (Database d, int _) => DatabaseSchema.createAniListTagsTable(d),
      ),
    );
    dao = AniListTagDao(() async => db);
  });

  tearDown(() async {
    await db.close();
  });

  group('AniListTagDao', () {
    test('getAll returns empty on fresh table', () async {
      expect(await dao.getAll(), isEmpty);
    });

    test('replaceAll inserts rows and getAll returns them sorted', () async {
      await dao.replaceAll(<AniListTag>[
        const AniListTag(
            id: 2, name: 'Magic', category: 'Theme-Other', updatedAt: 100),
        const AniListTag(
            id: 1, name: 'School', category: 'Setting', updatedAt: 200),
      ]);

      final List<AniListTag> all = await dao.getAll();
      expect(all, hasLength(2));
      expect(all.first.name, 'School');
      expect(all.last.name, 'Magic');
    });

    test('replaceAll wipes previous rows transactionally', () async {
      await dao.replaceAll(<AniListTag>[
        const AniListTag(id: 1, name: 'Old', updatedAt: 1),
      ]);
      await dao.replaceAll(<AniListTag>[
        const AniListTag(id: 2, name: 'New', updatedAt: 2),
      ]);
      final List<AniListTag> all = await dao.getAll();
      expect(all, hasLength(1));
      expect(all.single.name, 'New');
    });

  });
}
