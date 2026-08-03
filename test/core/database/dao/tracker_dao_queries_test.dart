import 'package:core/database/dao/tracker_dao.dart';
import 'package:core/database/migrations/migration.dart';
import 'package:core/database/migrations/migration_registry.dart';
import 'package:core/models/tracker_achievement.dart';
import 'package:core/models/tracker_game_data.dart';
import 'package:core/models/tracker_profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

TrackerProfile _profile({
  int id = 0,
  TrackerType type = TrackerType.ra,
  String userId = 'player1',
  String displayName = 'Player One',
  int createdAt = 1700000000,
  Map<String, dynamic>? profileData,
  int? totalPoints,
}) =>
    TrackerProfile(
      id: id,
      trackerType: type,
      userId: userId,
      displayName: displayName,
      createdAt: createdAt,
      profileData: profileData,
      totalPoints: totalPoints,
    );

TrackerGameData _gameData({
  int id = 0,
  TrackerType type = TrackerType.ra,
  int gameId = 100,
  int? platformId,
  String trackerGameId = 'ra-1',
  int lastSyncedAt = 1700000000,
  Map<String, dynamic>? trackerData,
}) =>
    TrackerGameData(
      id: id,
      trackerType: type,
      gameId: gameId,
      platformId: platformId,
      trackerGameId: trackerGameId,
      lastSyncedAt: lastSyncedAt,
      trackerData: trackerData,
    );

TrackerAchievement _achievement({
  String achievementId = 'a1',
  String trackerGameId = 'ra-1',
  String title = 'First blood',
  int displayOrder = 0,
  bool earned = false,
  TrackerType type = TrackerType.ra,
}) =>
    TrackerAchievement(
      id: 0,
      trackerType: type,
      trackerGameId: trackerGameId,
      achievementId: achievementId,
      title: title,
      displayOrder: displayOrder,
      earned: earned,
    );

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late TrackerDao dao;

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
    dao = TrackerDao(() async => db);
  });

  tearDown(() async {
    await db.close();
  });

  group('TrackerDao profiles', () {
    group('getProfile', () {
      test('returns null when the tracker has no profile', () async {
        expect(await dao.getProfile(TrackerType.ra), isNull);
      });

      test('does not leak a profile from another tracker', () async {
        await dao.upsertProfile(_profile(type: TrackerType.steam));

        expect(await dao.getProfile(TrackerType.ra), isNull);
      });

      test('decodes the profile_data JSON blob', () async {
        await dao.upsertProfile(_profile(
          profileData: const <String, dynamic>{'rank': 42},
        ));

        expect(
          (await dao.getProfile(TrackerType.ra))?.profileData,
          <String, dynamic>{'rank': 42},
        );
      });

      test('leaves profileData null when no blob was stored', () async {
        await dao.upsertProfile(_profile());

        expect((await dao.getProfile(TrackerType.ra))?.profileData, isNull);
      });
    });

    group('upsertProfile', () {
      test('assigns an autoincrement id and returns it on the copy', () async {
        final TrackerProfile saved = await dao.upsertProfile(_profile());

        expect(saved.id, greaterThan(0));
        expect((await dao.getProfile(TrackerType.ra))?.id, saved.id);
      });

      test('replaces the profile for the same tracker type', () async {
        await dao.upsertProfile(_profile(displayName: 'Old', totalPoints: 1));
        await dao.upsertProfile(_profile(displayName: 'New', totalPoints: 2));

        final List<TrackerProfile> all = await dao.getAllProfiles();
        expect(all, hasLength(1));
        expect(all.single.displayName, 'New');
        expect(all.single.totalPoints, 2);
      });

      test('keeps profiles of different trackers apart', () async {
        await dao.upsertProfile(_profile(type: TrackerType.ra));
        await dao.upsertProfile(_profile(type: TrackerType.steam));

        expect(await dao.getAllProfiles(), hasLength(2));
      });
    });

    group('getAllProfiles', () {
      test('returns empty when nothing is linked', () async {
        expect(await dao.getAllProfiles(), isEmpty);
      });

      test('sorts by created_at descending', () async {
        await dao.upsertProfile(_profile(
          type: TrackerType.ra,
          createdAt: 100,
        ));
        await dao.upsertProfile(_profile(
          type: TrackerType.steam,
          createdAt: 300,
        ));
        await dao.upsertProfile(_profile(
          type: TrackerType.trakt,
          createdAt: 200,
        ));

        expect(
          (await dao.getAllProfiles()).map((TrackerProfile p) => p.trackerType),
          <TrackerType>[TrackerType.steam, TrackerType.trakt, TrackerType.ra],
        );
      });
    });

    group('deleteProfile', () {
      test('drops the profile, its game data and its achievements', () async {
        await dao.upsertProfile(_profile());
        await dao.upsertGameData(_gameData());
        await dao.replaceAchievements(
          TrackerType.ra,
          'ra-1',
          <TrackerAchievement>[_achievement()],
        );

        await dao.deleteProfile(TrackerType.ra);

        expect(await dao.getProfile(TrackerType.ra), isNull);
        expect(await dao.getAllGameData(TrackerType.ra), isEmpty);
        expect(await dao.getAchievements(TrackerType.ra, 'ra-1'), isEmpty);
      });

      test('leaves another tracker untouched', () async {
        await dao.upsertProfile(_profile(type: TrackerType.ra));
        await dao.upsertProfile(_profile(type: TrackerType.steam));
        await dao.upsertGameData(_gameData(type: TrackerType.steam));

        await dao.deleteProfile(TrackerType.ra);

        expect(await dao.getProfile(TrackerType.steam), isNotNull);
        expect(await dao.getAllGameData(TrackerType.steam), hasLength(1));
      });

      test('is a no-op when the tracker has nothing stored', () async {
        await dao.deleteProfile(TrackerType.trakt);

        expect(await dao.getAllProfiles(), isEmpty);
      });
    });
  });

  group('TrackerDao game data queries', () {
    group('getGameData', () {
      test('returns null when nothing matches', () async {
        expect(await dao.getGameData(TrackerType.ra, 100), isNull);
      });

      test('null platformId only matches the platform-agnostic row', () async {
        await dao.upsertGameData(_gameData(platformId: 7));

        expect(await dao.getGameData(TrackerType.ra, 100), isNull);
        expect(
          await dao.getGameData(TrackerType.ra, 100, platformId: 7),
          isNotNull,
        );
      });

      test('decodes the tracker_data JSON blob', () async {
        await dao.upsertGameData(_gameData(
          trackerData: const <String, dynamic>{'recent': <String>[]},
        ));

        expect(
          (await dao.getGameData(TrackerType.ra, 100))?.trackerData,
          <String, dynamic>{'recent': <dynamic>[]},
        );
      });
    });

    group('getGameDataForAnyPlatform', () {
      test('returns every platform variant of one game', () async {
        await dao.upsertGameData(_gameData(platformId: 1));
        await dao.upsertGameData(_gameData(platformId: 2));
        await dao.upsertGameData(_gameData());

        expect(
          await dao.getGameDataForAnyPlatform(TrackerType.ra, 100),
          hasLength(3),
        );
      });

      test('ignores other games and other trackers', () async {
        await dao.upsertGameData(_gameData(gameId: 100));
        await dao.upsertGameData(_gameData(gameId: 200));
        await dao.upsertGameData(
          _gameData(gameId: 100, type: TrackerType.steam),
        );

        final List<TrackerGameData> found =
            await dao.getGameDataForAnyPlatform(TrackerType.ra, 100);

        expect(found, hasLength(1));
        expect(found.single.gameId, 100);
      });

      test('returns empty when the game is not tracked', () async {
        expect(
          await dao.getGameDataForAnyPlatform(TrackerType.ra, 999),
          isEmpty,
        );
      });
    });

    group('getAllGameData', () {
      test('returns only rows of the requested tracker', () async {
        await dao.upsertGameData(_gameData(gameId: 100));
        await dao.upsertGameData(_gameData(gameId: 200));
        await dao.upsertGameData(
          _gameData(gameId: 300, type: TrackerType.steam),
        );

        expect(await dao.getAllGameData(TrackerType.ra), hasLength(2));
        expect(await dao.getAllGameData(TrackerType.steam), hasLength(1));
      });

      test('returns empty for an unused tracker', () async {
        expect(await dao.getAllGameData(TrackerType.trakt), isEmpty);
      });
    });

    group('getGameDataForGame', () {
      test('spans trackers for one game id', () async {
        await dao.upsertGameData(_gameData(gameId: 100));
        await dao.upsertGameData(
          _gameData(gameId: 100, type: TrackerType.steam),
        );
        await dao.upsertGameData(_gameData(gameId: 200));

        final List<TrackerGameData> found = await dao.getGameDataForGame(100);

        expect(found, hasLength(2));
        expect(
          found.map((TrackerGameData d) => d.trackerType).toSet(),
          <TrackerType>{TrackerType.ra, TrackerType.steam},
        );
      });

      test('returns empty for an untracked game', () async {
        expect(await dao.getGameDataForGame(999), isEmpty);
      });
    });

    group('getGameDataForGameIds', () {
      test('returns empty for an empty id list', () async {
        expect(await dao.getGameDataForGameIds(const <int>[]), isEmpty);
      });

      test('skips game ids with no row', () async {
        await dao.upsertGameData(_gameData(gameId: 100));

        final List<TrackerGameData> found =
            await dao.getGameDataForGameIds(<int>[100, 999]);

        expect(found, hasLength(1));
        expect(found.single.gameId, 100);
      });

      test('spans more ids than one IN-clause chunk holds', () async {
        await dao.upsertGameDataBatch(<TrackerGameData>[
          for (int i = 1; i <= 1200; i++)
            _gameData(gameId: i, trackerGameId: 'ra-$i'),
        ]);

        final List<TrackerGameData> found = await dao.getGameDataForGameIds(
          <int>[for (int i = 1; i <= 1200; i++) i],
        );

        expect(found, hasLength(1200));
      });
    });

    group('upsertGameDataBatch', () {
      test('is a no-op for an empty list', () async {
        await dao.upsertGameDataBatch(const <TrackerGameData>[]);

        expect(await dao.getAllGameData(TrackerType.ra), isEmpty);
      });

      test('replaces rows colliding on (tracker, game, platform)', () async {
        await dao.upsertGameData(_gameData(gameId: 100, trackerGameId: 'old'));

        await dao.upsertGameDataBatch(<TrackerGameData>[
          _gameData(gameId: 100, trackerGameId: 'new'),
          _gameData(gameId: 200, trackerGameId: 'fresh'),
        ]);

        expect(
          (await dao.getGameData(TrackerType.ra, 100))?.trackerGameId,
          'new',
        );
        expect(await dao.getAllGameData(TrackerType.ra), hasLength(2));
      });
    });
  });

  group('TrackerDao achievements', () {
    group('getAchievements', () {
      test('returns empty when the game has none', () async {
        expect(await dao.getAchievements(TrackerType.ra, 'ra-1'), isEmpty);
      });

      test('sorts by display_order ascending', () async {
        await dao.replaceAchievements(
          TrackerType.ra,
          'ra-1',
          <TrackerAchievement>[
            _achievement(achievementId: 'c', title: 'Third', displayOrder: 3),
            _achievement(achievementId: 'a', title: 'First', displayOrder: 1),
            _achievement(achievementId: 'b', title: 'Second', displayOrder: 2),
          ],
        );

        expect(
          (await dao.getAchievements(TrackerType.ra, 'ra-1'))
              .map((TrackerAchievement a) => a.title),
          <String>['First', 'Second', 'Third'],
        );
      });

      test('scopes by tracker type as well as game id', () async {
        await dao.replaceAchievements(
          TrackerType.ra,
          'shared',
          <TrackerAchievement>[_achievement(trackerGameId: 'shared')],
        );

        expect(await dao.getAchievements(TrackerType.steam, 'shared'), isEmpty);
      });

      test('round-trips the earned flag', () async {
        await dao.replaceAchievements(
          TrackerType.ra,
          'ra-1',
          <TrackerAchievement>[
            _achievement(achievementId: 'a', earned: true),
            _achievement(achievementId: 'b', displayOrder: 1),
          ],
        );

        final List<TrackerAchievement> all =
            await dao.getAchievements(TrackerType.ra, 'ra-1');
        expect(all.first.earned, isTrue);
        expect(all.last.earned, isFalse);
      });
    });

    group('hasAchievements', () {
      test('is false when the game has none', () async {
        expect(await dao.hasAchievements(TrackerType.ra, 'ra-1'), isFalse);
      });

      test('is true once achievements are stored', () async {
        await dao.replaceAchievements(
          TrackerType.ra,
          'ra-1',
          <TrackerAchievement>[_achievement()],
        );

        expect(await dao.hasAchievements(TrackerType.ra, 'ra-1'), isTrue);
      });

      test('is false for the same game id under another tracker', () async {
        await dao.replaceAchievements(
          TrackerType.ra,
          'shared',
          <TrackerAchievement>[_achievement(trackerGameId: 'shared')],
        );

        expect(
          await dao.hasAchievements(TrackerType.steam, 'shared'),
          isFalse,
        );
      });
    });

    group('replaceAchievements', () {
      test('drops the previous set', () async {
        await dao.replaceAchievements(
          TrackerType.ra,
          'ra-1',
          <TrackerAchievement>[
            _achievement(achievementId: 'a'),
            _achievement(achievementId: 'b', displayOrder: 1),
          ],
        );

        await dao.replaceAchievements(
          TrackerType.ra,
          'ra-1',
          <TrackerAchievement>[_achievement(achievementId: 'c')],
        );

        final List<TrackerAchievement> all =
            await dao.getAchievements(TrackerType.ra, 'ra-1');
        expect(all, hasLength(1));
        expect(all.single.achievementId, 'c');
      });

      test('clears the set when given an empty list', () async {
        await dao.replaceAchievements(
          TrackerType.ra,
          'ra-1',
          <TrackerAchievement>[_achievement()],
        );

        await dao.replaceAchievements(
          TrackerType.ra,
          'ra-1',
          const <TrackerAchievement>[],
        );

        expect(await dao.hasAchievements(TrackerType.ra, 'ra-1'), isFalse);
      });

      test('leaves another game of the same tracker alone', () async {
        await dao.replaceAchievements(
          TrackerType.ra,
          'ra-1',
          <TrackerAchievement>[_achievement(trackerGameId: 'ra-1')],
        );
        await dao.replaceAchievements(
          TrackerType.ra,
          'ra-2',
          <TrackerAchievement>[_achievement(trackerGameId: 'ra-2')],
        );

        expect(await dao.getAchievements(TrackerType.ra, 'ra-1'), hasLength(1));
        expect(await dao.getAchievements(TrackerType.ra, 'ra-2'), hasLength(1));
      });
    });
  });
}
