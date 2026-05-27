import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/models/tracker_profile.dart';

void main() {
  group('TrackerType.fromString', () {
    test('maps known values', () {
      expect(TrackerType.fromString('ra'), TrackerType.ra);
      expect(TrackerType.fromString('steam'), TrackerType.steam);
      expect(TrackerType.fromString('trakt'), TrackerType.trakt);
    });

    test('falls back to ra for unknown values', () {
      expect(TrackerType.fromString('nope'), TrackerType.ra);
      expect(TrackerType.fromString(''), TrackerType.ra);
    });
  });

  group('TrackerProfile db mapping', () {
    TrackerProfile profile({
      int id = 0,
      Map<String, dynamic>? data,
    }) =>
        TrackerProfile(
          id: id,
          trackerType: TrackerType.steam,
          userId: 'u1',
          displayName: 'Player',
          createdAt: 1700000000,
          profileData: data,
        );

    test('toDb omits id when zero and encodes profile data as JSON', () {
      final Map<String, dynamic> db =
          profile(data: <String, dynamic>{'rank': 5}).toDb();
      expect(db.containsKey('id'), isFalse);
      expect(db['tracker_type'], 'steam');
      expect(db['profile_data'], '{"rank":5}');
    });

    test('toDb leaves profile data null when absent', () {
      expect(profile().toDb()['profile_data'], isNull);
    });

    test('fromDb decodes profile data and reads fields', () {
      final TrackerProfile p = TrackerProfile.fromDb(<String, dynamic>{
        'id': 3,
        'tracker_type': 'ra',
        'user_id': 'bob',
        'display_name': 'Bob',
        'created_at': 1700000000,
        'profile_data': '{"rank":5}',
      });
      expect(p.id, 3);
      expect(p.trackerType, TrackerType.ra);
      expect(p.profileData, <String, dynamic>{'rank': 5});
    });

    test('fromDb keeps profile data null when empty', () {
      final TrackerProfile p = TrackerProfile.fromDb(<String, dynamic>{
        'id': 1,
        'tracker_type': 'steam',
        'user_id': 'u',
        'display_name': 'd',
        'created_at': 1,
        'profile_data': '',
      });
      expect(p.profileData, isNull);
    });

    test('round-trips profile data through toDb -> fromDb', () {
      const TrackerProfile original = TrackerProfile(
        id: 9,
        trackerType: TrackerType.ra,
        userId: 'u',
        displayName: 'd',
        createdAt: 5,
        profileData: <String, dynamic>{'a': 1, 'b': 'x'},
      );
      final TrackerProfile restored = TrackerProfile.fromDb(original.toDb());
      expect(restored.profileData, original.profileData);
      expect(restored.trackerType, original.trackerType);
    });
  });

  test('copyWith changes only the given field', () {
    const TrackerProfile p = TrackerProfile(
      id: 1,
      trackerType: TrackerType.ra,
      userId: 'u',
      displayName: 'd',
      createdAt: 1,
    );
    final TrackerProfile updated = p.copyWith(linkedCollectionId: 42);
    expect(updated.linkedCollectionId, 42);
    expect(updated.userId, 'u');
    expect(updated.trackerType, TrackerType.ra);
  });
}
