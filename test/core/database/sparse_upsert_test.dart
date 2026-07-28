import 'package:core/database/migrations/migration.dart';
import 'package:core/database/migrations/migration_registry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tonkatsu_box/core/database/dao/manga_dao.dart';
import 'package:tonkatsu_box/core/database/dao/tv_show_dao.dart';
import 'package:core/database/sparse_upsert.dart';
import 'package:tonkatsu_box/shared/models/data_source.dart';
import 'package:tonkatsu_box/shared/models/manga.dart';
import 'package:tonkatsu_box/shared/models/tv_show.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('buildPreservingUpsert', () {
    test('coalesces only the preserved columns', () {
      final ({String sql, List<Object?> args}) upsert = buildPreservingUpsert(
        table: 't',
        row: <String, Object?>{'id': 1, 'src': 's', 'a': 'x', 'b': null},
        conflictKey: <String>['id', 'src'],
        preserveWhenNull: <String>{'b'},
      );

      expect(
        upsert.sql,
        'INSERT OR REPLACE INTO t (id, src, a, b) VALUES (?, ?, ?, '
        'COALESCE(?, (SELECT b FROM t WHERE id = ? AND src = ?)))',
      );
      // Preserved column appends the conflict-key values for its subquery.
      expect(upsert.args, <Object?>[1, 's', 'x', null, 1, 's']);
    });
  });

  group('sparse upserts against a real schema', () {
    late Database db;

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
    });

    tearDown(() async {
      await db.close();
    });

    group('TvShowDao', () {
      late TvShowDao dao;

      setUp(() {
        dao = TvShowDao(() async => db);
      });

      const TvShow fullShow = TvShow(
        tmdbId: 45016,
        title: 'The Bridge',
        totalSeasons: 4,
        totalEpisodes: 38,
        status: 'Ended',
        rating: 8.3,
      );

      // A row parsed from a list endpoint: no totals, no status.
      const TvShow sparseShow = TvShow(
        tmdbId: 45016,
        title: 'The Bridge (updated)',
        rating: 8.5,
      );

      test('sparse row keeps cached totals and status', () async {
        await dao.upsertTvShow(fullShow);
        await dao.upsertTvShow(sparseShow);

        final TvShow? loaded = await dao.getTvShowByTmdbId(45016);
        expect(loaded!.totalSeasons, 4);
        expect(loaded.totalEpisodes, 38);
        expect(loaded.status, 'Ended');
        // Non-preserved fields still take the incoming values.
        expect(loaded.title, 'The Bridge (updated)');
        expect(loaded.rating, 8.5);
      });

      test('full row fills totals over a sparse one', () async {
        await dao.upsertTvShow(sparseShow);
        await dao.upsertTvShow(fullShow);

        final TvShow? loaded = await dao.getTvShowByTmdbId(45016);
        expect(loaded!.totalEpisodes, 38);
        expect(loaded.title, 'The Bridge');
      });

      test('full row updates stale totals', () async {
        await dao.upsertTvShow(fullShow);
        await dao.upsertTvShow(
          fullShow.copyWith(totalSeasons: 5, totalEpisodes: 46),
        );

        final TvShow? loaded = await dao.getTvShowByTmdbId(45016);
        expect(loaded!.totalSeasons, 5);
        expect(loaded.totalEpisodes, 46);
      });

      test('fresh sparse insert stays sparse', () async {
        await dao.upsertTvShow(sparseShow);

        final TvShow? loaded = await dao.getTvShowByTmdbId(45016);
        expect(loaded!.totalEpisodes, isNull);
      });

      test('batch upsert preserves totals too', () async {
        await dao.upsertTvShow(fullShow);
        await dao.upsertTvShows(const <TvShow>[sparseShow]);

        final TvShow? loaded = await dao.getTvShowByTmdbId(45016);
        expect(loaded!.totalEpisodes, 38);
      });
    });

    group('MangaDao', () {
      late MangaDao dao;

      setUp(() {
        dao = MangaDao(() async => db);
      });

      test('sparse row keeps cached chapters and volumes', () async {
        await dao.upsertManga(const Manga(
          id: 7,
          title: 'Berserk',
          chapters: 380,
          volumes: 42,
        ));
        await dao.upsertManga(const Manga(id: 7, title: 'Berserk (list)'));

        final Manga? loaded = await dao.getManga(7);
        expect(loaded!.chapters, 380);
        expect(loaded.volumes, 42);
        expect(loaded.title, 'Berserk (list)');
      });

      test('full row updates chapters over a sparse one', () async {
        await dao.upsertManga(const Manga(id: 7, title: 'Berserk'));
        await dao.upsertManga(const Manga(
          id: 7,
          title: 'Berserk',
          chapters: 380,
          volumes: 42,
        ));

        final Manga? loaded = await dao.getManga(7);
        expect(loaded!.chapters, 380);
        expect(loaded.volumes, 42);
      });

      test('rows from different sources stay independent', () async {
        await dao.upsertManga(const Manga(
          id: 7,
          title: 'AniList row',
          chapters: 380,
        ));
        await dao.upsertManga(const Manga(
          id: 7,
          source: DataSource.mangabaka,
          title: 'MangaBaka row',
        ));

        final Manga? anilist = await dao.getManga(7);
        final Manga? mangabaka =
            await dao.getManga(7, source: DataSource.mangabaka);
        expect(anilist!.chapters, 380);
        expect(mangabaka!.chapters, isNull);
      });
    });
  });
}
