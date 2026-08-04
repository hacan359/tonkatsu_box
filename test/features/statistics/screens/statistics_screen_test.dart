import 'package:core/models/collection_item.dart';
import 'package:core/models/item_status.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/statistics/models/library_stats.dart';
import 'package:tonkatsu_box/features/statistics/providers/statistics_provider.dart';
import 'package:tonkatsu_box/features/statistics/screens/statistics_screen.dart';
import 'package:tonkatsu_box/features/statistics/views/statistics_view_desktop.dart';
import 'package:tonkatsu_box/features/statistics/views/statistics_view_mobile.dart';
import 'package:tonkatsu_box/features/statistics/widgets/stats_crowd_section.dart';
import 'package:tonkatsu_box/features/statistics/widgets/stats_formats_section.dart';
import 'package:tonkatsu_box/features/statistics/widgets/stats_hero_desktop.dart';
import 'package:tonkatsu_box/features/statistics/widgets/stats_hero_mobile.dart';
import 'package:tonkatsu_box/features/statistics/widgets/stats_months_ribbon_desktop.dart';
import 'package:tonkatsu_box/features/statistics/widgets/stats_months_ribbon_mobile.dart';
import 'package:tonkatsu_box/features/statistics/widgets/stats_period_picker.dart';
import 'package:tonkatsu_box/features/statistics/widgets/stats_types_section.dart';

import '../../../helpers/test_helpers.dart';

// A payload that populates every section. Cover URLs stay null so no
// network images load inside the test harness.
LibraryStats buildLibraryStats({
  List<int> years = const <int>[2024],
  int items = 6,
}) {
  final CollectionItem best = createTestCollectionItem(
    id: 1,
    mediaType: MediaType.movie,
    externalId: 1001,
    userRating: 9.0,
    movie: createTestMovie(tmdbId: 1001, title: 'Best Movie', rating: 7.0),
  );
  final CollectionItem worst = createTestCollectionItem(
    id: 2,
    mediaType: MediaType.movie,
    externalId: 1002,
    userRating: 3.0,
    movie: createTestMovie(tmdbId: 1002, title: 'Worst Movie', rating: 6.0),
  );
  return LibraryStats(
    period: const StatsPeriod.allTime(),
    availableYears: years,
    totals: LibraryTotals(
      items: items,
      completed: 3,
      replays: 1,
      likedUnits: 2,
      averageRating: 7.5,
    ),
    units: const UnitsWatched(
      tvEpisodes: 8,
      animeEpisodes: 4,
      moviesWatched: 3,
      mangaChapters: 20,
      bookPages: 150,
    ),
    typeStatus: const <MediaType, Map<ItemStatus, int>>{
      MediaType.game: <ItemStatus, int>{
        ItemStatus.completed: 2,
        ItemStatus.inProgress: 1,
      },
      MediaType.movie: <ItemStatus, int>{
        ItemStatus.completed: 1,
        ItemStatus.planned: 2,
      },
    },
    likedByType: const <MediaType, int>{MediaType.tvShow: 2},
    hours: const StatsHours(
      manualMinutes: 90,
      trackerMinutes: 120,
      estimatedMinutes: 240,
    ),
    months: <MonthActivity>[
      for (int m = 1; m <= 12; m++)
        MonthActivity(
          year: 2024,
          month: m,
          itemsAdded: m % 3,
          episodesWatched: m % 2,
          bestItemId: m == 5 ? 1 : null,
        ),
    ],
    platforms: const <PlatformStats>[
      PlatformStats(
        platformId: 1,
        name: 'PS5',
        gameCount: 2,
        minutes: 120,
        topItemIds: <int>[1],
      ),
    ],
    formatsByType: const <MediaType, List<FormatStats>>{
      MediaType.anime: <FormatStats>[
        FormatStats(
          label: 'TV',
          count: 3,
          statusCounts: <ItemStatus, int>{
            ItemStatus.completed: 2,
            ItemStatus.inProgress: 1,
          },
          topItemIds: <int>[1],
        ),
      ],
    },
    // Two groups so the wide layout exercises the 50/50 row branch.
    subgenres: const <SubgenreGroup>[
      SubgenreGroup(
        mediaType: MediaType.anime,
        titleCount: 3,
        tags: <TagCount>[TagCount('Isekai', 5)],
      ),
      SubgenreGroup(
        mediaType: MediaType.manga,
        titleCount: 2,
        tags: <TagCount>[TagCount('Drama', 2)],
      ),
    ],
    versus: <VersusPair>[
      VersusPair(
        mediaType: MediaType.movie,
        best: best,
        worst: worst,
        ratedCount: 5,
      ),
    ],
    topRated: <CollectionItem>[best, worst],
    higherThanCrowd: <RatingDelta>[
      RatingDelta(item: best, mine: 9.0, external: 7.0),
    ],
    lowerThanCrowd: <RatingDelta>[
      RatingDelta(item: worst, mine: 3.0, external: 6.0),
    ],
    wallItems: const <CollectionItem>[],
    coversById: <int, CollectionItem>{1: best, 2: worst},
  );
}

void main() {
  group('StatisticsScreen', () {
    List<Override> overrides(LibraryStats stats) => <Override>[
          libraryStatsProvider.overrideWith((Ref ref) async => stats),
        ];

    // The year's label is data (the year number), not a UI string, so
    // finding it by text stays design-agnostic.
    Finder yearOption(int year) => find.text('$year');

    testWidgets('should render without exception when stats are non-empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        const StatisticsScreen(),
        overrides: overrides(buildLibraryStats()),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(StatsHeroDesktop), findsOneWidget);
      expect(find.byType(StatsTypesSection), findsOneWidget);
      // Only anime has format data; the manga block is left out entirely so
      // it cannot contribute an empty gap to the page.
      expect(find.byType(StatsFormatsSection), findsOneWidget);
    });

    testWidgets('should build the wide page when the content area is wide', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        const StatisticsScreen(),
        overrides: overrides(buildLibraryStats()),
      );

      expect(find.byType(StatisticsViewDesktop), findsOneWidget);
      expect(find.byType(StatisticsViewMobile), findsNothing);
      expect(find.byType(StatsMonthsRibbonDesktop), findsOneWidget);
    });

    testWidgets('should stretch the sections across a wide window', (
      WidgetTester tester,
    ) async {
      // Wider than the 1240px column the page used to be centred in: the
      // sections must follow the window like every other tab of the hub.
      tester.view.physicalSize = const Size(2000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpApp(
        const StatisticsScreen(),
        overrides: overrides(buildLibraryStats()),
      );

      expect(tester.takeException(), isNull);
      // The crowd section stretches to the width it is offered rather than
      // sizing to content, so its box measures the room the page gives.
      expect(
        tester.getSize(find.byType(StatsCrowdSection)).width,
        greaterThan(1240),
      );
    });

    testWidgets('should never clip the headline count on a narrow phone', (
      WidgetTester tester,
    ) async {
      // The dropdown shares the count's row, and a six-figure library on a
      // 320dp screen used to ellipsize the count away.
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpApp(
        const StatisticsScreen(),
        overrides: overrides(buildLibraryStats(items: 987654)),
      );

      expect(tester.takeException(), isNull);
      // pumpApp pins the locale to en, so the grouping separator is fixed.
      final RenderParagraph count =
          tester.renderObject<RenderParagraph>(find.text('987,654'));
      expect(count.didExceedMaxLines, isFalse);
    });

    testWidgets('should build the phone page when the screen is phone sized', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpApp(
        const StatisticsScreen(),
        overrides: overrides(buildLibraryStats()),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(StatisticsViewMobile), findsOneWidget);
      expect(find.byType(StatisticsViewDesktop), findsNothing);
      expect(find.byType(StatsHeroMobile), findsOneWidget);
      expect(find.byType(StatsMonthsRibbonMobile), findsOneWidget);
    });

    testWidgets('should build the phone page in a narrow desktop window', (
      WidgetTester tester,
    ) async {
      // Same content width as a phone, but with no platform override: the
      // page follows the room it has, not the operating system.
      tester.view.physicalSize = const Size(480, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpApp(
        const StatisticsScreen(),
        overrides: overrides(buildLibraryStats()),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(StatisticsViewMobile), findsOneWidget);
    });

    testWidgets('should show the empty state when stats are empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        const StatisticsScreen(),
        overrides: overrides(createEmptyLibraryStats()),
      );

      expect(tester.takeException(), isNull);
      // The empty state replaces every data section on both form factors.
      expect(find.byType(StatsHeroDesktop), findsNothing);
      expect(find.byType(StatsHeroMobile), findsNothing);
    });

    testWidgets('should update the period state when a year is picked', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        const StatisticsScreen(),
        overrides: overrides(buildLibraryStats()),
      );
      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(StatisticsScreen)),
      );
      expect(container.read(statsPeriodProvider), const StatsPeriod.allTime());
      // The years only exist once the dropdown is open.
      expect(yearOption(2024), findsNothing);

      await tester.tap(find.byType(StatsPeriodPicker));
      await tester.pumpAndSettle();
      await tester.tap(yearOption(2024).last);
      await tester.pumpAndSettle();

      expect(
        container.read(statsPeriodProvider),
        const StatsPeriod.year(2024),
      );
    });
  });
}
