import 'package:core/database/dao/audio_dao.dart';
import 'package:core/database/migrations/migration.dart';
import 'package:core/database/migrations/migration_registry.dart';
import 'package:core/models/audio_item.dart';
import 'package:core/models/audio_kind.dart';
import 'package:core/models/audio_track.dart';
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
  late AudioDao dao;

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
    dao = AudioDao(() async => db);
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

  group('AudioDao', () {
    group('upsertAudioItem / getAudioItem', () {
      test('stores and reads an album back', () async {
        final AudioItem album = createTestAudioItem(rating: 9.5, ratingCount: 106);
        await dao.upsertAudioItem(album);

        final AudioItem? stored =
            await dao.getAudioItem(album.id, source: DataSource.musicBrainz);

        expect(stored, isNotNull);
        expect(stored!.nativeId, album.nativeId);
        expect(stored.title, album.title);
        expect(stored.rating, 9.5);
      });

      test('missing album returns null', () async {
        expect(
          await dao.getAudioItem(999, source: DataSource.musicBrainz),
          isNull,
        );
      });

      test('a search-row upsert keeps lookup extras and the picked release',
          () async {
        await dao.upsertAudioItem(createTestAudioItem(
          genres: const <String>['progressive rock'],
          rating: 9.5,
          ratingCount: 106,
          listenCount: 1000,
          releaseMbid: 'rel-1',
          trackCount: 10,
          discCount: 1,
        ));

        // A grid row for the same album has none of the detail fields.
        await dao.upsertAudioItem(createTestAudioItem(title: 'Renamed'));

        final AudioItem? stored =
            await dao.getAudioItem(12345, source: DataSource.musicBrainz);

        expect(stored!.title, 'Renamed');
        expect(stored.genres, <String>['progressive rock']);
        expect(stored.rating, 9.5);
        expect(stored.listenCount, 1000);
        expect(stored.releaseMbid, 'rel-1');
        expect(stored.trackCount, 10);
      });
    });

    group('getAudioItemsByIds', () {
      test('returns only the requested ids', () async {
        await dao.upsertAudioItems(<AudioItem>[
          createTestAudioItem(id: 1, nativeId: 'm1'),
          createTestAudioItem(id: 2, nativeId: 'm2'),
          createTestAudioItem(id: 3, nativeId: 'm3'),
        ]);

        final List<AudioItem> albums = await dao.getAudioItemsByIds(<int>[1, 3]);

        expect(albums.map((AudioItem a) => a.id).toSet(), <int>{1, 3});
      });

      test('empty input returns empty output', () async {
        expect(await dao.getAudioItemsByIds(<int>[]), isEmpty);
      });
    });

    group('replaceAudioTracks / getAudioTracks', () {
      test('stores tracks ordered by disc then position', () async {
        await dao.replaceAudioTracks(1, DataSource.musicBrainz, <AudioTrack>[
          createTestAudioTrack(audioId: 1, discNumber: 2, position: 1),
          createTestAudioTrack(audioId: 1, discNumber: 1, position: 2),
          createTestAudioTrack(audioId: 1, discNumber: 1, position: 1),
        ]);

        final List<AudioTrack> tracks =
            await dao.getAudioTracks(1, source: DataSource.musicBrainz);

        expect(
          tracks
              .map((AudioTrack t) => (t.discNumber, t.position))
              .toList(),
          <(int, int)>[(1, 1), (1, 2), (2, 1)],
        );
      });

      test('replacing drops leftovers from the previous edition', () async {
        await dao.replaceAudioTracks(1, DataSource.musicBrainz, <AudioTrack>[
          createTestAudioTrack(audioId: 1, position: 1),
          createTestAudioTrack(audioId: 1, position: 2),
          createTestAudioTrack(audioId: 1, position: 3),
        ]);

        await dao.replaceAudioTracks(1, DataSource.musicBrainz, <AudioTrack>[
          createTestAudioTrack(audioId: 1, position: 1, title: 'New'),
        ]);

        final List<AudioTrack> tracks =
            await dao.getAudioTracks(1, source: DataSource.musicBrainz);

        expect(tracks, hasLength(1));
        expect(tracks.single.title, 'New');
      });

      test('does not touch another album', () async {
        await dao.replaceAudioTracks(1, DataSource.musicBrainz, <AudioTrack>[
          createTestAudioTrack(audioId: 1),
        ]);
        await dao.replaceAudioTracks(2, DataSource.musicBrainz, <AudioTrack>[
          createTestAudioTrack(audioId: 2),
        ]);

        expect(
          await dao.getAudioTracks(1, source: DataSource.musicBrainz),
          hasLength(1),
        );
      });
    });

    group('upsertTracks', () {
      test('bulk-inserts tracks across albums and is idempotent', () async {
        final List<AudioTrack> batch = <AudioTrack>[
          createTestAudioTrack(audioId: 1, position: 1, title: 'A1'),
          createTestAudioTrack(audioId: 1, position: 2, title: 'A2'),
          createTestAudioTrack(audioId: 2, position: 1, title: 'B1'),
        ];
        await dao.upsertTracks(batch);
        // A re-import of the same payload must not duplicate rows.
        await dao.upsertTracks(batch);

        expect(
          await dao.getAudioTracks(1, source: DataSource.musicBrainz),
          hasLength(2),
        );
        expect(
          await dao.getAudioTracks(2, source: DataSource.musicBrainz),
          hasLength(1),
        );
      });

      test('empty input is a no-op', () async {
        await dao.upsertTracks(const <AudioTrack>[]);
        expect(
          await dao.getAudioTracks(1, source: DataSource.musicBrainz),
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

    test('clearAudioItems wipes albums and tracks', () async {
      await dao.upsertAudioItem(createTestAudioItem(id: 1, nativeId: 'm1'));
      await dao.replaceAudioTracks(1, DataSource.musicBrainz, <AudioTrack>[
        createTestAudioTrack(audioId: 1),
      ]);

      await dao.clearAudioItems();

      expect(await dao.getAudioItemsByIds(<int>[1]), isEmpty);
      expect(
        await dao.getAudioTracks(1, source: DataSource.musicBrainz),
        isEmpty,
      );
    });

    group('podcast episodes', () {
      test('upsertTracks grows the cache without evicting older episodes',
          () async {
        final AudioItem podcast = createTestAudioItem(
          id: 197123,
          source: DataSource.podcastIndex,
          kind: AudioKind.podcast,
          nativeId: '17457c36-46b7-5d1a-825b-0860515bea7d',
          title: 'Radiolab',
        );
        await dao.upsertAudioItem(podcast);
        await dao.upsertTracks(<AudioTrack>[
          createTestAudioTrack(
            audioId: 197123,
            discNumber: 0,
            position: 100,
            title: 'Old episode',
            datePublished: 1000,
            source: DataSource.podcastIndex,
          ),
        ]);

        // A later refresh carries only newer episodes — the old row stays.
        await dao.upsertTracks(<AudioTrack>[
          createTestAudioTrack(
            audioId: 197123,
            discNumber: 0,
            position: 58680086814,
            title: 'New episode',
            datePublished: 1786111200,
            source: DataSource.podcastIndex,
          ),
        ]);

        final List<AudioTrack> episodes = await dao.getAudioTracks(
          197123,
          source: DataSource.podcastIndex,
        );
        expect(episodes, hasLength(2));
        expect(
          episodes.map((AudioTrack t) => t.title),
          containsAll(<String>['Old episode', 'New episode']),
        );
      });

      test('listened marks key on (0, episode id) and survive int64 ids',
          () async {
        final int collectionId = await createCollection();
        const int episodeId = 58680086814;

        await dao.markTrackListened(
          collectionId,
          DataSource.podcastIndex,
          197123,
          0,
          episodeId,
        );

        final Map<(int, int), DateTime?> listened = await dao
            .getListenedTracks(collectionId, DataSource.podcastIndex, 197123);
        expect(listened.keys, contains((0, episodeId)));

        await dao.markTrackUnlistened(
          collectionId,
          DataSource.podcastIndex,
          197123,
          0,
          episodeId,
        );
        final Map<(int, int), DateTime?> after = await dao.getListenedTracks(
          collectionId,
          DataSource.podcastIndex,
          197123,
        );
        expect(after, isEmpty);
      });

      test('album and podcast rows with one numeric id stay distinct', () async {
        // A MusicBrainz hash and a Podcast Index feed id can collide; the
        // (id, source) key keeps both rows.
        final AudioItem album = createTestAudioItem(id: 4242);
        final AudioItem podcast = createTestAudioItem(
          id: 4242,
          source: DataSource.podcastIndex,
          kind: AudioKind.podcast,
          nativeId: 'guid-4242',
          title: 'Feed 4242',
        );
        await dao.upsertAudioItem(album);
        await dao.upsertAudioItem(podcast);

        final AudioItem? gotAlbum =
            await dao.getAudioItem(4242, source: DataSource.musicBrainz);
        final AudioItem? gotPodcast =
            await dao.getAudioItem(4242, source: DataSource.podcastIndex);
        expect(gotAlbum?.kind, AudioKind.album);
        expect(gotPodcast?.kind, AudioKind.podcast);
        expect(gotPodcast?.title, 'Feed 4242');
      });

      test('markTracksUnlistened clears a whole span in one call', () async {
        final int collectionId = await createCollection();
        const List<(int, int)> keys = <(int, int)>[
          (0, 58680086814),
          (0, 58353775042),
          (0, 58030369165),
        ];
        await dao.markTracksListenedAt(
          collectionId,
          DataSource.podcastIndex,
          197123,
          <(int, int, int?)>[
            for (final (int disc, int track) in keys) (disc, track, 1000),
          ],
        );
        expect(
          await dao.getListenedTracks(
              collectionId, DataSource.podcastIndex, 197123),
          hasLength(3),
        );

        // Clearing two of three leaves the third mark untouched.
        await dao.markTracksUnlistened(
          collectionId,
          DataSource.podcastIndex,
          197123,
          keys.sublist(0, 2),
        );
        final Map<(int, int), DateTime?> left = await dao.getListenedTracks(
            collectionId, DataSource.podcastIndex, 197123);
        expect(left.keys, <(int, int)>{(0, 58030369165)});
      });
    });
  });
}
