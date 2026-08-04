// Provider for tracking watched episodes of a show.

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

/// Episode tracker state.
class EpisodeTrackerState {
  /// Creates an [EpisodeTrackerState].
  const EpisodeTrackerState({
    this.episodesBySeason = const <int, List<TvEpisode>>{},
    this.watchedEpisodes = const <(int, int), DateTime?>{},
    this.loadingSeasons = const <int, bool>{},
    this.totalEpisodes,
    this.error,
  });

  /// Episodes by season (key is the season number).
  final Map<int, List<TvEpisode>> episodesBySeason;

  /// Watched episodes: (seasonNumber, episodeNumber) -> watch date.
  final Map<(int, int), DateTime?> watchedEpisodes;

  /// Per-season loading flags.
  final Map<int, bool> loadingSeasons;

  /// Show's official episode count resolved by the tracker (specials
  /// excluded). Fallback for cards whose cached [TvShow] has no totals.
  final int? totalEpisodes;

  /// Load error, if any.
  final String? error;

  /// Returns a copy with the given fields replaced.
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

  /// Whether the episode has been watched.
  bool isEpisodeWatched(int season, int episode) {
    return watchedEpisodes.containsKey((season, episode));
  }

  /// Returns the episode's watch date (or null).
  DateTime? getWatchedAt(int season, int episode) {
    return watchedEpisodes[(season, episode)];
  }

  /// Returns the number of watched episodes in a season.
  int watchedCountForSeason(int season) {
    int count = 0;
    for (final (int s, int _) in watchedEpisodes.keys) {
      if (s == season) count++;
    }
    return count;
  }

  /// Returns the total number of watched episodes.
  ///
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

/// Family argument of the episode tracker. `source` selects the
/// season/episode provider ([TvEpisodeSource]) and namespaces DB rows.
typedef EpisodeTrackerArg = ({
  int? collectionId,
  int showId,
  DataSource source,
});

/// Episode tracking provider.
///
/// When collectionId == null (uncategorized), tracking is disabled.
final NotifierProviderFamily<EpisodeTrackerNotifier, EpisodeTrackerState,
        EpisodeTrackerArg>
    episodeTrackerNotifierProvider = NotifierProvider.family<
        EpisodeTrackerNotifier,
        EpisodeTrackerState,
        EpisodeTrackerArg>(
  EpisodeTrackerNotifier.new,
);

/// Notifier that manages watched episodes.
class EpisodeTrackerNotifier
    extends FamilyNotifier<EpisodeTrackerState, EpisodeTrackerArg> {
  static final Logger _log = Logger('EpisodeTrackerNotifier');

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

    // Only the cheap queries run eagerly: grid cards watch this provider
    // per TV item and need just watched counts and totals. The full episode
    // cache loads lazily via [ensureCachedEpisodesLoaded].
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

  /// Resolves the show's episode total from the local cache so progress
  /// badges render "x/y" even when the cached show row has no totals
  /// (rows written from list endpoints before the cache warmer existed).
  /// Specials (season 0) are excluded, matching [totalWatchedCount].
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

  /// Loads every already-cached episode (all seasons) in one query, without
  /// touching the network. Lets the marks summary/filter resolve episode names
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

  /// Loads a season's episodes (from cache or API).
  Future<void> loadSeason(int seasonNumber) async {
    // Already loaded
    if (state.episodesBySeason.containsKey(seasonNumber)) return;
    // Already loading
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

  /// Toggles an episode's watched mark.
  Future<void> toggleEpisode(int season, int episode) async {
    final int? collId = _collectionId;
    if (collId == null) return;
    final bool isWatched = state.isEpisodeWatched(season, episode);

    if (isWatched) {
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
  }

  /// Toggles the watched mark for every episode in a season.
  Future<void> toggleSeason(int season) async {
    final int? collId = _collectionId;
    if (collId == null) return;
    final List<TvEpisode>? episodes = state.episodesBySeason[season];
    if (episodes == null || episodes.isEmpty) return;

    final int watchedCount = state.watchedCountForSeason(season);
    final bool allWatched = watchedCount == episodes.length;

    if (allWatched) {
      await _db.tvShowDao.unmarkSeasonWatched(
          collId, _source, _showId, season);
      final Map<(int, int), DateTime?> updated =
          Map<(int, int), DateTime?>.of(state.watchedEpisodes);
      for (final TvEpisode ep in episodes) {
        updated.remove((season, ep.episodeNumber));
      }
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

    // Fallback: if the TMDB API also returned no totalEpisodes but every
    // regular season is loaded, use the sum of loaded episodes. Season 0
    // (specials) is excluded — TMDB's totalSeasons doesn't count it.
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
              targetItem.id, targetStatus, targetItem.mediaType);
    }
  }
}
