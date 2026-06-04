// Provider for tracking watched episodes of a show.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../core/api/tmdb_api.dart';
import '../../../core/database/database_service.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/item_status.dart';
import '../../../shared/models/item_status_logic.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/tv_episode.dart';
import '../../../shared/models/tv_show.dart';
import 'collections_provider.dart';

/// Episode tracker state.
class EpisodeTrackerState {
  /// Creates an [EpisodeTrackerState].
  const EpisodeTrackerState({
    this.episodesBySeason = const <int, List<TvEpisode>>{},
    this.watchedEpisodes = const <(int, int), DateTime?>{},
    this.loadingSeasons = const <int, bool>{},
    this.error,
  });

  /// Episodes by season (key is the season number).
  final Map<int, List<TvEpisode>> episodesBySeason;

  /// Watched episodes: (seasonNumber, episodeNumber) -> watch date.
  final Map<(int, int), DateTime?> watchedEpisodes;

  /// Per-season loading flags.
  final Map<int, bool> loadingSeasons;

  /// Load error, if any.
  final String? error;

  /// Returns a copy with the given fields replaced.
  EpisodeTrackerState copyWith({
    Map<int, List<TvEpisode>>? episodesBySeason,
    Map<(int, int), DateTime?>? watchedEpisodes,
    Map<int, bool>? loadingSeasons,
    String? error,
  }) {
    return EpisodeTrackerState(
      episodesBySeason: episodesBySeason ?? this.episodesBySeason,
      watchedEpisodes: watchedEpisodes ?? this.watchedEpisodes,
      loadingSeasons: loadingSeasons ?? this.loadingSeasons,
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
  int get totalWatchedCount => watchedEpisodes.length;

  /// Returns the total number of loaded episodes.
  int get totalEpisodeCount {
    int count = 0;
    for (final List<TvEpisode> episodes in episodesBySeason.values) {
      count += episodes.length;
    }
    return count;
  }
}

/// Episode tracking provider.
///
/// When collectionId == null (uncategorized), tracking is disabled.
final NotifierProviderFamily<EpisodeTrackerNotifier, EpisodeTrackerState,
        ({int? collectionId, int showId})>
    episodeTrackerNotifierProvider = NotifierProvider.family<
        EpisodeTrackerNotifier,
        EpisodeTrackerState,
        ({int? collectionId, int showId})>(
  EpisodeTrackerNotifier.new,
);

/// Notifier that manages watched episodes.
class EpisodeTrackerNotifier extends FamilyNotifier<EpisodeTrackerState,
    ({int? collectionId, int showId})> {
  static final Logger _log = Logger('EpisodeTrackerNotifier');

  late DatabaseService _db;
  late TmdbApi _tmdbApi;
  late int? _collectionId;
  late int _showId;

  // Show totals fetched from the TMDB API, cached so we don't re-query on
  // every toggleEpisode/toggleSeason.
  int? _cachedTotalEpisodes;
  int? _cachedTotalSeasons;
  bool _hasFetchedTotals = false;

  @override
  EpisodeTrackerState build(({int? collectionId, int showId}) arg) {
    _collectionId = arg.collectionId;
    _showId = arg.showId;
    _db = ref.watch(databaseServiceProvider);
    _tmdbApi = ref.watch(tmdbApiProvider);

    // Episode tracking is not supported for uncategorized items
    if (_collectionId == null) return const EpisodeTrackerState();

    Future<void>.microtask(_loadWatchedEpisodes);

    return const EpisodeTrackerState();
  }

  Future<void> _loadWatchedEpisodes() async {
    final int? collId = _collectionId;
    if (collId == null) return;
    try {
      final Map<(int, int), DateTime?> watched =
          await _db.tvShowDao.getWatchedEpisodes(collId, _showId);
      state = state.copyWith(watchedEpisodes: watched);
    } on Exception catch (e) {
      state = state.copyWith(error: 'Failed to load watched episodes: $e');
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
          await _db.tvShowDao.getEpisodesByShowAndSeason(_showId, seasonNumber);

      if (episodes.isEmpty) {
        episodes =
            await _tmdbApi.getSeasonEpisodes(_showId, seasonNumber);
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
          await _tmdbApi.getSeasonEpisodes(_showId, seasonNumber);
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
          collId, _showId, season, episode);
      final Map<(int, int), DateTime?> updated =
          Map<(int, int), DateTime?>.of(state.watchedEpisodes)
            ..remove((season, episode));
      state = state.copyWith(watchedEpisodes: updated);
    } else {
      await _db.tvShowDao.markEpisodeWatched(
          collId, _showId, season, episode);
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
      await _db.tvShowDao.unmarkSeasonWatched(collId, _showId, season);
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
          collId, _showId, season, episodeNumbers);
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

    // Find the show item (either tvShow or animation)
    CollectionItem? targetItem;
    for (final CollectionItem ci in items) {
      if (ci.externalId == _showId &&
          (ci.mediaType == MediaType.tvShow ||
           ci.mediaType == MediaType.animation)) {
        targetItem = ci;
        break;
      }
    }
    if (targetItem == null) return;

    int totalInShow = _cachedTotalEpisodes ??
        targetItem.tvShow?.totalEpisodes ?? 0;
    int totalSeasons = _cachedTotalSeasons ??
        targetItem.tvShow?.totalSeasons ?? 0;

    // If totals are missing from the cache, fetch them from the TMDB API
    // (once per session, so we don't query on every toggle)
    if ((totalInShow == 0 || totalSeasons == 0) && !_hasFetchedTotals) {
      _hasFetchedTotals = true;
      try {
        final TvShow? freshShow = await _tmdbApi.getTvShow(_showId);
        if (freshShow != null) {
          await _db.tvShowDao.upsertTvShow(freshShow);
          totalInShow = freshShow.totalEpisodes ?? 0;
          totalSeasons = freshShow.totalSeasons ?? 0;
          _cachedTotalEpisodes = totalInShow;
          _cachedTotalSeasons = totalSeasons;
        }
      } on Exception catch (e) {
        _log.warning('TMDB API unavailable, using cached episode data', e);
      }
    }

    // Fallback: if the TMDB API also returned no totalEpisodes but every
    // season is loaded, use the sum of loaded episodes
    if (totalInShow == 0 &&
        totalSeasons > 0 &&
        state.episodesBySeason.length >= totalSeasons) {
      totalInShow = state.totalEpisodeCount;
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
