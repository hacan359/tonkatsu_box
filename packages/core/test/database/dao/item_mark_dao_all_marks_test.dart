import 'package:core/database/dao/item_mark_dao.dart';
import 'package:core/database/migrations/migration.dart';
import 'package:core/database/migrations/migration_registry.dart';
import 'package:core/models/collection_item.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/item_mark.dart';
import 'package:core/models/marked_unit.dart';
import 'package:core/models/media_type.dart';
import 'package:core/testing/builders.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

void main() {
  sqfliteFfiInit();
  final DatabaseFactory factory = databaseFactoryFfi;

  late Database db;
  late ItemMarkDao dao;

  const int showId = 10;
  const int albumId = 20;
  const int mangaId = 30;

  Future<void> insertItem(CollectionItem item) async {
    final Map<String, dynamic> row = item.toDb()..['id'] = item.id;
    await db.insert('collection_items', row);
  }

  setUp(() async {
    db = await factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: MigrationRegistry.latestVersion,
        onCreate: (Database d, int _) async {
          for (final Migration m in MigrationRegistry.all) {
            await m.migrate(d);
          }
        },
        onConfigure: (Database d) => d.execute('PRAGMA foreign_keys = ON'),
      ),
    );
    dao = ItemMarkDao(() async => db);

    await insertItem(
      createTestCollectionItem(
        id: showId,
        collectionId: null,
        mediaType: MediaType.tvShow,
        externalId: 1399,
        source: DataSource.tmdb,
      ),
    );
    await insertItem(
      createTestCollectionItem(
        id: albumId,
        collectionId: null,
        mediaType: MediaType.audio,
        externalId: 555,
        source: DataSource.musicBrainz,
      ),
    );
    await insertItem(
      createTestCollectionItem(
        id: mangaId,
        collectionId: null,
        mediaType: MediaType.manga,
        externalId: 77,
        source: DataSource.mangadex,
      ),
    );
  });

  tearDown(() async => db.close());

  group('ItemMarkDao.getAllMarks', () {
    test('returns only marks with a like or a non-blank note', () async {
      await dao.setFavorite(showId, kUnitEpisode, 1, 3, isFavorite: true);
      await dao.setComment(mangaId, kUnitChapter, 0, 12, 'twist here');
      // Blank notes never reach the table, but a row written verbatim by an
      // import can carry one — the query must still drop it.
      await db.insert('item_marks', <String, Object?>{
        'item_id': mangaId,
        'unit_type': kUnitChapter,
        'parent_number': 0,
        'unit_number': 13,
        'is_favorite': 0,
        'user_comment': '   ',
        'updated_at': 1,
      });

      final List<MarkedUnit> units = await dao.getAllMarks();

      expect(units, hasLength(2));
      expect(
        units.map((MarkedUnit u) => u.mark.unitNumber),
        containsAll(<int>[3, 12]),
      );
    });

    test('joins the episode name from tv_episodes_cache', () async {
      await db.insert('tv_episodes_cache', <String, Object?>{
        'tmdb_show_id': 1399,
        'season_number': 2,
        'episode_number': 5,
        'name': 'The Rains of Castamere',
        'source': 'tmdb',
      });
      await dao.setFavorite(showId, kUnitEpisode, 2, 5, isFavorite: true);
      // Same numbers under another source must not leak in.
      await db.insert('tv_episodes_cache', <String, Object?>{
        'tmdb_show_id': 1399,
        'season_number': 2,
        'episode_number': 6,
        'name': 'Wrong source',
        'source': 'kitsu',
      });
      await dao.setFavorite(showId, kUnitEpisode, 2, 6, isFavorite: true);

      final List<MarkedUnit> units = await dao.getAllMarks();

      final MarkedUnit named = units.singleWhere(
        (MarkedUnit u) => u.mark.unitNumber == 5,
      );
      final MarkedUnit unnamed = units.singleWhere(
        (MarkedUnit u) => u.mark.unitNumber == 6,
      );
      expect(named.unitTitle, 'The Rains of Castamere');
      expect(unnamed.unitTitle, isNull);
    });

    test('joins the track title from audio_tracks_cache by disc and position',
        () async {
      await db.insert('audio_tracks_cache', <String, Object?>{
        'audio_id': 555,
        'source': 'musicBrainz',
        'disc_number': 2,
        'position': 3,
        'title': 'Disc two, track three',
      });
      await db.insert('audio_tracks_cache', <String, Object?>{
        'audio_id': 555,
        'source': 'musicBrainz',
        'disc_number': 1,
        'position': 3,
        'title': 'Disc one, track three',
      });
      await dao.setComment(albumId, kUnitTrack, 2, 3, 'best one');

      final List<MarkedUnit> units = await dao.getAllMarks();

      expect(units.single.unitTitle, 'Disc two, track three');
      expect(units.single.mark.note, 'best one');
    });

    test('leaves unitTitle null for unit types without a cache', () async {
      await dao.setComment(mangaId, kUnitChapter, 0, 12, 'note');

      final List<MarkedUnit> units = await dao.getAllMarks();

      expect(units.single.unitTitle, isNull);
      expect(units.single.mark.unitType, kUnitChapter);
    });

    test('orders newest first by liked_at, then updated_at', () async {
      await db.insert('item_marks', <String, Object?>{
        'item_id': showId,
        'unit_type': kUnitEpisode,
        'parent_number': 1,
        'unit_number': 1,
        'is_favorite': 1,
        'liked_at': 1000,
        'updated_at': 1000,
      });
      await db.insert('item_marks', <String, Object?>{
        'item_id': mangaId,
        'unit_type': kUnitChapter,
        'parent_number': 0,
        'unit_number': 2,
        'is_favorite': 0,
        'user_comment': 'note',
        'updated_at': 3000,
      });
      await db.insert('item_marks', <String, Object?>{
        'item_id': showId,
        'unit_type': kUnitEpisode,
        'parent_number': 1,
        'unit_number': 3,
        'is_favorite': 1,
        'liked_at': 2000,
        'updated_at': 9000,
      });

      final List<MarkedUnit> units = await dao.getAllMarks();

      expect(
        units.map((MarkedUnit u) => u.mark.unitNumber).toList(),
        <int>[2, 3, 1],
      );
    });

    test('drops marks when their item is deleted (FK cascade)', () async {
      await dao.setFavorite(showId, kUnitEpisode, 1, 3, isFavorite: true);
      await dao.setComment(mangaId, kUnitChapter, 0, 12, 'note');

      await db.delete('collection_items', where: 'id = ?', whereArgs: <Object?>[
        showId,
      ]);

      final List<MarkedUnit> units = await dao.getAllMarks();
      expect(units.single.mark.itemId, mangaId);
    });

    test('returns an empty list on an empty library', () async {
      expect(await dao.getAllMarks(), isEmpty);
    });
  });
}
