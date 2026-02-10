// Провайдер для трекинга просмотренных эпизодов сериала.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/tmdb_api.dart';
import '../../../core/database/database_service.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/item_status.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/tv_episode.dart';
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
final NotifierProviderFamily<EpisodeTrackerNotifier, EpisodeTrackerState,
        ({int collectionId, int showId})>
    episodeTrackerNotifierProvider = NotifierProvider.family<
        EpisodeTrackerNotifier,
        EpisodeTrackerState,
        ({int collectionId, int showId})>(
  EpisodeTrackerNotifier.new,
);

/// Нотификатор для управления просмотренными эпизодами.
class EpisodeTrackerNotifier extends FamilyNotifier<EpisodeTrackerState,
    ({int collectionId, int showId})> {
  late DatabaseService _db;
  late TmdbApi _tmdbApi;
  late int _collectionId;
  late int _showId;

  @override
  EpisodeTrackerState build(({int collectionId, int showId}) arg) {
    _collectionId = arg.collectionId;
    _showId = arg.showId;
    _db = ref.watch(databaseServiceProvider);
    _tmdbApi = ref.watch(tmdbApiProvider);

    Future<void>.microtask(_loadWatchedEpisodes);

    return const EpisodeTrackerState();
  }

  Future<void> _loadWatchedEpisodes() async {
    try {
      final Map<(int, int), DateTime?> watched =
          await _db.getWatchedEpisodes(_collectionId, _showId);
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
    final bool isWatched = state.isEpisodeWatched(season, episode);

    if (isWatched) {
      await _db.markEpisodeUnwatched(
          _collectionId, _showId, season, episode);
      final Map<(int, int), DateTime?> updated =
          Map<(int, int), DateTime?>.of(state.watchedEpisodes)
            ..remove((season, episode));
      state = state.copyWith(watchedEpisodes: updated);
    } else {
      await _db.markEpisodeWatched(
          _collectionId, _showId, season, episode);
      final Map<(int, int), DateTime?> updated =
          Map<(int, int), DateTime?>.of(state.watchedEpisodes)
            ..[(season, episode)] = DateTime.now();
      state = state.copyWith(watchedEpisodes: updated);
    }

    await _checkAutoComplete();
  }

  /// Переключает отметку просмотра всех эпизодов сезона.
  Future<void> toggleSeason(int season) async {
    final List<TvEpisode>? episodes = state.episodesBySeason[season];
    if (episodes == null || episodes.isEmpty) return;

    final int watchedCount = state.watchedCountForSeason(season);
    final bool allWatched = watchedCount == episodes.length;

    if (allWatched) {
      // Снимаем все отметки сезона
      await _db.unmarkSeasonWatched(_collectionId, _showId, season);
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
          _collectionId, _showId, season, episodeNumbers);
      final DateTime now = DateTime.now();
      final Map<(int, int), DateTime?> updated =
          Map<(int, int), DateTime?>.of(state.watchedEpisodes);
      for (final int ep in episodeNumbers) {
        updated[(season, ep)] = now;
      }
      state = state.copyWith(watchedEpisodes: updated);
    }

    await _checkAutoComplete();
  }

  Future<void> _checkAutoComplete() async {
    final int totalWatched = state.totalWatchedCount;
    if (totalWatched == 0) return;

    final List<CollectionItem>? items = ref
        .read(collectionItemsNotifierProvider(_collectionId))
        .valueOrNull;
    if (items == null) return;

    // Находим элемент сериала, чтобы узнать общее количество эпизодов
    CollectionItem? targetItem;
    for (final CollectionItem ci in items) {
      if (ci.externalId == _showId && ci.mediaType == MediaType.tvShow) {
        targetItem = ci;
        break;
      }
    }
    if (targetItem == null) return;

    // Используем totalEpisodes из метаданных, а не количество загруженных
    final int totalInShow = targetItem.tvShow?.totalEpisodes ?? 0;
    final int total =
        totalInShow > 0 ? totalInShow : state.totalEpisodeCount;
    if (total == 0) return;

    if (totalWatched >= total &&
        targetItem.status != ItemStatus.completed) {
      await ref
          .read(collectionItemsNotifierProvider(_collectionId).notifier)
          .updateStatus(
              targetItem.id, ItemStatus.completed, MediaType.tvShow);
    }
  }
}
