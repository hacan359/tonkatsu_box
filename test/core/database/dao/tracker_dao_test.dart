import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tonkatsu_box/core/database/dao/tracker_dao.dart';
import 'package:tonkatsu_box/shared/models/tracker_game_data.dart';
import 'package:tonkatsu_box/shared/models/tracker_profile.dart';

Future<Database> _openTrackerDb() async {
  sqfliteFfiInit();
  final DatabaseFactory factory = databaseFactoryFfi;
  return factory.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (Database db, int version) async {
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
          CREATE UNIQUE INDEX idx_tracker_game_data_unique
          ON tracker_game_data(tracker_type, game_id, COALESCE(platform_id, -1))
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

TrackerGameData _data({
  int? platformId,
  String trackerGameId = '111',
  int gameId = 1942,
}) =>
    TrackerGameData(
      id: 0,
      trackerType: TrackerType.ra,
      gameId: gameId,
      platformId: platformId,
      trackerGameId: trackerGameId,
      lastSyncedAt: 1700000000,
    );

void main() {
  late Database db;
  late TrackerDao dao;

  setUp(() async {
    db = await _openTrackerDb();
    dao = TrackerDao(() async => db);
  });

  tearDown(() async {
    await db.close();
  });

  group('TrackerDao', () {
    group('upsertGameData with per-platform rows', () {
      test('stores two rows for the same game on different platforms', () async {
        // PS2 console_id 21 maps to IGDB platform 8 (real values not relevant);
        // here we just pick two distinct platform ids.
        await dao.upsertGameData(_data(platformId: 8, trackerGameId: 'ra-ps2'));
        await dao.upsertGameData(_data(platformId: 21, trackerGameId: 'ra-gc'));

        final TrackerGameData? ps2 =
            await dao.getGameData(TrackerType.ra, 1942, platformId: 8);
        final TrackerGameData? gc =
            await dao.getGameData(TrackerType.ra, 1942, platformId: 21);

        expect(ps2?.trackerGameId, 'ra-ps2');
        expect(gc?.trackerGameId, 'ra-gc');
      });

      test('replaces the row for the same (game, platform) pair', () async {
        await dao.upsertGameData(_data(
          platformId: 8,
          trackerGameId: 'ra-first',
        ));
        await dao.upsertGameData(_data(
          platformId: 8,
          trackerGameId: 'ra-second',
        ));

        final TrackerGameData? row =
            await dao.getGameData(TrackerType.ra, 1942, platformId: 8);
        expect(row?.trackerGameId, 'ra-second');
        // Total rows must stay at 1 — REPLACE happened, not INSERT.
        final List<TrackerGameData> all =
            await dao.getGameDataForAnyPlatform(TrackerType.ra, 1942);
        expect(all, hasLength(1));
      });

      test('NULL platformId is its own bucket — collides with another NULL',
          () async {
        // Both rows have platformId = null → COALESCE(-1) makes them collide.
        await dao.upsertGameData(_data(trackerGameId: 'first'));
        await dao.upsertGameData(_data(trackerGameId: 'second'));

        final TrackerGameData? row =
            await dao.getGameData(TrackerType.ra, 1942);
        expect(row?.trackerGameId, 'second');
        expect(
          await dao.getGameDataForAnyPlatform(TrackerType.ra, 1942),
          hasLength(1),
        );
      });

      test('NULL platformId does not collide with concrete platformId', () async {
        await dao.upsertGameData(_data(trackerGameId: 'legacy'));
        await dao.upsertGameData(_data(
          platformId: 8,
          trackerGameId: 'ps2',
        ));

        // Both rows coexist.
        expect(
          await dao.getGameDataForAnyPlatform(TrackerType.ra, 1942),
          hasLength(2),
        );
        expect(
          (await dao.getGameData(TrackerType.ra, 1942))?.trackerGameId,
          'legacy',
        );
        expect(
          (await dao.getGameData(TrackerType.ra, 1942, platformId: 8))
              ?.trackerGameId,
          'ps2',
        );
      });
    });

    group('deleteGameData', () {
      test('per-platform delete leaves other platform rows intact', () async {
        await dao.upsertGameData(_data(platformId: 8, trackerGameId: 'ps2'));
        await dao.upsertGameData(_data(platformId: 21, trackerGameId: 'gc'));

        await dao.deleteGameData(TrackerType.ra, 1942, platformId: 8);

        final List<TrackerGameData> remaining =
            await dao.getGameDataForAnyPlatform(TrackerType.ra, 1942);
        expect(remaining, hasLength(1));
        expect(remaining.single.platformId, 21);
      });

      test('allPlatforms drops every variant', () async {
        await dao.upsertGameData(_data(platformId: 8, trackerGameId: 'ps2'));
        await dao.upsertGameData(_data(platformId: 21, trackerGameId: 'gc'));

        await dao.deleteGameData(TrackerType.ra, 1942, allPlatforms: true);

        expect(
          await dao.getGameDataForAnyPlatform(TrackerType.ra, 1942),
          isEmpty,
        );
      });

      test('per-platform delete also drops linked achievements when no other '
          'tracker row references that tracker_game_id', () async {
        await dao.upsertGameData(_data(platformId: 8, trackerGameId: 'ps2'));
        await db.insert('tracker_achievements', <String, Object?>{
          'tracker_type': 'ra',
          'tracker_game_id': 'ps2',
          'achievement_id': 'a1',
          'title': 'Boom',
        });

        await dao.deleteGameData(TrackerType.ra, 1942, platformId: 8);

        final List<Map<String, Object?>> achievements =
            await db.query('tracker_achievements');
        expect(achievements, isEmpty);
      });
    });
  });
}
