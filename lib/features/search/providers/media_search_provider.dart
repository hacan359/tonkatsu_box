// Провайдер для поиска фильмов, сериалов и анимации через TMDB.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/tmdb_api.dart';
import '../../../core/database/database_service.dart';
import '../../../shared/models/movie.dart';
import '../../../shared/models/search_sort.dart';
import '../../../shared/models/tv_show.dart';
import '../models/media_search_item.dart';
import '../models/tv_sub_filter.dart';
import 'genre_provider.dart';

/// ID жанра Animation в TMDB (одинаковый для Movies и TV Shows).
const int animationGenreId = 16;

/// Строковое представление жанра Animation для фильтрации.
const String _animationGenreIdStr = '16';

/// Состояние поиска фильмов, сериалов и анимации.
class MediaSearchState {
  /// Создаёт [MediaSearchState].
  const MediaSearchState({
    this.query = '',
    this.items = const <MediaSearchItem>[],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.subFilter = TvSubFilter.all,
    this.currentSort = const SearchSort(),
    this.currentMoviePage = 1,
    this.currentTvPage = 1,
    this.hasMoreMovies = false,
    this.hasMoreTvShows = false,
  });

  /// Текущий поисковый запрос.
  final String query;

  /// Объединённые результаты поиска (фильмы + сериалы).
  final List<MediaSearchItem> items;

  /// Флаг загрузки первой страницы.
  final bool isLoading;

  /// Флаг загрузки следующей страницы.
  final bool isLoadingMore;

  /// Сообщение об ошибке.
  final String? error;

  /// Текущий субфильтр (все, фильмы, сериалы, анимация).
  final TvSubFilter subFilter;

  /// Текущая сортировка.
  final SearchSort currentSort;

  /// Текущая страница для фильмов TMDB.
  final int currentMoviePage;

  /// Текущая страница для сериалов TMDB.
  final int currentTvPage;

  /// Есть ли ещё страницы фильмов.
  final bool hasMoreMovies;

  /// Есть ли ещё страницы сериалов.
  final bool hasMoreTvShows;

  /// Есть ли ещё результаты (хотя бы один API).
  bool get hasMore => hasMoreMovies || hasMoreTvShows;

  /// Проверяет, есть ли результаты.
  bool get hasResults => items.isNotEmpty;

  /// Проверяет, пустой ли запрос.
  bool get isEmpty => query.isEmpty && !hasResults && !isLoading;

  /// Копирует с изменёнными полями.
  MediaSearchState copyWith({
    String? query,
    List<MediaSearchItem>? items,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    TvSubFilter? subFilter,
    SearchSort? currentSort,
    int? currentMoviePage,
    int? currentTvPage,
    bool? hasMoreMovies,
    bool? hasMoreTvShows,
    bool clearError = false,
  }) {
    return MediaSearchState(
      query: query ?? this.query,
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      subFilter: subFilter ?? this.subFilter,
      currentSort: currentSort ?? this.currentSort,
      currentMoviePage: currentMoviePage ?? this.currentMoviePage,
      currentTvPage: currentTvPage ?? this.currentTvPage,
      hasMoreMovies: hasMoreMovies ?? this.hasMoreMovies,
      hasMoreTvShows: hasMoreTvShows ?? this.hasMoreTvShows,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MediaSearchState &&
        other.query == query &&
        listEquals(other.items, items) &&
        other.isLoading == isLoading &&
        other.isLoadingMore == isLoadingMore &&
        other.error == error &&
        other.subFilter == subFilter &&
        other.currentSort == currentSort &&
        other.currentMoviePage == currentMoviePage &&
        other.currentTvPage == currentTvPage &&
        other.hasMoreMovies == hasMoreMovies &&
        other.hasMoreTvShows == hasMoreTvShows;
  }

  @override
  int get hashCode => Object.hash(
        query,
        Object.hashAll(items),
        isLoading,
        isLoadingMore,
        error,
        subFilter,
        currentSort,
        currentMoviePage,
        currentTvPage,
        hasMoreMovies,
        hasMoreTvShows,
      );
}

/// Провайдер для поиска фильмов, сериалов и анимации.
final NotifierProvider<MediaSearchNotifier, MediaSearchState>
    mediaSearchProvider =
    NotifierProvider<MediaSearchNotifier, MediaSearchState>(
  MediaSearchNotifier.new,
);

/// Notifier для управления поиском фильмов, сериалов и анимации.
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

  /// Выполняет поиск (первая страница).
  ///
  /// [query] — строка поиска.
  Future<void> search(String query) async {
    state = state.copyWith(
      query: query,
      clearError: true,
      currentMoviePage: 1,
      currentTvPage: 1,
      hasMoreMovies: false,
      hasMoreTvShows: false,
    );

    if (query.length < minQueryLength) {
      state = state.copyWith(
        items: const <MediaSearchItem>[],
        isLoading: false,
      );
      return;
    }

    await _performSearch(query, append: false);
  }

  /// Загружает следующую страницу результатов.
  Future<void> loadMore() async {
    if (state.isLoadingMore || state.isLoading || !state.hasMore) return;
    if (state.query.length < minQueryLength) return;

    await _performSearch(state.query, append: true);
  }

  /// Устанавливает субфильтр без перезапуска поиска.
  ///
  /// Пользователь должен нажать Enter для нового поиска.
  void setSubFilter(TvSubFilter filter) {
    if (state.subFilter == filter) return;
    state = state.copyWith(subFilter: filter);
  }

  Future<void> _performSearch(
    String query, {
    required bool append,
  }) async {
    if (append) {
      state = state.copyWith(isLoadingMore: true, clearError: true);
    } else {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final List<MediaSearchItem> newItems = <MediaSearchItem>[];
      bool hasMoreMovies = false;
      bool hasMoreTvShows = false;
      int moviePage = append ? state.currentMoviePage + 1 : 1;
      int tvPage = append ? state.currentTvPage + 1 : 1;

      switch (state.subFilter) {
        case TvSubFilter.all:
          // Ищем параллельно в фильмах и сериалах
          final bool shouldFetchMovies =
              !append || state.hasMoreMovies;
          final bool shouldFetchTvShows =
              !append || state.hasMoreTvShows;

          final List<Future<Object>> futures = <Future<Object>>[];
          if (shouldFetchMovies) {
            futures.add(_tmdbApi.searchMoviesPaged(
              query,
              page: append ? moviePage : 1,
            ));
          }
          if (shouldFetchTvShows) {
            futures.add(_tmdbApi.searchTvShowsPaged(
              query,
              page: append ? tvPage : 1,
            ));
          }

          final List<Object> results = await Future.wait(futures);

          int resultIndex = 0;
          if (shouldFetchMovies) {
            final TmdbPagedResult<Movie> movieResult =
                results[resultIndex] as TmdbPagedResult<Movie>;
            resultIndex++;
            final List<Movie> resolved =
                await _resolveMovieGenres(movieResult.results);
            if (resolved.isNotEmpty) {
              await _db.upsertMovies(resolved);
            }
            for (final Movie movie in resolved) {
              newItems.add(MediaSearchItem.fromMovie(movie));
            }
            hasMoreMovies = movieResult.hasMore;
            moviePage = movieResult.page;
          }
          if (shouldFetchTvShows) {
            final TmdbPagedResult<TvShow> tvResult =
                results[resultIndex] as TmdbPagedResult<TvShow>;
            final List<TvShow> resolved =
                await _resolveTvShowGenres(tvResult.results);
            if (resolved.isNotEmpty) {
              await _db.upsertTvShows(resolved);
            }
            for (final TvShow tvShow in resolved) {
              newItems.add(MediaSearchItem.fromTvShow(tvShow));
            }
            hasMoreTvShows = tvResult.hasMore;
            tvPage = tvResult.page;
          }

        case TvSubFilter.movies:
          // Только фильмы, исключая анимацию
          final TmdbPagedResult<Movie> movieResult =
              await _tmdbApi.searchMoviesPaged(
            query,
            page: append ? moviePage : 1,
          );
          final List<Movie> withoutAnimation =
              _excludeAnimationMovies(movieResult.results);
          final List<Movie> resolved =
              await _resolveMovieGenres(withoutAnimation);
          if (resolved.isNotEmpty) {
            await _db.upsertMovies(resolved);
          }
          for (final Movie movie in resolved) {
            newItems.add(MediaSearchItem.fromMovie(movie));
          }
          hasMoreMovies = movieResult.hasMore;
          moviePage = movieResult.page;

        case TvSubFilter.tvShows:
          // Только сериалы, исключая анимацию
          final TmdbPagedResult<TvShow> tvResult =
              await _tmdbApi.searchTvShowsPaged(
            query,
            page: append ? tvPage : 1,
          );
          final List<TvShow> withoutAnimation =
              _excludeAnimationTvShows(tvResult.results);
          final List<TvShow> resolved =
              await _resolveTvShowGenres(withoutAnimation);
          if (resolved.isNotEmpty) {
            await _db.upsertTvShows(resolved);
          }
          for (final TvShow tvShow in resolved) {
            newItems.add(MediaSearchItem.fromTvShow(tvShow));
          }
          hasMoreTvShows = tvResult.hasMore;
          tvPage = tvResult.page;

        case TvSubFilter.animation:
          // Параллельно ищем анимацию среди фильмов и сериалов
          final bool shouldFetchMovies =
              !append || state.hasMoreMovies;
          final bool shouldFetchTvShows =
              !append || state.hasMoreTvShows;

          final List<Future<Object>> futures = <Future<Object>>[];
          if (shouldFetchMovies) {
            futures.add(_tmdbApi.searchMoviesPaged(
              query,
              page: append ? moviePage : 1,
            ));
          }
          if (shouldFetchTvShows) {
            futures.add(_tmdbApi.searchTvShowsPaged(
              query,
              page: append ? tvPage : 1,
            ));
          }

          final List<Object> results = await Future.wait(futures);

          int resultIndex = 0;
          if (shouldFetchMovies) {
            final TmdbPagedResult<Movie> movieResult =
                results[resultIndex] as TmdbPagedResult<Movie>;
            resultIndex++;
            final List<Movie> animOnly =
                _filterAnimationOnlyMovies(movieResult.results);
            final List<Movie> resolved =
                await _resolveMovieGenres(animOnly);
            if (resolved.isNotEmpty) {
              await _db.upsertMovies(resolved);
            }
            for (final Movie movie in resolved) {
              newItems.add(MediaSearchItem.fromMovie(movie));
            }
            hasMoreMovies = movieResult.hasMore;
            moviePage = movieResult.page;
          }
          if (shouldFetchTvShows) {
            final TmdbPagedResult<TvShow> tvResult =
                results[resultIndex] as TmdbPagedResult<TvShow>;
            final List<TvShow> animOnly =
                _filterAnimationOnlyTvShows(tvResult.results);
            final List<TvShow> resolved =
                await _resolveTvShowGenres(animOnly);
            if (resolved.isNotEmpty) {
              await _db.upsertTvShows(resolved);
            }
            for (final TvShow tvShow in resolved) {
              newItems.add(MediaSearchItem.fromTvShow(tvShow));
            }
            hasMoreTvShows = tvResult.hasMore;
            tvPage = tvResult.page;
          }
      }

      if (state.query == query) {
        final List<MediaSearchItem> allItems = append
            ? <MediaSearchItem>[...state.items, ...newItems]
            : newItems;
        final List<MediaSearchItem> sorted =
            _applySort(allItems, state.currentSort, query);
        state = state.copyWith(
          items: sorted,
          isLoading: false,
          isLoadingMore: false,
          currentMoviePage: moviePage,
          currentTvPage: tvPage,
          hasMoreMovies: hasMoreMovies,
          hasMoreTvShows: hasMoreTvShows,
        );
      }
    } on TmdbApiException catch (e) {
      if (state.query == query) {
        state = state.copyWith(
          error: e.message,
          isLoading: false,
          isLoadingMore: false,
        );
      }
    } on Exception catch (e) {
      if (state.query == query) {
        state = state.copyWith(
          error: e.toString(),
          isLoading: false,
          isLoadingMore: false,
        );
      }
    }
  }

  /// Проверяет наличие жанра Animation (ID=16) в списке жанров.
  static bool _isAnimated(List<String>? genres) {
    if (genres == null || genres.isEmpty) return false;
    return genres.contains(_animationGenreIdStr) ||
        genres.contains('Animation');
  }

  /// Оставляет только анимационные фильмы.
  List<Movie> _filterAnimationOnlyMovies(List<Movie> movies) {
    return movies.where((Movie m) => _isAnimated(m.genres)).toList();
  }

  /// Оставляет только анимационные сериалы.
  List<TvShow> _filterAnimationOnlyTvShows(List<TvShow> tvShows) {
    return tvShows.where((TvShow t) => _isAnimated(t.genres)).toList();
  }

  /// Исключает анимационные фильмы из результатов.
  List<Movie> _excludeAnimationMovies(List<Movie> movies) {
    return movies.where((Movie m) => !_isAnimated(m.genres)).toList();
  }

  /// Исключает анимационные сериалы из результатов.
  List<TvShow> _excludeAnimationTvShows(List<TvShow> tvShows) {
    return tvShows.where((TvShow t) => !_isAnimated(t.genres)).toList();
  }

  /// Резолвит числовые genre_ids в имена жанров для фильмов.
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

    final List<MediaSearchItem> sorted =
        _applySort(state.items, sort, state.query);
    state = state.copyWith(currentSort: sort, items: sorted);
  }

  /// Применяет сортировку к списку элементов.
  List<MediaSearchItem> _applySort(
    List<MediaSearchItem> items,
    SearchSort sort,
    String query,
  ) {
    if (items.isEmpty) return items;

    final List<MediaSearchItem> sorted = List<MediaSearchItem>.of(items);
    final bool ascending = sort.order == SearchSortOrder.ascending;

    switch (sort.field) {
      case SearchSortField.relevance:
        _sortByRelevance(sorted, query, ascending);
      case SearchSortField.date:
        _sortByDate(sorted, ascending);
      case SearchSortField.rating:
        _sortByRating(sorted, ascending);
    }

    return sorted;
  }

  void _sortByRelevance(
    List<MediaSearchItem> items,
    String query,
    bool ascending,
  ) {
    final String lowerQuery = query.toLowerCase();
    items.sort((MediaSearchItem a, MediaSearchItem b) {
      final int scoreA =
          _relevanceScore(a.title.toLowerCase(), lowerQuery);
      final int scoreB =
          _relevanceScore(b.title.toLowerCase(), lowerQuery);
      return ascending ? scoreA.compareTo(scoreB) : scoreB.compareTo(scoreA);
    });
  }

  void _sortByDate(List<MediaSearchItem> items, bool ascending) {
    items.sort((MediaSearchItem a, MediaSearchItem b) {
      final int? yearA = a.year;
      final int? yearB = b.year;
      if (yearA == null && yearB == null) return 0;
      if (yearA == null) return 1;
      if (yearB == null) return -1;
      return ascending ? yearA.compareTo(yearB) : yearB.compareTo(yearA);
    });
  }

  void _sortByRating(List<MediaSearchItem> items, bool ascending) {
    items.sort((MediaSearchItem a, MediaSearchItem b) {
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

  /// Возвращает оценку релевантности (больше = лучше).
  int _relevanceScore(String name, String query) {
    if (name == query) return 3;
    if (name.startsWith(query)) return 2;
    if (name.contains(query)) return 1;
    return 0;
  }

  /// Очищает результаты поиска.
  void clear() {
    state = MediaSearchState(subFilter: state.subFilter);
  }
}
