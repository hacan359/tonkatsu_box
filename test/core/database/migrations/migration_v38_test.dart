import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tonkatsu_box/core/database/migrations/migration_v38.dart';

Future<Database> _openSeededDb() async {
  sqfliteFfiInit();
  final DatabaseFactory factory = databaseFactoryFfi;
  return factory.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE collection_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            collection_id INTEGER,
            media_type TEXT NOT NULL,
            external_id INTEGER NOT NULL,
            platform_id INTEGER,
            status TEXT NOT NULL DEFAULT 'not_started',
            added_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE tracker_game_data (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tracker_type TEXT NOT NULL,
            game_id INTEGER NOT NULL,
            platform_id INTEGER,
            tracker_game_id TEXT NOT NULL,
            tracker_game_title TEXT,
            achievements_earned INTEGER,
            achievements_total INTEGER,
            achievements_earned_hardcore INTEGER,
            award_kind TEXT,
            award_date INTEGER,
            playtime_minutes INTEGER,
            last_played_at INTEGER,
            tracker_data TEXT,
            last_synced_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE tracker_achievements (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tracker_type TEXT NOT NULL,
            tracker_game_id TEXT NOT NULL,
            achievement_id TEXT NOT NULL,
            title TEXT NOT NULL,
            description TEXT,
            points INTEGER,
            badge_name TEXT,
            type TEXT,
            display_order INTEGER NOT NULL DEFAULT 0,
            earned INTEGER NOT NULL DEFAULT 0,
            earned_at INTEGER
          )
        ''');
      },
    ),
  );
}

Future<int> _insertTrackerRow(
  Database db, {
  required int gameId,
  int? platformId,
  String trackerGameId = '111',
}) async {
  return db.insert('tracker_game_data', <String, Object?>{
    'tracker_type': 'ra',
    'game_id': gameId,
    'platform_id': platformId,
    'tracker_game_id': trackerGameId,
    'last_synced_at': 1700000000,
  });
}

Future<void> _insertCollectionItem(
  Database db, {
  required int externalId,
  int? platformId,
}) async {
  await db.insert('collection_items', <String, Object?>{
    'media_type': 'game',
    'external_id': externalId,
    'platform_id': platformId,
    'added_at': 1700000000,
  });
}

void main() {
  late Database db;

  setUp(() async {
    db = await _openSeededDb();
  });

  tearDown(() async {
    await db.close();
  });

  group('MigrationV38', () {
    test('fills platformId when exactly one platform is in the collection',
        () async {
      await _insertTrackerRow(db, gameId: 100, trackerGameId: 'ra100');
      await _insertCollectionItem(db, externalId: 100, platformId: 8);

      await MigrationV38().migrate(db);

      final List<Map<String, Object?>> rows =
          await db.query('tracker_game_data');
      expect(rows, hasLength(1));
      expect(rows.first['platform_id'], 8);
    });

    test('drops the NULL row when no matching collection_items exist',
        () async {
      await _insertTrackerRow(db, gameId: 100, trackerGameId: 'ra100');
      // No collection_items for game 100.

      await MigrationV38().migrate(db);

      expect(await db.query('tracker_game_data'), isEmpty);
    });

    test('drops the NULL row when collection has multiple platforms', () async {
      await _insertTrackerRow(db, gameId: 100, trackerGameId: 'ra100');
      await _insertCollectionItem(db, externalId: 100, platformId: 8);
      await _insertCollectionItem(db, externalId: 100, platformId: 21);

      await MigrationV38().migrate(db);

      expect(await db.query('tracker_game_data'), isEmpty);
    });

    test('leaves rows that already had platformId untouched', () async {
      await _insertTrackerRow(db, gameId: 100, platformId: 8, trackerGameId: 'ra-ps2');
      // No collection_items — wouldn't backfill anyway, but row must survive.

      await MigrationV38().migrate(db);

      final List<Map<String, Object?>> rows =
          await db.query('tracker_game_data');
      expect(rows, hasLength(1));
      expect(rows.first['platform_id'], 8);
    });

    test('drops orphan achievements when their parent NULL row is removed',
        () async {
      await _insertTrackerRow(db, gameId: 100, trackerGameId: 'orphan-ra');
      await db.insert('tracker_achievements', <String, Object?>{
        'tracker_type': 'ra',
        'tracker_game_id': 'orphan-ra',
        'achievement_id': 'a1',
        'title': 'Boom',
      });

      await MigrationV38().migrate(db);

      expect(await db.query('tracker_achievements'), isEmpty);
    });

    test('keeps achievements when another tracker row still references the '
        'same tracker_game_id', () async {
      // Two rows share the same RA tracker_game_id (e.g. legacy NULL row +
      // a freshly inserted per-platform row). Dropping the NULL row must
      // not cascade and delete the still-referenced achievements.
      await _insertTrackerRow(db, gameId: 100, trackerGameId: 'shared');
      await _insertTrackerRow(
        db,
        gameId: 100,
        platformId: 8,
        trackerGameId: 'shared',
      );
      await db.insert('tracker_achievements', <String, Object?>{
        'tracker_type': 'ra',
        'tracker_game_id': 'shared',
        'achievement_id': 'a1',
        'title': 'Keep me',
      });

      await MigrationV38().migrate(db);

      expect(await db.query('tracker_achievements'), hasLength(1));
    });
  });
}
