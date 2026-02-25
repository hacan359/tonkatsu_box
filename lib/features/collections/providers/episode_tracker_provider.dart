// Провайдер для трекинга просмотренных эпизодов сериала.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/tmdb_api.dart';
import '../../../core/database/database_service.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/item_status.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/tv_episode.dart';
import '../../../shared/models/tv_show.dart';
import 'collections_provider.dart';

/// Состояние трекера эпизодов.
class EpisodeTrackerState {
  /// Создаёт [EpisodeTrackerState].
  const EpisodeTrackerState({
    this.episodesBySeason = const <int, List<TvEpisode>>{},
    this.watchedEpisodes = const <(int, int), DateTime?>{},
    this.loadingSeasons = const <int, bool>{},
    this.error,
  });

  /// Эпизоды по сезонам (ключ — номер сезона).
  final Map<int, List<TvEpisode>> episodesBySeason;

  /// Просмотренные эпизоды: (seasonNumber, episodeNumber) → дата просмотра.
  final Map<(int, int), DateTime?> watchedEpisodes;

  /// Флаги загрузки по сезонам.
  final Map<int, bool> loadingSeasons;

  /// Ошибка загрузки (если есть).
  final String? error;

  /// Создаёт копию с изменёнными полями.
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

  /// Проверяет, просмотрен ли эпизод.
  bool isEpisodeWatched(int season, int episode) {
    return watchedEpisodes.containsKey((season, episode));
  }

  /// Возвращает дату просмотра эпизода (или null).
  DateTime? getWatchedAt(int season, int episode) {
    return watchedEpisodes[(season, episode)];
  }

  /// Возвращает количество просмотренных эпизодов в сезоне.
  int watchedCountForSeason(int season) {
    int count = 0;
    for (final (int s, int _) in watchedEpisodes.keys) {
      if (s == season) count++;
    }
    return count;
  }

  /// Возвращает общее количество просмотренных эпизодов.
  int get totalWatchedCount => watchedEpisodes.length;

  /// Возвращает общее количество загруженных эпизодов.
  int get totalEpisodeCount {
    int count = 0;
    for (final List<TvEpisode> episodes in episodesBySeason.values) {
      count += episodes.length;
    }
    return count;
  }
}

/// Провайдер для трекинга эпизодов.
///
/// Если collectionId == null (uncategorized), трекинг отключён.
final NotifierProviderFamily<EpisodeTrackerNotifier, EpisodeTrackerState,
        ({int? collectionId, int showId})>
    episodeTrackerNotifierProvider = NotifierProvider.family<
        EpisodeTrackerNotifier,
        EpisodeTrackerState,
        ({int? collectionId, int showId})>(
  EpisodeTrackerNotifier.new,
);

/// Нотификатор для управления просмотренными эпизодами.
class EpisodeTrackerNotifier extends FamilyNotifier<EpisodeTrackerState,
    ({int? collectionId, int showId})> {
  late DatabaseService _db;
  late TmdbApi _tmdbApi;
  late int? _collectionId;
  late int _showId;

  // Кэш данных о сериале, полученных из TMDB API (чтобы не делать запрос
  // при каждом toggleEpisode/toggleSeason).
  int? _cachedTotalEpisodes;
  int? _cachedTotalSeasons;

  @override
  EpisodeTrackerState build(({int? collectionId, int showId}) arg) {
    _collectionId = arg.collectionId;
    _showId = arg.showId;
    _db = ref.watch(databaseServiceProvider);
    _tmdbApi = ref.watch(tmdbApiProvider);

    // Трекинг эпизодов не поддерживается для uncategorized элементов
    if (_collectionId == null) return const EpisodeTrackerState();

    Future<void>.microtask(_loadWatchedEpisodes);

    return const EpisodeTrackerState();
  }

  Future<void> _loadWatchedEpisodes() async {
    final int? collId = _collectionId;
    if (collId == null) return;
    try {
      final Map<(int, int), DateTime?> watched =
          await _db.getWatchedEpisodes(collId, _showId);
      state = state.copyWith(watchedEpisodes: watched);
    } on Exception catch (e) {
      state = state.copyWith(error: 'Failed to load watched episodes: $e');
    }
  }

  /// Загружает эпизоды сезона (из кеша или API).
  Future<void> loadSeason(int seasonNumber) async {
    // Уже загружен
    if (state.episodesBySeason.containsKey(seasonNumber)) return;
    // Уже загружается
    if (state.loadingSeasons[seasonNumber] == true) return;

    state = state.copyWith(
      loadingSeasons: <int, bool>{
        ...state.loadingSeasons,
        seasonNumber: true,
      },
    );

    try {
      // Пробуем из кеша
      List<TvEpisode> episodes =
          await _db.getEpisodesByShowAndSeason(_showId, seasonNumber);

      if (episodes.isEmpty) {
        // Загружаем из API
        episodes =
            await _tmdbApi.getSeasonEpisodes(_showId, seasonNumber);
        // Кешируем
        if (episodes.isNotEmpty) {
          await _db.upsertEpisodes(episodes);
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

  /// Принудительно обновляет эпизоды сезона из API (добавляет новые,
  /// обновляет метаданные существующих, не трогает watched-статусы).
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
        await _db.upsertEpisodes(episodes);
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

  /// Переключает отметку просмотра эпизода.
  Future<void> toggleEpisode(int season, int episode) async {
    final int? collId = _collectionId;
    if (collId == null) return;
    final bool isWatched = state.isEpisodeWatched(season, episode);

    if (isWatched) {
      await _db.markEpisodeUnwatched(
          collId, _showId, season, episode);
      final Map<(int, int), DateTime?> updated =
          Map<(int, int), DateTime?>.of(state.watchedEpisodes)
            ..remove((season, episode));
      state = state.copyWith(watchedEpisodes: updated);
    } else {
      await _db.markEpisodeWatched(
          collId, _showId, season, episode);
      final Map<(int, int), DateTime?> updated =
          Map<(int, int), DateTime?>.of(state.watchedEpisodes)
            ..[(season, episode)] = DateTime.now();
      state = state.copyWith(watchedEpisodes: updated);
    }

    await _updateAutoStatus();
  }

  /// Переключает отметку просмотра всех эпизодов сезона.
  Future<void> toggleSeason(int season) async {
    final int? collId = _collectionId;
    if (collId == null) return;
    final List<TvEpisode>? episodes = state.episodesBySeason[season];
    if (episodes == null || episodes.isEmpty) return;

    final int watchedCount = state.watchedCountForSeason(season);
    final bool allWatched = watchedCount == episodes.length;

    if (allWatched) {
      // Снимаем все отметки сезона
      await _db.unmarkSeasonWatched(collId, _showId, season);
      final Map<(int, int), DateTime?> updated =
          Map<(int, int), DateTime?>.of(state.watchedEpisodes);
      for (final TvEpisode ep in episodes) {
        updated.remove((season, ep.episodeNumber));
      }
      state = state.copyWith(watchedEpisodes: updated);
    } else {
      // Отмечаем все эпизоды сезона
      final List<int> episodeNumbers =
          episodes.map((TvEpisode ep) => ep.episodeNumber).toList();
      await _db.markSeasonWatched(
          collId, _showId, season, episodeNumbers);
      final DateTime now = DateTime.now();
      final Map<(int, int), DateTime?> updated =
          Map<(int, int), DateTime?>.of(state.watchedEpisodes);
      for (final int ep in episodeNumbers) {
        updated[(season, ep)] = now;
      }
      state = state.copyWith(watchedEpisodes: updated);
    }

    await _updateAutoStatus();
  }

  Future<void> _updateAutoStatus() async {
    final int? collId = _collectionId;
    if (collId == null) return;

    final int totalWatched = state.totalWatchedCount;

    final List<CollectionItem>? items = ref
        .read(collectionItemsNotifierProvider(collId))
        .valueOrNull;
    if (items == null) {
      debugPrint('[EpisodeTracker] items == null for collectionId=$collId');
      return;
    }

    // Находим элемент сериала (tvShow или animation)
    CollectionItem? targetItem;
    for (final CollectionItem ci in items) {
      if (ci.externalId == _showId &&
          (ci.mediaType == MediaType.tvShow ||
           ci.mediaType == MediaType.animation)) {
        targetItem = ci;
        break;
      }
    }
    if (targetItem == null) {
      debugPrint(
        '[EpisodeTracker] targetItem not found: showId=$_showId, '
        'items count=${items.length}, '
        'types=${items.map((CollectionItem i) => '${i.externalId}:${i.mediaType}').join(', ')}',
      );
      return;
    }

    final ItemStatus currentStatus = targetItem.status;
    int totalInShow = _cachedTotalEpisodes ??
        targetItem.tvShow?.totalEpisodes ?? 0;
    int totalSeasons = _cachedTotalSeasons ??
        targetItem.tvShow?.totalSeasons ?? 0;

    debugPrint(
      '[EpisodeTracker] showId=$_showId, '
      'tvShow=${targetItem.tvShow != null ? "present" : "NULL"}, '
      'totalEpisodes=${targetItem.tvShow?.totalEpisodes}, '
      'totalSeasons=${targetItem.tvShow?.totalSeasons}, '
      'cachedEpisodes=$_cachedTotalEpisodes, '
      'cachedSeasons=$_cachedTotalSeasons, '
      'totalInShow=$totalInShow, '
      'totalWatched=$totalWatched, '
      'currentStatus=$currentStatus, '
      'loadedSeasons=${state.episodesBySeason.keys.toList()}, '
      'loadedEpisodeCount=${state.totalEpisodeCount}',
    );

    // Если в кэше нет totalEpisodes/totalSeasons — подгружаем из TMDB API
    if (totalInShow == 0 || totalSeasons == 0) {
      try {
        final TvShow? freshShow = await _tmdbApi.getTvShow(_showId);
        if (freshShow != null) {
          await _db.upsertTvShow(freshShow);
          totalInShow = freshShow.totalEpisodes ?? 0;
          totalSeasons = freshShow.totalSeasons ?? 0;
          // Кэшируем, чтобы не обращаться к API при каждом toggle
          _cachedTotalEpisodes = totalInShow;
          _cachedTotalSeasons = totalSeasons;
          debugPrint(
            '[EpisodeTracker] fetched from API: '
            'totalEpisodes=$totalInShow, totalSeasons=$totalSeasons',
          );
        }
      } on Exception catch (e) {
        debugPrint('[EpisodeTracker] failed to fetch TV details: $e');
      }
    }

    // Fallback: если TMDB API тоже не вернул totalEpisodes,
    // но все сезоны загружены — используем сумму загруженных эпизодов
    if (totalInShow == 0 &&
        totalSeasons > 0 &&
        state.episodesBySeason.length >= totalSeasons) {
      totalInShow = state.totalEpisodeCount;
      debugPrint(
        '[EpisodeTracker] fallback activated: totalSeasons=$totalSeasons, '
        'loadedSeasons=${state.episodesBySeason.length}, '
        'totalInShow=$totalInShow',
      );
    }

    // Все сняты → notStarted (если был inProgress или completed)
    if (totalWatched == 0) {
      if (currentStatus == ItemStatus.inProgress ||
          currentStatus == ItemStatus.completed) {
        debugPrint('[EpisodeTracker] → notStarted (all unwatched)');
        await ref
            .read(collectionItemsNotifierProvider(collId).notifier)
            .updateStatus(
                targetItem.id, ItemStatus.notStarted, targetItem.mediaType);
      }
      return;
    }

    // Все просмотрены → completed (только если totalInShow известен)
    if (totalInShow > 0 && totalWatched >= totalInShow) {
      if (currentStatus != ItemStatus.completed) {
        debugPrint(
          '[EpisodeTracker] → completed '
          '(totalWatched=$totalWatched >= totalInShow=$totalInShow)',
        );
        await ref
            .read(collectionItemsNotifierProvider(collId).notifier)
            .updateStatus(
                targetItem.id, ItemStatus.completed, targetItem.mediaType);
      }
      return;
    }

    // Есть просмотренные, но не все → inProgress
    // (если был notStarted, planned или completed)
    if (currentStatus == ItemStatus.notStarted ||
        currentStatus == ItemStatus.planned) {
      debugPrint('[EpisodeTracker] → inProgress (first watched)');
      await ref
          .read(collectionItemsNotifierProvider(collId).notifier)
          .updateStatus(
              targetItem.id, ItemStatus.inProgress, targetItem.mediaType);
    } else if (currentStatus == ItemStatus.completed &&
        totalInShow > 0 && totalWatched < totalInShow) {
      debugPrint('[EpisodeTracker] → inProgress (was completed, unchecked some)');
      await ref
          .read(collectionItemsNotifierProvider(collId).notifier)
          .updateStatus(
              targetItem.id, ItemStatus.inProgress, targetItem.mediaType);
    }

    if (totalInShow == 0) {
      debugPrint(
        '[EpisodeTracker] totalInShow=0, auto-complete skipped. '
        'Consider fetching TV show details from TMDB API.',
      );
    }
  }
}
