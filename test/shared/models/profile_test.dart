import 'dart:convert';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/models/profile.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('Profile', () {
    group('fromJson', () {
      test('should parse all fields correctly', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 'abc123',
          'name': 'Player One',
          'color': '#FF4444',
          'createdAt': '2024-06-15T10:30:00.000',
        };

        final Profile profile = Profile.fromJson(json);

        expect(profile.id, 'abc123');
        expect(profile.name, 'Player One');
        expect(profile.color, '#FF4444');
        expect(profile.createdAt, DateTime(2024, 6, 15, 10, 30));
      });
    });

    group('toJson', () {
      test('should serialize all fields correctly', () {
        final Profile profile = createTestProfile(
          id: 'xyz',
          name: 'Test',
          color: '#00FF00',
        );

        final Map<String, dynamic> json = profile.toJson();

        expect(json['id'], 'xyz');
        expect(json['name'], 'Test');
        expect(json['color'], '#00FF00');
        expect(json['createdAt'], profile.createdAt.toIso8601String());
      });
    });

    group('fromJson → toJson roundtrip', () {
      test('should produce identical JSON after roundtrip', () {
        final Map<String, dynamic> original = <String, dynamic>{
          'id': 'roundtrip',
          'name': 'Roundtrip User',
          'color': '#ABCDEF',
          'createdAt': '2024-03-01T12:00:00.000',
        };

        final Profile profile = Profile.fromJson(original);
        final Map<String, dynamic> result = profile.toJson();

        expect(result['id'], original['id']);
        expect(result['name'], original['name']);
        expect(result['color'], original['color']);
        expect(result['createdAt'], original['createdAt']);
      });
    });

    group('colorValue', () {
      test('should convert hex with hash to Color', () {
        final Profile profile = createTestProfile(color: '#EF7B44');
        expect(profile.colorValue, const Color(0xFFEF7B44));
      });

      test('should handle lowercase hex', () {
        final Profile profile = createTestProfile(color: '#abcdef');
        expect(profile.colorValue, const Color(0xFFABCDEF));
      });
    });

    group('hexToColor', () {
      test('should convert hex with hash prefix', () {
        expect(Profile.hexToColor('#FF0000'), const Color(0xFFFF0000));
      });

      test('should convert hex without hash prefix', () {
        expect(Profile.hexToColor('00FF00'), const Color(0xFF00FF00));
      });
    });

    group('folderName', () {
      test('should return id as folder name', () {
        final Profile profile = createTestProfile(id: 'my-id');
        expect(profile.folderName, 'my-id');
      });
    });

    group('copyWith', () {
      test('should copy with changed name', () {
        final Profile original = createTestProfile(name: 'Old');
        final Profile copy = original.copyWith(name: 'New');

        expect(copy.name, 'New');
        expect(copy.id, original.id);
        expect(copy.color, original.color);
        expect(copy.createdAt, original.createdAt);
      });

      test('should copy with changed color', () {
        final Profile original = createTestProfile(color: '#111111');
        final Profile copy = original.copyWith(color: '#222222');

        expect(copy.color, '#222222');
        expect(copy.name, original.name);
      });

      test('should keep original values when no args provided', () {
        final Profile original = createTestProfile();
        final Profile copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.name, original.name);
        expect(copy.color, original.color);
        expect(copy.createdAt, original.createdAt);
      });
    });
  });

  group('ProfilesData', () {
    group('fromJson', () {
      test('should parse version, currentProfileId and profiles', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'version': 1,
          'currentProfileId': 'p1',
          'profiles': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'p1',
              'name': 'Player 1',
              'color': '#FF0000',
              'createdAt': '2024-01-01T00:00:00.000',
            },
            <String, dynamic>{
              'id': 'p2',
              'name': 'Player 2',
              'color': '#00FF00',
              'createdAt': '2024-02-01T00:00:00.000',
            },
          ],
        };

        final ProfilesData data = ProfilesData.fromJson(json);

        expect(data.version, 1);
        expect(data.currentProfileId, 'p1');
        expect(data.profiles.length, 2);
        expect(data.profiles[0].name, 'Player 1');
        expect(data.profiles[1].name, 'Player 2');
      });
    });

    group('fromJsonString', () {
      test('should parse JSON string', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'version': 1,
          'currentProfileId': 'default',
          'profiles': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'default',
              'name': 'Default',
              'color': '#EF7B44',
              'createdAt': '2024-01-01T00:00:00.000',
            },
          ],
        };
        final String jsonString = jsonEncode(json);

        final ProfilesData data = ProfilesData.fromJsonString(jsonString);

        expect(data.version, 1);
        expect(data.profiles.length, 1);
        expect(data.profiles.first.id, 'default');
      });
    });

    group('defaultData', () {
      test('should create with default profile', () {
        final ProfilesData data = ProfilesData.defaultData();

        expect(data.version, 1);
        expect(data.currentProfileId, 'default');
        expect(data.profiles.length, 1);
        expect(data.profiles.first.id, 'default');
        expect(data.profiles.first.name, 'Default');
        expect(data.profiles.first.color, '#EF7B44');
      });

      test('should use custom author name', () {
        final ProfilesData data =
            ProfilesData.defaultData(authorName: 'Alice');

        expect(data.profiles.first.name, 'Alice');
      });
    });

    group('currentProfile', () {
      test('should return profile matching currentProfileId', () {
        final ProfilesData data = createTestProfilesData(
          currentProfileId: 'p2',
          profiles: <Profile>[
            createTestProfile(id: 'p1', name: 'One'),
            createTestProfile(id: 'p2', name: 'Two'),
          ],
        );

        expect(data.currentProfile.name, 'Two');
      });

      test('should fallback to first profile when currentProfileId not found', () {
        final ProfilesData data = createTestProfilesData(
          currentProfileId: 'nonexistent',
        );

        expect(data.currentProfile.id, 'test-profile');
      });
    });

    group('toJson', () {
      test('should serialize all fields', () {
        final ProfilesData data = createTestProfilesData();
        final Map<String, dynamic> json = data.toJson();

        expect(json['version'], data.version);
        expect(json['currentProfileId'], data.currentProfileId);
        expect((json['profiles'] as List<dynamic>).length, 1);
      });
    });

    group('toJsonString', () {
      test('should produce valid JSON string with indentation', () {
        final ProfilesData data = createTestProfilesData();
        final String jsonString = data.toJsonString();

        // Should be valid JSON
        final Map<String, dynamic> parsed =
            jsonDecode(jsonString) as Map<String, dynamic>;
        expect(parsed['version'], data.version);

        // Should contain indentation
        expect(jsonString.contains('  '), isTrue);
      });
    });

    group('fromJsonString → toJsonString roundtrip', () {
      test('should preserve data through roundtrip', () {
        final ProfilesData original = createTestProfilesData(
          profiles: <Profile>[
            createTestProfile(id: 'a', name: 'Alpha'),
            createTestProfile(id: 'b', name: 'Beta'),
          ],
          currentProfileId: 'a',
        );

        final String jsonString = original.toJsonString();
        final ProfilesData restored =
            ProfilesData.fromJsonString(jsonString);

        expect(restored.version, original.version);
        expect(restored.currentProfileId, original.currentProfileId);
        expect(restored.profiles.length, original.profiles.length);
        expect(restored.profiles[0].name, 'Alpha');
        expect(restored.profiles[1].name, 'Beta');
      });
    });

    group('copyWith', () {
      test('should copy with changed currentProfileId', () {
        final ProfilesData original =
            createTestProfilesData(currentProfileId: 'old');
        final ProfilesData copy =
            original.copyWith(currentProfileId: 'new');

        expect(copy.currentProfileId, 'new');
        expect(copy.profiles, original.profiles);
        expect(copy.version, original.version);
      });

      test('should copy with changed profiles list', () {
        final ProfilesData original = createTestProfilesData();
        final List<Profile> newProfiles = <Profile>[
          createTestProfile(id: 'x', name: 'X'),
        ];
        final ProfilesData copy =
            original.copyWith(profiles: newProfiles);

        expect(copy.profiles.length, 1);
        expect(copy.profiles.first.name, 'X');
        expect(copy.currentProfileId, original.currentProfileId);
      });

      test('should keep original values when no args provided', () {
        final ProfilesData original = createTestProfilesData();
        final ProfilesData copy = original.copyWith();

        expect(copy.version, original.version);
        expect(copy.currentProfileId, original.currentProfileId);
        expect(copy.profiles, original.profiles);
      });
    });
  });

  group('ProfileStats', () {
    test('should store collectionsCount and itemsCount', () {
      final ProfileStats stats = createTestProfileStats(
        collectionsCount: 5,
        itemsCount: 42,
      );

      expect(stats.collectionsCount, 5);
      expect(stats.itemsCount, 42);
    });

    test('empty should have zero counts', () {
      expect(ProfileStats.empty.collectionsCount, 0);
      expect(ProfileStats.empty.itemsCount, 0);
    });
  });

  group('ProfileColors', () {
    test('should have 18 predefined colors', () {
      expect(ProfileColors.values.length, 18);
    });

    test('all colors should start with hash', () {
      for (final String color in ProfileColors.values) {
        expect(color.startsWith('#'), isTrue, reason: '$color should start with #');
      }
    });

    test('all colors should be valid 6-digit hex', () {
      for (final String color in ProfileColors.values) {
        final String hex = color.substring(1);
        expect(hex.length, 6, reason: '$color should be 6-digit hex');
        expect(
          int.tryParse(hex, radix: 16),
          isNotNull,
          reason: '$color should be valid hex',
        );
      }
    });

    test('first color should be brand orange', () {
      expect(ProfileColors.values.first, '#EF7B44');
    });
  });
}
