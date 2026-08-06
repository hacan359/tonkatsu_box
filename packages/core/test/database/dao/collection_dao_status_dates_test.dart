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
import 'package:core/models/item_status.dart';
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
        // Mirrors openAppDatabase — without it FK cascades silently no-op.
        onConfigure: (Database d) => d.execute('PRAGMA foreign_keys = ON'),
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
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> newItem({ItemStatus status = ItemStatus.notStarted}) async {
    final int collectionId =
        (await dao.createCollection(name: 'Films', author: 'me')).id;
    final int? id = await dao.addItemToCollection(
      collectionId: collectionId,
      mediaType: MediaType.movie,
      externalId: 100,
      status: status,
    );
    return id!;
  }

  Future<Map<String, dynamic>> readItem(int id) async {
    final List<Map<String, dynamic>> rows = await db.query(
      'collection_items',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    return rows.first;
  }

  int toDbSeconds(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;

  group('CollectionDao status/date writes', () {
    group('updateItemStatus', () {
      test('should stamp completed_at with now on the completed transition',
          () async {
        final int id = await newItem();
        final int before = toDbSeconds(DateTime.now());

        await dao.updateItemStatus(id, ItemStatus.completed,
            mediaType: MediaType.movie);

        final Map<String, dynamic> row = await readItem(id);
        expect(row['completed_at'] as int, greaterThanOrEqualTo(before));
        expect(row['started_at'], isNotNull);
      });

      test('should overwrite an existing completed_at with now', () async {
        // The provider must therefore write explicit dates strictly after
        // this call — the ordering the watched-date regression was about.
        final int id = await newItem();
        final DateTime past = DateTime(2023, 2, 14);
        await dao.updateItemActivityDates(id, completedAt: past);

        await dao.updateItemStatus(id, ItemStatus.completed,
            mediaType: MediaType.movie);

        final Map<String, dynamic> row = await readItem(id);
        expect(row['completed_at'] as int, isNot(toDbSeconds(past)));
      });
    });

    group('updateItemActivityDates after updateItemStatus', () {
      test('should keep the explicit past watched date', () async {
        final int id = await newItem();
        final DateTime past = DateTime(2023, 2, 14);

        await dao.updateItemStatus(id, ItemStatus.completed,
            mediaType: MediaType.movie);
        await dao.updateItemActivityDates(id, completedAt: past);

        final Map<String, dynamic> row = await readItem(id);
        expect(row['completed_at'] as int, toDbSeconds(past));
        expect(ItemStatus.fromString(row['status'] as String),
            ItemStatus.completed);
      });
    });

    group('updateItemActivityDates clear flags', () {
      test('should erase the date and leave the status untouched', () async {
        final int id = await newItem();
        await dao.updateItemStatus(id, ItemStatus.completed,
            mediaType: MediaType.movie);

        await dao.updateItemActivityDates(
          id,
          clearStartedAt: true,
          clearCompletedAt: true,
        );

        final Map<String, dynamic> row = await readItem(id);
        expect(row['started_at'], isNull);
        expect(row['completed_at'], isNull);
        expect(ItemStatus.fromString(row['status'] as String),
            ItemStatus.completed);
      });

      test('should clear one date while updating the other', () async {
        final int id = await newItem();
        final DateTime past = DateTime(2023, 2, 14);
        await dao.updateItemStatus(id, ItemStatus.completed,
            mediaType: MediaType.movie);

        await dao.updateItemActivityDates(
          id,
          completedAt: past,
          clearStartedAt: true,
        );

        final Map<String, dynamic> row = await readItem(id);
        expect(row['started_at'], isNull);
        expect(row['completed_at'] as int, toDbSeconds(past));
      });
    });
  });
}
