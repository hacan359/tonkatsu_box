import 'package:core/models/media_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:core/models/anime.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/anilist_api.dart';
import 'package:tonkatsu_box/features/search/filters/anilist_studio_filter.dart';
import 'package:tonkatsu_box/features/search/models/common_filter.dart';
import 'package:tonkatsu_box/features/search/models/search_source.dart';
import 'package:tonkatsu_box/features/search/providers/browse_provider.dart';
import 'package:tonkatsu_box/features/search/sources/search_sources.dart';
import 'package:tonkatsu_box/features/settings/providers/settings_provider.dart';

import '../../../helpers/test_helpers.dart';

/// Shared pick that only AniList and MangaDex can answer, standing in for a
/// value MangaBaka and Kitsu do not have (e.g. "cancelled").
CommonSelection _partialStatus() => const CommonSelection(
      semantic: FilterSemantic.statusCancelled,
      targets: <String, CommonFilterTarget>{
        'manga': (filterKey: 'status', value: 'CANCELLED'),
        'mangadex': (filterKey: 'status', value: 'cancelled'),
      },
    );

void main() {
  group('BrowseSettingsKeys', () {
    test('keeps the legacy key so pre-0.41 installs can be migrated', () {
      expect(BrowseSettingsKeys.sourceId, 'browse_source_id');
      expect(BrowseSettingsKeys.mediaType, 'browse_media_type');
    });
  });

  group('BrowseState', () {
    test('defaults to every source of the type being active', () {
      const BrowseState state = BrowseState(mediaType: MediaType.manga);

      expect(state.sources, hasLength(4));
      expect(state.activeSources, hasLength(4));
      expect(state.disabledSourceIds, isEmpty);
      expect(state.hasFilters, isFalse);
      expect(state.hasActiveQuery, isFalse);
      expect(state.items, isEmpty);
      expect(state.isEmpty, isTrue);
    });

    test('a disabled source drops out of activeSources', () {
      const BrowseState state = BrowseState(
        mediaType: MediaType.manga,
        disabledSourceIds: <String>{'mangadex'},
      );

      expect(
        state.activeSources.map((SearchSource s) => s.id),
        isNot(contains('mangadex')),
      );
      expect(state.activeSources, hasLength(3));
    });

    group('own filters narrow the query to their owner', () {
      test('one owner leaves only that source', () {
        const BrowseState state = BrowseState(
          mediaType: MediaType.manga,
          ownFilterValues: <String, Map<String, Object?>>{
            'mangadex': <String, Object?>{'publicationDemographic': 'seinen'},
          },
        );

        expect(state.ownFilterOwners, <String>{'mangadex'});
        expect(state.activeSources.map((SearchSource s) => s.id), <String>[
          'mangadex',
        ]);
        expect(state.hasFilters, isTrue);
      });

      test('an empty multi-select value does not count as set', () {
        const BrowseState state = BrowseState(
          mediaType: MediaType.manga,
          ownFilterValues: <String, Map<String, Object?>>{
            'mangadex': <String, Object?>{'tag': <Object>[]},
          },
        );

        expect(state.ownFilterOwners, isEmpty);
        expect(state.activeSources, hasLength(4));
        expect(state.hasFilters, isFalse);
      });
    });

    group('shared filters', () {
      test('sources without the picked value drop out and are reported', () {
        final BrowseState state = BrowseState(
          mediaType: MediaType.manga,
          commonSelections: <String, CommonSelection>{
            'status': _partialStatus(),
          },
        );

        expect(
          state.activeSources.map((SearchSource s) => s.id).toSet(),
          <String>{'manga', 'mangadex'},
        );
        expect(state.unsupportedSourceIds, <String>{'mangabaka', 'kitsu_manga'});
        expect(state.hasFilters, isTrue);
      });

      test('each source gets the value spelled its own way', () {
        final BrowseState state = BrowseState(
          mediaType: MediaType.manga,
          commonSelections: <String, CommonSelection>{
            'status': _partialStatus(),
          },
        );

        expect(state.filterValuesFor('manga'), <String, Object?>{
          'status': 'CANCELLED',
        });
        expect(state.filterValuesFor('mangadex'), <String, Object?>{
          'status': 'cancelled',
        });
        // Cannot answer it, so it gets nothing rather than a wrong value.
        expect(state.filterValuesFor('mangabaka'), isEmpty);
      });

      test('a shared pick merges with the source\'s own filters', () {
        final BrowseState state = BrowseState(
          mediaType: MediaType.manga,
          ownFilterValues: <String, Map<String, Object?>>{
            'mangadex': <String, Object?>{'publicationDemographic': 'seinen'},
          },
          commonSelections: <String, CommonSelection>{
            'status': _partialStatus(),
          },
        );

        expect(state.filterValuesFor('mangadex'), <String, Object?>{
          'publicationDemographic': 'seinen',
          'status': 'cancelled',
        });
      });
    });

    group('query state', () {
      test('a query under two characters is not active', () {
        const BrowseState state = BrowseState(
          mediaType: MediaType.manga,
          searchQuery: 'a',
        );

        expect(state.hasSearchQuery, isFalse);
        expect(state.hasActiveQuery, isFalse);
      });

      test('two characters or more counts', () {
        const BrowseState state = BrowseState(
          mediaType: MediaType.manga,
          searchQuery: 'ab',
        );

        expect(state.hasSearchQuery, isTrue);
        expect(state.hasActiveQuery, isTrue);
      });
    });

    test('items are flattened in active-source order', () {
      const BrowseState state = BrowseState(
        mediaType: MediaType.manga,
        itemsBySource: <String, List<Object>>{
          'mangadex': <Object>['d1', 'd2'],
          'manga': <Object>['a1'],
        },
      );

      // Registration order, not insertion order of the map.
      expect(state.items, <Object>['a1', 'd1', 'd2']);
    });

    test('items of a disabled source are not shown', () {
      const BrowseState state = BrowseState(
        mediaType: MediaType.manga,
        disabledSourceIds: <String>{'mangadex'},
        itemsBySource: <String, List<Object>>{
          'mangadex': <Object>['d1'],
          'manga': <Object>['a1'],
        },
      );

      expect(state.items, <Object>['a1']);
    });

    group('sorting', () {
      test('is offered only while a single source answers', () {
        const BrowseState many = BrowseState(mediaType: MediaType.manga);
        expect(many.canSort, isFalse);

        const BrowseState one = BrowseState(mediaType: MediaType.game);
        expect(one.canSort, isTrue);
      });

      test('a picked value is ignored while several sources answer', () {
        const BrowseState state = BrowseState(
          mediaType: MediaType.manga,
          sortBy: 'SCORE_DESC',
        );

        final SearchSource first = state.sources.first;
        expect(state.sortByFor(first), first.defaultSort.apiValue);
      });

      test('speaks the vocabulary of the source it applies to', () {
        final BrowseState state = BrowseState(
          mediaType: MediaType.manga,
          disabledSourceIds: <String>{
            for (final SearchSource s in searchSourcesFor(MediaType.manga))
              if (s.id != 'mangadex') s.id,
          },
        );

        // Not AniList's, even though AniList is the type's primary source.
        expect(state.sortSource?.id, 'mangadex');
        expect(state.effectiveSortBy, 'relevance');
      });

      test('is off while the source ignores sort on a search response', () {
        // Narrowed to TMDB explicitly: movie has more than one provider now,
        // and this test is about the single-source case.
        final Set<String> onlyTmdb = <String>{
          for (final SearchSource s in searchSourcesFor(MediaType.movie))
            if (s.id != 'movies') s.id,
        };
        final BrowseState browsing = BrowseState(
          mediaType: MediaType.movie,
          disabledSourceIds: onlyTmdb,
        );
        final BrowseState searching = BrowseState(
          mediaType: MediaType.movie,
          searchQuery: 'dune',
          disabledSourceIds: onlyTmdb,
        );

        expect(browsing.canSort, isTrue);
        expect(searching.isSingleSource, isTrue);
        expect(searching.sortIgnoredDuringSearch, isTrue);
        expect(searching.canSort, isFalse);
      });

      test('stays on for a source that does sort search results', () {
        final BrowseState state = BrowseState(
          mediaType: MediaType.manga,
          searchQuery: 'berserk',
          disabledSourceIds: <String>{
            for (final SearchSource s in searchSourcesFor(MediaType.manga))
              if (s.id != 'manga') s.id,
          },
        );

        expect(state.sortIgnoredDuringSearch, isFalse);
        expect(state.canSort, isTrue);
      });

      test('a picked value applies once narrowed to one source', () {
        final BrowseState state = BrowseState(
          mediaType: MediaType.manga,
          sortBy: 'SCORE_DESC',
          disabledSourceIds: <String>{
            for (final SearchSource s in searchSourcesFor(MediaType.manga))
              if (s.id != 'manga') s.id,
          },
        );

        expect(state.canSort, isTrue);
        expect(state.effectiveSortBy, 'SCORE_DESC');
      });
    });

    group('loading', () {
      test('is reported per source, not as one flag', () {
        const BrowseState state = BrowseState(
          mediaType: MediaType.manga,
          loadingSourceIds: <String>{'kitsu_manga'},
          itemsBySource: <String, List<Object>>{
            'manga': <Object>['a'],
          },
        );

        expect(state.isSourceLoading('kitsu_manga'), isTrue);
        // Already answered, so it must not shimmer while Kitsu is pending.
        expect(state.isSourceLoading('manga'), isFalse);
        expect(state.isLoading, isTrue);
      });

      test('nothing pending means nothing is loading', () {
        const BrowseState state = BrowseState(mediaType: MediaType.manga);

        expect(state.isLoading, isFalse);
        expect(state.isSourceLoading('manga'), isFalse);
      });
    });

    group('filter counts', () {
      test('count only values that are actually set', () {
        final BrowseState state = BrowseState(
          mediaType: MediaType.manga,
          ownFilterValues: const <String, Map<String, Object?>>{
            'mangadex': <String, Object?>{
              'publicationDemographic': 'seinen',
              'tag': <Object>[],
              'contentRating': null,
            },
            'manga': <String, Object?>{'year': 1989},
          },
          commonSelections: <String, CommonSelection>{
            'status': _partialStatus(),
          },
        );

        expect(state.ownFilterCount, 2);
        expect(state.activeFilterCount, 3);
      });

      test('are zero with nothing picked', () {
        const BrowseState state = BrowseState(mediaType: MediaType.manga);

        expect(state.ownFilterCount, 0);
        expect(state.activeFilterCount, 0);
      });
    });

    test('books cannot browse on filters alone', () {
      const BrowseState books = BrowseState(mediaType: MediaType.book);
      const BrowseState manga = BrowseState(mediaType: MediaType.manga);

      expect(books.textQueryOnly, isTrue);
      expect(manga.textQueryOnly, isFalse);
    });

    test('copyWith clears the sort value on request', () {
      const BrowseState state = BrowseState(
        mediaType: MediaType.manga,
        sortBy: 'SCORE_DESC',
      );

      expect(state.copyWith(clearSortBy: true).sortBy, isNull);
      expect(state.copyWith().sortBy, 'SCORE_DESC');
    });
  });

  group('BrowseNotifier', () {
    Future<ProviderContainer> containerWith(
      Map<String, Object> initialPrefs,
    ) async {
      SharedPreferences.setMockInitialValues(initialPrefs);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    void seedLoaded(BrowseNotifier notifier) {
      notifier.state = notifier.state.copyWith(
        searchQuery: 'berserk',
        itemsBySource: <String, List<Object>>{
          'manga': <Object>['a'],
          'mangadex': <Object>['d'],
        },
        disabledSourceIds: const <String>{'mangabaka', 'kitsu_manga'},
      );
      notifier.state = notifier.state.copyWith(
        loadedSignatures: <String, String>{
          'manga': notifier.signatureOf('manga'),
          'mangadex': notifier.signatureOf('mangadex'),
        },
      );
    }

    test('restores the saved media type', () async {
      final ProviderContainer container = await containerWith(
        <String, Object>{BrowseSettingsKeys.mediaType: 'manga'},
      );

      expect(container.read(browseProvider).mediaType, MediaType.manga);
    });

    test('migrates a pre-0.41 source id to its media type', () async {
      final ProviderContainer container = await containerWith(
        <String, Object>{BrowseSettingsKeys.sourceId: 'kitsu_anime'},
      );

      final BrowseState state = container.read(browseProvider);
      expect(state.mediaType, MediaType.anime);
      // Every source of the type comes on — that is the point of the migration.
      expect(state.activeSources, hasLength(2));
    });

    test('setMediaType keeps the typed query but drops filters', () async {
      final ProviderContainer container =
          await containerWith(<String, Object>{});
      final BrowseNotifier notifier = container.read(browseProvider.notifier);

      // Seeded rather than set through the notifier so the test stays offline —
      // setOwnFilter would fire a real request.
      notifier.state = notifier.state.copyWith(
        searchQuery: 'b',
        ownFilterValues: const <String, Map<String, Object?>>{
          'manga': <String, Object?>{'year': 1989},
        },
      );
      notifier.setMediaType(MediaType.anime);

      final BrowseState state = container.read(browseProvider);
      expect(state.mediaType, MediaType.anime);
      expect(state.searchQuery, 'b');
      expect(state.hasFilters, isFalse);
    });

    test('setSearchQuery drops the stale query when the box is emptied',
        () async {
      final ProviderContainer container =
          await containerWith(<String, Object>{});
      final BrowseNotifier notifier = container.read(browseProvider.notifier);
      notifier.state = notifier.state.copyWith(searchQuery: 'berserk');

      notifier.setSearchQuery('b');

      expect(container.read(browseProvider).searchQuery, isEmpty);
      expect(container.read(browseProvider).hasSearchQuery, isFalse);
    });

    test('setSearchQuery below the threshold with no prior query is a no-op',
        () async {
      final ProviderContainer container =
          await containerWith(<String, Object>{});
      final BrowseNotifier notifier = container.read(browseProvider.notifier);
      final BrowseState before = container.read(browseProvider);

      notifier.setSearchQuery('b');

      expect(identical(container.read(browseProvider), before), isTrue);
    });

    test('setSource narrows to that one provider', () async {
      final ProviderContainer container =
          await containerWith(<String, Object>{});

      container.read(browseProvider.notifier).setSource('kitsu_manga');

      final BrowseState state = container.read(browseProvider);
      expect(state.mediaType, MediaType.manga);
      expect(state.activeSources.map((SearchSource s) => s.id), <String>[
        'kitsu_manga',
      ]);
    });

    test('narrowTo leaves a single source active', () async {
      final ProviderContainer container = await containerWith(
        <String, Object>{BrowseSettingsKeys.mediaType: 'manga'},
      );

      await container.read(browseProvider.notifier).narrowTo('mangadex');

      expect(
        container.read(browseProvider).activeSources.map(
              (SearchSource s) => s.id,
            ),
        <String>['mangadex'],
      );
    });

    test('the last enabled source cannot be switched off', () async {
      final ProviderContainer container = await containerWith(
        <String, Object>{BrowseSettingsKeys.mediaType: 'manga'},
      );
      final BrowseNotifier notifier = container.read(browseProvider.notifier);

      await notifier.narrowTo('mangadex');
      await notifier.toggleSource('mangadex');

      expect(container.read(browseProvider).activeSources, hasLength(1));
    });

    test('a sort value never leaks into another provider\'s request', () async {
      final ProviderContainer container = await containerWith(
        <String, Object>{BrowseSettingsKeys.mediaType: 'manga'},
      );
      final BrowseNotifier notifier = container.read(browseProvider.notifier);

      await notifier.narrowTo('manga');
      await notifier.setSort('SCORE_DESC');
      await notifier.toggleSource('mangadex');

      final BrowseState state = container.read(browseProvider);
      final SearchSource anilist =
          state.sources.firstWhere((SearchSource s) => s.id == 'manga');
      final SearchSource mangadex =
          state.sources.firstWhere((SearchSource s) => s.id == 'mangadex');

      expect(state.sortByFor(anilist), 'SCORE_DESC');
      expect(state.sortByFor(mangadex), mangadex.defaultSort.apiValue);
    });

    test('clearing filters drops the marks of a discarded request', () async {
      final ProviderContainer container = await containerWith(
        <String, Object>{BrowseSettingsKeys.mediaType: 'manga'},
      );
      final BrowseNotifier notifier = container.read(browseProvider.notifier);

      // Stand in for a request in flight with no query left to re-run it.
      notifier.state = notifier.state.copyWith(
        loadingSourceIds: const <String>{'kitsu_manga'},
      );
      notifier.clearFilters();

      // Otherwise that source shimmers forever — nothing will ever answer it.
      expect(container.read(browseProvider).isLoading, isFalse);
    });

    test('clearing the search drops the marks of a discarded request', () async {
      final ProviderContainer container = await containerWith(
        <String, Object>{BrowseSettingsKeys.mediaType: 'manga'},
      );
      final BrowseNotifier notifier = container.read(browseProvider.notifier);

      notifier.state = notifier.state.copyWith(
        searchQuery: 'berserk',
        loadingSourceIds: const <String>{'kitsu_manga'},
      );
      notifier.clearSearch();

      expect(container.read(browseProvider).isLoading, isFalse);
    });

    test('clearing filters resets a load-more left in flight', () async {
      final ProviderContainer container = await containerWith(
        <String, Object>{BrowseSettingsKeys.mediaType: 'manga'},
      );
      final BrowseNotifier notifier = container.read(browseProvider.notifier);

      // Stand in for a page-2 request whose completion the generation bump
      // will discard — the flag must not stay up or loadMore is blocked.
      notifier.state = notifier.state.copyWith(isLoadingMore: true);
      notifier.clearFilters();

      expect(container.read(browseProvider).isLoadingMore, isFalse);
    });

    test('clearing the search resets a load-more left in flight', () async {
      final ProviderContainer container = await containerWith(
        <String, Object>{BrowseSettingsKeys.mediaType: 'manga'},
      );
      final BrowseNotifier notifier = container.read(browseProvider.notifier);

      notifier.state = notifier.state.copyWith(
        searchQuery: 'berserk',
        isLoadingMore: true,
      );
      notifier.clearSearch();

      expect(container.read(browseProvider).isLoadingMore, isFalse);
    });

    test('setSort is refused when the source ignores sort on search', () async {
      final ProviderContainer container = await containerWith(
        <String, Object>{BrowseSettingsKeys.mediaType: 'movie'},
      );
      final BrowseNotifier notifier = container.read(browseProvider.notifier);

      notifier.state = notifier.state.copyWith(searchQuery: 'dune');
      await notifier.setSort('vote_average.desc');

      // Rejected rather than sent to an endpoint that would ignore it.
      expect(container.read(browseProvider).sortBy, isNull);
      expect(container.read(browseProvider).sortSourceId, isNull);
    });

    test('hiding a provider keeps its results and asks nobody', () async {
      final ProviderContainer container = await containerWith(
        <String, Object>{BrowseSettingsKeys.mediaType: 'manga'},
      );
      final BrowseNotifier notifier = container.read(browseProvider.notifier);

      // Stand in for a query that already produced results for two providers.
      seedLoaded(notifier);

      await notifier.toggleSource('mangadex');

      final BrowseState hidden = container.read(browseProvider);
      expect(hidden.items, <Object>['a']);
      // Kept, so switching it back on needs no request.
      expect(hidden.itemsBySource['mangadex'], <Object>['d']);
      expect(hidden.isLoading, isFalse);

      await notifier.toggleSource('mangadex');
      final BrowseState shown = container.read(browseProvider);
      expect(shown.items, <Object>['a', 'd']);
      expect(shown.isLoading, isFalse);
    });

    test('narrowing to one provider and back asks nobody', () async {
      final ProviderContainer container = await containerWith(
        <String, Object>{BrowseSettingsKeys.mediaType: 'manga'},
      );
      final BrowseNotifier notifier = container.read(browseProvider.notifier);

      seedLoaded(notifier);

      await notifier.narrowTo('mangadex');

      expect(container.read(browseProvider).items, <Object>['d']);
      expect(container.read(browseProvider).isLoading, isFalse);
    });
  });

  group('BrowseState.activeExclusiveFilter', () {
    test('returns the exclusive filter that holds a value', () {
      const BrowseState state = BrowseState(
        mediaType: MediaType.anime,
        ownFilterValues: <String, Map<String, Object?>>{
          'anilist_anime': <String, Object?>{
            AniListStudioFilter.filterKey: 'MAPPA',
            'tag': <String>['Time Loop'],
          },
        },
      );

      expect(
        state.activeExclusiveFilter('anilist_anime'),
        isA<AniListStudioFilter>(),
      );
    });

    test('ignores non-exclusive values and other sources', () {
      const BrowseState state = BrowseState(
        mediaType: MediaType.anime,
        ownFilterValues: <String, Map<String, Object?>>{
          'anilist_anime': <String, Object?>{'tag': <String>['Time Loop']},
        },
      );

      expect(state.activeExclusiveFilter('anilist_anime'), isNull);
      expect(state.activeExclusiveFilter('kitsu_anime'), isNull);
    });

    test('treats a cleared value as not set', () {
      const BrowseState state = BrowseState(
        mediaType: MediaType.anime,
        ownFilterValues: <String, Map<String, Object?>>{
          'anilist_anime': <String, Object?>{
            AniListStudioFilter.filterKey: null,
          },
        },
      );

      expect(state.activeExclusiveFilter('anilist_anime'), isNull);
    });
  });

  group('BrowseNotifier exclusive filter', () {
    late MockAniListApi api;

    Future<BrowseNotifier> notifierWithStudio() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      api = MockAniListApi();
      when(() => api.browseAnimeByStudio(
            studio: any(named: 'studio'),
            sort: any(named: 'sort'),
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
          )).thenAnswer((_) async =>
          (<Anime>[createTestAnime(id: 1)], false, 1));
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
          aniListApiProvider.overrideWithValue(api),
        ],
      );
      addTearDown(container.dispose);
      final BrowseNotifier notifier = container.read(browseProvider.notifier);
      notifier.setSource('anilist_anime');
      return notifier;
    }

    test('setOwnFilters stores every key and fetches once', () async {
      final BrowseNotifier notifier = await notifierWithStudio();

      await notifier.setOwnFilters('anilist_anime', <String, Object?>{
        AniListStudioFilter.filterKey: 'MAPPA',
        'format': 'TV',
      });

      expect(
        notifier.state.ownFilterValues['anilist_anime'],
        <String, Object?>{AniListStudioFilter.filterKey: 'MAPPA', 'format': 'TV'},
      );
      verify(() => api.browseAnimeByStudio(
            studio: 'MAPPA',
            sort: any(named: 'sort'),
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
          )).called(1);
      expect(notifier.state.items, hasLength(1));
    });

    test('typing does not refetch while a studio is set', () async {
      final BrowseNotifier notifier = await notifierWithStudio();
      await notifier.setOwnFilter(
        'anilist_anime',
        AniListStudioFilter.filterKey,
        'MAPPA',
      );

      await notifier.search('violet');

      verify(() => api.browseAnimeByStudio(
            studio: any(named: 'studio'),
            sort: any(named: 'sort'),
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
          )).called(1);
    });
  });
}
