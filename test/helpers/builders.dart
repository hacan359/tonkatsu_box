import 'package:core/models/collection_item.dart';
import 'package:core/models/item_status.dart';
import 'package:core/models/media_type.dart';
import 'package:tonkatsu_box/core/api/steam_api.dart';
import 'package:tonkatsu_box/data/repositories/collection_repository.dart';
import 'package:tonkatsu_box/features/statistics/models/library_stats.dart';

// Model factories live in the core package so its own tests can use them too.
export 'package:core/testing/builders.dart';

CollectionStats createTestStats({
  int total = 5,
  int completed = 2,
  int inProgress = 1,
  int notStarted = 1,
  int dropped = 0,
  int planned = 1,
  int gameCount = 0,
  int movieCount = 0,
  int tvShowCount = 0,
  int animationCount = 0,
  int visualNovelCount = 0,
  int mangaCount = 0,
}) {
  return CollectionStats(
    total: total,
    completed: completed,
    inProgress: inProgress,
    notStarted: notStarted,
    dropped: dropped,
    planned: planned,
    gameCount: gameCount,
    movieCount: movieCount,
    tvShowCount: tvShowCount,
    animationCount: animationCount,
    visualNovelCount: visualNovelCount,
    mangaCount: mangaCount,
  );
}

SteamOwnedGame createTestSteamOwnedGame({
  int appId = 440,
  String name = 'Team Fortress 2',
  int playtimeMinutes = 1250,
  DateTime? lastPlayed,
}) {
  return SteamOwnedGame(
    appId: appId,
    name: name,
    playtimeMinutes: playtimeMinutes,
    lastPlayed: lastPlayed,
  );
}

LibraryStats createEmptyLibraryStats({
  StatsPeriod period = const StatsPeriod.allTime(),
}) {
  return LibraryStats(
    period: period,
    availableYears: const <int>[],
    totals: const LibraryTotals.empty(),
    units: const UnitsWatched.empty(),
    typeStatus: const <MediaType, Map<ItemStatus, int>>{},
    likedByType: const <MediaType, int>{},
    hours: const StatsHours.empty(),
    months: const <MonthActivity>[],
    platforms: const <PlatformStats>[],
    formatsByType: const <MediaType, List<FormatStats>>{},
    subgenres: const <SubgenreGroup>[],
    versus: const <VersusPair>[],
    topRated: const <CollectionItem>[],
    higherThanCrowd: const <RatingDelta>[],
    lowerThanCrowd: const <RatingDelta>[],
    wallItems: const <CollectionItem>[],
    coversById: const <int, CollectionItem>{},
  );
}
