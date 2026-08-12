import 'dart:async';

import 'package:core/database/dao/collection_dao.dart';
import 'package:core/database/dao/stats_dao.dart';
import 'package:core/models/anime.dart';
import 'package:core/models/collection_item.dart';
import 'package:core/models/item_status.dart';
import 'package:core/models/manga.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_service.dart';
import '../models/library_stats.dart';

/// Minimum rated items a media type needs before its best/worst pair shows —
/// two, so best and worst are never the same title.
const int kVersusMinRatings = 2;

/// Minimum |my rating − source rating| for the "me vs the crowd" rows.
const double kCrowdMinDelta = 1.0;

/// How many items each cover strip shows.
const int kTopRatedCount = 6;
const int kCrowdRowCount = 6;
const int kWallCoverCount = 12;

/// Selected reporting window.
final StateProvider<StatsPeriod> statsPeriodProvider =
    StateProvider<StatsPeriod>((Ref ref) => const StatsPeriod.allTime());

/// The full statistics payload for the selected period.
final AutoDisposeFutureProvider<LibraryStats> libraryStatsProvider =
    FutureProvider.autoDispose<LibraryStats>((Ref ref) async {
  final StatsPeriod period = ref.watch(statsPeriodProvider);
  final StatsDao stats = ref.watch(statsDaoProvider);
  final CollectionDao items = ref.watch(collectionDaoProvider);
  final int? year = period.year;

  // Aggregates are independent of each other — fetch them in parallel and
  // keep only the hydration pass sequential (it needs the ids below).
  final (
    List<int> availableYears,
    Map<MediaType, Map<ItemStatus, int>> typeStatus,
    int rewatches,
    double? averageRating,
    ({int tv, int anime}) episodeSplit,
    ({int animeEpisodes, int mangaChapters, int bookPages}) counters,
    Map<MediaType, int> likedByType,
    int musicTracks,
  ) = await (
    stats.getAvailableYears(),
    stats.getTypeStatusCounts(year: year),
    stats.getRewatchSum(year: year),
    stats.getAverageRating(year: year),
    stats.getEpisodeSplit(year: year),
    stats.getProgressCounterSums(year: year),
    stats.getLikedUnitsByType(year: year),
    stats.getListenedTrackTotal(year: year),
  ).wait;

  // Library-wide status totals, folded across media types.
  final Map<ItemStatus, int> counts = <ItemStatus, int>{};
  for (final Map<ItemStatus, int> perStatus in typeStatus.values) {
    perStatus.forEach((ItemStatus status, int c) {
      counts[status] = (counts[status] ?? 0) + c;
    });
  }
  final int liked =
      likedByType.values.fold(0, (int sum, int c) => sum + c);

  final UnitsWatched units = UnitsWatched(
    tvEpisodes: episodeSplit.tv,
    animeEpisodes: episodeSplit.anime + counters.animeEpisodes,
    // "Movies watched" is the completed-movie count, already in the split.
    moviesWatched: typeStatus[MediaType.movie]?[ItemStatus.completed] ?? 0,
    mangaChapters: counters.mangaChapters,
    bookPages: counters.bookPages,
    musicTracks: musicTracks,
  );

  final LibraryTotals totals = LibraryTotals(
    items: counts.values.fold(0, (int sum, int c) => sum + c),
    completed: counts[ItemStatus.completed] ?? 0,
    replays: rewatches + (counts[ItemStatus.replaying] ?? 0),
    likedUnits: liked,
    averageRating: averageRating,
  );

  final (
    int manualMinutes,
    int trackerMinutes,
    int estimatedMinutes,
    Map<String, int> addedByMonth,
    Map<String, int> episodesByMonth,
    Map<String, int> bestByMonth,
    Map<int?, Map<ItemStatus, int>> statusByPlatform,
    Map<String, Map<ItemStatus, int>> animeFormatStatus,
    Map<String, Map<ItemStatus, int>> mangaFormatStatus,
  ) = await (
    stats.getManualMinutes(year: year),
    stats.getTrackerMinutes(year: year),
    stats.getEstimatedMinutes(year: year),
    stats.getAddedByMonth(year: year),
    stats.getEpisodesByMonth(year: year),
    stats.getBestItemByMonth(year: year),
    stats.getGamePlatformStatusCounts(year: year),
    stats.getSourceFormatStatusCounts(MediaType.anime, year: year),
    stats.getSourceFormatStatusCounts(MediaType.manga, year: year),
  ).wait;

  final StatsHours hours = StatsHours(
    manualMinutes: manualMinutes,
    trackerMinutes: trackerMinutes,
    estimatedMinutes: estimatedMinutes,
  );

  // Months: the chosen year, or the current year from January (all time).
  final List<MonthActivity> months = _monthBuckets(
    year: year,
    added: addedByMonth,
    episodes: episodesByMonth,
    best: bestByMonth,
  );

  final (
    List<Map<String, dynamic>> platformRows,
    Map<int?, int> trackerByPlatform,
    Map<int?, List<int>> topByPlatform,
    ({int titles, List<(String, int)> tags}) animeTags,
    ({int titles, List<(String, int)> tags}) mangaTags,
    Map<String, List<int>> animeTopByFormat,
    Map<String, List<int>> mangaTopByFormat,
    List<int> ratedIds,
  ) = await (
    stats.getGamePlatformRows(year: year),
    stats.getTrackerMinutesByPlatform(year: year),
    stats.getTopGamesByPlatform(year: year),
    stats.getSourceTagCounts(MediaType.anime, year: year),
    stats.getSourceTagCounts(MediaType.manga, year: year),
    stats.getTopItemsByFormat(MediaType.anime, year: year),
    stats.getTopItemsByFormat(MediaType.manga, year: year),
    stats.getRatedItemIds(year: year),
  ).wait;

  final List<PlatformStats> platforms = <PlatformStats>[
    for (final Map<String, dynamic> row in platformRows)
      PlatformStats(
        platformId: row['platform_id'] as int?,
        name: (row['abbreviation'] as String?) ?? (row['name'] as String?),
        gameCount: (row['games'] as int?) ?? 0,
        minutes: ((row['manual_minutes'] as int?) ?? 0) +
            (trackerByPlatform[row['platform_id'] as int?] ?? 0),
        topItemIds:
            topByPlatform[row['platform_id'] as int?] ?? const <int>[],
        statusCounts: statusByPlatform[row['platform_id'] as int?] ??
            const <ItemStatus, int>{},
      ),
  ]..sort((PlatformStats a, PlatformStats b) {
      // Popularity first: the platform with the most games leads.
      final int byGames = b.gameCount.compareTo(a.gameCount);
      return byGames != 0 ? byGames : b.minutes.compareTo(a.minutes);
    });

  final Map<MediaType, List<FormatStats>> formatsByType =
      <MediaType, List<FormatStats>>{
    MediaType.anime:
        _formatCards(MediaType.anime, animeFormatStatus, animeTopByFormat),
    MediaType.manga:
        _formatCards(MediaType.manga, mangaFormatStatus, mangaTopByFormat),
  }..removeWhere((MediaType _, List<FormatStats> cards) => cards.isEmpty);

  final List<SubgenreGroup> subgenres = <SubgenreGroup>[
    if (animeTags.tags.isNotEmpty)
      _subgenreGroup(MediaType.anime, animeTags),
    if (mangaTags.tags.isNotEmpty)
      _subgenreGroup(MediaType.manga, mangaTags),
  ];

  // One hydration pass for everything that shows a cover.
  final Set<int> coverIds = <int>{
    ...ratedIds,
    ...bestByMonth.values,
    for (final PlatformStats p in platforms) ...p.topItemIds,
    for (final List<FormatStats> cards in formatsByType.values)
      for (final FormatStats f in cards) ...f.topItemIds,
  };
  final List<CollectionItem> hydrated =
      await items.getItemsWithDataByRowIds(coverIds.toList());
  final Map<int, CollectionItem> coversById = <int, CollectionItem>{
    for (final CollectionItem item in hydrated) item.id: item,
  };

  final List<CollectionItem> rated = <CollectionItem>[
    for (final int id in ratedIds)
      if (coversById[id] != null && coversById[id]!.userRating != null)
        coversById[id]!,
  ]..sort((CollectionItem a, CollectionItem b) =>
      b.userRating!.compareTo(a.userRating!));

  return LibraryStats(
    period: period,
    availableYears: availableYears,
    totals: totals,
    units: units,
    typeStatus: typeStatus,
    likedByType: likedByType,
    hours: hours,
    months: months,
    platforms: platforms,
    formatsByType: formatsByType,
    subgenres: subgenres,
    versus: _versusPairs(rated),
    topRated: rated.take(kTopRatedCount).toList(),
    higherThanCrowd: _crowdDeltas(rated, higher: true),
    lowerThanCrowd: _crowdDeltas(rated, higher: false),
    wallItems: rated
        .where((CollectionItem i) => i.thumbnailUrl != null)
        .take(kWallCoverCount)
        .toList(),
    coversById: coversById,
  );
});

/// Drill-down payload for one month, keyed by (year, month).
final AutoDisposeFutureProviderFamily<MonthDetail, (int, int)>
    monthDetailProvider = FutureProvider.autoDispose
        .family<MonthDetail, (int, int)>((Ref ref, (int, int) key) async {
  final StatsDao stats = ref.watch(statsDaoProvider);
  final (int year, int month) = key;

  final List<(int, MediaType, int)> byDayType =
      await stats.getMonthAddedByDayType(year, month);

  // Day buckets 1–7, 8–14, 15–21, 22–28, 29+ — simpler than ISO weeks,
  // which straddle month borders.
  final List<Map<MediaType, int>> weeks =
      List<Map<MediaType, int>>.generate(5, (_) => <MediaType, int>{});
  int totalAdded = 0;
  for (final (int day, MediaType type, int count) in byDayType) {
    final int bucket = ((day - 1) ~/ 7).clamp(0, 4);
    weeks[bucket][type] = (weeks[bucket][type] ?? 0) + count;
    totalAdded += count;
  }

  return MonthDetail(
    year: year,
    month: month,
    weeks: weeks,
    totalAdded: totalAdded,
  );
});

/// Month buckets: the selected calendar year, or the current year up to
/// this month when [year] is null (all time).
List<MonthActivity> _monthBuckets({
  required int? year,
  required Map<String, int> added,
  required Map<String, int> episodes,
  required Map<String, int> best,
}) {
  final List<(int, int)> keys = <(int, int)>[];
  if (year != null) {
    for (int m = 1; m <= 12; m++) {
      keys.add((year, m));
    }
  } else {
    // All time: the current local year from January up to this month.
    final DateTime now = DateTime.now();
    for (int m = 1; m <= now.month; m++) {
      keys.add((now.year, m));
    }
  }
  return <MonthActivity>[
    for (final (int, int) key in keys)
      MonthActivity(
        year: key.$1,
        month: key.$2,
        itemsAdded: added[_ym(key.$1, key.$2)] ?? 0,
        episodesWatched: episodes[_ym(key.$1, key.$2)] ?? 0,
        bestItemId: best[_ym(key.$1, key.$2)],
      ),
  ];
}

String _ym(int year, int month) =>
    '$year-${month.toString().padLeft(2, '0')}';

SubgenreGroup _subgenreGroup(
  MediaType type,
  ({int titles, List<(String, int)> tags}) group,
) {
  return SubgenreGroup(
    mediaType: type,
    titleCount: group.titles,
    tags: <TagCount>[
      for (final (String, int) t in group.tags) TagCount(t.$1, t.$2),
    ],
  );
}

/// Format cards for one media type: status maps keyed by raw source codes
/// become labelled, sorted cards with their top covers attached.
List<FormatStats> _formatCards(
  MediaType type,
  Map<String, Map<ItemStatus, int>> statusByFormat,
  Map<String, List<int>> topByFormat,
) {
  String label(String code) => type == MediaType.anime
      ? Anime.animeFormatLabel(code) ?? code
      : Manga.mangaFormatLabel(code) ?? code;
  final List<FormatStats> cards = <FormatStats>[
    for (final MapEntry<String, Map<ItemStatus, int>> entry
        in statusByFormat.entries)
      FormatStats(
        label: label(entry.key),
        count: entry.value.values.fold(0, (int sum, int c) => sum + c),
        statusCounts: entry.value,
        topItemIds: topByFormat[entry.key] ?? const <int>[],
      ),
  ]..sort((FormatStats a, FormatStats b) => b.count.compareTo(a.count));
  return cards;
}

/// Best/worst pairs per media type, only where at least [kVersusMinRatings]
/// items are rated. [rated] must be sorted by rating descending.
List<VersusPair> _versusPairs(List<CollectionItem> rated) {
  final Map<MediaType, List<CollectionItem>> byType =
      <MediaType, List<CollectionItem>>{};
  for (final CollectionItem item in rated) {
    byType.putIfAbsent(item.displayMediaType, () => <CollectionItem>[]).add(item);
  }
  final List<VersusPair> pairs = <VersusPair>[];
  byType.forEach((MediaType type, List<CollectionItem> list) {
    if (list.length < kVersusMinRatings) return;
    pairs.add(VersusPair(
      mediaType: type,
      best: list.first,
      worst: list.last,
      ratedCount: list.length,
    ));
  });
  pairs.sort((VersusPair a, VersusPair b) =>
      b.ratedCount.compareTo(a.ratedCount));
  return pairs;
}

/// Rows where the user's rating differs most from the source rating (both
/// normalised to 0–10 by the models). [higher]: user above the crowd.
List<RatingDelta> _crowdDeltas(
  List<CollectionItem> rated, {
  required bool higher,
}) {
  final List<RatingDelta> deltas = <RatingDelta>[
    for (final CollectionItem item in rated)
      if (item.apiRating != null)
        RatingDelta(
          item: item,
          mine: item.userRating!,
          external: item.apiRating!,
        ),
  ];
  final List<RatingDelta> side = deltas
      .where((RatingDelta d) =>
          higher ? d.delta >= kCrowdMinDelta : d.delta <= -kCrowdMinDelta)
      .toList()
    ..sort((RatingDelta a, RatingDelta b) =>
        higher ? b.delta.compareTo(a.delta) : a.delta.compareTo(b.delta));
  return side.take(kCrowdRowCount).toList();
}
