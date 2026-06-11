import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_error_extract.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/search_source.dart';
import '../sources/search_sources.dart';

/// SharedPreferences keys for persisting Browse state.
abstract final class BrowseSettingsKeys {
  static const String sourceId = 'browse_source_id';
}

class BrowseState {
  const BrowseState({
    required this.sourceId,
    this.filterValues = const <String, Object?>{},
    this.sortBy,
    this.items = const <Object>[],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.currentPage = 1,
    this.hasMore = false,
    this.error,
    this.errorDetail,
    this.searchQuery = '',
  });

  final String sourceId;

  /// Filter values, e.g. {"genre": 28, "year": 2024, "platform": 19}.
  final Map<String, Object?> filterValues;

  /// Current sort as the raw API value.
  final String? sortBy;

  /// Result items (Game, Movie or TvShow).
  final List<Object> items;

  /// First-page load in progress.
  final bool isLoading;

  /// Next-page (pagination) load in progress.
  final bool isLoadingMore;

  final int currentPage;

  final bool hasMore;

  final String? error;

  /// Detailed error debug info, meant for copy-to-clipboard.
  final String? errorDetail;

  final String searchQuery;

  /// True when any filter is set (non-null and not an empty list).
  bool get hasFilters => filterValues.values.any(
        (Object? v) =>
            v != null && (v is! List<Object> || v.isNotEmpty),
      );

  bool get hasSearchQuery => searchQuery.trim().length >= 2;

  bool get hasActiveQuery => hasSearchQuery || hasFilters;

  bool get isEmpty => items.isEmpty && !isLoading;

  SearchSource get source => getSearchSourceById(sourceId);

  String get effectiveSortBy => sortBy ?? source.defaultSort.apiValue;

  BrowseState copyWith({
    String? sourceId,
    Map<String, Object?>? filterValues,
    String? sortBy,
    List<Object>? items,
    bool? isLoading,
    bool? isLoadingMore,
    int? currentPage,
    bool? hasMore,
    String? error,
    String? errorDetail,
    String? searchQuery,
    bool clearError = false,
    bool clearSortBy = false,
  }) {
    return BrowseState(
      sourceId: sourceId ?? this.sourceId,
      filterValues: filterValues ?? this.filterValues,
      sortBy: clearSortBy ? null : (sortBy ?? this.sortBy),
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
      errorDetail: clearError ? null : (errorDetail ?? this.errorDetail),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

final NotifierProvider<BrowseNotifier, BrowseState> browseProvider =
    NotifierProvider<BrowseNotifier, BrowseState>(BrowseNotifier.new);

class BrowseNotifier extends Notifier<BrowseState> {
  late SharedPreferences _prefs;

  @override
  BrowseState build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    final String savedSourceId =
        _prefs.getString(BrowseSettingsKeys.sourceId) ?? 'movies';
    return BrowseState(sourceId: savedSourceId);
  }

  /// Switching the source resets filters and content, but keeps the text
  /// query: the new source has different filters, while the text the user
  /// already typed shouldn't be lost by switching.
  void setSource(String sourceId) {
    _generation++;
    final String preservedQuery = state.searchQuery;
    state = BrowseState(sourceId: sourceId, searchQuery: preservedQuery);
    _prefs.setString(BrowseSettingsKeys.sourceId, sourceId);
    if (state.hasSearchQuery) {
      _fetch();
    }
  }

  /// Monotonic counter guarding against race conditions: every new
  /// operation increments it, and a result whose generation no longer
  /// matches after an await is discarded as stale.
  int _generation = 0;

  Future<void> setFilter(String key, Object? value) async {
    final Map<String, Object?> updated =
        Map<String, Object?>.from(state.filterValues);
    updated[key] = value;

    state = state.copyWith(
      filterValues: updated,
      items: const <Object>[],
      currentPage: 1,
      hasMore: false,
      clearError: true,
    );

    await _fetch();
  }

  Future<void> setSort(String sortBy) async {
    state = state.copyWith(
      sortBy: sortBy,
      items: const <Object>[],
      currentPage: 1,
      hasMore: false,
      clearError: true,
    );

    await _fetch();
  }

  void clearFilters() {
    _generation++;
    state = state.copyWith(
      filterValues: const <String, Object?>{},
      items: const <Object>[],
      currentPage: 1,
      hasMore: false,
      clearError: true,
      clearSortBy: true,
    );

    // A remaining text query still warrants a reload with text only.
    if (state.hasSearchQuery) {
      _fetch();
    }
  }

  /// Updates the text query without triggering a search. Used to sync the
  /// text from the controller right before a filter change.
  void setSearchQuery(String query) {
    final String trimmed = query.trim();
    if (trimmed.length < 2 || state.searchQuery == trimmed) return;
    state = state.copyWith(searchQuery: trimmed);
  }

  Future<void> search(String query) async {
    if (query.trim().length < 2) return;

    state = state.copyWith(
      searchQuery: query.trim(),
      items: const <Object>[],
      currentPage: 1,
      hasMore: false,
    );

    await _fetch();
  }

  void clearSearch() {
    _generation++;
    state = state.copyWith(
      searchQuery: '',
      items: const <Object>[],
      currentPage: 1,
      hasMore: false,
      clearError: true,
    );

    // Remaining filters still warrant a reload with filters only.
    if (state.hasFilters) {
      _fetch();
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    final int gen = ++_generation;

    state = state.copyWith(isLoadingMore: true);

    try {
      final SearchSource source = state.source;
      final int nextPage = state.currentPage + 1;

      final BrowseResult result = await source.fetch(
        ref,
        query: state.hasSearchQuery ? state.searchQuery : null,
        filterValues: state.filterValues,
        sortBy: state.effectiveSortBy,
        page: nextPage,
      );

      if (_generation != gen) return; // stale result

      state = state.copyWith(
        items: <Object>[...state.items, ...result.items],
        hasMore: result.hasMore,
        currentPage: nextPage,
        isLoadingMore: false,
      );
    } on Exception catch (e) {
      if (_generation != gen) return;
      final ApiError err = extractApiError(e);
      state = state.copyWith(
        isLoadingMore: false,
        error: err.message,
        errorDetail: err.detail,
      );
    }
  }

  Future<void> _fetch() async {
    if (!state.hasActiveQuery) return;

    final int gen = ++_generation;

    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final SearchSource source = state.source;
      final BrowseResult result = await source.fetch(
        ref,
        query: state.hasSearchQuery ? state.searchQuery : null,
        filterValues: state.filterValues,
        sortBy: state.effectiveSortBy,
        page: 1,
      );

      if (_generation != gen) return; // stale result

      state = state.copyWith(
        items: result.items,
        hasMore: result.hasMore,
        currentPage: 1,
        isLoading: false,
      );
    } on Exception catch (e) {
      if (_generation != gen) return;
      final ApiError err = extractApiError(e);
      state = state.copyWith(
        isLoading: false,
        error: err.message,
        errorDetail: err.detail,
      );
    }
  }

  Future<void> refresh() async {
    if (state.hasActiveQuery) {
      await _fetch();
    }
  }
}
