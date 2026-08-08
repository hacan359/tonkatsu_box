import 'package:core/database/dao/movie_dao.dart';
import 'package:core/database/migrations/migration.dart';
import 'package:core/database/migrations/migration_registry.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/movie.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late MovieDao dao;

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
        onConfigure: (Database d) => d.execute('PRAGMA foreign_keys = ON'),
      ),
    );
    dao = MovieDao(() async => db);
  });

  tearDown(() async {
    await db.close();
  });

  group('MovieDao source', () {
    test('keeps two providers apart under the same numeric id', () async {
      const Movie tmdb = Movie(tmdbId: 113, title: 'From TMDB');
      const Movie tvdb =
          Movie(tmdbId: 113, title: 'Inception', source: DataSource.tvdb);

      await dao.upsertMovie(tmdb);
      await dao.upsertMovie(tvdb);

      expect((await dao.getMovieByTmdbId(113))?.title, 'From TMDB');
      expect(
        (await dao.getMovieByTmdbId(113, source: DataSource.tvdb))?.title,
        'Inception',
      );
    });

    test('defaults a lookup to TMDB', () async {
      const Movie tvdb =
          Movie(tmdbId: 500, title: 'Only on TheTVDB', source: DataSource.tvdb);

      await dao.upsertMovie(tvdb);

      expect(await dao.getMovieByTmdbId(500), isNull);
    });

    test('overwrites within one source instead of duplicating', () async {
      await dao.upsertMovie(const Movie(tmdbId: 7, title: 'Old'));
      await dao.upsertMovie(const Movie(tmdbId: 7, title: 'New'));

      final List<Movie> all = await dao.getMoviesByTmdbIds(<int>[7]);

      expect(all, hasLength(1));
      expect(all.single.title, 'New');
    });

    test('getMoviesByTmdbIds returns every source for an id', () async {
      await dao.upsertMovie(const Movie(tmdbId: 9, title: 'A'));
      await dao.upsertMovie(
        const Movie(tmdbId: 9, title: 'B', source: DataSource.tvdb),
      );

      final List<Movie> all = await dao.getMoviesByTmdbIds(<int>[9]);

      expect(
        all.map((Movie m) => m.source).toSet(),
        <DataSource>{DataSource.tmdb, DataSource.tvdb},
      );
    });

    test('a search-shaped upsert does not blank a cached runtime', () async {
      await dao.upsertMovie(
        const Movie(tmdbId: 42, title: 'Full', runtime: 148, overview: 'Long'),
      );

      await dao.upsertMovie(const Movie(tmdbId: 42, title: 'Full'));

      final Movie? stored = await dao.getMovieByTmdbId(42);
      expect(stored?.runtime, 148);
      expect(stored?.overview, 'Long');
    });

    test('batch upsert writes each source row', () async {
      await dao.upsertMovies(const <Movie>[
        Movie(tmdbId: 1, title: 'T'),
        Movie(tmdbId: 1, title: 'V', source: DataSource.tvdb),
      ]);

      expect(await dao.getMoviesByTmdbIds(<int>[1]), hasLength(2));
    });
  });
}
