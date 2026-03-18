// Тесты для RaUserProfile.

import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/models/ra_user_profile.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('RaUserProfile', () {
    group('constructor', () {
      test('should create with required fields', () {
        const RaUserProfile profile = RaUserProfile(
          user: 'Hacan359',
          totalPoints: 5000,
          memberSince: '2024-03-15 11:27:24',
        );

        expect(profile.user, equals('Hacan359'));
        expect(profile.totalPoints, equals(5000));
        expect(profile.memberSince, equals('2024-03-15 11:27:24'));
        expect(profile.userPic, isNull);
        expect(profile.richPresenceMsg, isNull);
        expect(profile.totalTruePoints, equals(0));
      });

      test('should create with all fields', () {
        final RaUserProfile profile = createTestRaUserProfile(
          user: 'TestUser',
          totalPoints: 5000,
          memberSince: '2024-03-15 11:27:24',
          userPic: '/UserPic/TestUser.png',
          richPresenceMsg: 'Playing Super Mario World',
          totalTruePoints: 8000,
        );

        expect(profile.user, equals('TestUser'));
        expect(profile.totalPoints, equals(5000));
        expect(profile.memberSince, equals('2024-03-15 11:27:24'));
        expect(profile.userPic, equals('/UserPic/TestUser.png'));
        expect(profile.richPresenceMsg, equals('Playing Super Mario World'));
        expect(profile.totalTruePoints, equals(8000));
      });
    });

    group('fromJson', () {
      test('should parse full JSON response', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'User': 'Hacan359',
          'TotalPoints': 5000,
          'MemberSince': '2024-03-15 11:27:24',
          'UserPic': '/UserPic/Hacan359.png',
          'RichPresenceMsg': 'Playing Super Mario World',
          'TotalTruePoints': 8000,
        };

        final RaUserProfile profile = RaUserProfile.fromJson(json);

        expect(profile.user, equals('Hacan359'));
        expect(profile.totalPoints, equals(5000));
        expect(profile.memberSince, equals('2024-03-15 11:27:24'));
        expect(profile.userPic, equals('/UserPic/Hacan359.png'));
        expect(profile.richPresenceMsg, equals('Playing Super Mario World'));
        expect(profile.totalTruePoints, equals(8000));
      });

      test('should handle missing optional fields', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'User': 'TestUser',
          'TotalPoints': 100,
          'MemberSince': '2024-01-01',
        };

        final RaUserProfile profile = RaUserProfile.fromJson(json);

        expect(profile.user, equals('TestUser'));
        expect(profile.totalPoints, equals(100));
        expect(profile.memberSince, equals('2024-01-01'));
        expect(profile.userPic, isNull);
        expect(profile.richPresenceMsg, isNull);
        expect(profile.totalTruePoints, equals(0));
      });

      test('should handle null values with defaults', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'User': null,
          'TotalPoints': null,
          'MemberSince': null,
          'TotalTruePoints': null,
        };

        final RaUserProfile profile = RaUserProfile.fromJson(json);

        expect(profile.user, equals(''));
        expect(profile.totalPoints, equals(0));
        expect(profile.memberSince, equals(''));
        expect(profile.totalTruePoints, equals(0));
      });

      test('should handle empty JSON', () {
        final RaUserProfile profile =
            RaUserProfile.fromJson(const <String, dynamic>{});

        expect(profile.user, equals(''));
        expect(profile.totalPoints, equals(0));
        expect(profile.memberSince, equals(''));
        expect(profile.userPic, isNull);
        expect(profile.richPresenceMsg, isNull);
        expect(profile.totalTruePoints, equals(0));
      });
    });

    group('userPicUrl', () {
      test('should return full URL when userPic is set', () {
        final RaUserProfile profile = createTestRaUserProfile(
          userPic: '/UserPic/TestUser.png',
        );

        expect(
          profile.userPicUrl,
          equals('https://retroachievements.org/UserPic/TestUser.png'),
        );
      });

      test('should return null when userPic is null', () {
        final RaUserProfile profile = createTestRaUserProfile();

        expect(profile.userPicUrl, isNull);
      });
    });
  });
}
