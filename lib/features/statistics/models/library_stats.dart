import '../../../shared/models/collection_item.dart';
import '../../../shared/models/item_status.dart';
import '../../../shared/models/media_type.dart';

/// Reporting window for the statistics page: a calendar [year], or all time
/// when [year] is null.
class StatsPeriod {
  /// All-time window.
  const StatsPeriod.allTime() : year = null;

  /// A single calendar year.
  const StatsPeriod.year(int this.year);

  /// Calendar year, or null for all time.
  final int? year;

  /// Whether this period spans the whole library.
  bool get isAllTime => year == null;

  @override
  bool operator ==(Object other) => other is StatsPeriod && other.year == year;

  @override
  int get hashCode => year.hashCode;
}

/// Headline counters for the hero strip.
class LibraryTotals {
  /// Creates library totals.
  const LibraryTotals({
    required this.items,
    required this.completed,
    required this.replays,
    required this.likedUnits,
    required this.averageRating,
  });

  /// Empty totals (no data in the period).
  const LibraryTotals.empty()
      : items = 0,
        completed = 0,
        replays = 0,
        likedUnits = 0,
        averageRating = null;

  /// Items added in the period.
  final int items;

  /// Of those, how many are completed.
  final int completed;

  /// Rewatch/replay counters summed, plus items currently in replay.
  final int replays;

  /// Liked units (episodes/chapters) — item marks, not favorite items.
  final int likedUnits;

  /// Average of user ratings in the period, or null when nothing is rated.
  final double? averageRating;
}

/// Watched/read unit counts split by medium. Anime combines the Kitsu episode
/// tracker with AniList flat counters; manga/books are flat counters only.
class UnitsWatched {
  /// Creates the unit split.
  const UnitsWatched({
    required this.tvEpisodes,
    required this.animeEpisodes,
    required this.moviesWatched,
    required this.mangaChapters,
    required this.bookPages,
  });

  /// Nothing watched or read.
  const UnitsWatched.empty()
      : tvEpisodes = 0,
        animeEpisodes = 0,
        moviesWatched = 0,
        mangaChapters = 0,
        bookPages = 0;

  /// TV episodes marked watched (TMDB / TVmaze trackers).
  final int tvEpisodes;

  /// Anime episodes: Kitsu tracker marks plus AniList progress counters.
  final int animeEpisodes;

  /// Completed movies.
  final int moviesWatched;

  /// Manga chapters read (progress counters).
  final int mangaChapters;

  /// Book pages read (progress counters).
  final int bookPages;

  /// TV and anime episodes combined.
  int get episodes => tvEpisodes + animeEpisodes;
}

/// Time spent, split by how trustworthy the source is: manually entered and
/// tracker-reported minutes are facts, runtime-based estimates are not.
class StatsHours {
  /// Creates the hours split.
  const StatsHours({
    required this.manualMinutes,
    required this.trackerMinutes,
    required this.estimatedMinutes,
  });

  /// No recorded time.
  const StatsHours.empty()
      : manualMinutes = 0,
        trackerMinutes = 0,
        estimatedMinutes = 0;

  /// Minutes the user typed into the "time spent" field.
  final int manualMinutes;

  /// Minutes reported by achievement trackers (RetroAchievements).
  final int trackerMinutes;

  /// Minutes estimated from cached runtimes (watched episodes and completed
  /// movies, rewatches included).
  final int estimatedMinutes;

  /// Everything combined.
  int get totalMinutes => manualMinutes + trackerMinutes + estimatedMinutes;

  /// Total, in whole hours.
  int get totalHours => totalMinutes ~/ 60;
}

/// One month of the activity ribbon.
class MonthActivity {
  /// Creates a month bucket.
  const MonthActivity({
    required this.year,
    required this.month,
    required this.itemsAdded,
    required this.episodesWatched,
    this.bestItemId,
  });

  /// Calendar year.
  final int year;

  /// Calendar month, 1–12.
  final int month;

  /// Items added this month.
  final int itemsAdded;

  /// Episodes watched this month.
  final int episodesWatched;

  /// Row id of the highest-rated item added this month, for the cover.
  final int? bestItemId;

  /// Added + watched, the ribbon's bar value.
  int get activity => itemsAdded + episodesWatched;
}

/// Drill-down payload for one month of the ribbon.
class MonthDetail {
  /// Creates the month detail.
  const MonthDetail({
    required this.year,
    required this.month,
    required this.weeks,
    required this.totalAdded,
  });

  /// Calendar year.
  final int year;

  /// Calendar month, 1–12.
  final int month;

  /// Five day buckets (1–7, 8–14, 15–21, 22–28, 29+), each mapping a media
  /// type to how many items of it were added.
  final List<Map<MediaType, int>> weeks;

  /// Total items added this month.
  final int totalAdded;
}

/// One game platform card.
class PlatformStats {
  /// Creates a platform bucket.
  const PlatformStats({
    required this.platformId,
    required this.name,
    required this.gameCount,
    required this.minutes,
    required this.topItemIds,
    this.statusCounts = const <ItemStatus, int>{},
  });

  /// Platform row id; null groups games without a platform.
  final int? platformId;

  /// Display name (abbreviation preferred); null when the platform is not
  /// set — the widget shows a localized fallback.
  final String? name;

  /// Games on this platform (added in the period).
  final int gameCount;

  /// Manual + tracker minutes for those games.
  final int minutes;

  /// Row ids of the most-played titles, for the covers.
  final List<int> topItemIds;

  /// Status breakdown of this platform's games.
  final Map<ItemStatus, int> statusCounts;

  /// Whole hours of [minutes].
  int get hours => minutes ~/ 60;
}

/// A counted label (tag chips, subgenres).
class TagCount {
  /// Creates a counted tag.
  const TagCount(this.name, this.count);

  /// Tag label.
  final String name;

  /// How many items carry it.
  final int count;
}

/// Source-provided subgenre tags for one media type column.
class SubgenreGroup {
  /// Creates a subgenre column.
  const SubgenreGroup({
    required this.mediaType,
    required this.titleCount,
    required this.tags,
  });

  /// The media type the tags describe (anime or manga).
  final MediaType mediaType;

  /// How many titles contributed tags.
  final int titleCount;

  /// Tags sorted by count, capped by the DAO.
  final List<TagCount> tags;
}

/// One source-format card (TV/OVA/Movie for anime, manga/novel/one-shot
/// for manga) of a formats block.
class FormatStats {
  /// Creates a format bucket.
  const FormatStats({
    required this.label,
    required this.count,
    required this.statusCounts,
    required this.topItemIds,
  });

  /// Human-readable format label, already mapped from the source code.
  final String label;

  /// Titles of this format added in the period.
  final int count;

  /// Status breakdown of this format's titles.
  final Map<ItemStatus, int> statusCounts;

  /// Row ids of the highest-rated titles, for the covers.
  final List<int> topItemIds;
}

/// Best/worst pair for one media type (versus block).
class VersusPair {
  /// Creates a versus pair.
  const VersusPair({
    required this.mediaType,
    required this.best,
    required this.worst,
    required this.ratedCount,
  });

  /// The media type of the pair.
  final MediaType mediaType;

  /// Highest-rated item.
  final CollectionItem best;

  /// Lowest-rated item.
  final CollectionItem worst;

  /// How many rated items backed the pair.
  final int ratedCount;
}

/// One row of the "me vs the crowd" block.
class RatingDelta {
  /// Creates a rating delta row.
  const RatingDelta({
    required this.item,
    required this.mine,
    required this.external,
  });

  /// The item, hydrated for the cover and title.
  final CollectionItem item;

  /// The user's rating (0–10).
  final double mine;

  /// The source rating normalised to 0–10.
  final double external;

  /// Signed gap, positive when the user rates higher.
  double get delta => mine - external;
}

/// Everything the statistics screen renders.
class LibraryStats {
  /// Creates the full stats payload.
  const LibraryStats({
    required this.period,
    required this.availableYears,
    required this.totals,
    required this.units,
    required this.typeStatus,
    required this.likedByType,
    required this.hours,
    required this.months,
    required this.platforms,
    required this.formatsByType,
    required this.subgenres,
    required this.versus,
    required this.topRated,
    required this.higherThanCrowd,
    required this.lowerThanCrowd,
    required this.wallItems,
    required this.coversById,
  });

  /// The period the payload was computed for.
  final StatsPeriod period;

  /// Years that have any added items, newest first (for the period picker).
  final List<int> availableYears;

  /// Hero counters.
  final LibraryTotals totals;

  /// Watched/read units split by medium.
  final UnitsWatched units;

  /// Status breakdown per media type — feeds the per-type detail blocks.
  final Map<MediaType, Map<ItemStatus, int>> typeStatus;

  /// Liked units per media type of the owning item.
  final Map<MediaType, int> likedByType;

  /// Time spent split.
  final StatsHours hours;

  /// Twelve activity buckets, oldest first.
  final List<MonthActivity> months;

  /// Game platform cards, biggest first.
  final List<PlatformStats> platforms;

  /// Source format cards per media type (anime, manga), biggest first;
  /// types with no format data are absent.
  final Map<MediaType, List<FormatStats>> formatsByType;

  /// Source subgenre columns (anime, manga) that have data.
  final List<SubgenreGroup> subgenres;

  /// Best/worst pairs per media type with enough ratings.
  final List<VersusPair> versus;

  /// Highest-rated items of the period.
  final List<CollectionItem> topRated;

  /// Items the user rates far above the source rating.
  final List<RatingDelta> higherThanCrowd;

  /// Items the user rates far below the source rating.
  final List<RatingDelta> lowerThanCrowd;

  /// Covers for the hero wall / share collage (best rated with covers).
  final List<CollectionItem> wallItems;

  /// Hydrated items referenced by [months] and [platforms], keyed by row id.
  final Map<int, CollectionItem> coversById;

  /// True when the period has nothing to show.
  bool get isEmpty => totals.items == 0 && units.episodes == 0;
}
