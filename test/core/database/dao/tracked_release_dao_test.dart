import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tonkatsu_box/core/database/dao/tracked_release_dao.dart';
import 'package:tonkatsu_box/core/database/schema.dart';
import 'package:tonkatsu_box/shared/models/data_source.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';
import 'package:tonkatsu_box/shared/models/tracked_release.dart';

void main() {
  sqfliteFfiInit();
  final DatabaseFactory factory = databaseFactoryFfi;

  late Database db;
  late TrackedReleaseDao dao;

  setUp(() async {
    db = await factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (Database db, int _) async {
          await DatabaseSchema.createTrackedReleasesTable(db);
          await DatabaseSchema.createCollectionItemsTable(db);
        },
      ),
    );
    dao = TrackedReleaseDao(() async => db);
  });

  tearDown(() async => db.close());

  group('TrackedReleaseDao', () {
    test('should report tracked after subscribe', () async {
      await dao.subscribe(100, DataSource.tmdb, MediaType.tvShow);

      expect(
        await dao.isTracked(100, DataSource.tmdb, MediaType.tvShow),
        isTrue,
      );
    });

    test('should not collide across providers sharing an id', () async {
      await dao.subscribe(100, DataSource.anilist, MediaType.manga);

      expect(
        await dao.isTracked(100, DataSource.mangabaka, MediaType.manga),
        isFalse,
      );
    });

    test('should remove subscription on unsubscribe', () async {
      await dao.subscribe(100, DataSource.tmdb, MediaType.tvShow);
      await dao.unsubscribe(100, DataSource.tmdb, MediaType.tvShow);

      expect(
        await dao.isTracked(100, DataSource.tmdb, MediaType.tvShow),
        isFalse,
      );
    });

    test('should be idempotent when subscribing the same identity twice',
        () async {
      await dao.subscribe(100, DataSource.tmdb, MediaType.tvShow);
      await dao.subscribe(100, DataSource.tmdb, MediaType.tvShow);

      expect((await dao.getAll()).length, 1);
    });

    test('should return all subscriptions parsed', () async {
      await dao.subscribe(1, DataSource.tmdb, MediaType.tvShow);
      await dao.subscribe(2, DataSource.tmdb, MediaType.animation);

      final List<TrackedRelease> all = await dao.getAll();

      expect(all.length, 2);
      expect(all.map((TrackedRelease r) => r.mediaType),
          containsAll(<MediaType>[MediaType.tvShow, MediaType.animation]));
    });

    test('should expose identity tuples via getTrackedKeys', () async {
      await dao.subscribe(7, DataSource.tmdb, MediaType.tvShow);

      expect(
        await dao.getTrackedKeys(),
        contains((7, 'tmdb', 'tv_show')),
      );
    });

    test('deleteOrphaned drops subscriptions whose item left all collections',
        () async {
      await dao.subscribe(1, DataSource.tmdb, MediaType.tvShow);
      await dao.subscribe(2, DataSource.tmdb, MediaType.tvShow);
      await db.insert('collection_items', <String, Object?>{
        'external_id': 1,
        'media_type': MediaType.tvShow.value,
        'added_at': 0,
        'sort_order': 0,
      });

      await dao.deleteOrphaned();

      final Set<int> ids =
          (await dao.getAll()).map((TrackedRelease r) => r.externalId).toSet();
      expect(ids, <int>{1});
    });
  });
}
