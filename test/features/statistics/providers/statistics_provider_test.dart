import 'package:core/models/collection_item.dart';
import 'package:core/models/item_status.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/database/database_service.dart';
import 'package:tonkatsu_box/features/statistics/models/library_stats.dart';
import 'package:tonkatsu_box/features/statistics/providers/statistics_provider.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late MockStatsDao mockStatsDao;
  late MockCollectionDao mockCollectionDao;

  setUpAll(() {
    registerAllFallbacks();
    registerFallbackValue(MediaType.anime);
  });

  // Baseline stubs: every DAO call the provider makes answers empty, so each
  // test only overrides the aggregates it exercises.
  void stubEmptyDefaults() {
    when(() => mockStatsDao.getAvailableYears())
        .thenAnswer((_) async => <int>[]);
    when(() => mockStatsDao.getTypeStatusCounts(year: any(named: 'year')))
        .thenAnswer((_) async => <MediaType, Map<ItemStatus, int>>{});
    when(() => mockStatsDao.getRewatchSum(year: any(named: 'year')))
        .thenAnswer((_) async => 0);
    when(() => mockStatsDao.getAverageRating(year: any(named: 'year')))
        .thenAnswer((_) async => null);
    when(() => mockStatsDao.getEpisodeSplit(year: any(named: 'year')))
        .thenAnswer((_) async => (tv: 0, anime: 0));
    when(() => mockStatsDao.getProgressCounterSums(year: any(named: 'year')))
        .thenAnswer(
            (_) async => (animeEpisodes: 0, mangaChapters: 0, bookPages: 0));
    when(() => mockStatsDao.getLikedUnitsByType(year: any(named: 'year')))
        .thenAnswer((_) async => <MediaType, int>{});
    when(() => mockStatsDao.getListenedTrackTotal(year: any(named: 'year')))
        .thenAnswer((_) async => 0);
    when(() => mockStatsDao.getManualMinutes(year: any(named: 'year')))
        .thenAnswer((_) async => 0);
    when(() => mockStatsDao.getTrackerMinutes(year: any(named: 'year')))
        .thenAnswer((_) async => 0);
    when(() => mockStatsDao.getEstimatedMinutes(year: any(named: 'year')))
        .thenAnswer((_) async => 0);
    when(() => mockStatsDao.getAddedByMonth(year: any(named: 'year')))
        .thenAnswer((_) async => <String, int>{});
    when(() => mockStatsDao.getEpisodesByMonth(year: any(named: 'year')))
        .thenAnswer((_) async => <String, int>{});
    when(() => mockStatsDao.getBestItemByMonth(year: any(named: 'year')))
        .thenAnswer((_) async => <String, int>{});
    when(() => mockStatsDao.getGamePlatformRows(year: any(named: 'year')))
        .thenAnswer((_) async => <Map<String, dynamic>>[]);
    when(() =>
            mockStatsDao.getTrackerMinutesByPlatform(year: any(named: 'year')))
        .thenAnswer((_) async => <int?, int>{});
    when(() => mockStatsDao.getGamePlatformStatusCounts(
            year: any(named: 'year')))
        .thenAnswer((_) async => <int?, Map<ItemStatus, int>>{});
    when(() => mockStatsDao.getTopGamesByPlatform(year: any(named: 'year')))
        .thenAnswer((_) async => <int?, List<int>>{});
    when(() =>
            mockStatsDao.getSourceTagCounts(any(), year: any(named: 'year')))
        .thenAnswer((_) async => (titles: 0, tags: <(String, int)>[]));
    when(() => mockStatsDao.getSourceFormatStatusCounts(any(),
            year: any(named: 'year')))
        .thenAnswer((_) async => <String, Map<ItemStatus, int>>{});
    when(() =>
            mockStatsDao.getTopItemsByFormat(any(), year: any(named: 'year')))
        .thenAnswer((_) async => <String, List<int>>{});
    when(() => mockStatsDao.getRatedItemIds(year: any(named: 'year')))
        .thenAnswer((_) async => <int>[]);
    when(() => mockCollectionDao.getItemsWithDataByRowIds(any()))
        .thenAnswer((_) async => <CollectionItem>[]);
  }

  setUp(() {
    mockStatsDao = MockStatsDao();
    mockCollectionDao = MockCollectionDao();
    stubEmptyDefaults();
  });

  ProviderContainer createContainer() {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        statsDaoProvider.overrideWithValue(mockStatsDao),
        collectionDaoProvider.overrideWithValue(mockCollectionDao),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  // Reads the payload for [period], keeping the autoDispose provider alive.
  Future<LibraryStats> readStats(
    ProviderContainer container, {
    StatsPeriod period = const StatsPeriod.allTime(),
  }) {
    container.read(statsPeriodProvider.notifier).state = period;
    container.listen(libraryStatsProvider, (_, _) {});
    return container.read(libraryStatsProvider.future);
  }

  CollectionItem ratedMovie({
    required int id,
    required double userRating,
    double? apiRating,
    String? posterUrl,
  }) {
    return createTestCollectionItem(
      id: id,
      mediaType: MediaType.movie,
      externalId: 1000 + id,
      userRating: userRating,
      movie: createTestMovie(
        tmdbId: 1000 + id,
        title: 'Movie $id',
        rating: apiRating,
        posterUrl: posterUrl,
      ),
    );
  }

  void stubRatedItems(List<CollectionItem> items) {
    when(() => mockStatsDao.getRatedItemIds(year: any(named: 'year')))
        .thenAnswer(
      (_) async => <int>[for (final CollectionItem item in items) item.id],
    );
    when(() => mockCollectionDao.getItemsWithDataByRowIds(any()))
        .thenAnswer((_) async => items);
  }

  group('libraryStatsProvider', () {
    group('totals', () {
      test(
          'should fold per-type statuses into library totals when statuses '
          'and rewatches exist', () async {
        final Map<MediaType, Map<ItemStatus, int>> typeStatus =
            <MediaType, Map<ItemStatus, int>>{
          MediaType.game: <ItemStatus, int>{
            ItemStatus.completed: 2,
            ItemStatus.inProgress: 2,
            ItemStatus.replaying: 1,
          },
          MediaType.movie: <ItemStatus, int>{ItemStatus.completed: 1},
        };
        when(() => mockStatsDao.getTypeStatusCounts(year: any(named: 'year')))
            .thenAnswer((_) async => typeStatus);
        when(() => mockStatsDao.getRewatchSum(year: any(named: 'year')))
            .thenAnswer((_) async => 2);
        when(() => mockStatsDao.getLikedUnitsByType(year: any(named: 'year')))
            .thenAnswer(
          (_) async => <MediaType, int>{MediaType.tvShow: 4, MediaType.anime: 2},
        );

        final LibraryStats stats = await readStats(createContainer());

        expect(stats.totals.items, 6);
        expect(stats.totals.completed, 3);
        // Rewatch sum (2) plus items currently in replay (1).
        expect(stats.totals.replays, 3);
        // Per-type liked units are summed for the hero counter and kept
        // split for the type blocks.
        expect(stats.totals.likedUnits, 6);
        expect(stats.likedByType[MediaType.tvShow], 4);
        expect(stats.typeStatus, typeStatus);
        // "Movies watched" derives from the same split, no extra query.
        expect(stats.units.moviesWatched, 1);
      });
    });

    group('platforms', () {
      test(
          'should merge tracker minutes into platform cards and sort by '
          'minutes when both sources report time', () async {
        when(() => mockStatsDao.getGamePlatformRows(year: any(named: 'year')))
            .thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{
              'platform_id': 1,
              'name': 'PlayStation 5',
              'abbreviation': 'PS5',
              'games': 2,
              'manual_minutes': 100,
            },
            <String, dynamic>{
              'platform_id': 2,
              'name': 'Nintendo Switch',
              'abbreviation': null,
              'games': 5,
              'manual_minutes': 50,
            },
            <String, dynamic>{
              'platform_id': null,
              'name': null,
              'abbreviation': null,
              'games': 1,
              'manual_minutes': null,
            },
          ],
        );
        when(() => mockStatsDao.getTrackerMinutesByPlatform(
            year: any(named: 'year'))).thenAnswer(
          (_) async => <int?, int>{1: 20, 2: 500},
        );
        when(() => mockStatsDao.getTopGamesByPlatform(
            year: any(named: 'year'))).thenAnswer(
          (_) async => <int?, List<int>>{
            1: <int>[11, 12],
          },
        );
        when(() => mockStatsDao.getGamePlatformStatusCounts(
            year: any(named: 'year'))).thenAnswer(
          (_) async => <int?, Map<ItemStatus, int>>{
            2: <ItemStatus, int>{
              ItemStatus.completed: 3,
              ItemStatus.planned: 2,
            },
          },
        );

        final LibraryStats stats = await readStats(createContainer());

        expect(stats.platforms, hasLength(3));
        expect(stats.platforms[0].platformId, 2);
        expect(stats.platforms[0].statusCounts[ItemStatus.completed], 3);
        expect(stats.platforms[1].statusCounts, isEmpty);
        expect(stats.platforms[0].minutes, 550);
        expect(stats.platforms[0].name, 'Nintendo Switch');
        expect(stats.platforms[1].platformId, 1);
        expect(stats.platforms[1].minutes, 120);
        expect(stats.platforms[1].name, 'PS5');
        expect(stats.platforms[1].topItemIds, <int>[11, 12]);
        expect(stats.platforms[2].platformId, isNull);
        expect(stats.platforms[2].minutes, 0);
      });

      test('should keep every platform card, minutes breaking count ties',
          () async {
        when(() => mockStatsDao.getGamePlatformRows(year: any(named: 'year')))
            .thenAnswer(
          (_) async => <Map<String, dynamic>>[
            for (int i = 1; i <= 8; i++)
              <String, dynamic>{
                'platform_id': i,
                'name': 'Platform $i',
                'abbreviation': null,
                'games': 1,
                'manual_minutes': i * 10,
              },
          ],
        );

        final LibraryStats stats = await readStats(createContainer());

        expect(stats.platforms, hasLength(8));
        expect(
          <int?>[for (final PlatformStats p in stats.platforms) p.platformId],
          <int?>[8, 7, 6, 5, 4, 3, 2, 1],
        );
      });
    });

    group('formats', () {
      test(
          'should build labelled format cards sorted by count and drop types '
          'without data', () async {
        when(() => mockStatsDao.getSourceFormatStatusCounts(MediaType.anime,
            year: any(named: 'year'))).thenAnswer(
          (_) async => <String, Map<ItemStatus, int>>{
            'MOVIE': <ItemStatus, int>{ItemStatus.completed: 2},
            'TV': <ItemStatus, int>{
              ItemStatus.completed: 3,
              ItemStatus.inProgress: 2,
            },
          },
        );
        when(() => mockStatsDao.getTopItemsByFormat(MediaType.anime,
            year: any(named: 'year'))).thenAnswer(
          (_) async => <String, List<int>>{
            'TV': <int>[7, 8],
          },
        );

        final LibraryStats stats = await readStats(createContainer());

        expect(stats.formatsByType.keys, <MediaType>[MediaType.anime]);
        final List<FormatStats> cards =
            stats.formatsByType[MediaType.anime]!;
        expect(cards, hasLength(2));
        // Raw source codes are mapped to display labels.
        expect(cards[0].label, 'TV');
        expect(cards[0].count, 5);
        expect(cards[0].statusCounts[ItemStatus.inProgress], 2);
        expect(cards[0].topItemIds, <int>[7, 8]);
        expect(cards[1].label, 'Movie');
        expect(cards[1].count, 2);
        expect(cards[1].topItemIds, isEmpty);
      });

      test('should hydrate format top covers together with the other ids',
          () async {
        when(() => mockStatsDao.getSourceFormatStatusCounts(MediaType.manga,
            year: any(named: 'year'))).thenAnswer(
          (_) async => <String, Map<ItemStatus, int>>{
            'MANGA': <ItemStatus, int>{ItemStatus.completed: 1},
          },
        );
        when(() => mockStatsDao.getTopItemsByFormat(MediaType.manga,
            year: any(named: 'year'))).thenAnswer(
          (_) async => <String, List<int>>{
            'MANGA': <int>[21],
          },
        );

        await readStats(createContainer());

        final VerificationResult result = verify(
          () => mockCollectionDao.getItemsWithDataByRowIds(captureAny()),
        )..called(1);
        final List<int> requested = result.captured.single as List<int>;
        expect(requested, contains(21));
      });
    });

    group('subgenres', () {
      test('should keep only media types with tags when one group is empty',
          () async {
        when(() => mockStatsDao.getSourceTagCounts(MediaType.anime,
            year: any(named: 'year'))).thenAnswer(
          (_) async => (titles: 3, tags: <(String, int)>[('Isekai', 5), ('Mecha', 2)]),
        );
        when(() => mockStatsDao.getSourceTagCounts(MediaType.manga,
            year: any(named: 'year'))).thenAnswer(
          (_) async => (titles: 0, tags: <(String, int)>[]),
        );

        final LibraryStats stats = await readStats(createContainer());

        expect(stats.subgenres, hasLength(1));
        final SubgenreGroup group = stats.subgenres.single;
        expect(group.mediaType, MediaType.anime);
        expect(group.titleCount, 3);
        expect(group.tags, hasLength(2));
        expect(group.tags[0].name, 'Isekai');
        expect(group.tags[0].count, 5);
        expect(group.tags[1].name, 'Mecha');
        expect(group.tags[1].count, 2);
      });
    });

    group('versus', () {
      test(
          'should build a best/worst pair only when a media type has enough '
          'rated items', () async {
        final List<CollectionItem> movies = <CollectionItem>[
          for (int i = 1; i <= 5; i++)
            ratedMovie(id: i, userRating: 10.0 - i),
        ];
        final List<CollectionItem> games = <CollectionItem>[
          createTestCollectionItem(
            id: 6,
            externalId: 1006,
            userRating: 8.0,
            game: createTestGame(id: 1006, name: 'Game 6'),
          ),
        ];
        stubRatedItems(<CollectionItem>[...movies, ...games]);

        final LibraryStats stats = await readStats(createContainer());

        // One rated game is below kVersusMinRatings — movies only.
        expect(stats.versus, hasLength(1));
        final VersusPair pair = stats.versus.single;
        expect(pair.mediaType, MediaType.movie);
        expect(pair.best.id, 1);
        expect(pair.worst.id, 5);
        expect(pair.ratedCount, 5);
      });
    });

    group('crowd deltas', () {
      test(
          'should split items into higher and lower sides when the gap '
          'reaches the threshold', () async {
        stubRatedItems(<CollectionItem>[
          ratedMovie(id: 1, userRating: 9.0, apiRating: 6.0),
          // Below the 1.0 threshold — excluded from both sides.
          ratedMovie(id: 2, userRating: 8.0, apiRating: 7.5),
          ratedMovie(id: 3, userRating: 5.0, apiRating: 7.0),
          ratedMovie(id: 4, userRating: 9.0, apiRating: 7.0),
          // No source rating — excluded.
          ratedMovie(id: 5, userRating: 6.0),
          ratedMovie(id: 6, userRating: 4.0, apiRating: 8.0),
        ]);

        final LibraryStats stats = await readStats(createContainer());

        expect(
          <int>[for (final RatingDelta d in stats.higherThanCrowd) d.item.id],
          <int>[1, 4],
        );
        expect(
          <int>[for (final RatingDelta d in stats.lowerThanCrowd) d.item.id],
          <int>[6, 3],
        );
      });

      test('should cap crowd rows when more items pass the threshold',
          () async {
        stubRatedItems(<CollectionItem>[
          for (int i = 1; i <= 8; i++)
            ratedMovie(id: i, userRating: 10.0, apiRating: 9.5 - i * 0.5),
        ]);

        final LibraryStats stats = await readStats(createContainer());

        expect(stats.higherThanCrowd, hasLength(kCrowdRowCount));
        // Biggest gap first: ids 8..3 by descending delta.
        expect(
          <int>[for (final RatingDelta d in stats.higherThanCrowd) d.item.id],
          <int>[8, 7, 6, 5, 4, 3],
        );
      });
    });

    group('top rated and wall', () {
      test(
          'should sort top rated by rating and keep only covered items on '
          'the wall', () async {
        stubRatedItems(<CollectionItem>[
          // Highest rated item has no poster — top rated yes, wall no.
          ratedMovie(id: 1, userRating: 10.0),
          for (int i = 2; i <= 15; i++)
            ratedMovie(
              id: i,
              userRating: 10.0 - i * 0.1,
              posterUrl: '/w500/poster_$i.jpg',
            ),
        ]);

        final LibraryStats stats = await readStats(createContainer());

        expect(stats.topRated, hasLength(kTopRatedCount));
        expect(
          <int>[for (final CollectionItem i in stats.topRated) i.id],
          <int>[1, 2, 3, 4, 5, 6],
        );
        expect(stats.wallItems, hasLength(kWallCoverCount));
        expect(
          <int>[for (final CollectionItem i in stats.wallItems) i.id],
          isNot(contains(1)),
        );
        expect(stats.wallItems.first.id, 2);
      });
    });

    group('months', () {
      test('should build twelve calendar buckets when a year is selected',
          () async {
        when(() => mockStatsDao.getAddedByMonth(year: any(named: 'year')))
            .thenAnswer(
          (_) async => <String, int>{'2024-01': 3, '2024-05': 7},
        );
        when(() => mockStatsDao.getEpisodesByMonth(year: any(named: 'year')))
            .thenAnswer(
          (_) async => <String, int>{'2024-05': 10, '2024-12': 2},
        );
        when(() => mockStatsDao.getBestItemByMonth(year: any(named: 'year')))
            .thenAnswer(
          (_) async => <String, int>{'2024-05': 42},
        );

        final LibraryStats stats = await readStats(
          createContainer(),
          period: const StatsPeriod.year(2024),
        );

        expect(stats.months, hasLength(12));
        expect(
          <int>[for (final MonthActivity m in stats.months) m.month],
          <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
        );
        expect(
          stats.months.every((MonthActivity m) => m.year == 2024),
          isTrue,
        );
        expect(stats.months[0].itemsAdded, 3);
        expect(stats.months[0].episodesWatched, 0);
        expect(stats.months[4].itemsAdded, 7);
        expect(stats.months[4].episodesWatched, 10);
        expect(stats.months[4].bestItemId, 42);
        expect(stats.months[11].episodesWatched, 2);
        expect(stats.months[1].itemsAdded, 0);
        expect(stats.months[1].bestItemId, isNull);
      });
    });

    group('hydration', () {
      test(
          'should hydrate covers once with the union of rated, monthly best '
          'and platform top ids', () async {
        when(() => mockStatsDao.getRatedItemIds(year: any(named: 'year')))
            .thenAnswer((_) async => <int>[1, 2]);
        when(() => mockStatsDao.getBestItemByMonth(year: any(named: 'year')))
            .thenAnswer((_) async => <String, int>{'2024-03': 3});
        when(() => mockStatsDao.getGamePlatformRows(year: any(named: 'year')))
            .thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{
              'platform_id': 1,
              'name': 'PC',
              'abbreviation': null,
              'games': 2,
              'manual_minutes': 60,
            },
          ],
        );
        when(() => mockStatsDao.getTopGamesByPlatform(
            year: any(named: 'year'))).thenAnswer(
          (_) async => <int?, List<int>>{
            1: <int>[4, 5],
          },
        );

        await readStats(
          createContainer(),
          period: const StatsPeriod.year(2024),
        );

        final VerificationResult result = verify(
          () => mockCollectionDao.getItemsWithDataByRowIds(captureAny()),
        )..called(1);
        final List<int> requested = result.captured.single as List<int>;
        expect(requested.toSet(), <int>{1, 2, 3, 4, 5});
      });
    });
  });
}
