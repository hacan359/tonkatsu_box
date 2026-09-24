import 'dart:async';

import 'package:core/models/collection_item.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/item_status.dart';
import 'package:core/models/item_status_logic.dart';
import 'package:core/models/tv_episode.dart';
import 'package:core/models/tv_season.dart';
import 'package:core/models/tv_show.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../core/api/episode_source/tv_episode_source.dart';
import '../../../core/database/database_service.dart';
import 'collections_provider.dart';

class EpisodeTrackerState {
  const EpisodeTrackerState({
    this.episodesBySeason = const <int, List<TvEpisode>>{},
    this.watchedEpisodes = const <(int, int), DateTime?>{},
    this.loadingSeasons = const <int, bool>{},
    this.totalEpisodes,
    this.error,
  });

  final Map<int, List<TvEpisode>> episodesBySeason;

  /// Watched episodes: (seasonNumber, episodeNumber) -> watch date.
  final Map<(int, int), DateTime?> watchedEpisodes;

  final Map<int, bool> loadingSeasons;

  /// Show's official episode count resolved by the tracker (specials
  /// excluded). Fallback for cards whose cached [TvShow] has no totals.
  final int? totalEpisodes;

  final String? error;

  EpisodeTrackerState copyWith({
    Map<int, List<TvEpisode>>? episodesBySeason,
    Map<(int, int), DateTime?>? watchedEpisodes,
    Map<int, bool>? loadingSeasons,
    int? totalEpisodes,
    String? error,
  }) {
    return EpisodeTrackerState(
      episodesBySeason: episodesBySeason ?? this.episodesBySeason,
      watchedEpisodes: watchedEpisodes ?? this.watchedEpisodes,
      loadingSeasons: loadingSeasons ?? this.loadingSeasons,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      error: error,
    );
  }

  bool isEpisodeWatched(int season, int episode) {
    return watchedEpisodes.containsKey((season, episode));
  }

  DateTime? getWatchedAt(int season, int episode) {
    return watchedEpisodes[(season, episode)];
  }

  int watchedCountForSeason(int season) {
    int count = 0;
    for (final (int s, int _) in watchedEpisodes.keys) {
      if (s == season) count++;
    }
    return count;
  }

  /// Specials (season 0) are excluded: TMDB's `number_of_episodes` does not
  /// count them, so they must not count toward overall progress either.
  int get totalWatchedCount {
    int count = 0;
    for (final (int s, int _) in watchedEpisodes.keys) {
      if (s > 0) count++;
    }
    return count;
  }

  /// Returns the total number of loaded episodes, excluding specials
  /// (season 0) — see [totalWatchedCount].
  int get totalEpisodeCount {
    int count = 0;
    for (final MapEntry<int, List<TvEpisode>> entry
        in episodesBySeason.entries) {
      if (entry.key > 0) count += entry.value.length;
    }
    return count;
  }
}

/// Watched marks keyed by (season, episode); a null date is a legacy import.
typedef WatchedMarks = Map<(int, int), DateTime?>;

/// Family argument of the episode tracker. `source` selects the
/// season/episode provider ([TvEpisodeSource]) and namespaces DB rows.
typedef EpisodeTrackerArg = ({
  int? collectionId,
  int showId,
  DataSource source,
});

/// When collectionId == null (uncategorized), tracking is disabled.
final NotifierProviderFamily<EpisodeTrackerNotifier, EpisodeTrackerState,
        EpisodeTrackerArg>
    episodeTrackerNotifierProvider = NotifierProvider.family<
        EpisodeTrackerNotifier,
        EpisodeTrackerState,
        EpisodeTrackerArg>(
  EpisodeTrackerNotifier.new,
);

class EpisodeTrackerNotifier
    extends FamilyNotifier<EpisodeTrackerState, EpisodeTrackerArg> {
  static final Logger _log = Logger('EpisodeTrackerNotifier');
  static const int _watchedDateHour = 12;

  late DatabaseService _db;
  late TvEpisodeSource _episodeSource;
  late int? _collectionId;
  late int _showId;
  late DataSource _source;

  // Show totals fetched from the source API, cached so we don't re-query on
  // every toggleEpisode/toggleSeason.
  int? _cachedTotalEpisodes;
  int? _cachedTotalSeasons;
  bool _hasFetchedTotals = false;

  @override
  EpisodeTrackerState build(EpisodeTrackerArg arg) {
    _collectionId = arg.collectionId;
    _showId = arg.showId;
    _source = arg.source;
    _db = ref.watch(databaseServiceProvider);
    _episodeSource = ref.watch(tvEpisodeSourceResolverProvider)(arg.source);

    // Episode tracking is not supported for uncategorized items
    if (_collectionId == null) return const EpisodeTrackerState();

    // Only cheap queries run eagerly (grid cards need just counts/totals);
    // the full episode cache loads lazily via ensureCachedEpisodesLoaded.
    Future<void>.microtask(_loadWatchedEpisodes);
    Future<void>.microtask(_resolveCachedTotals);

    return const EpisodeTrackerState();
  }

  bool _cachedEpisodesLoaded = false;

  /// Loads the cached episode metadata once; the detail screen calls this —
  /// cards don't need it.
  Future<void> ensureCachedEpisodesLoaded() async {
    if (_cachedEpisodesLoaded) return;
    _cachedEpisodesLoaded = true;
    await _loadCachedEpisodes();
  }

  /// Resolves totals from the local cache so badges render "x/y" even when
  /// the cached show row has none; specials excluded ([totalWatchedCount]).
  Future<void> _resolveCachedTotals() async {
    try {
      final TvShow? show =
          await _db.tvShowDao.getTvShowByTmdbId(_showId, source: _source);
      int total = show?.totalEpisodes ?? 0;
      if (total == 0) {
        final List<TvSeason> seasons =
            await _db.tvShowDao.getTvSeasonsByShowId(_source, _showId);
        for (final TvSeason season in seasons) {
          if (season.seasonNumber > 0) {
            total += season.episodeCount ?? 0;
          }
        }
      }
      if (total > 0 && state.totalEpisodes == null) {
        state = state.copyWith(totalEpisodes: total);
      }
    } on Exception catch (_) {
      // Cache read failed — totals stay unknown, badges show bare counts.
    }
  }

  Future<void> _loadWatchedEpisodes() async {
    final int? collId = _collectionId;
    if (collId == null) return;
    try {
      final Map<(int, int), DateTime?> watched =
          await _db.tvShowDao.getWatchedEpisodes(collId, _source, _showId);
      state = state.copyWith(watchedEpisodes: watched);
    } on Exception catch (e) {
      state = state.copyWith(error: 'Failed to load watched episodes: $e');
    }
  }

  /// One network-free query so the marks summary/filter resolve episode names
  /// up front; uncached seasons still lazy-load from TMDB on expand.
  Future<void> _loadCachedEpisodes() async {
    try {
      final List<TvEpisode> episodes =
          await _db.tvShowDao.getEpisodesByShowId(_source, _showId);
      if (episodes.isEmpty) return;
      final Map<int, List<TvEpisode>> bySeason = <int, List<TvEpisode>>{};
      for (final TvEpisode ep in episodes) {
        (bySeason[ep.seasonNumber] ??= <TvEpisode>[]).add(ep);
      }
      state = state.copyWith(
        episodesBySeason: <int, List<TvEpisode>>{
          ...bySeason,
          ...state.episodesBySeason,
        },
      );
    } on Exception catch (_) {
      // Cache read failed — non-fatal; seasons still load lazily on expand.
    }
  }

  Future<void> loadSeason(int seasonNumber) async {
    if (state.episodesBySeason.containsKey(seasonNumber)) return;
    if (state.loadingSeasons[seasonNumber] == true) return;

    state = state.copyWith(
      loadingSeasons: <int, bool>{
        ...state.loadingSeasons,
        seasonNumber: true,
      },
    );

    try {
      List<TvEpisode> episodes =
          await _db.tvShowDao
              .getEpisodesByShowAndSeason(_source, _showId, seasonNumber);

      if (episodes.isEmpty) {
        episodes =
            await _episodeSource.getSeasonEpisodes(_showId, seasonNumber);
        if (episodes.isNotEmpty) {
          await _db.tvShowDao.upsertEpisodes(episodes);
        }
      }

      state = state.copyWith(
        episodesBySeason: <int, List<TvEpisode>>{
          ...state.episodesBySeason,
          seasonNumber: episodes,
        },
        loadingSeasons: <int, bool>{
          ...state.loadingSeasons,
          seasonNumber: false,
        },
        error: null,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        loadingSeasons: <int, bool>{
          ...state.loadingSeasons,
          seasonNumber: false,
        },
        error: 'Failed to load season $seasonNumber: $e',
      );
    }
  }

  /// Force-refreshes a season's episodes from the API (adds new ones,
  /// refreshes existing metadata, leaves watched statuses untouched).
  Future<void> refreshSeason(int seasonNumber) async {
    if (state.loadingSeasons[seasonNumber] == true) return;

    state = state.copyWith(
      loadingSeasons: <int, bool>{
        ...state.loadingSeasons,
        seasonNumber: true,
      },
    );

    try {
      final List<TvEpisode> episodes =
          await _episodeSource.getSeasonEpisodes(_showId, seasonNumber);
      if (episodes.isNotEmpty) {
        await _db.tvShowDao.upsertEpisodes(episodes);
      }

      state = state.copyWith(
        episodesBySeason: <int, List<TvEpisode>>{
          ...state.episodesBySeason,
          seasonNumber: episodes,
        },
        loadingSeasons: <int, bool>{
          ...state.loadingSeasons,
          seasonNumber: false,
        },
        error: null,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        loadingSeasons: <int, bool>{
          ...state.loadingSeasons,
          seasonNumber: false,
        },
        error: 'Failed to refresh season $seasonNumber: $e',
      );
    }
  }

  /// Returns the marks an unmark removed (empty when it marked), so the
  /// caller can offer an undo that brings the old dates back.
  Future<WatchedMarks> toggleEpisode(int season, int episode) async {
    final int? collId = _collectionId;
    if (collId == null) return const <(int, int), DateTime?>{};
    final bool isWatched = state.isEpisodeWatched(season, episode);
    WatchedMarks removed = const <(int, int), DateTime?>{};

    if (isWatched) {
      removed = <(int, int), DateTime?>{
        (season, episode): state.watchedEpisodes[(season, episode)],
      };
      await _db.tvShowDao.markEpisodeUnwatched(
          collId, _source, _showId, season, episode);
      final Map<(int, int), DateTime?> updated =
          Map<(int, int), DateTime?>.of(state.watchedEpisodes)
            ..remove((season, episode));
      state = state.copyWith(watchedEpisodes: updated);
    } else {
      await _db.tvShowDao.markEpisodeWatched(
          collId, _source, _showId, season, episode);
      final Map<(int, int), DateTime?> updated =
          Map<(int, int), DateTime?>.of(state.watchedEpisodes)
            ..[(season, episode)] = DateTime.now();
      state = state.copyWith(watchedEpisodes: updated);
    }

    unawaited(_updateAutoStatus());
    return removed;
  }

  /// Same contract as [toggleEpisode]: returns what an unmark removed.
  Future<WatchedMarks> toggleSeason(int season) async {
    final int? collId = _collectionId;
    if (collId == null) return const <(int, int), DateTime?>{};
    final List<TvEpisode>? episodes = state.episodesBySeason[season];
    if (episodes == null || episodes.isEmpty) {
      return const <(int, int), DateTime?>{};
    }

    final int watchedCount = state.watchedCountForSeason(season);
    final bool allWatched = watchedCount == episodes.length;
    WatchedMarks removed = const <(int, int), DateTime?>{};

    if (allWatched) {
      removed = <(int, int), DateTime?>{
        for (final MapEntry<(int, int), DateTime?> e
            in state.watchedEpisodes.entries)
          if (e.key.$1 == season) e.key: e.value,
      };
      await _db.tvShowDao.unmarkSeasonWatched(
          collId, _source, _showId, season);
      // The DELETE is season-wide, so marks outside the loaded list go too.
      final Map<(int, int), DateTime?> updated =
          Map<(int, int), DateTime?>.of(state.watchedEpisodes)
            ..removeWhere(((int, int) key, DateTime? _) => key.$1 == season);
      state = state.copyWith(watchedEpisodes: updated);
    } else {
      final List<int> episodeNumbers =
          episodes.map((TvEpisode ep) => ep.episodeNumber).toList();
      await _db.tvShowDao.markSeasonWatched(
          collId, _source, _showId, season, episodeNumbers);
      final DateTime now = DateTime.now();
      final Map<(int, int), DateTime?> updated =
          Map<(int, int), DateTime?>.of(state.watchedEpisodes);
      for (final int ep in episodeNumbers) {
        updated[(season, ep)] = now;
      }
      state = state.copyWith(watchedEpisodes: updated);
    }

    unawaited(_updateAutoStatus());
    return removed;
  }

  /// Undo for an unmark: writes the marks back with their original dates.
  /// [syncStatus] is off when the caller restores the status itself.
  Future<void> restoreWatched(
    WatchedMarks marks, {
    bool syncStatus = true,
  }) async {
    final int? collId = _collectionId;
    if (collId == null || marks.isEmpty) return;
    try {
      await _db.tvShowDao.markEpisodesWatchedAt(collId, _source, _showId, <(
        int,
        int,
        int?,
      )>[
        for (final MapEntry<(int, int), DateTime?> e in marks.entries)
          (e.key.$1, e.key.$2, e.value?.millisecondsSinceEpoch),
      ]);
      state = state.copyWith(
        watchedEpisodes: <(int, int), DateTime?>{
          ...state.watchedEpisodes,
          ...marks,
        },
      );
    } on Exception catch (e) {
      _log.warning('Failed to restore episode marks of show $_showId', e);
      return;
    }
    if (syncStatus) unawaited(_updateAutoStatus());
  }

  /// Written at local noon: stats bucket months in local time, and midnight
  /// would push an edge-of-month episode into the neighbouring month.
  Future<void> setEpisodeWatchedDate(
    int season,
    int episode,
    DateTime? date,
  ) async {
    final int? collId = _collectionId;
    if (collId == null || !state.isEpisodeWatched(season, episode)) return;
    final DateTime? stamp = date == null
        ? null
        : DateTime(date.year, date.month, date.day, _watchedDateHour);
    try {
      final bool existed = await _db.tvShowDao.updateEpisodeWatchedAt(collId,
          _source, _showId, season, episode, stamp?.millisecondsSinceEpoch);
      if (!existed) return;
      state = state.copyWith(
        watchedEpisodes: <(int, int), DateTime?>{
          ...state.watchedEpisodes,
          (season, episode): stamp,
        },
      );
    } on Exception catch (e) {
      _log.warning('Failed to set watched date of show $_showId', e);
    }
  }

  Future<void> _updateAutoStatus() async {
    final int? collId = _collectionId;
    if (collId == null) return;

    final int totalWatched = state.totalWatchedCount;

    final List<CollectionItem>? items = ref
        .read(collectionItemsNotifierProvider(collId))
        .valueOrNull;
    if (items == null) return;

    CollectionItem? targetItem;
    for (final CollectionItem ci in items) {
      if (ci.externalId == _showId &&
          ci.dataSource == _source &&
          ci.usesEpisodeTracker) {
        targetItem = ci;
        break;
      }
    }
    if (targetItem == null) return;

    // Kitsu anime have no cached `tvShow` row, but the anime record already
    // carries the episode count — that spares a request on every toggle.
    int totalInShow = _cachedTotalEpisodes ??
        targetItem.tvShow?.totalEpisodes ??
        targetItem.anime?.episodes ??
        0;
    int totalSeasons = _cachedTotalSeasons ??
        targetItem.tvShow?.totalSeasons ??
        0;

    // Fetch missing totals from the source API once per session, so a
    // toggle doesn't turn into a network call every time.
    if ((totalInShow == 0 || totalSeasons == 0) && !_hasFetchedTotals) {
      _hasFetchedTotals = true;
      try {
        final TvShow? freshShow = await _episodeSource.getShow(_showId);
        if (freshShow != null) {
          await _db.tvShowDao.upsertTvShow(freshShow);
          totalInShow = freshShow.totalEpisodes ?? 0;
          totalSeasons = freshShow.totalSeasons ?? 0;
          _cachedTotalEpisodes = totalInShow;
          _cachedTotalSeasons = totalSeasons;
        }
      } on Exception catch (e) {
        _log.warning('Source API unavailable, using cached episode data', e);
      }
    }

    // If TMDB returned no totalEpisodes but every regular season is loaded,
    // sum loaded episodes; specials excluded (totalSeasons doesn't count 0).
    final int loadedRegularSeasons =
        state.episodesBySeason.keys.where((int s) => s > 0).length;
    if (totalInShow == 0 &&
        totalSeasons > 0 &&
        loadedRegularSeasons >= totalSeasons) {
      totalInShow = state.totalEpisodeCount;
    }

    // Kitsu carries no totals for an ongoing anime, but the tracker section
    // cached its synthesized seasons with aired counts — sum those.
    if (totalInShow == 0) {
      try {
        final List<TvSeason> seasons =
            await _db.tvShowDao.getTvSeasonsByShowId(_source, _showId);
        for (final TvSeason season in seasons) {
          if (season.seasonNumber > 0) {
            totalInShow += season.episodeCount ?? 0;
          }
        }
        if (totalInShow > 0) _cachedTotalEpisodes = totalInShow;
      } on Exception catch (_) {
        // Totals stay unknown; auto-status keeps the current status.
      }
    }

    // Publish resolved totals so progress badges can render "x/y" even when
    // the cached show row (e.g. from search results) has no totals.
    if (totalInShow > 0 && totalInShow != state.totalEpisodes) {
      state = state.copyWith(totalEpisodes: totalInShow);
    }

    final ItemStatus? targetStatus = computeStatusFromProgress(
      currentStatus: targetItem.status,
      hasAnyProgress: totalWatched > 0,
      isFullyCompleted: totalInShow > 0 && totalWatched >= totalInShow,
    );
    if (targetStatus != null) {
      await ref
          .read(collectionItemsNotifierProvider(collId).notifier)
          .updateStatus(
            targetItem.id,
            targetStatus,
            targetItem.mediaType,
            syncEpisodes: false,
          );
    }
  }

  /// Marks every regular episode watched; seasons not yet cached are fetched
  /// from the source. Existing marks keep their own dates.
  Future<void> markAllWatched({DateTime? at}) async {
    final int? collId = _collectionId;
    if (collId == null) return;
    final DateTime stamp = at ?? DateTime.now();

    try {
      final List<TvSeason> seasons = await _resolveSeasons();
      // Specials (season 0) don't count toward completion, so a "completed"
      // title must not claim them as watched.
      final List<int> seasonNumbers = <int>[
        for (final TvSeason season in seasons)
          if (season.seasonNumber > 0) season.seasonNumber,
      ];
      for (final int seasonNumber in seasonNumbers) {
        await loadSeason(seasonNumber);
      }

      final Map<(int, int), DateTime?> updated =
          Map<(int, int), DateTime?>.of(state.watchedEpisodes);
      final List<(int, int, int?)> rows = <(int, int, int?)>[];
      for (final int seasonNumber in seasonNumbers) {
        final List<TvEpisode> episodes =
            state.episodesBySeason[seasonNumber] ?? const <TvEpisode>[];
        for (final TvEpisode ep in episodes) {
          final (int, int) key = (seasonNumber, ep.episodeNumber);
          if (updated.containsKey(key)) continue;
          updated[key] = stamp;
          rows.add((seasonNumber, ep.episodeNumber,
              stamp.millisecondsSinceEpoch));
        }
      }
      if (rows.isEmpty) return;

      await _db.tvShowDao.markEpisodesWatchedAt(collId, _source, _showId, rows);
      state = state.copyWith(watchedEpisodes: updated);
    } on Exception catch (e) {
      _log.warning('Failed to mark all episodes of show $_showId watched', e);
    }
  }

  /// Returns the removed marks for an undo; empty when nothing was marked
  /// or the write failed.
  Future<WatchedMarks> unmarkAllWatched() async {
    final int? collId = _collectionId;
    if (collId == null) return const <(int, int), DateTime?>{};
    try {
      // State may still be loading on a freshly built tracker; the DB is
      // the full picture of what the DELETE is about to erase.
      final WatchedMarks removed =
          await _db.tvShowDao.getWatchedEpisodes(collId, _source, _showId);
      await _db.tvShowDao.unmarkShowWatched(collId, _source, _showId);
      state = state.copyWith(
        watchedEpisodes: const <(int, int), DateTime?>{},
      );
      return removed;
    } on Exception catch (e) {
      _log.warning('Failed to unmark episodes of show $_showId', e);
      return const <(int, int), DateTime?>{};
    }
  }

  Future<List<TvSeason>> _resolveSeasons() async {
    final List<TvSeason> cached =
        await _db.tvShowDao.getTvSeasonsByShowId(_source, _showId);
    if (cached.isNotEmpty) return cached;
    final List<TvSeason> fetched = await _episodeSource.getSeasons(_showId);
    if (fetched.isNotEmpty) {
      await _db.tvShowDao.upsertTvSeasons(fetched);
    }
    return fetched;
  }
}
