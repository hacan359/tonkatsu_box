import 'package:core/database/dao/album_dao.dart';
import 'package:core/database/migrations/migration.dart';
import 'package:core/database/migrations/migration_registry.dart';
import 'package:core/models/album.dart';
import 'package:core/models/album_track.dart';
import 'package:core/models/data_source.dart';
import 'package:core/testing/builders.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late AlbumDao dao;

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
    dao = AlbumDao(() async => db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> createCollection() async {
    return db.insert('collections', <String, dynamic>{
      'name': 'Test',
      'author': 'Tester',
      'created_at': 0,
    });
  }

  group('AlbumDao', () {
    group('upsertAlbum / getAlbum', () {
      test('stores and reads an album back', () async {
        final Album album = createTestAlbum(rating: 9.5, ratingCount: 106);
        await dao.upsertAlbum(album);

        final Album? stored =
            await dao.getAlbum(album.id, source: DataSource.musicBrainz);

        expect(stored, isNotNull);
        expect(stored!.mbid, album.mbid);
        expect(stored.title, album.title);
        expect(stored.rating, 9.5);
      });

      test('missing album returns null', () async {
        expect(
          await dao.getAlbum(999, source: DataSource.musicBrainz),
          isNull,
        );
      });

      test('a search-row upsert keeps lookup extras and the picked release',
          () async {
        await dao.upsertAlbum(createTestAlbum(
          genres: const <String>['progressive rock'],
          rating: 9.5,
          ratingCount: 106,
          listenCount: 1000,
          releaseMbid: 'rel-1',
          trackCount: 10,
          discCount: 1,
        ));

        // A grid row for the same album has none of the detail fields.
        await dao.upsertAlbum(createTestAlbum(title: 'Renamed'));

        final Album? stored =
            await dao.getAlbum(12345, source: DataSource.musicBrainz);

        expect(stored!.title, 'Renamed');
        expect(stored.genres, <String>['progressive rock']);
        expect(stored.rating, 9.5);
        expect(stored.listenCount, 1000);
        expect(stored.releaseMbid, 'rel-1');
        expect(stored.trackCount, 10);
      });
    });

    group('getAlbumsByIds', () {
      test('returns only the requested ids', () async {
        await dao.upsertAlbums(<Album>[
          createTestAlbum(id: 1, mbid: 'm1'),
          createTestAlbum(id: 2, mbid: 'm2'),
          createTestAlbum(id: 3, mbid: 'm3'),
        ]);

        final List<Album> albums = await dao.getAlbumsByIds(<int>[1, 3]);

        expect(albums.map((Album a) => a.id).toSet(), <int>{1, 3});
      });

      test('empty input returns empty output', () async {
        expect(await dao.getAlbumsByIds(<int>[]), isEmpty);
      });
    });

    group('replaceAlbumTracks / getAlbumTracks', () {
      test('stores tracks ordered by disc then position', () async {
        await dao.replaceAlbumTracks(1, DataSource.musicBrainz, <AlbumTrack>[
          createTestAlbumTrack(albumId: 1, discNumber: 2, position: 1),
          createTestAlbumTrack(albumId: 1, discNumber: 1, position: 2),
          createTestAlbumTrack(albumId: 1, discNumber: 1, position: 1),
        ]);

        final List<AlbumTrack> tracks =
            await dao.getAlbumTracks(1, source: DataSource.musicBrainz);

        expect(
          tracks
              .map((AlbumTrack t) => (t.discNumber, t.position))
              .toList(),
          <(int, int)>[(1, 1), (1, 2), (2, 1)],
        );
      });

      test('replacing drops leftovers from the previous edition', () async {
        await dao.replaceAlbumTracks(1, DataSource.musicBrainz, <AlbumTrack>[
          createTestAlbumTrack(albumId: 1, position: 1),
          createTestAlbumTrack(albumId: 1, position: 2),
          createTestAlbumTrack(albumId: 1, position: 3),
        ]);

        await dao.replaceAlbumTracks(1, DataSource.musicBrainz, <AlbumTrack>[
          createTestAlbumTrack(albumId: 1, position: 1, title: 'New'),
        ]);

        final List<AlbumTrack> tracks =
            await dao.getAlbumTracks(1, source: DataSource.musicBrainz);

        expect(tracks, hasLength(1));
        expect(tracks.single.title, 'New');
      });

      test('does not touch another album', () async {
        await dao.replaceAlbumTracks(1, DataSource.musicBrainz, <AlbumTrack>[
          createTestAlbumTrack(albumId: 1),
        ]);
        await dao.replaceAlbumTracks(2, DataSource.musicBrainz, <AlbumTrack>[
          createTestAlbumTrack(albumId: 2),
        ]);

        expect(
          await dao.getAlbumTracks(1, source: DataSource.musicBrainz),
          hasLength(1),
        );
      });
    });

    group('upsertTracks', () {
      test('bulk-inserts tracks across albums and is idempotent', () async {
        final List<AlbumTrack> batch = <AlbumTrack>[
          createTestAlbumTrack(albumId: 1, position: 1, title: 'A1'),
          createTestAlbumTrack(albumId: 1, position: 2, title: 'A2'),
          createTestAlbumTrack(albumId: 2, position: 1, title: 'B1'),
        ];
        await dao.upsertTracks(batch);
        // A re-import of the same payload must not duplicate rows.
        await dao.upsertTracks(batch);

        expect(
          await dao.getAlbumTracks(1, source: DataSource.musicBrainz),
          hasLength(2),
        );
        expect(
          await dao.getAlbumTracks(2, source: DataSource.musicBrainz),
          hasLength(1),
        );
      });

      test('empty input is a no-op', () async {
        await dao.upsertTracks(const <AlbumTrack>[]);
        expect(
          await dao.getAlbumTracks(1, source: DataSource.musicBrainz),
          isEmpty,
        );
      });
    });

    group('listened tracks', () {
      test('mark, read and unmark', () async {
        final int collectionId = await createCollection();

        await dao.markTrackListened(
          collectionId, DataSource.musicBrainz, 1, 1, 5);

        Map<(int, int), DateTime?> listened = await dao.getListenedTracks(
          collectionId, DataSource.musicBrainz, 1);
        expect(listened.keys, <(int, int)>{(1, 5)});
        expect(listened[(1, 5)], isNotNull);

        await dao.markTrackUnlistened(
          collectionId, DataSource.musicBrainz, 1, 1, 5);

        listened = await dao.getListenedTracks(
          collectionId, DataSource.musicBrainz, 1);
        expect(listened, isEmpty);
      });

      test('double mark is idempotent', () async {
        final int collectionId = await createCollection();

        await dao.markTrackListened(
          collectionId, DataSource.musicBrainz, 1, 1, 1);
        await dao.markTrackListened(
          collectionId, DataSource.musicBrainz, 1, 1, 1);

        expect(
          await dao.getListenedTracks(
              collectionId, DataSource.musicBrainz, 1),
          hasLength(1),
        );
      });

      test('batch restore keeps explicit timestamps', () async {
        final int collectionId = await createCollection();

        await dao.markTracksListenedAt(
          collectionId,
          DataSource.musicBrainz,
          1,
          <(int, int, int?)>[(1, 1, 1000), (1, 2, null)],
        );

        final Map<(int, int), DateTime?> listened = await dao
            .getListenedTracks(collectionId, DataSource.musicBrainz, 1);

        expect(listened[(1, 1)],
            DateTime.fromMillisecondsSinceEpoch(1000));
        expect(listened.containsKey((1, 2)), isTrue);
        expect(listened[(1, 2)], isNull);
      });

      test('getAllListenedTracks dedupes across collections', () async {
        final int c1 = await createCollection();
        final int c2 = await createCollection();

        await dao.markTracksListenedAt(
            c1, DataSource.musicBrainz, 1, <(int, int, int?)>[(1, 1, 1000)]);
        await dao.markTracksListenedAt(
            c2, DataSource.musicBrainz, 1, <(int, int, int?)>[(1, 1, 2000)]);

        final List<Map<String, Object?>> all =
            await dao.getAllListenedTracks();

        expect(all, hasLength(1));
        expect(all.single['listened_at'], 2000);
      });

      test('marks cascade away with the collection', () async {
        final int collectionId = await createCollection();
        await dao.markTrackListened(
          collectionId, DataSource.musicBrainz, 1, 1, 1);

        await db.delete(
          'collections',
          where: 'id = ?',
          whereArgs: <Object?>[collectionId],
        );

        expect(
          await dao.getListenedTracks(
              collectionId, DataSource.musicBrainz, 1),
          isEmpty,
        );
      });
    });

    test('clearAlbums wipes albums and tracks', () async {
      await dao.upsertAlbum(createTestAlbum(id: 1, mbid: 'm1'));
      await dao.replaceAlbumTracks(1, DataSource.musicBrainz, <AlbumTrack>[
        createTestAlbumTrack(albumId: 1),
      ]);

      await dao.clearAlbums();

      expect(await dao.getAlbumsByIds(<int>[1]), isEmpty);
      expect(
        await dao.getAlbumTracks(1, source: DataSource.musicBrainz),
        isEmpty,
      );
    });
  });
}
