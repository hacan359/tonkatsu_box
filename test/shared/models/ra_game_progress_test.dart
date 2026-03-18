// Тесты для RaGameProgress.

import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/models/item_status.dart';
import 'package:xerabora/shared/models/ra_game_progress.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('RaGameProgress', () {
    group('constructor', () {
      test('should create with required fields', () {
        final RaGameProgress progress = createTestRaGameProgress();

        expect(progress.gameId, equals(1234));
        expect(progress.title, equals('Super Mario World'));
        expect(progress.consoleName, equals('SNES'));
        expect(progress.consoleId, equals(3));
        expect(progress.numAwarded, equals(50));
        expect(progress.maxPossible, equals(96));
        expect(progress.hardcoreMode, isTrue);
        expect(progress.highestAwardKind, isNull);
        expect(progress.lastPlayedAt, isNull);
      });

      test('should create with all fields', () {
        final DateTime lastPlayed = DateTime(2024, 6, 15);
        final RaGameProgress progress = createTestRaGameProgress(
          gameId: 5678,
          title: 'Chrono Trigger',
          consoleName: 'SNES',
          consoleId: 3,
          numAwarded: 40,
          maxPossible: 40,
          hardcoreMode: true,
          highestAwardKind: 'mastered-hardcore',
          lastPlayedAt: lastPlayed,
        );

        expect(progress.gameId, equals(5678));
        expect(progress.title, equals('Chrono Trigger'));
        expect(progress.highestAwardKind, equals('mastered-hardcore'));
        expect(progress.lastPlayedAt, equals(lastPlayed));
      });
    });

    group('fromJson', () {
      test('should parse full JSON response', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'GameID': 1234,
          'Title': 'Super Mario World',
          'ConsoleName': 'SNES',
          'ConsoleID': 3,
          'NumAwardedHardcore': 50,
          'NumAwarded': 30,
          'MaxPossible': 96,
          'HighestAwardKind': 'beaten-hardcore',
          'MostRecentAwardedDate': '2024-06-15T12:00:00Z',
        };

        final RaGameProgress progress = RaGameProgress.fromJson(json);

        expect(progress.gameId, equals(1234));
        expect(progress.title, equals('Super Mario World'));
        expect(progress.consoleName, equals('SNES'));
        expect(progress.consoleId, equals(3));
        // Приоритет: NumAwardedHardcore > NumAwarded.
        expect(progress.numAwarded, equals(50));
        expect(progress.maxPossible, equals(96));
        expect(progress.hardcoreMode, isTrue);
        expect(progress.highestAwardKind, equals('beaten-hardcore'));
        expect(progress.lastPlayedAt, isNotNull);
      });

      test('should fallback to NumAwarded when NumAwardedHardcore is null',
          () {
        final Map<String, dynamic> json = <String, dynamic>{
          'GameID': 1234,
          'Title': 'Test Game',
          'ConsoleName': 'NES',
          'ConsoleID': 7,
          'NumAwarded': 10,
          'MaxPossible': 20,
        };

        final RaGameProgress progress = RaGameProgress.fromJson(json);

        expect(progress.numAwarded, equals(10));
        expect(progress.hardcoreMode, isFalse);
      });

      test('should handle missing optional fields', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'GameID': 100,
          'Title': 'Test',
          'ConsoleName': 'GB',
          'ConsoleID': 4,
          'MaxPossible': 10,
        };

        final RaGameProgress progress = RaGameProgress.fromJson(json);

        expect(progress.numAwarded, equals(0));
        expect(progress.hardcoreMode, isFalse);
        expect(progress.highestAwardKind, isNull);
        expect(progress.lastPlayedAt, isNull);
      });

      test('should handle null values with defaults', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'GameID': null,
          'Title': null,
          'ConsoleName': null,
          'ConsoleID': null,
          'NumAwardedHardcore': null,
          'NumAwarded': null,
          'MaxPossible': null,
        };

        final RaGameProgress progress = RaGameProgress.fromJson(json);

        expect(progress.gameId, equals(0));
        expect(progress.title, equals(''));
        expect(progress.consoleName, equals(''));
        expect(progress.consoleId, equals(0));
        expect(progress.numAwarded, equals(0));
        expect(progress.maxPossible, equals(0));
        expect(progress.hardcoreMode, isFalse);
      });

      test('should handle empty JSON', () {
        final RaGameProgress progress =
            RaGameProgress.fromJson(const <String, dynamic>{});

        expect(progress.gameId, equals(0));
        expect(progress.title, equals(''));
        expect(progress.maxPossible, equals(0));
      });

      test('should parse invalid date string as null', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'GameID': 1,
          'Title': 'Test',
          'ConsoleName': 'NES',
          'ConsoleID': 7,
          'MaxPossible': 5,
          'MostRecentAwardedDate': 'not-a-date',
        };

        final RaGameProgress progress = RaGameProgress.fromJson(json);

        expect(progress.lastPlayedAt, isNull);
      });
    });

    group('completionRate', () {
      test('should calculate correct rate', () {
        final RaGameProgress progress = createTestRaGameProgress(
          numAwarded: 50,
          maxPossible: 100,
        );

        expect(progress.completionRate, closeTo(0.5, 0.001));
      });

      test('should return 0.0 when maxPossible is 0', () {
        final RaGameProgress progress = createTestRaGameProgress(
          numAwarded: 0,
          maxPossible: 0,
        );

        expect(progress.completionRate, equals(0.0));
      });

      test('should return 1.0 when all awarded', () {
        final RaGameProgress progress = createTestRaGameProgress(
          numAwarded: 96,
          maxPossible: 96,
        );

        expect(progress.completionRate, closeTo(1.0, 0.001));
      });
    });

    group('itemStatus', () {
      test('should return completed when highestAwardKind starts with mastered',
          () {
        final RaGameProgress progress = createTestRaGameProgress(
          highestAwardKind: 'mastered-hardcore',
          numAwarded: 96,
        );

        expect(progress.itemStatus, equals(ItemStatus.completed));
      });

      test(
          'should return completed when highestAwardKind starts with completed',
          () {
        final RaGameProgress progress = createTestRaGameProgress(
          highestAwardKind: 'completed-hardcore',
          numAwarded: 50,
        );

        expect(progress.itemStatus, equals(ItemStatus.completed));
      });

      test('should return completed when highestAwardKind starts with beaten',
          () {
        final RaGameProgress progress = createTestRaGameProgress(
          highestAwardKind: 'beaten-softcore',
          numAwarded: 30,
        );

        expect(progress.itemStatus, equals(ItemStatus.completed));
      });

      test('should return inProgress when numAwarded > 0 and no award', () {
        final RaGameProgress progress = createTestRaGameProgress(
          highestAwardKind: null,
          numAwarded: 10,
        );

        expect(progress.itemStatus, equals(ItemStatus.inProgress));
      });

      test('should return planned when numAwarded is 0 and no award', () {
        final RaGameProgress progress = createTestRaGameProgress(
          highestAwardKind: null,
          numAwarded: 0,
        );

        expect(progress.itemStatus, equals(ItemStatus.planned));
      });

      test(
          'should return inProgress when award is unrecognized but has achievements',
          () {
        final RaGameProgress progress = createTestRaGameProgress(
          highestAwardKind: 'some-other-award',
          numAwarded: 5,
        );

        expect(progress.itemStatus, equals(ItemStatus.inProgress));
      });

      test(
          'should return planned when award is unrecognized and no achievements',
          () {
        final RaGameProgress progress = createTestRaGameProgress(
          highestAwardKind: 'some-other-award',
          numAwarded: 0,
        );

        expect(progress.itemStatus, equals(ItemStatus.planned));
      });
    });
  });
}
