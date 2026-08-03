import 'package:core/database/dao/anime_dao.dart';
import 'package:core/database/migrations/migration.dart';
import 'package:core/database/migrations/migration_registry.dart';
import 'package:core/models/anime.dart';
import 'package:core/models/data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Anime _anime({
  int id = 1,
  String title = 'Cowboy Bebop',
  DataSource source = DataSource.anilist,
  String? titleEnglish,
  int? episodes,
  List<String>? genres,
  int? updatedAt,
}) =>
    Anime(
      id: id,
      title: title,
      source: source,
      titleEnglish: titleEnglish,
      episodes: episodes,
      genres: genres,
      updatedAt: updatedAt,
    );

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late AnimeDao dao;

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
    dao = AnimeDao(() async => db);
  });

  tearDown(() async {
    await db.close();
  });

  group('AnimeDao', () {
    group('upsertAnime', () {
      test('inserts a row readable by getAnime', () async {
        await dao.upsertAnime(_anime(titleEnglish: 'Cowboy Bebop'));

        final Anime? stored = await dao.getAnime(1);
        expect(stored?.title, 'Cowboy Bebop');
        expect(stored?.titleEnglish, 'Cowboy Bebop');
        expect(stored?.source, DataSource.anilist);
      });

      test('replaces a row with the same (id, source)', () async {
        await dao.upsertAnime(_anime(title: 'Old', episodes: 10));
        await dao.upsertAnime(_anime(title: 'New', episodes: 26));

        expect((await dao.getAnime(1))?.title, 'New');
        expect((await dao.getAnime(1))?.episodes, 26);
        expect(await dao.getAnimeByIds(<int>[1]), hasLength(1));
      });

      test('keeps same-id rows from different sources side by side', () async {
        await dao.upsertAnime(_anime(title: 'From AniList'));
        await dao.upsertAnime(
          _anime(title: 'From Kitsu', source: DataSource.kitsu),
        );

        expect((await dao.getAnime(1))?.title, 'From AniList');
        expect(
          (await dao.getAnime(1, source: DataSource.kitsu))?.title,
          'From Kitsu',
        );
        expect(await dao.getAnimeByIds(<int>[1]), hasLength(2));
      });

      test('round-trips a list column', () async {
        await dao.upsertAnime(
          _anime(genres: const <String>['Action', 'Sci-Fi']),
        );

        expect((await dao.getAnime(1))?.genres, <String>['Action', 'Sci-Fi']);
      });
    });

    group('upsertAnimes', () {
      test('is a no-op for an empty list', () async {
        await dao.upsertAnimes(const <Anime>[]);

        expect(await dao.getAnimeByIds(<int>[1, 2]), isEmpty);
      });

      test('inserts every item', () async {
        await dao.upsertAnimes(<Anime>[
          _anime(id: 1, title: 'A'),
          _anime(id: 2, title: 'B'),
          _anime(id: 3, title: 'C'),
        ]);

        expect(await dao.getAnimeByIds(<int>[1, 2, 3]), hasLength(3));
      });

      test('replaces rows that already exist', () async {
        await dao.upsertAnime(_anime(id: 1, title: 'Old'));

        await dao.upsertAnimes(<Anime>[
          _anime(id: 1, title: 'New'),
          _anime(id: 2, title: 'Fresh'),
        ]);

        expect((await dao.getAnime(1))?.title, 'New');
        expect((await dao.getAnime(2))?.title, 'Fresh');
      });
    });

    group('getAnime', () {
      test('returns null for an unknown id', () async {
        expect(await dao.getAnime(404), isNull);
      });

      test('returns null when the id exists under another source', () async {
        await dao.upsertAnime(_anime(source: DataSource.kitsu));

        expect(await dao.getAnime(1), isNull);
      });
    });

    group('getAnimeByIds', () {
      test('returns empty for an empty id list', () async {
        expect(await dao.getAnimeByIds(const <int>[]), isEmpty);
      });

      test('skips ids with no row', () async {
        await dao.upsertAnime(_anime(id: 1));

        final List<Anime> found = await dao.getAnimeByIds(<int>[1, 999]);

        expect(found, hasLength(1));
        expect(found.single.id, 1);
      });

      test('matches across sources for the same id', () async {
        await dao.upsertAnime(_anime(id: 1, source: DataSource.anilist));
        await dao.upsertAnime(_anime(id: 1, source: DataSource.kitsu));

        final List<Anime> found = await dao.getAnimeByIds(<int>[1]);

        expect(
          found.map((Anime a) => a.source).toSet(),
          <DataSource>{DataSource.anilist, DataSource.kitsu},
        );
      });

      test('spans more ids than one IN-clause chunk holds', () async {
        await dao.upsertAnimes(<Anime>[
          for (int i = 1; i <= 1200; i++) _anime(id: i, title: 'anime$i'),
        ]);

        final List<Anime> found = await dao.getAnimeByIds(
          <int>[for (int i = 1; i <= 1200; i++) i],
        );

        expect(found, hasLength(1200));
      });
    });
  });
}
