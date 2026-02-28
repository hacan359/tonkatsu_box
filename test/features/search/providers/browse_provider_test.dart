import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/search/providers/browse_provider.dart';
import 'package:xerabora/features/search/sources/tmdb_movies_source.dart';

void main() {
  group('BrowseSettingsKeys', () {
    test('sourceId constant value', () {
      expect(BrowseSettingsKeys.sourceId, 'browse_source_id');
    });
  });

  group('BrowseState', () {
    group('constructor', () {
      test('creates with default values', () {
        const BrowseState state = BrowseState(sourceId: 'movies');

        expect(state.sourceId, 'movies');
        expect(state.filterValues, isEmpty);
        expect(state.sortBy, isNull);
        expect(state.items, isEmpty);
        expect(state.isLoading, isFalse);
        expect(state.isLoadingMore, isFalse);
        expect(state.currentPage, 1);
        expect(state.hasMore, isFalse);
        expect(state.error, isNull);
        expect(state.isSearchMode, isFalse);
        expect(state.searchQuery, isEmpty);
      });

      test('creates with all fields', () {
        const BrowseState state = BrowseState(
          sourceId: 'games',
          filterValues: <String, Object?>{'genre': 12},
          sortBy: 'rating desc',
          items: <Object>['a', 'b'],
          isLoading: true,
          isLoadingMore: true,
          currentPage: 3,
          hasMore: true,
          error: 'fail',
          isSearchMode: true,
          searchQuery: 'zelda',
        );

        expect(state.sourceId, 'games');
        expect(state.filterValues, <String, Object?>{'genre': 12});
        expect(state.sortBy, 'rating desc');
        expect(state.items, hasLength(2));
        expect(state.isLoading, isTrue);
        expect(state.isLoadingMore, isTrue);
        expect(state.currentPage, 3);
        expect(state.hasMore, isTrue);
        expect(state.error, 'fail');
        expect(state.isSearchMode, isTrue);
        expect(state.searchQuery, 'zelda');
      });
    });

    group('hasFilters', () {
      test('returns false for empty filterValues', () {
        const BrowseState state = BrowseState(sourceId: 'movies');
        expect(state.hasFilters, isFalse);
      });

      test('returns false when all values are null', () {
        const BrowseState state = BrowseState(
          sourceId: 'movies',
          filterValues: <String, Object?>{'genre': null, 'year': null},
        );
        expect(state.hasFilters, isFalse);
      });

      test('returns true when at least one value is not null', () {
        const BrowseState state = BrowseState(
          sourceId: 'movies',
          filterValues: <String, Object?>{'genre': 28, 'year': null},
        );
        expect(state.hasFilters, isTrue);
      });

      test('returns true when all values are not null', () {
        const BrowseState state = BrowseState(
          sourceId: 'movies',
          filterValues: <String, Object?>{'genre': 28, 'year': 2024},
        );
        expect(state.hasFilters, isTrue);
      });
    });

    group('isEmpty', () {
      test('returns true when items empty and not loading', () {
        const BrowseState state = BrowseState(sourceId: 'movies');
        expect(state.isEmpty, isTrue);
      });

      test('returns false when items not empty', () {
        const BrowseState state = BrowseState(
          sourceId: 'movies',
          items: <Object>['item'],
        );
        expect(state.isEmpty, isFalse);
      });

      test('returns false when loading', () {
        const BrowseState state = BrowseState(
          sourceId: 'movies',
          isLoading: true,
        );
        expect(state.isEmpty, isFalse);
      });
    });

    group('source', () {
      test('returns TmdbMoviesSource for "movies"', () {
        const BrowseState state = BrowseState(sourceId: 'movies');
        expect(state.source, isA<TmdbMoviesSource>());
      });

      test('returns default source for unknown id', () {
        const BrowseState state = BrowseState(sourceId: 'unknown');
        // getSearchSourceById returns first source for unknown
        expect(state.source.id, 'movies');
      });
    });

    group('effectiveSortBy', () {
      test('returns sortBy when set', () {
        const BrowseState state = BrowseState(
          sourceId: 'movies',
          sortBy: 'custom_sort',
        );
        expect(state.effectiveSortBy, 'custom_sort');
      });

      test('returns default sort when sortBy is null', () {
        const BrowseState state = BrowseState(sourceId: 'movies');
        // TmdbMoviesSource defaultSort is 'popularity.desc'
        expect(state.effectiveSortBy, 'popularity.desc');
      });
    });

    group('copyWith', () {
      test('copies all fields when specified', () {
        const BrowseState original = BrowseState(sourceId: 'movies');

        final BrowseState copied = original.copyWith(
          sourceId: 'games',
          filterValues: const <String, Object?>{'key': 'val'},
          sortBy: 'rating',
          items: const <Object>['x'],
          isLoading: true,
          isLoadingMore: true,
          currentPage: 5,
          hasMore: true,
          error: 'err',
          isSearchMode: true,
          searchQuery: 'query',
        );

        expect(copied.sourceId, 'games');
        expect(copied.filterValues, <String, Object?>{'key': 'val'});
        expect(copied.sortBy, 'rating');
        expect(copied.items, <Object>['x']);
        expect(copied.isLoading, isTrue);
        expect(copied.isLoadingMore, isTrue);
        expect(copied.currentPage, 5);
        expect(copied.hasMore, isTrue);
        expect(copied.error, 'err');
        expect(copied.isSearchMode, isTrue);
        expect(copied.searchQuery, 'query');
      });

      test('preserves original values when not specified', () {
        const BrowseState original = BrowseState(
          sourceId: 'games',
          sortBy: 'rating',
          isLoading: true,
          currentPage: 3,
          error: 'old error',
        );

        final BrowseState copied = original.copyWith(isLoading: false);

        expect(copied.sourceId, 'games');
        expect(copied.sortBy, 'rating');
        expect(copied.isLoading, isFalse);
        expect(copied.currentPage, 3);
        expect(copied.error, 'old error');
      });

      test('clearError sets error to null', () {
        const BrowseState original = BrowseState(
          sourceId: 'movies',
          error: 'some error',
        );

        final BrowseState copied = original.copyWith(clearError: true);

        expect(copied.error, isNull);
      });

      test('clearError does not clear when false', () {
        const BrowseState original = BrowseState(
          sourceId: 'movies',
          error: 'some error',
        );

        final BrowseState copied = original.copyWith(clearError: false);

        expect(copied.error, 'some error');
      });

      test('clearSortBy sets sortBy to null', () {
        const BrowseState original = BrowseState(
          sourceId: 'movies',
          sortBy: 'custom',
        );

        final BrowseState copied = original.copyWith(clearSortBy: true);

        expect(copied.sortBy, isNull);
      });

      test('clearSortBy does not clear when false', () {
        const BrowseState original = BrowseState(
          sourceId: 'movies',
          sortBy: 'custom',
        );

        final BrowseState copied = original.copyWith(clearSortBy: false);

        expect(copied.sortBy, 'custom');
      });

      test('new error overrides when clearError is false', () {
        const BrowseState original = BrowseState(
          sourceId: 'movies',
          error: 'old',
        );

        final BrowseState copied =
            original.copyWith(error: 'new', clearError: false);

        expect(copied.error, 'new');
      });

      test('new sortBy overrides when clearSortBy is false', () {
        const BrowseState original = BrowseState(
          sourceId: 'movies',
          sortBy: 'old',
        );

        final BrowseState copied =
            original.copyWith(sortBy: 'new', clearSortBy: false);

        expect(copied.sortBy, 'new');
      });

      test('clearSortBy takes precedence over sortBy', () {
        const BrowseState original = BrowseState(
          sourceId: 'movies',
          sortBy: 'old',
        );

        final BrowseState copied =
            original.copyWith(sortBy: 'new', clearSortBy: true);

        expect(copied.sortBy, isNull);
      });

      test('clearError takes precedence over error', () {
        const BrowseState original = BrowseState(
          sourceId: 'movies',
          error: 'old',
        );

        final BrowseState copied =
            original.copyWith(error: 'new', clearError: true);

        expect(copied.error, isNull);
      });
    });
  });
}
