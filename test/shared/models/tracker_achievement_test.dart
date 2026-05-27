import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/models/tracker_achievement.dart';
import 'package:xerabora/shared/models/tracker_profile.dart';

void main() {
  group('TrackerAchievement.fromRaJson', () {
    Map<String, dynamic> raJson({
      Object? hardcore,
      Object? normal,
      String type = 'progression',
    }) =>
        <String, dynamic>{
          'ID': 42,
          'Title': 'First Blood',
          'Description': 'Win a fight',
          'Points': 10,
          'BadgeName': '12345',
          'Type': type,
          'DisplayOrder': 3,
          'DateEarnedHardcore': ?hardcore,
          'DateEarned': ?normal,
        };

    test('unearned when no date present', () {
      final TrackerAchievement a =
          TrackerAchievement.fromRaJson(raJson(), trackerGameId: 'g1');
      expect(a.earned, isFalse);
      expect(a.earnedAt, isNull);
      expect(a.achievementId, '42'); // numeric ID stringified
      expect(a.trackerType, TrackerType.ra);
    });

    test('earned with a valid date', () {
      final int expected =
          DateTime.parse('2023-05-01 12:00:00').millisecondsSinceEpoch ~/ 1000;
      final TrackerAchievement a = TrackerAchievement.fromRaJson(
        raJson(hardcore: '2023-05-01 12:00:00'),
        trackerGameId: 'g1',
      );
      expect(a.earned, isTrue);
      expect(a.earnedAt, expected);
    });

    test('prefers hardcore date over the normal one', () {
      final int hardcore =
          DateTime.parse('2023-05-01 12:00:00').millisecondsSinceEpoch ~/ 1000;
      final TrackerAchievement a = TrackerAchievement.fromRaJson(
        raJson(hardcore: '2023-05-01 12:00:00', normal: '2024-01-01 00:00:00'),
        trackerGameId: 'g1',
      );
      expect(a.earnedAt, hardcore);
    });

    test('blank date string stays unearned', () {
      final TrackerAchievement a = TrackerAchievement.fromRaJson(
        raJson(hardcore: ''),
        trackerGameId: 'g1',
      );
      expect(a.earned, isFalse);
    });
  });

  group('computed properties', () {
    TrackerAchievement make({String? badgeName, String? type}) =>
        TrackerAchievement(
          id: 1,
          trackerType: TrackerType.ra,
          trackerGameId: 'g',
          achievementId: 'a',
          title: 't',
          displayOrder: 0,
          earned: false,
          badgeName: badgeName,
          type: type,
        );

    test('badge urls are null without a badge name', () {
      final TrackerAchievement a = make();
      expect(a.badgeUrl, isNull);
      expect(a.lockedBadgeUrl, isNull);
    });

    test('badge urls built from badge name', () {
      final TrackerAchievement a = make(badgeName: '999');
      expect(a.badgeUrl, contains('/Badge/999.png'));
      expect(a.lockedBadgeUrl, contains('/Badge/999_lock.png'));
    });

    test('type flags', () {
      expect(make(type: 'missable').isMissable, isTrue);
      expect(make(type: 'progression').isProgression, isTrue);
      expect(make(type: 'win_condition').isWinCondition, isTrue);
      expect(make(type: 'missable').isProgression, isFalse);
      expect(make().isMissable, isFalse);
    });

    test('earnedDateTime is null when not earned', () {
      expect(make().earnedDateTime, isNull);
    });
  });

  group('db round-trip', () {
    test('toDb omits id when zero and maps earned to int', () {
      const TrackerAchievement a = TrackerAchievement(
        id: 0,
        trackerType: TrackerType.ra,
        trackerGameId: 'g',
        achievementId: 'a',
        title: 't',
        displayOrder: 2,
        earned: true,
      );
      final Map<String, dynamic> db = a.toDb();
      expect(db.containsKey('id'), isFalse);
      expect(db['earned'], 1);
    });

    test('fromDb reads earned int back to bool', () {
      final TrackerAchievement a = TrackerAchievement.fromDb(<String, dynamic>{
        'id': 7,
        'tracker_type': TrackerType.ra.value,
        'tracker_game_id': 'g',
        'achievement_id': 'a',
        'title': 't',
        'display_order': 1,
        'earned': 1,
      });
      expect(a.id, 7);
      expect(a.earned, isTrue);
    });
  });
}
