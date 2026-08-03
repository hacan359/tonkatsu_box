import 'package:core/database/dao/anime_dao.dart';
import 'package:core/database/dao/book_dao.dart';
import 'package:core/database/dao/collection_dao.dart';
import 'package:core/database/dao/custom_media_dao.dart';
import 'package:core/database/dao/game_dao.dart';
import 'package:core/database/dao/manga_dao.dart';
import 'package:core/database/dao/movie_dao.dart';
import 'package:core/database/dao/tv_show_dao.dart';
import 'package:core/database/dao/visual_novel_dao.dart';
import 'package:core/database/migrations/migration.dart';
import 'package:core/database/migrations/migration_registry.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/media_type.dart';
import 'package:test/test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late CollectionDao dao;

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
    Future<Database> getDb() async => db;
    dao = CollectionDao(
      getDb,
      gameDao: GameDao(getDb),
      movieDao: MovieDao(getDb),
      tvShowDao: TvShowDao(getDb),
      visualNovelDao: VisualNovelDao(getDb),
      animeDao: AnimeDao(getDb),
      mangaDao: MangaDao(getDb),
      bookDao: BookDao(getDb),
      customMediaDao: CustomMediaDao(getDb),
    );

    for (final int id in <int>[1, 2]) {
      await db.insert('collections', <String, Object?>{
        'id': id,
        'name': 'C$id',
        'author': 'tester',
        'created_at': 1700000000,
      });
    }
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> insertItem({
    required int id,
    required int collectionId,
    required String mediaType,
    required int externalId,
    String? source,
    int? platformId,
  }) async {
    return db.insert('collection_items', <String, Object?>{
      'id': id,
      'collection_id': collectionId,
      'media_type': mediaType,
      'external_id': externalId,
      'source': source,
      'platform_id': platformId,
      'status': 'not_started',
      'sort_order': id,
      'added_at': 1700000000,
    });
  }

  Future<void> insertWatched({
    required int collectionId,
    required int showId,
    String source = 'tmdb',
    int season = 1,
    int episode = 1,
  }) async {
    await db.insert('watched_episodes', <String, Object?>{
      'collection_id': collectionId,
      'source': source,
      'show_id': showId,
      'season_number': season,
      'episode_number': episode,
      'watched_at': 1700000000,
    });
  }

  Future<int> watchedCount(int collectionId, int showId) async {
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT COUNT(*) AS cnt FROM watched_episodes '
      'WHERE collection_id = ? AND show_id = ?',
      <Object?>[collectionId, showId],
    );
    return rows.single['cnt']! as int;
  }

  group('CollectionDao.removeItemFromCollection — watched marks', () {
    test('keeps watch marks so re-adding the show restores progress',
        () async {
      await insertItem(
          id: 10, collectionId: 1, mediaType: 'tv_show', externalId: 500);
      await insertWatched(collectionId: 1, showId: 500, episode: 1);
      await insertWatched(collectionId: 1, showId: 500, episode: 2);

      await dao.removeItemFromCollection(10);

      expect(await watchedCount(1, 500), 2);

      await insertItem(
          id: 12, collectionId: 1, mediaType: 'tv_show', externalId: 500);

      final TvShowDao tvDao = TvShowDao(() async => db);
      final Map<(int, int), DateTime?> watched =
          await tvDao.getWatchedEpisodes(1, DataSource.tmdb, 500);
      expect(watched.keys, <(int, int)>{(1, 1), (1, 2)});
    });
  });

  group('CollectionDao.updateItemCollectionId — watched transfer', () {
    test('should move watch marks to the target collection', () async {
      await insertItem(
          id: 10, collectionId: 1, mediaType: 'tv_show', externalId: 500);
      await insertWatched(collectionId: 1, showId: 500, episode: 1);
      await insertWatched(collectionId: 1, showId: 500, episode: 2);

      final bool ok = await dao.updateItemCollectionId(10, 2);

      expect(ok, isTrue);
      expect(await watchedCount(1, 500), 0);
      expect(await watchedCount(2, 500), 2);
    });

    test('should preserve watched_at on transfer', () async {
      await insertItem(
          id: 10, collectionId: 1, mediaType: 'tv_show', externalId: 500);
      await insertWatched(collectionId: 1, showId: 500);

      await dao.updateItemCollectionId(10, 2);

      final List<Map<String, Object?>> rows = await db.query(
        'watched_episodes',
        where: 'collection_id = 2',
      );
      expect(rows.single['watched_at'], 1700000000);
    });

    test(
        'moving to uncategorized leaves marks in the source and restores '
        'them on return', () async {
      await insertItem(
          id: 10, collectionId: 1, mediaType: 'tv_show', externalId: 500);
      await insertWatched(collectionId: 1, showId: 500, episode: 1);
      await insertWatched(collectionId: 1, showId: 500, episode: 2);

      await dao.updateItemCollectionId(10, null);

      expect(await watchedCount(1, 500), 2);

      await dao.updateItemCollectionId(10, 1);

      final TvShowDao tvDao = TvShowDao(() async => db);
      final Map<(int, int), DateTime?> watched =
          await tvDao.getWatchedEpisodes(1, DataSource.tmdb, 500);
      expect(watched.keys, <(int, int)>{(1, 1), (1, 2)});
    });

    test('should copy marks but keep the source rows while a sibling remains',
        () async {
      await insertItem(
          id: 10, collectionId: 1, mediaType: 'tv_show', externalId: 500);
      await insertItem(
        id: 11,
        collectionId: 1,
        mediaType: 'animation',
        externalId: 500,
        platformId: 1,
      );
      await insertWatched(collectionId: 1, showId: 500);

      await dao.updateItemCollectionId(10, 2);

      expect(await watchedCount(1, 500), 1);
      expect(await watchedCount(2, 500), 1);
    });

    test('should overwrite stale orphan marks in the target', () async {
      await insertItem(
          id: 10, collectionId: 1, mediaType: 'tv_show', externalId: 500);
      await insertWatched(collectionId: 1, showId: 500, episode: 1);
      // An orphan of an earlier removal left in the target for the same
      // episode.
      await insertWatched(collectionId: 2, showId: 500, episode: 1);

      final bool ok = await dao.updateItemCollectionId(10, 2);

      expect(ok, isTrue);
      expect(await watchedCount(2, 500), 1);
    });

    test('should move marks for a kitsu anime', () async {
      await insertItem(
        id: 10,
        collectionId: 1,
        mediaType: 'anime',
        externalId: 244,
        source: 'kitsu',
      );
      await insertWatched(collectionId: 1, showId: 244, source: 'kitsu');

      await dao.updateItemCollectionId(10, 2);

      expect(await watchedCount(1, 244), 0);
      expect(await watchedCount(2, 244), 1);
    });

    test('should not touch marks for an anilist anime', () async {
      await insertItem(
        id: 10,
        collectionId: 1,
        mediaType: 'anime',
        externalId: 600,
        source: 'anilist',
      );
      await insertWatched(collectionId: 1, showId: 600, source: 'anilist');

      await dao.updateItemCollectionId(10, 2);

      expect(await watchedCount(1, 600), 1);
      expect(await watchedCount(2, 600), 0);
    });

    test('should move marks for an animated series but not an animated movie',
        () async {
      await insertItem(
        id: 10,
        collectionId: 1,
        mediaType: 'animation',
        externalId: 700,
        platformId: AnimationSource.tvShow,
      );
      await insertItem(
        id: 11,
        collectionId: 1,
        mediaType: 'animation',
        externalId: 800,
        platformId: AnimationSource.movie,
      );
      await insertWatched(collectionId: 1, showId: 700);
      await insertWatched(collectionId: 1, showId: 800);

      await dao.updateItemCollectionId(10, 2);
      await dao.updateItemCollectionId(11, 3);

      expect(await watchedCount(2, 700), 1);
      expect(await watchedCount(1, 800), 1);
      expect(await watchedCount(3, 800), 0);
    });

    test('should not touch marks when moving a non-tv item', () async {
      await insertItem(
          id: 10, collectionId: 1, mediaType: 'tv_show', externalId: 500);
      await insertItem(
          id: 11, collectionId: 1, mediaType: 'movie', externalId: 500);
      await insertWatched(collectionId: 1, showId: 500);

      await dao.updateItemCollectionId(11, 2);

      expect(await watchedCount(1, 500), 1);
      expect(await watchedCount(2, 500), 0);
    });

    test('should keep marks in place when the move hits a UNIQUE conflict',
        () async {
      await insertItem(
          id: 10, collectionId: 1, mediaType: 'tv_show', externalId: 500);
      await insertItem(
          id: 11, collectionId: 2, mediaType: 'tv_show', externalId: 500);
      await insertWatched(collectionId: 1, showId: 500);

      final bool ok = await dao.updateItemCollectionId(10, 2);

      expect(ok, isFalse);
      expect(await watchedCount(1, 500), 1);
      expect(await watchedCount(2, 500), 0);
    });
  });
}
