import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/models/tracker_game_data.dart';
import 'package:tonkatsu_box/shared/models/tracker_profile.dart';

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
  });
}
