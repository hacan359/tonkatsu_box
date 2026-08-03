import 'package:core/models/tracker_game_data.dart';
import 'package:core/models/tracker_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TrackerGameData', () {
    group('fromDb / toDb round trip', () {
      test('preserves platformId when set', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'id': 7,
          'tracker_type': 'ra',
          'game_id': 1942,
          'platform_id': 8,
          'tracker_game_id': '12345',
          'tracker_game_title': 'SpongeBob: BFBB (PS2)',
          'achievements_earned': 10,
          'achievements_total': 50,
          'achievements_earned_hardcore': 5,
          'award_kind': 'beaten-hardcore',
          'award_date': 1700000000,
          'playtime_minutes': null,
          'last_played_at': 1701000000,
          'tracker_data': null,
          'last_synced_at': 1701123456,
        };

        final TrackerGameData data = TrackerGameData.fromDb(row);

        expect(data.platformId, 8);
        expect(data.gameId, 1942);
        expect(data.trackerGameId, '12345');
        // toDb round-trips platform_id; id is preserved for non-zero values.
        final Map<String, dynamic> roundTrip = data.toDb();
        expect(roundTrip['platform_id'], 8);
        expect(roundTrip['game_id'], 1942);
      });

      test('reads NULL platform_id as null (legacy rows)', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'id': 1,
          'tracker_type': 'ra',
          'game_id': 1942,
          'platform_id': null,
          'tracker_game_id': '12345',
          'last_synced_at': 1701123456,
        };

        final TrackerGameData data = TrackerGameData.fromDb(row);

        expect(data.platformId, isNull);
        expect(data.toDb()['platform_id'], isNull);
      });

      test('falls back to null when platform_id key is missing entirely', () {
        // Pre-v37 backup archives won't even carry the key.
        final Map<String, dynamic> row = <String, dynamic>{
          'id': 1,
          'tracker_type': 'ra',
          'game_id': 1942,
          'tracker_game_id': '12345',
          'last_synced_at': 1701123456,
        };

        expect(TrackerGameData.fromDb(row).platformId, isNull);
      });
    });

    group('copyWith', () {
      const TrackerGameData base = TrackerGameData(
        id: 1,
        trackerType: TrackerType.ra,
        gameId: 1942,
        platformId: 8,
        trackerGameId: '12345',
        lastSyncedAt: 1700000000,
      );

      test('keeps platformId untouched when not passed', () {
        expect(base.copyWith(achievementsEarned: 1).platformId, 8);
      });

      test('replaces platformId when explicitly passed', () {
        expect(base.copyWith(platformId: 9).platformId, 9);
      });

      test('clears platformId via the explicit clear flag', () {
        expect(base.copyWith(clearPlatformId: true).platformId, isNull);
      });

      test('clearPlatformId wins over a passed platformId', () {
        // The clear flag is the explicit "set null" sentinel — passing a
        // value alongside must not resurrect the field.
        expect(
          base.copyWith(clearPlatformId: true, platformId: 99).platformId,
          isNull,
        );
      });
    });

    group('tracker_data decoding', () {
      Map<String, dynamic> rowWith(String? trackerData) => <String, dynamic>{
            'id': 1,
            'tracker_type': 'ra',
            'game_id': 1942,
            'tracker_game_id': '12345',
            'tracker_data': trackerData,
            'last_synced_at': 1701123456,
          };

      test('decodes a JSON blob into a map', () {
        final TrackerGameData data =
            TrackerGameData.fromDb(rowWith('{"recent":[1,2]}'));

        expect(data.trackerData, <String, dynamic>{
          'recent': <dynamic>[1, 2],
        });
      });

      test('leaves trackerData null for a NULL column', () {
        expect(TrackerGameData.fromDb(rowWith(null)).trackerData, isNull);
      });

      test('leaves trackerData null for an empty string', () {
        expect(TrackerGameData.fromDb(rowWith('')).trackerData, isNull);
      });

      test('re-encodes the blob on toDb', () {
        const TrackerGameData data = TrackerGameData(
          id: 1,
          trackerType: TrackerType.ra,
          gameId: 1942,
          trackerGameId: '12345',
          lastSyncedAt: 1700000000,
          trackerData: <String, dynamic>{'a': 1},
        );

        expect(data.toDb()['tracker_data'], '{"a":1}');
      });
    });

    group('completionRate', () {
      TrackerGameData withCounts({int? earned, int? total}) => TrackerGameData(
            id: 1,
            trackerType: TrackerType.ra,
            gameId: 1,
            trackerGameId: '1',
            lastSyncedAt: 0,
            achievementsEarned: earned,
            achievementsTotal: total,
          );

      test('is the earned/total ratio', () {
        expect(withCounts(earned: 10, total: 40).completionRate, 0.25);
      });

      test('is 0 when the total is unknown', () {
        expect(withCounts(earned: 10).completionRate, 0.0);
      });

      test('is 0 when the total is zero, not a division by zero', () {
        expect(withCounts(earned: 0, total: 0).completionRate, 0.0);
      });

      test('is 0 when nothing was earned yet', () {
        expect(withCounts(total: 40).completionRate, 0.0);
      });

      test('is 1 for a fully earned game', () {
        expect(withCounts(earned: 40, total: 40).completionRate, 1.0);
      });
    });

    group('hardcoreCompletionRate', () {
      TrackerGameData withCounts({int? hardcore, int? total}) =>
          TrackerGameData(
            id: 1,
            trackerType: TrackerType.ra,
            gameId: 1,
            trackerGameId: '1',
            lastSyncedAt: 0,
            achievementsEarnedHardcore: hardcore,
            achievementsTotal: total,
          );

      test('is the hardcore/total ratio', () {
        expect(withCounts(hardcore: 20, total: 40).hardcoreCompletionRate, 0.5);
      });

      test('is 0 when the total is unknown', () {
        expect(withCounts(hardcore: 20).hardcoreCompletionRate, 0.0);
      });

      test('is 0 when the total is zero', () {
        expect(withCounts(hardcore: 0, total: 0).hardcoreCompletionRate, 0.0);
      });

      test('is 0 when no hardcore count was reported', () {
        expect(withCounts(total: 40).hardcoreCompletionRate, 0.0);
      });
    });

    group('award flags', () {
      TrackerGameData withAward(String? kind) => TrackerGameData(
            id: 1,
            trackerType: TrackerType.ra,
            gameId: 1,
            trackerGameId: '1',
            lastSyncedAt: 0,
            awardKind: kind,
          );

      test('all flags are false without an award', () {
        final TrackerGameData data = withAward(null);

        expect(data.hasAward, isFalse);
        expect(data.isMastered, isFalse);
        expect(data.isBeaten, isFalse);
        expect(data.isHardcore, isFalse);
      });

      test('mastered-hardcore is both mastered and hardcore', () {
        final TrackerGameData data = withAward('mastered-hardcore');

        expect(data.hasAward, isTrue);
        expect(data.isMastered, isTrue);
        expect(data.isHardcore, isTrue);
        expect(data.isBeaten, isFalse);
      });

      test('beaten-softcore is beaten but not hardcore', () {
        final TrackerGameData data = withAward('beaten-softcore');

        expect(data.isBeaten, isTrue);
        expect(data.isHardcore, isFalse);
        expect(data.isMastered, isFalse);
      });
    });

    test('raGameUrl points at the RetroAchievements game page', () {
      const TrackerGameData data = TrackerGameData(
        id: 1,
        trackerType: TrackerType.ra,
        gameId: 1,
        trackerGameId: '12345',
        lastSyncedAt: 0,
      );

      expect(data.raGameUrl, 'https://retroachievements.org/game/12345');
    });
  });
}
