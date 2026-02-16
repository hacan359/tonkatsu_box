import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/search/models/media_search_item.dart';
import 'package:xerabora/features/search/models/tv_sub_filter.dart';
import 'package:xerabora/features/search/providers/media_search_provider.dart';
import 'package:xerabora/shared/models/movie.dart';
import 'package:xerabora/shared/models/search_sort.dart';
import 'package:xerabora/shared/models/tv_show.dart';

void main() {
  group('MediaSearchState', () {
    test('creates default state', () {
      const MediaSearchState state = MediaSearchState();

      expect(state.query, isEmpty);
      expect(state.items, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.isLoadingMore, isFalse);
      expect(state.error, isNull);
      expect(state.subFilter, TvSubFilter.all);
      expect(state.currentSort, const SearchSort());
      expect(state.currentMoviePage, 1);
      expect(state.currentTvPage, 1);
      expect(state.hasMoreMovies, isFalse);
      expect(state.hasMoreTvShows, isFalse);
    });

    group('hasMore', () {
      test('returns false when no more of either', () {
        const MediaSearchState state = MediaSearchState();
        expect(state.hasMore, isFalse);
      });

      test('returns true when hasMoreMovies is true', () {
        const MediaSearchState state = MediaSearchState(
          hasMoreMovies: true,
        );
        expect(state.hasMore, isTrue);
      });

      test('returns true when hasMoreTvShows is true', () {
        const MediaSearchState state = MediaSearchState(
          hasMoreTvShows: true,
        );
        expect(state.hasMore, isTrue);
      });

      test('returns true when both have more', () {
        const MediaSearchState state = MediaSearchState(
          hasMoreMovies: true,
          hasMoreTvShows: true,
        );
        expect(state.hasMore, isTrue);
      });
    });

    group('hasResults', () {
      test('returns true when items is not empty', () {
        const MediaSearchState state = MediaSearchState(
          items: <MediaSearchItem>[
            MediaSearchItem.fromMovie(
              Movie(tmdbId: 1, title: 'Test Movie'),
            ),
          ],
        );

        expect(state.hasResults, isTrue);
      });

      test('returns false when items is empty', () {
        const MediaSearchState state = MediaSearchState();
        expect(state.hasResults, isFalse);
      });
    });

    group('isEmpty', () {
      test('returns true for default state', () {
        const MediaSearchState state = MediaSearchState();
        expect(state.isEmpty, isTrue);
      });

      test('returns false when query is not empty', () {
        const MediaSearchState state = MediaSearchState(query: 'test');
        expect(state.isEmpty, isFalse);
      });

      test('returns false when items is not empty', () {
        const MediaSearchState state = MediaSearchState(
          items: <MediaSearchItem>[
            MediaSearchItem.fromMovie(
              Movie(tmdbId: 1, title: 'Test'),
            ),
          ],
        );
        expect(state.isEmpty, isFalse);
      });

      test('returns false when loading', () {
        const MediaSearchState state = MediaSearchState(isLoading: true);
        expect(state.isEmpty, isFalse);
      });
    });

    group('copyWith', () {
      test('updates specified fields', () {
        const MediaSearchState original = MediaSearchState();
        final MediaSearchState updated = original.copyWith(
          query: 'test query',
          isLoading: true,
          subFilter: TvSubFilter.movies,
        );

        expect(updated.query, 'test query');
        expect(updated.isLoading, isTrue);
        expect(updated.subFilter, TvSubFilter.movies);
      });

      test('preserves unspecified fields', () {
        const MediaSearchState original = MediaSearchState(
          query: 'original',
          items: <MediaSearchItem>[
            MediaSearchItem.fromMovie(
              Movie(tmdbId: 1, title: 'Movie'),
            ),
          ],
          subFilter: TvSubFilter.animation,
        );

        final MediaSearchState updated = original.copyWith(isLoading: true);

        expect(updated.query, 'original');
        expect(updated.items, hasLength(1));
        expect(updated.subFilter, TvSubFilter.animation);
        expect(updated.isLoading, isTrue);
      });

      test('clears error when clearError is true', () {
        const MediaSearchState original = MediaSearchState(
          error: 'Some error',
        );

        final MediaSearchState updated = original.copyWith(clearError: true);

        expect(updated.error, isNull);
      });

      test('does not clear error when clearError is false', () {
        const MediaSearchState original = MediaSearchState(
          error: 'Some error',
        );

        final MediaSearchState updated = original.copyWith();

        expect(updated.error, 'Some error');
      });

      test('updates items', () {
        const MediaSearchState original = MediaSearchState();
        const List<MediaSearchItem> newItems = <MediaSearchItem>[
          MediaSearchItem.fromMovie(
            Movie(tmdbId: 1, title: 'Movie 1'),
          ),
          MediaSearchItem.fromTvShow(
            TvShow(tmdbId: 2, title: 'Show 1'),
          ),
        ];

        final MediaSearchState updated = original.copyWith(items: newItems);

        expect(updated.items, hasLength(2));
        expect(updated.items[0].title, 'Movie 1');
        expect(updated.items[1].title, 'Show 1');
      });

      test('updates error', () {
        const MediaSearchState original = MediaSearchState();

        final MediaSearchState updated =
            original.copyWith(error: 'Network error');

        expect(updated.error, 'Network error');
      });

      test('updates subFilter', () {
        const MediaSearchState original = MediaSearchState();

        final MediaSearchState updated =
            original.copyWith(subFilter: TvSubFilter.tvShows);

        expect(updated.subFilter, TvSubFilter.tvShows);
      });

      test('updates currentSort', () {
        const MediaSearchState original = MediaSearchState();
        const SearchSort newSort = SearchSort(
          field: SearchSortField.rating,
          order: SearchSortOrder.ascending,
        );

        final MediaSearchState updated =
            original.copyWith(currentSort: newSort);

        expect(updated.currentSort.field, SearchSortField.rating);
        expect(updated.currentSort.order, SearchSortOrder.ascending);
      });

      test('preserves currentSort when not specified', () {
        const SearchSort sort = SearchSort(field: SearchSortField.date);
        const MediaSearchState original = MediaSearchState(currentSort: sort);

        final MediaSearchState updated = original.copyWith(query: 'test');

        expect(updated.currentSort, sort);
      });

      test('updates isLoadingMore', () {
        const MediaSearchState original = MediaSearchState();

        final MediaSearchState updated =
            original.copyWith(isLoadingMore: true);

        expect(updated.isLoadingMore, isTrue);
      });

      test('updates pagination fields', () {
        const MediaSearchState original = MediaSearchState();

        final MediaSearchState updated = original.copyWith(
          currentMoviePage: 3,
          currentTvPage: 5,
          hasMoreMovies: true,
          hasMoreTvShows: false,
        );

        expect(updated.currentMoviePage, 3);
        expect(updated.currentTvPage, 5);
        expect(updated.hasMoreMovies, isTrue);
        expect(updated.hasMoreTvShows, isFalse);
      });

      test('preserves pagination fields when not specified', () {
        const MediaSearchState original = MediaSearchState(
          currentMoviePage: 2,
          currentTvPage: 4,
          hasMoreMovies: true,
          hasMoreTvShows: true,
        );

        final MediaSearchState updated = original.copyWith(query: 'test');

        expect(updated.currentMoviePage, 2);
        expect(updated.currentTvPage, 4);
        expect(updated.hasMoreMovies, isTrue);
        expect(updated.hasMoreTvShows, isTrue);
      });
    });

    group('equality', () {
      test('states with same values are equal', () {
        const MediaSearchState state1 = MediaSearchState(
          query: 'test',
          items: <MediaSearchItem>[
            MediaSearchItem.fromMovie(
              Movie(tmdbId: 1, title: 'Movie'),
            ),
          ],
          subFilter: TvSubFilter.movies,
        );
        const MediaSearchState state2 = MediaSearchState(
          query: 'test',
          items: <MediaSearchItem>[
            MediaSearchItem.fromMovie(
              Movie(tmdbId: 1, title: 'Movie'),
            ),
          ],
          subFilter: TvSubFilter.movies,
        );

        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
      });

      test('states with different queries are not equal', () {
        const MediaSearchState state1 = MediaSearchState(query: 'test1');
        const MediaSearchState state2 = MediaSearchState(query: 'test2');

        expect(state1, isNot(equals(state2)));
      });

      test('states with different subFilter are not equal', () {
        const MediaSearchState state1 = MediaSearchState(
          subFilter: TvSubFilter.movies,
        );
        const MediaSearchState state2 = MediaSearchState(
          subFilter: TvSubFilter.tvShows,
        );

        expect(state1, isNot(equals(state2)));
      });

      test('states with different items are not equal', () {
        const MediaSearchState state1 = MediaSearchState(
          items: <MediaSearchItem>[
            MediaSearchItem.fromMovie(
              Movie(tmdbId: 1, title: 'Movie 1'),
            ),
          ],
        );
        const MediaSearchState state2 = MediaSearchState(
          items: <MediaSearchItem>[
            MediaSearchItem.fromMovie(
              Movie(tmdbId: 2, title: 'Movie 2'),
            ),
          ],
        );

        expect(state1, isNot(equals(state2)));
      });

      test('states with different isLoading are not equal', () {
        const MediaSearchState state1 = MediaSearchState(isLoading: true);
        const MediaSearchState state2 = MediaSearchState(isLoading: false);

        expect(state1, isNot(equals(state2)));
      });

      test('states with different isLoadingMore are not equal', () {
        const MediaSearchState state1 = MediaSearchState(isLoadingMore: true);
        const MediaSearchState state2 = MediaSearchState(isLoadingMore: false);

        expect(state1, isNot(equals(state2)));
      });

      test('states with different error are not equal', () {
        const MediaSearchState state1 = MediaSearchState(error: 'error1');
        const MediaSearchState state2 = MediaSearchState(error: 'error2');

        expect(state1, isNot(equals(state2)));
      });

      test('uses listEquals for items comparison', () {
        const MediaSearchState state1 = MediaSearchState(
          items: <MediaSearchItem>[
            MediaSearchItem.fromMovie(
              Movie(tmdbId: 1, title: 'A'),
            ),
            MediaSearchItem.fromTvShow(
              TvShow(tmdbId: 2, title: 'B'),
            ),
          ],
        );
        const MediaSearchState state2 = MediaSearchState(
          items: <MediaSearchItem>[
            MediaSearchItem.fromTvShow(
              TvShow(tmdbId: 2, title: 'B'),
            ),
            MediaSearchItem.fromMovie(
              Movie(tmdbId: 1, title: 'A'),
            ),
          ],
        );

        // Different order means not equal (listEquals checks order)
        expect(
          listEquals(state1.items, state2.items),
          isFalse,
        );
        expect(state1, isNot(equals(state2)));
      });

      test('states with different currentSort are not equal', () {
        const MediaSearchState state1 = MediaSearchState(
          currentSort: SearchSort(field: SearchSortField.date),
        );
        const MediaSearchState state2 = MediaSearchState(
          currentSort: SearchSort(field: SearchSortField.rating),
        );

        expect(state1, isNot(equals(state2)));
      });

      test('states with same currentSort are equal', () {
        const MediaSearchState state1 = MediaSearchState(
          currentSort: SearchSort(field: SearchSortField.date),
        );
        const MediaSearchState state2 = MediaSearchState(
          currentSort: SearchSort(field: SearchSortField.date),
        );

        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
      });

      test('states with different pagination fields are not equal', () {
        const MediaSearchState state1 = MediaSearchState(
          currentMoviePage: 1,
          currentTvPage: 1,
        );
        const MediaSearchState state2 = MediaSearchState(
          currentMoviePage: 2,
          currentTvPage: 3,
        );

        expect(state1, isNot(equals(state2)));
      });

      test('states with different hasMore flags are not equal', () {
        const MediaSearchState state1 = MediaSearchState(
          hasMoreMovies: true,
          hasMoreTvShows: false,
        );
        const MediaSearchState state2 = MediaSearchState(
          hasMoreMovies: false,
          hasMoreTvShows: true,
        );

        expect(state1, isNot(equals(state2)));
      });

      test('identical states return true', () {
        const MediaSearchState state = MediaSearchState(query: 'test');
        expect(state == state, isTrue);
      });
    });
  });

  group('animationGenreId', () {
    test('has value 16', () {
      expect(animationGenreId, 16);
    });
  });
}
