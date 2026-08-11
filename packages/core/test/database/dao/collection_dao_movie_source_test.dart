import 'package:core/database/dao/anime_dao.dart';
import 'package:core/database/dao/book_dao.dart';
import 'package:core/database/dao/collection_dao.dart';
import 'package:core/database/dao/custom_media_dao.dart';
import 'package:core/database/dao/game_dao.dart';
import 'package:core/database/dao/manga_dao.dart';
import 'package:core/database/dao/movie_dao.dart';
import 'package:core/database/dao/stats_dao.dart';
import 'package:core/database/dao/tv_show_dao.dart';
import 'package:core/database/dao/visual_novel_dao.dart';
import 'package:core/database/migrations/migration.dart';
import 'package:core/database/migrations/migration_registry.dart';
import 'package:core/models/collection_item.dart';
import 'package:core/models/cover_info.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/movie.dart';
import 'package:test/test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// TMDB and TheTVDB hand out overlapping numeric movie ids, so every read path
/// that joins `movies_cache` has to carry the source too.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late CollectionDao dao;
  late MovieDao movieDao;
  late StatsDao statsDao;

  const int sharedId = 113;

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
    Future<Database> getDb() async => db;
    movieDao = MovieDao(getDb);
    statsDao = StatsDao(getDb);
    dao = CollectionDao(
      getDb,
      gameDao: GameDao(getDb),
      movieDao: movieDao,
      tvShowDao: TvShowDao(getDb),
      visualNovelDao: VisualNovelDao(getDb),
      animeDao: AnimeDao(getDb),
      mangaDao: MangaDao(getDb),
      bookDao: BookDao(getDb),
      customMediaDao: CustomMediaDao(getDb),
    );

    await db.insert('collections', <String, Object?>{
      'id': 1,
      'name': 'Films',
      'author': 'tester',
      'created_at': 1700000000,
    });

    await movieDao.upsertMovies(const <Movie>[
      Movie(
        tmdbId: sharedId,
        title: 'TMDB film',
        posterUrl: 'https://image.tmdb.org/t/p/w500/tmdb.jpg',
        runtime: 100,
      ),
      Movie(
        tmdbId: sharedId,
        title: 'TheTVDB film',
        posterUrl: 'https://artworks.thetvdb.com/banners/tvdb.jpg',
        runtime: 70,
        source: DataSource.tvdb,
      ),
    ]);
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> addMovieItem(DataSource? source, {String status = 'completed'}) async {
    final int? id = await dao.addItemToCollection(
      collectionId: 1,
      mediaType: MediaType.movie,
      externalId: sharedId,
      source: source,
    );
    await db.update(
      'collection_items',
      <String, Object?>{'status': status},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
    return id!;
  }

  group('CollectionDao movie source', () {
    test('hydrates each item with the movie from its own provider', () async {
      await addMovieItem(DataSource.tmdb);
      await addMovieItem(DataSource.tvdb);

      final List<CollectionItem> items =
          await dao.getAllCollectionItemsWithData();

      expect(items, hasLength(2));
      final Map<DataSource, String?> titles = <DataSource, String?>{
        for (final CollectionItem i in items)
          i.source ?? DataSource.tmdb: i.movie?.title,
      };
      expect(titles[DataSource.tmdb], 'TMDB film');
      expect(titles[DataSource.tvdb], 'TheTVDB film');
    });

    test('reads a legacy null-source row as TMDB', () async {
      await addMovieItem(null);

      final List<CollectionItem> items =
          await dao.getAllCollectionItemsWithData();

      expect(items.single.movie?.title, 'TMDB film');
    });

    test('covers stay one per item when both providers cache the id', () async {
      await addMovieItem(DataSource.tmdb);

      final List<CoverInfo> covers = await dao.getCollectionCovers(1);

      expect(covers, hasLength(1));
      expect(covers.single.thumbnailUrl, contains('tmdb'));
    });
  });

  group('StatsDao movie runtime', () {
    test('counts a film once when two providers cache the id', () async {
      await addMovieItem(DataSource.tmdb);

      expect(await statsDao.getEstimatedMinutes(), 100);
    });

    test('uses the runtime of the item\'s own provider', () async {
      await addMovieItem(DataSource.tvdb);

      expect(await statsDao.getEstimatedMinutes(), 70);
    });
  });
}
