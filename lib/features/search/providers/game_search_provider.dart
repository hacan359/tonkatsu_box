import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/game_repository.dart';
import '../../../shared/models/game.dart';

/// Состояние поиска игр.
class GameSearchState {
  /// Создаёт [GameSearchState].
  const GameSearchState({
    this.query = '',
    this.results = const <Game>[],
    this.isLoading = false,
    this.error,
    this.selectedPlatformIds = const <int>[],
  });

  /// Текущий поисковый запрос.
  final String query;

  /// Результаты поиска.
  final List<Game> results;

  /// Флаг загрузки.
  final bool isLoading;

  /// Сообщение об ошибке.
  final String? error;

  /// Выбранные платформы для фильтрации.
  final List<int> selectedPlatformIds;

  /// Проверяет, есть ли результаты.
  bool get hasResults => results.isNotEmpty;

  /// Проверяет, пустой ли запрос.
  bool get isEmpty => query.isEmpty && results.isEmpty && !isLoading;

  /// Проверяет, есть ли выбранные платформы.
  bool get hasPlatformFilter => selectedPlatformIds.isNotEmpty;

  /// Копирует с изменёнными полями.
  GameSearchState copyWith({
    String? query,
    List<Game>? results,
    bool? isLoading,
    String? error,
    List<int>? selectedPlatformIds,
    bool clearError = false,
  }) {
    return GameSearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      selectedPlatformIds: selectedPlatformIds ?? this.selectedPlatformIds,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameSearchState &&
        other.query == query &&
        listEquals(other.results, results) &&
        other.isLoading == isLoading &&
        other.error == error &&
        listEquals(other.selectedPlatformIds, selectedPlatformIds);
  }

  @override
  int get hashCode => Object.hash(
        query,
        Object.hashAll(results),
        isLoading,
        error,
        Object.hashAll(selectedPlatformIds),
      );
}

/// Провайдер для поиска игр.
final NotifierProvider<GameSearchNotifier, GameSearchState>
    gameSearchProvider =
    NotifierProvider<GameSearchNotifier, GameSearchState>(
  GameSearchNotifier.new,
);

/// Notifier для управления поиском игр.
class GameSearchNotifier extends Notifier<GameSearchState> {
  late GameRepository _repository;

  /// Минимальная длина запроса для поиска.
  static const int minQueryLength = 2;

  @override
  GameSearchState build() {
    _repository = ref.watch(gameRepositoryProvider);
    return const GameSearchState();
  }

  /// Выполняет поиск игр.
  ///
  /// [query] — строка поиска.
  Future<void> search(String query) async {
    state = state.copyWith(query: query, clearError: true);

    if (query.length < minQueryLength) {
      state = state.copyWith(results: <Game>[], isLoading: false);
      return;
    }

    await _performSearch(query);
  }

  Future<void> _performSearch(String query) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final List<Game> results = await _repository.searchGames(
        query: query,
        platformIds: state.selectedPlatformIds.isEmpty
            ? null
            : state.selectedPlatformIds,
      );

      // Проверяем, что запрос всё ещё актуален
      if (state.query == query) {
        state = state.copyWith(results: results, isLoading: false);
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

  /// Устанавливает фильтр по платформам и повторяет поиск.
  ///
  /// [platformIds] — список ID платформ. Пустой список = все платформы.
  Future<void> setPlatformFilters(List<int> platformIds) async {
    state = state.copyWith(selectedPlatformIds: platformIds);

    if (state.query.length >= minQueryLength) {
      await _performSearch(state.query);
    }
  }

  /// Добавляет платформу в фильтр.
  Future<void> addPlatformFilter(int platformId) async {
    if (state.selectedPlatformIds.contains(platformId)) return;

    final List<int> newIds = <int>[...state.selectedPlatformIds, platformId];
    await setPlatformFilters(newIds);
  }

  /// Удаляет платформу из фильтра.
  Future<void> removePlatformFilter(int platformId) async {
    if (!state.selectedPlatformIds.contains(platformId)) return;

    final List<int> newIds = state.selectedPlatformIds
        .where((int id) => id != platformId)
        .toList();
    await setPlatformFilters(newIds);
  }

  /// Очищает фильтр платформ.
  Future<void> clearPlatformFilters() async {
    await setPlatformFilters(<int>[]);
  }

  /// Очищает результаты поиска.
  void clear() {
    state = const GameSearchState();
  }
}
