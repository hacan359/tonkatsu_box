// Провайдер для поиска фильмов и сериалов через TMDB.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/tmdb_api.dart';
import '../../../core/database/database_service.dart';
import '../../../shared/models/movie.dart';
import '../../../shared/models/tv_show.dart';

/// Активный таб поиска медиа.
enum MediaSearchTab {
  /// Фильмы.
  movies,

  /// Сериалы.
  tvShows,
}

/// Состояние поиска фильмов и сериалов.
class MediaSearchState {
  /// Создаёт [MediaSearchState].
  const MediaSearchState({
    this.query = '',
    this.movieResults = const <Movie>[],
    this.tvShowResults = const <TvShow>[],
    this.isLoading = false,
    this.error,
    this.activeTab = MediaSearchTab.movies,
  });

  /// Текущий поисковый запрос.
  final String query;

  /// Результаты поиска фильмов.
  final List<Movie> movieResults;

  /// Результаты поиска сериалов.
  final List<TvShow> tvShowResults;

  /// Флаг загрузки.
  final bool isLoading;

  /// Сообщение об ошибке.
  final String? error;

  /// Активный таб.
  final MediaSearchTab activeTab;

  /// Проверяет, есть ли результаты для активного таба.
  bool get hasResults {
    switch (activeTab) {
      case MediaSearchTab.movies:
        return movieResults.isNotEmpty;
      case MediaSearchTab.tvShows:
        return tvShowResults.isNotEmpty;
    }
  }

  /// Проверяет, пустой ли запрос.
  bool get isEmpty => query.isEmpty && !hasResults && !isLoading;

  /// Копирует с изменёнными полями.
  MediaSearchState copyWith({
    String? query,
    List<Movie>? movieResults,
    List<TvShow>? tvShowResults,
    bool? isLoading,
    String? error,
    MediaSearchTab? activeTab,
    bool clearError = false,
  }) {
    return MediaSearchState(
      query: query ?? this.query,
      movieResults: movieResults ?? this.movieResults,
      tvShowResults: tvShowResults ?? this.tvShowResults,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      activeTab: activeTab ?? this.activeTab,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MediaSearchState &&
        other.query == query &&
        listEquals(other.movieResults, movieResults) &&
        listEquals(other.tvShowResults, tvShowResults) &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.activeTab == activeTab;
  }

  @override
  int get hashCode => Object.hash(
        query,
        Object.hashAll(movieResults),
        Object.hashAll(tvShowResults),
        isLoading,
        error,
        activeTab,
      );
}

/// Провайдер для поиска фильмов и сериалов.
final NotifierProvider<MediaSearchNotifier, MediaSearchState>
    mediaSearchProvider =
    NotifierProvider<MediaSearchNotifier, MediaSearchState>(
  MediaSearchNotifier.new,
);

/// Notifier для управления поиском фильмов и сериалов.
class MediaSearchNotifier extends Notifier<MediaSearchState> {
  late TmdbApi _tmdbApi;
  late DatabaseService _db;
  Timer? _debounceTimer;

  /// Время задержки перед поиском (debounce).
  static const Duration debounceDelay = Duration(milliseconds: 400);

  /// Минимальная длина запроса для поиска.
  static const int minQueryLength = 2;

  @override
  MediaSearchState build() {
    _tmdbApi = ref.watch(tmdbApiProvider);
    _db = ref.watch(databaseServiceProvider);

    ref.onDispose(() {
      _debounceTimer?.cancel();
    });

    return const MediaSearchState();
  }

  /// Выполняет поиск с debounce.
  void search(String query) {
    _debounceTimer?.cancel();

    state = state.copyWith(query: query, clearError: true);

    if (query.length < minQueryLength) {
      state = state.copyWith(
        movieResults: <Movie>[],
        tvShowResults: <TvShow>[],
        isLoading: false,
      );
      return;
    }

    state = state.copyWith(isLoading: true);

    _debounceTimer = Timer(debounceDelay, () {
      _performSearch(query);
    });
  }

  /// Выполняет немедленный поиск без debounce.
  Future<void> searchImmediate(String query) async {
    _debounceTimer?.cancel();

    state = state.copyWith(query: query, clearError: true);

    if (query.length < minQueryLength) {
      state = state.copyWith(
        movieResults: <Movie>[],
        tvShowResults: <TvShow>[],
        isLoading: false,
      );
      return;
    }

    await _performSearch(query);
  }

  Future<void> _performSearch(String query) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      switch (state.activeTab) {
        case MediaSearchTab.movies:
          final List<Movie> results = await _tmdbApi.searchMovies(query);
          if (state.query == query) {
            // Кэшируем результаты
            if (results.isNotEmpty) {
              await _db.upsertMovies(results);
            }
            state = state.copyWith(movieResults: results, isLoading: false);
          }
        case MediaSearchTab.tvShows:
          final List<TvShow> results = await _tmdbApi.searchTvShows(query);
          if (state.query == query) {
            // Кэшируем результаты
            if (results.isNotEmpty) {
              await _db.upsertTvShows(results);
            }
            state = state.copyWith(tvShowResults: results, isLoading: false);
          }
      }
    } on TmdbApiException catch (e) {
      if (state.query == query) {
        state = state.copyWith(
          error: e.message,
          isLoading: false,
        );
      }
    } on Exception catch (e) {
      if (state.query == query) {
        state = state.copyWith(
          error: e.toString(),
          isLoading: false,
        );
      }
    }
  }

  /// Переключает активный таб и повторяет поиск при необходимости.
  Future<void> switchTab(MediaSearchTab tab) async {
    if (state.activeTab == tab) return;

    state = state.copyWith(activeTab: tab, clearError: true);

    if (state.query.length >= minQueryLength) {
      await _performSearch(state.query);
    }
  }

  /// Очищает результаты поиска.
  void clear() {
    _debounceTimer?.cancel();
    state = MediaSearchState(activeTab: state.activeTab);
  }
}
