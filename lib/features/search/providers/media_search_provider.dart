// Провайдер для поиска фильмов и сериалов через TMDB.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/tmdb_api.dart';
import '../../../core/database/database_service.dart';
import '../../../shared/models/movie.dart';
import '../../../shared/models/search_sort.dart';
import '../../../shared/models/tv_show.dart';
import 'genre_provider.dart';

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
    this.currentSort = const SearchSort(),
    this.selectedYear,
    this.selectedGenreIds = const <int>[],
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

  /// Текущая сортировка.
  final SearchSort currentSort;

  /// Фильтр по году (опционально).
  final int? selectedYear;

  /// Фильтр по жанрам (ID жанров TMDB).
  final List<int> selectedGenreIds;

  /// Проверяет, есть ли активные фильтры.
  bool get hasFilters => selectedYear != null || selectedGenreIds.isNotEmpty;

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
    SearchSort? currentSort,
    int? selectedYear,
    List<int>? selectedGenreIds,
    bool clearError = false,
    bool clearYear = false,
  }) {
    return MediaSearchState(
      query: query ?? this.query,
      movieResults: movieResults ?? this.movieResults,
      tvShowResults: tvShowResults ?? this.tvShowResults,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      activeTab: activeTab ?? this.activeTab,
      currentSort: currentSort ?? this.currentSort,
      selectedYear: clearYear ? null : (selectedYear ?? this.selectedYear),
      selectedGenreIds: selectedGenreIds ?? this.selectedGenreIds,
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
        other.activeTab == activeTab &&
        other.currentSort == currentSort &&
        other.selectedYear == selectedYear &&
        listEquals(other.selectedGenreIds, selectedGenreIds);
  }

  @override
  int get hashCode => Object.hash(
        query,
        Object.hashAll(movieResults),
        Object.hashAll(tvShowResults),
        isLoading,
        error,
        activeTab,
        currentSort,
        selectedYear,
        Object.hashAll(selectedGenreIds),
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

  /// Минимальная длина запроса для поиска.
  static const int minQueryLength = 2;

  @override
  MediaSearchState build() {
    _tmdbApi = ref.watch(tmdbApiProvider);
    _db = ref.watch(databaseServiceProvider);
    return const MediaSearchState();
  }

  /// Выполняет поиск фильмов или сериалов.
  ///
  /// [query] — строка поиска.
  Future<void> search(String query) async {
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
          final List<Movie> results = await _tmdbApi.searchMovies(
            query,
            year: state.selectedYear,
          );
          if (state.query == query) {
            // Фильтруем по жанрам (по ID, до резолвинга)
            final List<Movie> filtered = _filterMoviesByGenre(
              results,
              state.selectedGenreIds,
            );
            // Резолвим genre_ids в имена
            final List<Movie> resolved = await _resolveMovieGenres(filtered);
            // Кэшируем с резолвленными жанрами
            if (resolved.isNotEmpty) {
              await _db.upsertMovies(resolved);
            }
            final List<Movie> sorted = _applySortToMovies(
              resolved,
              state.currentSort,
              query,
            );
            state = state.copyWith(movieResults: sorted, isLoading: false);
          }
        case MediaSearchTab.tvShows:
          final List<TvShow> results = await _tmdbApi.searchTvShows(
            query,
            firstAirDateYear: state.selectedYear,
          );
          if (state.query == query) {
            // Фильтруем по жанрам (по ID, до резолвинга)
            final List<TvShow> filtered = _filterTvShowsByGenre(
              results,
              state.selectedGenreIds,
            );
            // Резолвим genre_ids в имена
            final List<TvShow> resolved = await _resolveTvShowGenres(filtered);
            // Кэшируем с резолвленными жанрами
            if (resolved.isNotEmpty) {
              await _db.upsertTvShows(resolved);
            }
            final List<TvShow> sorted = _applySortToTvShows(
              resolved,
              state.currentSort,
              query,
            );
            state = state.copyWith(tvShowResults: sorted, isLoading: false);
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

  /// Резолвит числовые genre_ids в имена жанров для фильмов.
  ///
  /// Использует БД-кэш жанров. При ошибке возвращает исходный список.
  Future<List<Movie>> _resolveMovieGenres(List<Movie> movies) async {
    try {
      final Map<String, String> genreMap =
          await ref.read(movieGenreMapProvider.future);
      if (genreMap.isEmpty) return movies;

      return movies.map((Movie movie) {
        if (movie.genres == null || movie.genres!.isEmpty) return movie;

        final List<String> resolved = movie.genres!
            .map((String g) => genreMap[g] ?? g)
            .toList();
        return movie.copyWith(genres: resolved);
      }).toList();
    } on Exception {
      return movies;
    }
  }

  /// Резолвит числовые genre_ids в имена жанров для сериалов.
  ///
  /// Использует БД-кэш жанров. При ошибке возвращает исходный список.
  Future<List<TvShow>> _resolveTvShowGenres(List<TvShow> tvShows) async {
    try {
      final Map<String, String> genreMap =
          await ref.read(tvGenreMapProvider.future);
      if (genreMap.isEmpty) return tvShows;

      return tvShows.map((TvShow tvShow) {
        if (tvShow.genres == null || tvShow.genres!.isEmpty) return tvShow;

        final List<String> resolved = tvShow.genres!
            .map((String g) => genreMap[g] ?? g)
            .toList();
        return tvShow.copyWith(genres: resolved);
      }).toList();
    } on Exception {
      return tvShows;
    }
  }

  /// Устанавливает сортировку и пересортирует текущие результаты.
  void setSort(SearchSort sort) {
    if (state.currentSort == sort) return;

    final List<Movie> sortedMovies = _applySortToMovies(
      state.movieResults,
      sort,
      state.query,
    );
    final List<TvShow> sortedTvShows = _applySortToTvShows(
      state.tvShowResults,
      sort,
      state.query,
    );
    state = state.copyWith(
      currentSort: sort,
      movieResults: sortedMovies,
      tvShowResults: sortedTvShows,
    );
  }

  /// Применяет сортировку к списку фильмов.
  List<Movie> _applySortToMovies(
    List<Movie> movies,
    SearchSort sort,
    String query,
  ) {
    if (movies.isEmpty) return movies;

    final List<Movie> sorted = List<Movie>.of(movies);
    final bool ascending = sort.order == SearchSortOrder.ascending;

    switch (sort.field) {
      case SearchSortField.relevance:
        _sortMoviesByRelevance(sorted, query, ascending);
      case SearchSortField.date:
        sorted.sort((Movie a, Movie b) {
          final int? yearA = a.releaseYear;
          final int? yearB = b.releaseYear;
          if (yearA == null && yearB == null) return 0;
          if (yearA == null) return 1;
          if (yearB == null) return -1;
          return ascending ? yearA.compareTo(yearB) : yearB.compareTo(yearA);
        });
      case SearchSortField.rating:
        sorted.sort((Movie a, Movie b) {
          final double? ratingA = a.rating;
          final double? ratingB = b.rating;
          if (ratingA == null && ratingB == null) return 0;
          if (ratingA == null) return 1;
          if (ratingB == null) return -1;
          return ascending
              ? ratingA.compareTo(ratingB)
              : ratingB.compareTo(ratingA);
        });
    }

    return sorted;
  }

  /// Применяет сортировку к списку сериалов.
  List<TvShow> _applySortToTvShows(
    List<TvShow> tvShows,
    SearchSort sort,
    String query,
  ) {
    if (tvShows.isEmpty) return tvShows;

    final List<TvShow> sorted = List<TvShow>.of(tvShows);
    final bool ascending = sort.order == SearchSortOrder.ascending;

    switch (sort.field) {
      case SearchSortField.relevance:
        _sortTvShowsByRelevance(sorted, query, ascending);
      case SearchSortField.date:
        sorted.sort((TvShow a, TvShow b) {
          final int? yearA = a.firstAirYear;
          final int? yearB = b.firstAirYear;
          if (yearA == null && yearB == null) return 0;
          if (yearA == null) return 1;
          if (yearB == null) return -1;
          return ascending ? yearA.compareTo(yearB) : yearB.compareTo(yearA);
        });
      case SearchSortField.rating:
        sorted.sort((TvShow a, TvShow b) {
          final double? ratingA = a.rating;
          final double? ratingB = b.rating;
          if (ratingA == null && ratingB == null) return 0;
          if (ratingA == null) return 1;
          if (ratingB == null) return -1;
          return ascending
              ? ratingA.compareTo(ratingB)
              : ratingB.compareTo(ratingA);
        });
    }

    return sorted;
  }

  void _sortMoviesByRelevance(
    List<Movie> movies,
    String query,
    bool ascending,
  ) {
    final String lowerQuery = query.toLowerCase();
    movies.sort((Movie a, Movie b) {
      final int scoreA = _relevanceScore(a.title.toLowerCase(), lowerQuery);
      final int scoreB = _relevanceScore(b.title.toLowerCase(), lowerQuery);
      return ascending ? scoreA.compareTo(scoreB) : scoreB.compareTo(scoreA);
    });
  }

  void _sortTvShowsByRelevance(
    List<TvShow> tvShows,
    String query,
    bool ascending,
  ) {
    final String lowerQuery = query.toLowerCase();
    tvShows.sort((TvShow a, TvShow b) {
      final int scoreA = _relevanceScore(a.title.toLowerCase(), lowerQuery);
      final int scoreB = _relevanceScore(b.title.toLowerCase(), lowerQuery);
      return ascending ? scoreA.compareTo(scoreB) : scoreB.compareTo(scoreA);
    });
  }

  /// Возвращает оценку релевантности (больше = лучше).
  int _relevanceScore(String name, String query) {
    if (name == query) return 3;
    if (name.startsWith(query)) return 2;
    if (name.contains(query)) return 1;
    return 0;
  }

  /// Устанавливает фильтр по году и повторяет поиск.
  Future<void> setYearFilter(int? year) async {
    if (state.selectedYear == year) return;

    if (year != null) {
      state = state.copyWith(selectedYear: year);
    } else {
      state = state.copyWith(clearYear: true);
    }

    if (state.query.length >= minQueryLength) {
      await _performSearch(state.query);
    }
  }

  /// Устанавливает фильтр по жанрам и пересортирует результаты.
  ///
  /// Жанры фильтруются локально (TMDB Search API не поддерживает with_genres).
  Future<void> setGenreFilter(List<int> genreIds) async {
    if (listEquals(state.selectedGenreIds, genreIds)) return;

    state = state.copyWith(selectedGenreIds: genreIds);

    // Перезапускаем поиск для обновления локального фильтра
    if (state.query.length >= minQueryLength) {
      await _performSearch(state.query);
    }
  }

  /// Применяет фильтры года и жанров за один вызов.
  ///
  /// Выполняет только один поиск вместо двух отдельных вызовов
  /// [setYearFilter] и [setGenreFilter].
  Future<void> applyFilters({
    int? year,
    required List<int> genreIds,
  }) async {
    final bool yearChanged = state.selectedYear != year;
    final bool genresChanged =
        !listEquals(state.selectedGenreIds, genreIds);

    if (!yearChanged && !genresChanged) return;

    state = state.copyWith(
      selectedYear: year,
      clearYear: year == null,
      selectedGenreIds: genreIds,
    );

    if (state.query.length >= minQueryLength) {
      await _performSearch(state.query);
    }
  }

  /// Очищает все фильтры и повторяет поиск.
  Future<void> clearFilters() async {
    if (!state.hasFilters) return;

    state = state.copyWith(
      clearYear: true,
      selectedGenreIds: <int>[],
    );

    if (state.query.length >= minQueryLength) {
      await _performSearch(state.query);
    }
  }

  /// Фильтрует фильмы по жанрам локально.
  List<Movie> _filterMoviesByGenre(
    List<Movie> movies,
    List<int> genreIds,
  ) {
    if (genreIds.isEmpty) return movies;

    final Set<String> genreIdStrings =
        genreIds.map((int id) => id.toString()).toSet();

    return movies.where((Movie movie) {
      final List<String>? movieGenres = movie.genres;
      if (movieGenres == null || movieGenres.isEmpty) return false;
      return genreIdStrings.any(movieGenres.contains);
    }).toList();
  }

  /// Фильтрует сериалы по жанрам локально.
  List<TvShow> _filterTvShowsByGenre(
    List<TvShow> tvShows,
    List<int> genreIds,
  ) {
    if (genreIds.isEmpty) return tvShows;

    final Set<String> genreIdStrings =
        genreIds.map((int id) => id.toString()).toSet();

    return tvShows.where((TvShow tvShow) {
      final List<String>? showGenres = tvShow.genres;
      if (showGenres == null || showGenres.isEmpty) return false;
      return genreIdStrings.any(showGenres.contains);
    }).toList();
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
    state = MediaSearchState(activeTab: state.activeTab);
  }
}
