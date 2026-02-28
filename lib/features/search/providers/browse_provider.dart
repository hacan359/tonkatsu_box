// Провайдер Browse mode для поиска с фильтрами.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../settings/providers/settings_provider.dart';
import '../models/search_source.dart';
import '../sources/search_sources.dart';

/// Ключи SharedPreferences для сохранения состояния Browse.
abstract final class BrowseSettingsKeys {
  /// Выбранный источник.
  static const String sourceId = 'browse_source_id';
}

/// Состояние Browse mode.
class BrowseState {
  /// Создаёт [BrowseState].
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
    this.isSearchMode = false,
    this.searchQuery = '',
  });

  /// ID текущего источника.
  final String sourceId;

  /// Значения фильтров: {"genre": 28, "year": 2024, "platform": 19}.
  final Map<String, Object?> filterValues;

  /// Текущая сортировка (API-значение).
  final String? sortBy;

  /// Список элементов (Game, Movie, TvShow).
  final List<Object> items;

  /// Загрузка первой страницы.
  final bool isLoading;

  /// Загрузка следующей страницы (пагинация).
  final bool isLoadingMore;

  /// Текущая страница.
  final int currentPage;

  /// Есть ли ещё страницы.
  final bool hasMore;

  /// Сообщение об ошибке.
  final String? error;

  /// Режим поиска (вместо Browse).
  final bool isSearchMode;

  /// Текстовый поисковый запрос.
  final String searchQuery;

  /// Есть ли активные фильтры (не null).
  bool get hasFilters =>
      filterValues.values.any((Object? v) => v != null);

  /// Пустое состояние.
  bool get isEmpty => items.isEmpty && !isLoading;

  /// Текущий источник.
  SearchSource get source => getSearchSourceById(sourceId);

  /// Текущая сортировка или дефолтная.
  String get effectiveSortBy => sortBy ?? source.defaultSort.apiValue;

  /// Копирование с изменениями.
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
    bool? isSearchMode,
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
      isSearchMode: isSearchMode ?? this.isSearchMode,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Провайдер состояния Browse.
final NotifierProvider<BrowseNotifier, BrowseState> browseProvider =
    NotifierProvider<BrowseNotifier, BrowseState>(BrowseNotifier.new);

/// Notifier для Browse mode.
class BrowseNotifier extends Notifier<BrowseState> {
  late SharedPreferences _prefs;

  @override
  BrowseState build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    final String savedSourceId =
        _prefs.getString(BrowseSettingsKeys.sourceId) ?? 'movies';
    return BrowseState(sourceId: savedSourceId);
  }

  /// Сменить источник — сбросить фильтры и контент.
  void setSource(String sourceId) {
    _generation++;
    state = BrowseState(sourceId: sourceId);
    _prefs.setString(BrowseSettingsKeys.sourceId, sourceId);
  }

  /// Монотонный счётчик для защиты от race condition.
  ///
  /// Каждая новая операция (fetch/search/loadMore) инкрементирует счётчик.
  /// Если после await счётчик изменился — результат игнорируется.
  int _generation = 0;

  /// Установить значение фильтра и перезагрузить.
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

  /// Сменить сортировку и перезагрузить.
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

  /// Сбросить все фильтры.
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
  }

  /// Перейти в режим поиска.
  void enterSearchMode() {
    _generation++;
    state = state.copyWith(
      isSearchMode: true,
      items: const <Object>[],
      searchQuery: '',
      currentPage: 1,
      hasMore: false,
      clearError: true,
    );
  }

  /// Выйти из режима поиска (вернуться в Browse).
  void exitSearchMode() {
    _generation++;
    state = state.copyWith(
      isSearchMode: false,
      items: const <Object>[],
      searchQuery: '',
      currentPage: 1,
      hasMore: false,
      clearError: true,
    );

    // Если были фильтры — перезагрузить
    if (state.hasFilters) {
      _fetch();
    }
  }

  /// Выполнить текстовый поиск.
  Future<void> search(String query) async {
    if (query.trim().length < 2) return;

    final int gen = ++_generation;

    state = state.copyWith(
      searchQuery: query.trim(),
      items: const <Object>[],
      currentPage: 1,
      hasMore: false,
      isLoading: true,
      clearError: true,
    );

    try {
      final SearchSource source = state.source;
      final BrowseResult result = await source.search(
        ref,
        query: query.trim(),
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
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Загрузить следующую страницу.
  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    final int gen = ++_generation;

    state = state.copyWith(isLoadingMore: true);

    try {
      final SearchSource source = state.source;
      final int nextPage = state.currentPage + 1;

      final BrowseResult result;
      if (state.isSearchMode && state.searchQuery.isNotEmpty) {
        result = await source.search(
          ref,
          query: state.searchQuery,
          page: nextPage,
        );
      } else {
        result = await source.browse(
          ref,
          filterValues: state.filterValues,
          sortBy: state.effectiveSortBy,
          page: nextPage,
        );
      }

      if (_generation != gen) return; // stale result

      state = state.copyWith(
        items: <Object>[...state.items, ...result.items],
        hasMore: result.hasMore,
        currentPage: nextPage,
        isLoadingMore: false,
      );
    } on Exception catch (e) {
      if (_generation != gen) return;
      state = state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  /// Загрузить/перезагрузить контент с текущими фильтрами.
  Future<void> _fetch() async {
    if (!state.hasFilters) return;

    final int gen = ++_generation;

    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final SearchSource source = state.source;
      final BrowseResult result = await source.browse(
        ref,
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
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Принудительная перезагрузка.
  Future<void> refresh() async {
    if (state.isSearchMode && state.searchQuery.isNotEmpty) {
      await search(state.searchQuery);
    } else if (state.hasFilters) {
      await _fetch();
    }
  }
}
