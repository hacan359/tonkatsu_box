import 'package:core/database/dao/tv_show_dao.dart';
import 'package:core/database/migrations/migration.dart';
import 'package:core/database/migrations/migration_registry.dart';
import 'package:core/models/data_source.dart';
import 'package:test/test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  final DatabaseFactory factory = databaseFactoryFfi;

  late Database db;
  late TvShowDao dao;

  const int collectionId = 1;
  const int otherCollectionId = 2;
  const int showId = 100;
  const int otherShowId = 200;

  setUp(() async {
    // Foreign keys stay OFF so watched rows can exist without seeding
    // collection_items.
    db = await factory.openDatabase(
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
    dao = TvShowDao(() async => db);
  });

  tearDown(() async => db.close());

  group('TvShowDao', () {
    group('unmarkShowWatched', () {
      test('removes every mark of the show in the collection, specials too',
          () async {
        await dao.markEpisodesWatchedAt(
          collectionId,
          DataSource.tmdb,
          showId,
          <(int, int, int?)>[(0, 1, 10), (1, 1, 20), (2, 3, null)],
        );

        await dao.unmarkShowWatched(collectionId, DataSource.tmdb, showId);

        expect(
          await dao.getWatchedEpisodes(collectionId, DataSource.tmdb, showId),
          isEmpty,
        );
      });

      test('leaves other collections, shows and sources alone', () async {
        await dao.markEpisodeWatched(
            collectionId, DataSource.tmdb, showId, 1, 1);
        await dao.markEpisodeWatched(
            otherCollectionId, DataSource.tmdb, showId, 1, 1);
        await dao.markEpisodeWatched(
            collectionId, DataSource.tmdb, otherShowId, 1, 1);
        await dao.markEpisodeWatched(
            collectionId, DataSource.tvmaze, showId, 1, 1);

        await dao.unmarkShowWatched(collectionId, DataSource.tmdb, showId);

        expect(
          await dao.getWatchedEpisodes(
              otherCollectionId, DataSource.tmdb, showId),
          hasLength(1),
        );
        expect(
          await dao.getWatchedEpisodes(
              collectionId, DataSource.tmdb, otherShowId),
          hasLength(1),
        );
        expect(
          await dao.getWatchedEpisodes(
              collectionId, DataSource.tvmaze, showId),
          hasLength(1),
        );
      });

      test('is a no-op when nothing is marked', () async {
        await dao.unmarkShowWatched(collectionId, DataSource.tmdb, showId);
        expect(
          await dao.getWatchedEpisodes(collectionId, DataSource.tmdb, showId),
          isEmpty,
        );
      });
    });

    group('updateEpisodeWatchedAt', () {
      test('rewrites the date of an existing mark without a second row',
          () async {
        await dao.markEpisodesWatchedAt(collectionId, DataSource.tmdb, showId,
            <(int, int, int?)>[(1, 1, 10)]);

        final bool existed = await dao.updateEpisodeWatchedAt(
            collectionId, DataSource.tmdb, showId, 1, 1, 5000);

        expect(existed, isTrue);
        expect(
          await dao.getWatchedEpisodes(collectionId, DataSource.tmdb, showId),
          <(int, int), DateTime?>{
            (1, 1): DateTime.fromMillisecondsSinceEpoch(5000),
          },
        );
      });

      test('accepts null for an unknown date', () async {
        await dao.markEpisodesWatchedAt(collectionId, DataSource.tmdb, showId,
            <(int, int, int?)>[(1, 1, 10)]);

        await dao.updateEpisodeWatchedAt(
            collectionId, DataSource.tmdb, showId, 1, 1, null);

        expect(
          await dao.getWatchedEpisodes(collectionId, DataSource.tmdb, showId),
          <(int, int), DateTime?>{(1, 1): null},
        );
      });

      test('never marks an unwatched episode', () async {
        final bool existed = await dao.updateEpisodeWatchedAt(
            collectionId, DataSource.tmdb, showId, 1, 1, 5000);

        expect(existed, isFalse);
        expect(
          await dao.getWatchedEpisodes(collectionId, DataSource.tmdb, showId),
          isEmpty,
        );
      });

      test('touches only the addressed collection and episode', () async {
        await dao.markEpisodesWatchedAt(collectionId, DataSource.tmdb, showId,
            <(int, int, int?)>[(1, 1, 10), (1, 2, 10)]);
        await dao.markEpisodesWatchedAt(otherCollectionId, DataSource.tmdb,
            showId, <(int, int, int?)>[(1, 1, 10)]);

        await dao.updateEpisodeWatchedAt(
            collectionId, DataSource.tmdb, showId, 1, 1, 5000);

        final DateTime untouched = DateTime.fromMillisecondsSinceEpoch(10);
        expect(
          (await dao.getWatchedEpisodes(
              collectionId, DataSource.tmdb, showId))[(1, 2)],
          untouched,
        );
        expect(
          (await dao.getWatchedEpisodes(
              otherCollectionId, DataSource.tmdb, showId))[(1, 1)],
          untouched,
        );
      });
    });
  });
}
