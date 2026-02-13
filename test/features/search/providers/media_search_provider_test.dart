import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/search/providers/media_search_provider.dart';
import 'package:xerabora/shared/models/movie.dart';
import 'package:xerabora/shared/models/search_sort.dart';
import 'package:xerabora/shared/models/tv_show.dart';

void main() {
  group('MediaSearchTab', () {
    test('has movies, tvShows and animation values', () {
      expect(MediaSearchTab.values, hasLength(3));
      expect(MediaSearchTab.movies, isNotNull);
      expect(MediaSearchTab.tvShows, isNotNull);
      expect(MediaSearchTab.animation, isNotNull);
    });
  });

  group('MediaSearchState', () {
    test('creates default state', () {
      const MediaSearchState state = MediaSearchState();

      expect(state.query, isEmpty);
      expect(state.movieResults, isEmpty);
      expect(state.tvShowResults, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.activeTab, MediaSearchTab.movies);
      expect(state.currentSort, const SearchSort());
      expect(state.selectedYear, isNull);
      expect(state.selectedGenreIds, isEmpty);
    });

    group('hasFilters', () {
      test('returns false for default state', () {
        const MediaSearchState state = MediaSearchState();
        expect(state.hasFilters, isFalse);
      });

      test('returns true when year is set', () {
        const MediaSearchState state = MediaSearchState(selectedYear: 2024);
        expect(state.hasFilters, isTrue);
      });

      test('returns true when genres are set', () {
        const MediaSearchState state = MediaSearchState(
          selectedGenreIds: <int>[28, 12],
        );
        expect(state.hasFilters, isTrue);
      });

      test('returns true when both year and genres are set', () {
        const MediaSearchState state = MediaSearchState(
          selectedYear: 2024,
          selectedGenreIds: <int>[28],
        );
        expect(state.hasFilters, isTrue);
      });
    });

    group('hasResults', () {
      test('returns true when movies tab has results', () {
        const MediaSearchState state = MediaSearchState(
          activeTab: MediaSearchTab.movies,
          movieResults: <Movie>[
            Movie(tmdbId: 1, title: 'Test Movie'),
          ],
        );

        expect(state.hasResults, isTrue);
      });

      test('returns true when tvShows tab has results', () {
        const MediaSearchState state = MediaSearchState(
          activeTab: MediaSearchTab.tvShows,
          tvShowResults: <TvShow>[
            TvShow(tmdbId: 1, title: 'Test Show'),
          ],
        );

        expect(state.hasResults, isTrue);
      });

      test('returns false when movies tab has no results', () {
        const MediaSearchState state = MediaSearchState(
          activeTab: MediaSearchTab.movies,
          movieResults: <Movie>[],
        );

        expect(state.hasResults, isFalse);
      });

      test('returns false when tvShows tab has no results', () {
        const MediaSearchState state = MediaSearchState(
          activeTab: MediaSearchTab.tvShows,
          tvShowResults: <TvShow>[],
        );

        expect(state.hasResults, isFalse);
      });

      test('returns false for movies tab even if tvShows has results', () {
        const MediaSearchState state = MediaSearchState(
          activeTab: MediaSearchTab.movies,
          movieResults: <Movie>[],
          tvShowResults: <TvShow>[
            TvShow(tmdbId: 1, title: 'Test Show'),
          ],
        );

        expect(state.hasResults, isFalse);
      });

      test('returns false for tvShows tab even if movies has results', () {
        const MediaSearchState state = MediaSearchState(
          activeTab: MediaSearchTab.tvShows,
          movieResults: <Movie>[
            Movie(tmdbId: 1, title: 'Test Movie'),
          ],
          tvShowResults: <TvShow>[],
        );

        expect(state.hasResults, isFalse);
      });

      test('returns true when animation tab has movie results', () {
        const MediaSearchState state = MediaSearchState(
          activeTab: MediaSearchTab.animation,
          animationMovieResults: <Movie>[
            Movie(tmdbId: 1, title: 'Spirited Away'),
          ],
        );

        expect(state.hasResults, isTrue);
      });

      test('returns true when animation tab has tvShow results', () {
        const MediaSearchState state = MediaSearchState(
          activeTab: MediaSearchTab.animation,
          animationTvShowResults: <TvShow>[
            TvShow(tmdbId: 1, title: 'Attack on Titan'),
          ],
        );

        expect(state.hasResults, isTrue);
      });

      test('returns false when animation tab has no results', () {
        const MediaSearchState state = MediaSearchState(
          activeTab: MediaSearchTab.animation,
          animationMovieResults: <Movie>[],
          animationTvShowResults: <TvShow>[],
        );

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

      test('returns false when movies tab has results', () {
        const MediaSearchState state = MediaSearchState(
          activeTab: MediaSearchTab.movies,
          movieResults: <Movie>[
            Movie(tmdbId: 1, title: 'Test Movie'),
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
          activeTab: MediaSearchTab.tvShows,
        );

        expect(updated.query, 'test query');
        expect(updated.isLoading, isTrue);
        expect(updated.activeTab, MediaSearchTab.tvShows);
      });

      test('preserves unspecified fields', () {
        const MediaSearchState original = MediaSearchState(
          query: 'original',
          movieResults: <Movie>[Movie(tmdbId: 1, title: 'Movie')],
          activeTab: MediaSearchTab.tvShows,
        );

        final MediaSearchState updated = original.copyWith(isLoading: true);

        expect(updated.query, 'original');
        expect(updated.movieResults, hasLength(1));
        expect(updated.activeTab, MediaSearchTab.tvShows);
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

      test('updates movie results', () {
        const MediaSearchState original = MediaSearchState();
        const List<Movie> newResults = <Movie>[
          Movie(tmdbId: 1, title: 'Movie 1'),
          Movie(tmdbId: 2, title: 'Movie 2'),
        ];

        final MediaSearchState updated =
            original.copyWith(movieResults: newResults);

        expect(updated.movieResults, hasLength(2));
        expect(updated.movieResults[0].title, 'Movie 1');
        expect(updated.movieResults[1].title, 'Movie 2');
      });

      test('updates tv show results', () {
        const MediaSearchState original = MediaSearchState();
        const List<TvShow> newResults = <TvShow>[
          TvShow(tmdbId: 1, title: 'Show 1'),
          TvShow(tmdbId: 2, title: 'Show 2'),
        ];

        final MediaSearchState updated =
            original.copyWith(tvShowResults: newResults);

        expect(updated.tvShowResults, hasLength(2));
        expect(updated.tvShowResults[0].title, 'Show 1');
        expect(updated.tvShowResults[1].title, 'Show 2');
      });

      test('updates animation movie results', () {
        const MediaSearchState original = MediaSearchState();
        const List<Movie> newResults = <Movie>[
          Movie(tmdbId: 10, title: 'Spirited Away'),
          Movie(tmdbId: 11, title: 'Your Name'),
        ];

        final MediaSearchState updated =
            original.copyWith(animationMovieResults: newResults);

        expect(updated.animationMovieResults, hasLength(2));
        expect(updated.animationMovieResults[0].title, 'Spirited Away');
        expect(updated.animationMovieResults[1].title, 'Your Name');
      });

      test('updates animation tvShow results', () {
        const MediaSearchState original = MediaSearchState();
        const List<TvShow> newResults = <TvShow>[
          TvShow(tmdbId: 20, title: 'Attack on Titan'),
          TvShow(tmdbId: 21, title: 'Naruto'),
        ];

        final MediaSearchState updated =
            original.copyWith(animationTvShowResults: newResults);

        expect(updated.animationTvShowResults, hasLength(2));
        expect(updated.animationTvShowResults[0].title, 'Attack on Titan');
        expect(updated.animationTvShowResults[1].title, 'Naruto');
      });

      test('updates error', () {
        const MediaSearchState original = MediaSearchState();

        final MediaSearchState updated =
            original.copyWith(error: 'Network error');

        expect(updated.error, 'Network error');
      });

      test('updates activeTab', () {
        const MediaSearchState original = MediaSearchState();

        final MediaSearchState updated =
            original.copyWith(activeTab: MediaSearchTab.tvShows);

        expect(updated.activeTab, MediaSearchTab.tvShows);
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

      test('updates selectedYear', () {
        const MediaSearchState original = MediaSearchState();

        final MediaSearchState updated =
            original.copyWith(selectedYear: 2024);

        expect(updated.selectedYear, 2024);
      });

      test('clears selectedYear with clearYear', () {
        const MediaSearchState original = MediaSearchState(
          selectedYear: 2024,
        );

        final MediaSearchState updated = original.copyWith(clearYear: true);

        expect(updated.selectedYear, isNull);
      });

      test('preserves selectedYear when not specified', () {
        const MediaSearchState original = MediaSearchState(
          selectedYear: 2023,
        );

        final MediaSearchState updated = original.copyWith(query: 'test');

        expect(updated.selectedYear, 2023);
      });

      test('updates selectedGenreIds', () {
        const MediaSearchState original = MediaSearchState();

        final MediaSearchState updated =
            original.copyWith(selectedGenreIds: <int>[28, 12]);

        expect(updated.selectedGenreIds, <int>[28, 12]);
      });

      test('clears selectedGenreIds with empty list', () {
        const MediaSearchState original = MediaSearchState(
          selectedGenreIds: <int>[28, 12],
        );

        final MediaSearchState updated =
            original.copyWith(selectedGenreIds: <int>[]);

        expect(updated.selectedGenreIds, isEmpty);
      });

      test('preserves selectedGenreIds when not specified', () {
        const MediaSearchState original = MediaSearchState(
          selectedGenreIds: <int>[28],
        );

        final MediaSearchState updated = original.copyWith(query: 'test');

        expect(updated.selectedGenreIds, <int>[28]);
      });
    });

    group('equality', () {
      test('states with same values are equal', () {
        const MediaSearchState state1 = MediaSearchState(
          query: 'test',
          movieResults: <Movie>[Movie(tmdbId: 1, title: 'Movie')],
          activeTab: MediaSearchTab.movies,
        );
        const MediaSearchState state2 = MediaSearchState(
          query: 'test',
          movieResults: <Movie>[Movie(tmdbId: 1, title: 'Movie')],
          activeTab: MediaSearchTab.movies,
        );

        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
      });

      test('states with different queries are not equal', () {
        const MediaSearchState state1 = MediaSearchState(query: 'test1');
        const MediaSearchState state2 = MediaSearchState(query: 'test2');

        expect(state1, isNot(equals(state2)));
      });

      test('states with different activeTab are not equal', () {
        const MediaSearchState state1 = MediaSearchState(
          activeTab: MediaSearchTab.movies,
        );
        const MediaSearchState state2 = MediaSearchState(
          activeTab: MediaSearchTab.tvShows,
        );

        expect(state1, isNot(equals(state2)));
      });

      test('states with different movie results are not equal', () {
        const MediaSearchState state1 = MediaSearchState(
          movieResults: <Movie>[Movie(tmdbId: 1, title: 'Movie 1')],
        );
        const MediaSearchState state2 = MediaSearchState(
          movieResults: <Movie>[Movie(tmdbId: 2, title: 'Movie 2')],
        );

        expect(state1, isNot(equals(state2)));
      });

      test('states with different tv show results are not equal', () {
        const MediaSearchState state1 = MediaSearchState(
          tvShowResults: <TvShow>[TvShow(tmdbId: 1, title: 'Show 1')],
        );
        const MediaSearchState state2 = MediaSearchState(
          tvShowResults: <TvShow>[TvShow(tmdbId: 2, title: 'Show 2')],
        );

        expect(state1, isNot(equals(state2)));
      });

      test('states with different isLoading are not equal', () {
        const MediaSearchState state1 = MediaSearchState(isLoading: true);
        const MediaSearchState state2 = MediaSearchState(isLoading: false);

        expect(state1, isNot(equals(state2)));
      });

      test('states with different error are not equal', () {
        const MediaSearchState state1 = MediaSearchState(error: 'error1');
        const MediaSearchState state2 = MediaSearchState(error: 'error2');

        expect(state1, isNot(equals(state2)));
      });

      test('uses listEquals for movieResults comparison', () {
        const MediaSearchState state1 = MediaSearchState(
          movieResults: <Movie>[
            Movie(tmdbId: 1, title: 'A'),
            Movie(tmdbId: 2, title: 'B'),
          ],
        );
        const MediaSearchState state2 = MediaSearchState(
          movieResults: <Movie>[
            Movie(tmdbId: 2, title: 'B'),
            Movie(tmdbId: 1, title: 'A'),
          ],
        );

        // Different order means not equal (listEquals checks order)
        expect(
          listEquals(state1.movieResults, state2.movieResults),
          isFalse,
        );
        expect(state1, isNot(equals(state2)));
      });

      test('uses listEquals for tvShowResults comparison', () {
        const MediaSearchState state1 = MediaSearchState(
          tvShowResults: <TvShow>[
            TvShow(tmdbId: 1, title: 'A'),
            TvShow(tmdbId: 2, title: 'B'),
          ],
        );
        const MediaSearchState state2 = MediaSearchState(
          tvShowResults: <TvShow>[
            TvShow(tmdbId: 2, title: 'B'),
            TvShow(tmdbId: 1, title: 'A'),
          ],
        );

        expect(
          listEquals(state1.tvShowResults, state2.tvShowResults),
          isFalse,
        );
        expect(state1, isNot(equals(state2)));
      });

      test('states with different animationMovieResults are not equal', () {
        const MediaSearchState state1 = MediaSearchState(
          animationMovieResults: <Movie>[
            Movie(tmdbId: 1, title: 'Spirited Away'),
          ],
        );
        const MediaSearchState state2 = MediaSearchState(
          animationMovieResults: <Movie>[
            Movie(tmdbId: 2, title: 'Your Name'),
          ],
        );

        expect(state1, isNot(equals(state2)));
      });

      test('states with different animationTvShowResults are not equal', () {
        const MediaSearchState state1 = MediaSearchState(
          animationTvShowResults: <TvShow>[
            TvShow(tmdbId: 1, title: 'Attack on Titan'),
          ],
        );
        const MediaSearchState state2 = MediaSearchState(
          animationTvShowResults: <TvShow>[
            TvShow(tmdbId: 2, title: 'Naruto'),
          ],
        );

        expect(state1, isNot(equals(state2)));
      });

      test('states with same animation results are equal', () {
        const MediaSearchState state1 = MediaSearchState(
          animationMovieResults: <Movie>[
            Movie(tmdbId: 1, title: 'Spirited Away'),
          ],
          animationTvShowResults: <TvShow>[
            TvShow(tmdbId: 1, title: 'Attack on Titan'),
          ],
        );
        const MediaSearchState state2 = MediaSearchState(
          animationMovieResults: <Movie>[
            Movie(tmdbId: 1, title: 'Spirited Away'),
          ],
          animationTvShowResults: <TvShow>[
            TvShow(tmdbId: 1, title: 'Attack on Titan'),
          ],
        );

        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
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

      test('states with different selectedYear are not equal', () {
        const MediaSearchState state1 = MediaSearchState(
          selectedYear: 2024,
        );
        const MediaSearchState state2 = MediaSearchState(
          selectedYear: 2023,
        );

        expect(state1, isNot(equals(state2)));
      });

      test('states with same selectedYear are equal', () {
        const MediaSearchState state1 = MediaSearchState(
          selectedYear: 2024,
        );
        const MediaSearchState state2 = MediaSearchState(
          selectedYear: 2024,
        );

        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
      });

      test('states with different selectedGenreIds are not equal', () {
        const MediaSearchState state1 = MediaSearchState(
          selectedGenreIds: <int>[28],
        );
        const MediaSearchState state2 = MediaSearchState(
          selectedGenreIds: <int>[12],
        );

        expect(state1, isNot(equals(state2)));
      });

      test('states with same selectedGenreIds are equal', () {
        const MediaSearchState state1 = MediaSearchState(
          selectedGenreIds: <int>[28, 12],
        );
        const MediaSearchState state2 = MediaSearchState(
          selectedGenreIds: <int>[28, 12],
        );

        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
      });
    });
  });
}
