import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/tmdb_api.dart';
import '../../../core/database/database_service.dart';
import '../../../shared/models/calendar_entry.dart';
import '../../../shared/models/calendar_recurrence.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/data_source.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/tracked_release.dart';
import '../../../shared/models/tv_episode.dart';
import '../../../shared/models/tv_season.dart';
import '../../../shared/models/tv_show.dart';
import '../models/release_event.dart';

/// Whether a TMDB title is currently tracked, for the detail-screen bell.
final AutoDisposeFutureProviderFamily<bool, ({int externalId, MediaType mediaType})>
    isReleaseTrackedProvider =
    FutureProvider.autoDispose.family<bool, ({int externalId, MediaType mediaType})>(
  (Ref ref, ({int externalId, MediaType mediaType}) key) {
    return ref
        .watch(trackedReleaseDaoProvider)
        .isTracked(key.externalId, DataSource.tmdb, key.mediaType);
  },
);

/// Whether an item has a manual calendar entry, for the detail-screen bell.
final AutoDisposeFutureProviderFamily<bool,
        ({int externalId, DataSource source, MediaType mediaType})>
    isCalendarEntryProvider = FutureProvider.autoDispose.family<bool,
        ({int externalId, DataSource source, MediaType mediaType})>(
  (Ref ref, ({int externalId, DataSource source, MediaType mediaType}) key) {
    return ref
        .watch(calendarEntryDaoProvider)
        .isAdded(key.externalId, key.source, key.mediaType);
  },
);

/// How many tracked episodes air today — for the navigation bell badge.
final Provider<int> releasesTodayCountProvider = Provider<int>((Ref ref) {
  final ReleasesCalendarData? data =
      ref.watch(releasesProvider).valueOrNull;
  if (data == null) return 0;
  final DateTime now = DateTime.now();
  return data.events
      .where((ReleaseEvent e) =>
          e.airDate.year == now.year &&
          e.airDate.month == now.month &&
          e.airDate.day == now.day)
      .length;
});

/// Episodes of every tracked show, laid out for the Releases calendar.
final AsyncNotifierProvider<ReleasesNotifier, ReleasesCalendarData>
    releasesProvider =
    AsyncNotifierProvider<ReleasesNotifier, ReleasesCalendarData>(
  ReleasesNotifier.new,
);

class ReleasesNotifier extends AsyncNotifier<ReleasesCalendarData> {
  static const Set<MediaType> _supported = <MediaType>{
    MediaType.tvShow,
    MediaType.animation,
  };

  /// Re-fetches seasons and episodes for every tracked show from TMDB and
  /// updates the cache, then rebuilds. Used by pull-to-refresh / the refresh
  /// button — the only way to pick up newly announced episodes.
  Future<void> refreshFromApi() async {
    final DatabaseService db = ref.read(databaseServiceProvider);
    final TmdbApi api = ref.read(tmdbApiProvider);
    final List<TrackedRelease> tracked = await db.trackedReleaseDao.getAll();

    for (final TrackedRelease t in tracked) {
      if (t.source != DataSource.tmdb || !_supported.contains(t.mediaType)) {
        continue;
      }
      try {
        final List<TvSeason> seasons = await api.getTvSeasons(t.externalId);
        if (seasons.isNotEmpty) await db.tvShowDao.upsertTvSeasons(seasons);
        for (final TvSeason s in seasons) {
          final List<TvEpisode> episodes =
              await api.getSeasonEpisodes(t.externalId, s.seasonNumber);
          if (episodes.isNotEmpty) await db.tvShowDao.upsertEpisodes(episodes);
        }
      } on Object {
        // Network/API failure for one show shouldn't abort the whole refresh.
      }
    }

    ref.invalidateSelf();
  }

  @override
  Future<ReleasesCalendarData> build() async {
    final DatabaseService db = ref.watch(databaseServiceProvider);
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    // Tidy past one-time manual entries before reading anything.
    await db.calendarEntryDao.deletePastOnce(today);

    final List<TrackedRelease> tracked = await db.trackedReleaseDao.getAll();
    final List<TrackedRelease> tmdb = tracked
        .where((TrackedRelease t) =>
            t.source == DataSource.tmdb && _supported.contains(t.mediaType))
        .toList();
    final List<CalendarEntry> manual = await db.calendarEntryDao.getAll();

    final List<List<ReleaseEvent>> perShow = await Future.wait(<Future<List<ReleaseEvent>>>[
      ...tmdb.map((TrackedRelease t) => _eventsForShow(db, t, today)),
      ...manual.map((CalendarEntry e) => _eventsForEntry(db, e, today)),
    ]);

    return ReleasesCalendarData(
      trackedCount: tmdb.length + manual.length,
      events: perShow.expand((List<ReleaseEvent> e) => e).toList(),
    );
  }

  /// Expands a manual entry into events for its occurrences within a year.
  Future<List<ReleaseEvent>> _eventsForEntry(
    DatabaseService db,
    CalendarEntry entry,
    DateTime today,
  ) async {
    final CollectionItem? item =
        await db.collectionDao.findCollectionItemWithData(
      collectionId: null,
      mediaType: entry.mediaType,
      externalId: entry.externalId,
    );
    if (item == null) return <ReleaseEvent>[];

    return <ReleaseEvent>[
      for (final DateTime date in _occurrences(entry, today))
        ReleaseEvent(
          externalId: entry.externalId,
          mediaType: entry.mediaType,
          showTitle: item.itemName,
          airDate: date,
          watched: false,
          isUpcoming: true,
          posterUrl: item.thumbnailUrl,
          imageType: item.imageType,
          cacheImageId: item.coverImageId,
          collectionId: item.collectionId,
          itemId: item.id,
        ),
    ];
  }

  /// Occurrence dates for an entry from today up to one year ahead.
  List<DateTime> _occurrences(CalendarEntry entry, DateTime today) {
    final DateTime start = DateTime(
      entry.startDate.year,
      entry.startDate.month,
      entry.startDate.day,
    );
    final DateTime horizon = today.add(const Duration(days: 365));

    switch (entry.recurrence) {
      case CalendarRecurrence.once:
        return start.isBefore(today) ? <DateTime>[] : <DateTime>[start];
      case CalendarRecurrence.weekly:
        final List<DateTime> out = <DateTime>[];
        for (int i = 0; i < 1000; i++) {
          final DateTime occ = start.add(Duration(days: 7 * i));
          if (occ.isAfter(horizon)) break;
          if (!occ.isBefore(today)) out.add(occ);
        }
        return out;
      case CalendarRecurrence.monthly:
        final List<DateTime> out = <DateTime>[];
        for (int i = 0; i < 400; i++) {
          final DateTime occ =
              DateTime(start.year, start.month + i, start.day);
          if (occ.isAfter(horizon)) break;
          if (!occ.isBefore(today)) out.add(occ);
        }
        return out;
    }
  }

  Future<List<ReleaseEvent>> _eventsForShow(
    DatabaseService db,
    TrackedRelease t,
    DateTime today,
  ) async {
    // The reads are independent — start them together.
    final Future<TvShow?> showF = db.tvShowDao.getTvShowByTmdbId(t.externalId);
    final Future<CollectionItem?> itemF = db.collectionDao.findCollectionItem(
      collectionId: null,
      mediaType: t.mediaType,
      externalId: t.externalId,
    );
    final Future<List<TvEpisode>> episodesF =
        db.tvShowDao.getEpisodesByShowId(t.externalId);

    final CollectionItem? item = await itemF;
    final TvShow? show = await showF;
    final List<TvEpisode> episodes = await episodesF;

    // Drop the show entirely once it is gone from every collection.
    if (item == null) return <ReleaseEvent>[];

    final String title = show?.title ?? item.itemName;

    final List<ReleaseEvent> events = <ReleaseEvent>[];
    for (final TvEpisode e in episodes) {
      final DateTime? date = DateTime.tryParse(e.airDate ?? '');
      if (date == null) continue;
      // The calendar lists today and upcoming episodes (drop past dates).
      if (DateTime(date.year, date.month, date.day).isBefore(today)) continue;
      events.add(ReleaseEvent(
        externalId: t.externalId,
        mediaType: t.mediaType,
        showTitle: title,
        season: e.seasonNumber,
        episode: e.episodeNumber,
        airDate: date,
        watched: false,
        isUpcoming: true,
        posterUrl: show?.posterThumbUrl,
        imageType: item.imageType,
        cacheImageId: item.coverImageId,
        collectionId: item.collectionId,
        itemId: item.id,
      ));
    }
    return events;
  }
}
