import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/game_repository.dart';
import '../../../shared/models/game.dart';
import '../../../shared/models/search_sort.dart';

const int _gamePageSize = 50;

class GameSearchState {
  const GameSearchState({
    this.query = '',
    this.results = const <Game>[],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.selectedPlatformIds = const <int>[],
    this.currentSort = const SearchSort(),
    this.currentOffset = 0,
    this.hasMore = false,
  });

  final String query;

  final List<Game> results;

  /// First-page load in progress.
  final bool isLoading;

  /// Next-page (pagination) load in progress.
  final bool isLoadingMore;

  final String? error;

  final List<int> selectedPlatformIds;

  final SearchSort currentSort;

  /// Current offset for IGDB pagination.
  final int currentOffset;

  final bool hasMore;

  bool get hasResults => results.isNotEmpty;

  bool get isEmpty => query.isEmpty && results.isEmpty && !isLoading;

  bool get hasPlatformFilter => selectedPlatformIds.isNotEmpty;

  GameSearchState copyWith({
    String? query,
    List<Game>? results,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    List<int>? selectedPlatformIds,
    SearchSort? currentSort,
    int? currentOffset,
    bool? hasMore,
    bool clearError = false,
  }) {
    return GameSearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      selectedPlatformIds: selectedPlatformIds ?? this.selectedPlatformIds,
      currentSort: currentSort ?? this.currentSort,
      currentOffset: currentOffset ?? this.currentOffset,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameSearchState &&
        other.query == query &&
        listEquals(other.results, results) &&
        other.isLoading == isLoading &&
        other.isLoadingMore == isLoadingMore &&
        other.error == error &&
        listEquals(other.selectedPlatformIds, selectedPlatformIds) &&
        other.currentSort == currentSort &&
        other.currentOffset == currentOffset &&
        other.hasMore == hasMore;
  }

  @override
  int get hashCode => Object.hash(
        query,
        Object.hashAll(results),
        isLoading,
        isLoadingMore,
        error,
        Object.hashAll(selectedPlatformIds),
        currentSort,
        currentOffset,
        hasMore,
      );
}

final NotifierProvider<GameSearchNotifier, GameSearchState>
    gameSearchProvider =
    NotifierProvider<GameSearchNotifier, GameSearchState>(
  GameSearchNotifier.new,
);

class GameSearchNotifier extends Notifier<GameSearchState> {
  late GameRepository _repository;

  /// Queries shorter than this are not searched.
  static const int minQueryLength = 2;

  @override
  GameSearchState build() {
    _repository = ref.watch(gameRepositoryProvider);
    return const GameSearchState();
  }

  Future<void> search(String query) async {
    state = state.copyWith(
      query: query,
      clearError: true,
      currentOffset: 0,
      hasMore: false,
    );

    if (query.length < minQueryLength) {
      state = state.copyWith(results: <Game>[], isLoading: false);
      return;
    }

    await _performSearch(query, offset: 0, append: false);
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || state.isLoading || !state.hasMore) return;
    if (state.query.length < minQueryLength) return;

    final int nextOffset = state.currentOffset + _gamePageSize;
    await _performSearch(state.query, offset: nextOffset, append: true);
  }

  Future<void> _performSearch(
    String query, {
    required int offset,
    required bool append,
  }) async {
    if (append) {
      state = state.copyWith(isLoadingMore: true, clearError: true);
    } else {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final List<Game> results = await _repository.searchGames(
        query: query,
        platformIds: state.selectedPlatformIds.isEmpty
            ? null
            : state.selectedPlatformIds,
        offset: offset,
      );

      // Drop the result if the query changed while we were awaiting.
      if (state.query == query) {
        final List<Game> allResults = append
            ? <Game>[...state.results, ...results]
            : results;
        final List<Game> sorted =
            _applySort(allResults, state.currentSort, query);
        state = state.copyWith(
          results: sorted,
          isLoading: false,
          isLoadingMore: false,
          currentOffset: offset,
          hasMore: results.length >= _gamePageSize,
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

  /// Re-sorts the already loaded results in place, without a new fetch.
  void setSort(SearchSort sort) {
    if (state.currentSort == sort) return;

    final List<Game> sorted = _applySort(
      state.results,
      sort,
      state.query,
    );
    state = state.copyWith(currentSort: sort, results: sorted);
  }

  List<Game> _applySort(
    List<Game> games,
    SearchSort sort,
    String query,
  ) {
    if (games.isEmpty) return games;

    final List<Game> sorted = List<Game>.of(games);
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

  void _sortByRelevance(List<Game> games, String query, bool ascending) {
    final String lowerQuery = query.toLowerCase();

    games.sort((Game a, Game b) {
      final int scoreA = _relevanceScore(a.name.toLowerCase(), lowerQuery);
      final int scoreB = _relevanceScore(b.name.toLowerCase(), lowerQuery);
      return ascending ? scoreA.compareTo(scoreB) : scoreB.compareTo(scoreA);
    });
  }

  /// Relevance score; higher is better.
  int _relevanceScore(String name, String query) {
    if (name == query) return 3;
    if (name.startsWith(query)) return 2;
    if (name.contains(query)) return 1;
    return 0;
  }

  void _sortByDate(List<Game> games, bool ascending) {
    games.sort((Game a, Game b) {
      final DateTime? dateA = a.releaseDate;
      final DateTime? dateB = b.releaseDate;

      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;

      return ascending
          ? dateA.compareTo(dateB)
          : dateB.compareTo(dateA);
    });
  }

  void _sortByRating(List<Game> games, bool ascending) {
    games.sort((Game a, Game b) {
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

  /// Sets the platform filter and re-runs the search.
  /// An empty [platformIds] means "all platforms".
  Future<void> setPlatformFilters(List<int> platformIds) async {
    state = state.copyWith(selectedPlatformIds: platformIds);

    if (state.query.length >= minQueryLength) {
      await _performSearch(state.query, offset: 0, append: false);
    }
  }

  Future<void> addPlatformFilter(int platformId) async {
    if (state.selectedPlatformIds.contains(platformId)) return;

    final List<int> newIds = <int>[...state.selectedPlatformIds, platformId];
    await setPlatformFilters(newIds);
  }

  Future<void> removePlatformFilter(int platformId) async {
    if (!state.selectedPlatformIds.contains(platformId)) return;

    final List<int> newIds = state.selectedPlatformIds
        .where((int id) => id != platformId)
        .toList();
    await setPlatformFilters(newIds);
  }

  Future<void> clearPlatformFilters() async {
    await setPlatformFilters(<int>[]);
  }

  void clear() {
    state = const GameSearchState();
  }
}
