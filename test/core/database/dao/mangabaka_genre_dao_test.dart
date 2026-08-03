import 'package:core/database/dao/mangabaka_genre_dao.dart';
import 'package:core/database/schema.dart';
import 'package:core/models/mangabaka_genre.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late MangaBakaGenreDao dao;

  Future<void> seed(String key, String name, int sortOrder, {int isAdult = 0}) {
    return db.insert('mangabaka_genres', <String, Object?>{
      'key': key,
      'name': name,
      'is_adult': isAdult,
      'sort_order': sortOrder,
    });
  }

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (Database d, int _) =>
            DatabaseSchema.createMangaBakaGenresTable(d),
      ),
    );
    dao = MangaBakaGenreDao(() async => db);
  });

  tearDown(() async {
    await db.close();
  });

  group('MangaBakaGenreDao', () {
    test('getAll returns empty on a fresh table', () async {
      expect(await dao.getAll(), isEmpty);
    });

    test('getAll sorts by sort_order, not by key or name', () async {
      await seed('romance', 'Romance', 1);
      await seed('action', 'Action', 3);
      await seed('fantasy', 'Fantasy', 2);

      final List<MangaBakaGenre> all = await dao.getAll();
      expect(
        all.map((MangaBakaGenre g) => g.key),
        <String>['romance', 'fantasy', 'action'],
      );
    });

    test('getAll maps key, name and the adult flag', () async {
      await seed('hentai', 'Hentai', 1, isAdult: 1);
      await seed('action', 'Action', 2);

      final List<MangaBakaGenre> all = await dao.getAll();
      expect(all.first.key, 'hentai');
      expect(all.first.name, 'Hentai');
      expect(all.first.isAdult, isTrue);
      expect(all.last.isAdult, isFalse);
    });
  });
}
