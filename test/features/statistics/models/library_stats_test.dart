import 'package:core/models/collection_item.dart';
import 'package:core/models/item_status.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/statistics/models/library_stats.dart';

import '../../../helpers/test_helpers.dart';

// Wraps hand-built fields into an otherwise empty payload, so each test only
// states the part of the payload it cares about.
LibraryStats _statsWithTotals(
  LibraryTotals totals, {
  UnitsWatched units = const UnitsWatched.empty(),
  Map<MediaType, Map<ItemStatus, int>> typeStatus =
      const <MediaType, Map<ItemStatus, int>>{},
  List<MonthActivity> months = const <MonthActivity>[],
  Map<MediaType, List<FormatStats>> formatsByType =
      const <MediaType, List<FormatStats>>{},
  List<RatingDelta> higherThanCrowd = const <RatingDelta>[],
  List<RatingDelta> lowerThanCrowd = const <RatingDelta>[],
}) {
  return LibraryStats(
    period: const StatsPeriod.allTime(),
    availableYears: const <int>[],
    totals: totals,
    units: units,
    typeStatus: typeStatus,
    likedByType: const <MediaType, int>{},
    hours: const StatsHours.empty(),
    months: months,
    platforms: const <PlatformStats>[],
    formatsByType: formatsByType,
    subgenres: const <SubgenreGroup>[],
    versus: const <VersusPair>[],
    topRated: const <CollectionItem>[],
    higherThanCrowd: higherThanCrowd,
    lowerThanCrowd: lowerThanCrowd,
    wallItems: const <CollectionItem>[],
    coversById: const <int, CollectionItem>{},
  );
}

MonthActivity _month({int itemsAdded = 0, int episodesWatched = 0}) {
  return MonthActivity(
    year: 2024,
    month: 1,
    itemsAdded: itemsAdded,
    episodesWatched: episodesWatched,
  );
}

void main() {
  group('StatsPeriod', () {
    group('operator ==', () {
      test('should be equal when both periods are allTime', () {
        expect(const StatsPeriod.allTime(), const StatsPeriod.allTime());
        expect(
          const StatsPeriod.allTime().hashCode,
          const StatsPeriod.allTime().hashCode,
        );
      });

      test('should be equal when both periods carry the same year', () {
        expect(const StatsPeriod.year(2024), const StatsPeriod.year(2024));
        expect(
          const StatsPeriod.year(2024).hashCode,
          const StatsPeriod.year(2024).hashCode,
        );
      });

      test('should not be equal when years differ', () {
        expect(
          const StatsPeriod.year(2024),
          isNot(const StatsPeriod.year(2023)),
        );
      });

      test('should not be equal when one period is allTime', () {
        expect(
          const StatsPeriod.year(2024),
          isNot(const StatsPeriod.allTime()),
        );
      });
    });

    group('isAllTime', () {
      test('should return true when the period has no year', () {
        expect(const StatsPeriod.allTime().isAllTime, isTrue);
      });

      test('should return false when the period has a year', () {
        expect(const StatsPeriod.year(2024).isAllTime, isFalse);
      });
    });
  });

  group('StatsHours', () {
    group('totalMinutes', () {
      test('should sum manual, tracker and estimated minutes', () {
        const StatsHours hours = StatsHours(
          manualMinutes: 30,
          trackerMinutes: 40,
          estimatedMinutes: 50,
        );

        expect(hours.totalMinutes, 120);
      });
    });

    group('totalHours', () {
      test('should truncate partial hours when dividing minutes', () {
        const StatsHours hours = StatsHours(
          manualMinutes: 61,
          trackerMinutes: 0,
          estimatedMinutes: 58,
        );

        expect(hours.totalHours, 1);
      });

      test('should return whole hours when the total divides evenly', () {
        const StatsHours hours = StatsHours(
          manualMinutes: 60,
          trackerMinutes: 60,
          estimatedMinutes: 60,
        );

        expect(hours.totalHours, 3);
      });
    });

    group('empty', () {
      test('should carry zero minutes in every bucket when empty', () {
        const StatsHours hours = StatsHours.empty();

        expect(hours.manualMinutes, 0);
        expect(hours.trackerMinutes, 0);
        expect(hours.estimatedMinutes, 0);
        expect(hours.totalMinutes, 0);
        expect(hours.totalHours, 0);
      });
    });
  });

  group('MonthActivity', () {
    group('activity', () {
      test('should sum items added and episodes watched', () {
        const MonthActivity month = MonthActivity(
          year: 2024,
          month: 5,
          itemsAdded: 3,
          episodesWatched: 7,
        );

        expect(month.activity, 10);
      });

      test('should return zero when the month has no data', () {
        const MonthActivity month = MonthActivity(
          year: 2024,
          month: 1,
          itemsAdded: 0,
          episodesWatched: 0,
        );

        expect(month.activity, 0);
      });
    });
  });

  group('RatingDelta', () {
    group('delta', () {
      test('should be positive when the user rates above the crowd', () {
        final RatingDelta delta = RatingDelta(
          item: createTestCollectionItem(),
          mine: 9.0,
          external: 6.5,
        );

        expect(delta.delta, closeTo(2.5, 0.0001));
      });

      test('should be negative when the user rates below the crowd', () {
        final RatingDelta delta = RatingDelta(
          item: createTestCollectionItem(),
          mine: 4.0,
          external: 7.0,
        );

        expect(delta.delta, closeTo(-3.0, 0.0001));
      });
    });
  });

  group('LibraryStats', () {
    group('isEmpty', () {
      test('should return true when items and episodes are both zero', () {
        expect(createEmptyLibraryStats().isEmpty, isTrue);
      });

      test('should return false when items were added in the period', () {
        const LibraryTotals totals = LibraryTotals(
          items: 4,
          completed: 1,
          replays: 0,
          likedUnits: 0,
          averageRating: null,
        );

        expect(_statsWithTotals(totals).isEmpty, isFalse);
      });

      test('should return false when only episodes were watched', () {
        const UnitsWatched units = UnitsWatched(
          tvEpisodes: 12,
          animeEpisodes: 0,
          moviesWatched: 0,
          mangaChapters: 0,
          bookPages: 0,
        );

        expect(
          _statsWithTotals(const LibraryTotals.empty(), units: units).isEmpty,
          isFalse,
        );
      });
    });

    group('hasTypeBreakdown', () {
      test('should return false when no type has a counted item', () {
        expect(
          _statsWithTotals(
            const LibraryTotals.empty(),
            typeStatus: const <MediaType, Map<ItemStatus, int>>{
              MediaType.game: <ItemStatus, int>{ItemStatus.completed: 0},
            },
          ).hasTypeBreakdown,
          isFalse,
        );
      });

      test('should return true when any type has a counted item', () {
        expect(
          _statsWithTotals(
            const LibraryTotals.empty(),
            typeStatus: const <MediaType, Map<ItemStatus, int>>{
              MediaType.game: <ItemStatus, int>{ItemStatus.completed: 0},
              MediaType.movie: <ItemStatus, int>{ItemStatus.planned: 1},
            },
          ).hasTypeBreakdown,
          isTrue,
        );
      });
    });

    group('hasMonthActivity', () {
      test('should return false when every month is idle', () {
        expect(
          _statsWithTotals(
            const LibraryTotals.empty(),
            months: <MonthActivity>[_month(), _month()],
          ).hasMonthActivity,
          isFalse,
        );
      });

      test('should return true when a month only watched episodes', () {
        expect(
          _statsWithTotals(
            const LibraryTotals.empty(),
            months: <MonthActivity>[_month(), _month(episodesWatched: 3)],
          ).hasMonthActivity,
          isTrue,
        );
      });
    });

    group('hasCrowdDeltas', () {
      test('should return false when both delta lists are empty', () {
        expect(createEmptyLibraryStats().hasCrowdDeltas, isFalse);
      });

      test('should return true when only the lower list has rows', () {
        final CollectionItem item = createTestCollectionItem(id: 1);

        expect(
          _statsWithTotals(
            const LibraryTotals.empty(),
            lowerThanCrowd: <RatingDelta>[
              RatingDelta(item: item, mine: 3, external: 8),
            ],
          ).hasCrowdDeltas,
          isTrue,
        );
      });
    });

    group('hasFormats', () {
      const FormatStats format = FormatStats(
        label: 'TV',
        count: 2,
        statusCounts: <ItemStatus, int>{},
        topItemIds: <int>[],
      );

      test('should return false when the type has no entry', () {
        expect(createEmptyLibraryStats().hasFormats(MediaType.anime), isFalse);
      });

      test('should return false when the type has an empty list', () {
        expect(
          _statsWithTotals(
            const LibraryTotals.empty(),
            formatsByType: const <MediaType, List<FormatStats>>{
              MediaType.anime: <FormatStats>[],
            },
          ).hasFormats(MediaType.anime),
          isFalse,
        );
      });

      test('should return true only for the type that has cards', () {
        final LibraryStats stats = _statsWithTotals(
          const LibraryTotals.empty(),
          formatsByType: const <MediaType, List<FormatStats>>{
            MediaType.anime: <FormatStats>[format],
          },
        );

        expect(stats.hasFormats(MediaType.anime), isTrue);
        expect(stats.hasFormats(MediaType.manga), isFalse);
      });
    });
  });
}
