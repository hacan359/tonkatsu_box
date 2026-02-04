import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/search/providers/game_search_provider.dart';
import 'package:xerabora/shared/models/game.dart';

void main() {
  group('GameSearchState', () {
    test('creates default state', () {
      const GameSearchState state = GameSearchState();

      expect(state.query, isEmpty);
      expect(state.results, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.selectedPlatformIds, isEmpty);
    });

    test('hasResults returns true when results is not empty', () {
      const GameSearchState state = GameSearchState(
        results: <Game>[Game(id: 1, name: 'Test')],
      );

      expect(state.hasResults, isTrue);
    });

    test('hasResults returns false when results is empty', () {
      const GameSearchState state = GameSearchState();

      expect(state.hasResults, isFalse);
    });

    test('isEmpty returns true for default state', () {
      const GameSearchState state = GameSearchState();

      expect(state.isEmpty, isTrue);
    });

    test('isEmpty returns false when query is not empty', () {
      const GameSearchState state = GameSearchState(query: 'test');

      expect(state.isEmpty, isFalse);
    });

    test('isEmpty returns false when results is not empty', () {
      const GameSearchState state = GameSearchState(
        results: <Game>[Game(id: 1, name: 'Test')],
      );

      expect(state.isEmpty, isFalse);
    });

    test('isEmpty returns false when loading', () {
      const GameSearchState state = GameSearchState(isLoading: true);

      expect(state.isEmpty, isFalse);
    });

    test('hasPlatformFilter returns true when platforms are selected', () {
      const GameSearchState state = GameSearchState(
        selectedPlatformIds: <int>[130, 48],
      );

      expect(state.hasPlatformFilter, isTrue);
    });

    test('hasPlatformFilter returns false when no platforms selected', () {
      const GameSearchState state = GameSearchState();

      expect(state.hasPlatformFilter, isFalse);
    });

    group('copyWith', () {
      test('updates specified fields', () {
        const GameSearchState original = GameSearchState();
        final GameSearchState updated = original.copyWith(
          query: 'test query',
          isLoading: true,
          selectedPlatformIds: <int>[130, 48],
        );

        expect(updated.query, 'test query');
        expect(updated.isLoading, isTrue);
        expect(updated.selectedPlatformIds, <int>[130, 48]);
      });

      test('preserves unspecified fields', () {
        const GameSearchState original = GameSearchState(
          query: 'original',
          results: <Game>[Game(id: 1, name: 'Game')],
          selectedPlatformIds: <int>[100],
        );

        final GameSearchState updated = original.copyWith(isLoading: true);

        expect(updated.query, 'original');
        expect(updated.results, hasLength(1));
        expect(updated.selectedPlatformIds, <int>[100]);
        expect(updated.isLoading, isTrue);
      });

      test('clears error when clearError is true', () {
        const GameSearchState original = GameSearchState(
          error: 'Some error',
        );

        final GameSearchState updated = original.copyWith(clearError: true);

        expect(updated.error, isNull);
      });

      test('does not clear error when clearError is false', () {
        const GameSearchState original = GameSearchState(
          error: 'Some error',
        );

        final GameSearchState updated = original.copyWith();

        expect(updated.error, 'Some error');
      });

      test('updates results', () {
        const GameSearchState original = GameSearchState();
        const List<Game> newResults = <Game>[
          Game(id: 1, name: 'Game 1'),
          Game(id: 2, name: 'Game 2'),
        ];

        final GameSearchState updated = original.copyWith(results: newResults);

        expect(updated.results, hasLength(2));
        expect(updated.results[0].name, 'Game 1');
        expect(updated.results[1].name, 'Game 2');
      });

      test('updates error', () {
        const GameSearchState original = GameSearchState();

        final GameSearchState updated =
            original.copyWith(error: 'Network error');

        expect(updated.error, 'Network error');
      });

      test('updates selectedPlatformIds', () {
        const GameSearchState original = GameSearchState();

        final GameSearchState updated = original.copyWith(
          selectedPlatformIds: <int>[1, 2, 3],
        );

        expect(updated.selectedPlatformIds, <int>[1, 2, 3]);
      });

      test('clears selectedPlatformIds with empty list', () {
        const GameSearchState original = GameSearchState(
          selectedPlatformIds: <int>[1, 2, 3],
        );

        final GameSearchState updated = original.copyWith(
          selectedPlatformIds: <int>[],
        );

        expect(updated.selectedPlatformIds, isEmpty);
      });
    });

    group('equality', () {
      test('states with same values are equal', () {
        const GameSearchState state1 = GameSearchState(
          query: 'test',
          results: <Game>[Game(id: 1, name: 'Game')],
          selectedPlatformIds: <int>[130],
        );
        const GameSearchState state2 = GameSearchState(
          query: 'test',
          results: <Game>[Game(id: 1, name: 'Game')],
          selectedPlatformIds: <int>[130],
        );

        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
      });

      test('states with different selectedPlatformIds are not equal', () {
        const GameSearchState state1 = GameSearchState(
          selectedPlatformIds: <int>[130],
        );
        const GameSearchState state2 = GameSearchState(
          selectedPlatformIds: <int>[48],
        );

        expect(state1, isNot(equals(state2)));
      });

      test('states with different platform list order are not equal', () {
        const GameSearchState state1 = GameSearchState(
          selectedPlatformIds: <int>[130, 48],
        );
        const GameSearchState state2 = GameSearchState(
          selectedPlatformIds: <int>[48, 130],
        );

        // listEquals compares order too
        expect(listEquals(state1.selectedPlatformIds, state2.selectedPlatformIds), isFalse);
        expect(state1, isNot(equals(state2)));
      });
    });
  });
}
