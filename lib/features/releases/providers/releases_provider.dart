import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/tmdb_api.dart';
import '../../../core/database/database_service.dart';
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
        if (seasons.isNotEmpty) await db.upsertTvSeasons(seasons);
        for (final TvSeason s in seasons) {
          final List<TvEpisode> episodes =
              await api.getSeasonEpisodes(t.externalId, s.seasonNumber);
          if (episodes.isNotEmpty) await db.upsertEpisodes(episodes);
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

    final List<TrackedRelease> tracked = await db.trackedReleaseDao.getAll();
    final List<TrackedRelease> tmdb = tracked
        .where((TrackedRelease t) =>
            t.source == DataSource.tmdb && _supported.contains(t.mediaType))
        .toList();

    final List<List<ReleaseEvent>> perShow = await Future.wait(
      tmdb.map((TrackedRelease t) => _eventsForShow(db, t, today)),
    );

    return ReleasesCalendarData(
      trackedCount: tmdb.length,
      events: perShow.expand((List<ReleaseEvent> e) => e).toList(),
    );
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
        collectionId: item.collectionId,
        itemId: item.id,
      ));
    }
    return events;
  }
}
