// Абстракции для поисковых источников данных.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/models/media_type.dart';

/// ID жанра Animation в TMDB. Используется для фильтрации анимации.
const int tmdbAnimationGenreId = 16;

/// Вариант фильтра.
class FilterOption {
  /// Создаёт [FilterOption].
  const FilterOption({
    required this.id,
    required this.label,
    this.icon,
    this.value,
  });

  /// Уникальный идентификатор варианта.
  final String id;

  /// Отображаемое название.
  final String label;

  /// Иконка (опционально).
  final IconData? icon;

  /// Значение для передачи в API.
  final Object? value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FilterOption &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'FilterOption($id, $label)';
}

/// Вариант сортировки для Browse mode.
class BrowseSortOption {
  /// Создаёт [BrowseSortOption].
  const BrowseSortOption({
    required this.id,
    required this.apiValue,
  });

  /// Уникальный идентификатор (используется как ключ локализации).
  final String id;

  /// Значение для API запроса.
  final String apiValue;

  /// Локализованное название сортировки.
  String label(S l) => switch (id) {
        'popular' => l.browseSortPopular,
        'top_rated' || 'rating' => l.browseSortTopRated,
        'newest' => l.browseSortNewest,
        _ => id,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BrowseSortOption &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Описание одного фильтра.
///
/// Каждый фильтр объявляет свой ключ, placeholder и список вариантов.
abstract class SearchFilter {
  /// Уникальный ключ фильтра ("genre", "year", "platform").
  String get key;

  /// Отображаемое имя когда ничего не выбрано.
  String placeholder(S l);

  /// Список вариантов (загружается асинхронно).
  ///
  /// [l] — объект локализации для переведённых названий опций.
  Future<List<FilterOption>> options(WidgetRef ref, S l);

  /// Ключ для кэширования/сравнения (по умолчанию = [key]).
  ///
  /// Переопределяйте, если несколько фильтров имеют одинаковый [key],
  /// но разные наборы опций (например, жанры Movie vs TV vs IGDB).
  String get cacheKey => key;

  /// Значение "все" (сброс фильтра).
  FilterOption get allOption;
}

/// Результат Browse-запроса (Discover с фильтрами).
class BrowseResult {
  /// Создаёт [BrowseResult].
  const BrowseResult({
    required this.items,
    required this.mediaType,
    this.hasMore = false,
    this.totalPages = 1,
    this.currentPage = 1,
  });

  /// Список элементов (Game, Movie, TvShow).
  final List<Object> items;

  /// Тип медиа для отображения.
  final MediaType mediaType;

  /// Есть ли ещё страницы.
  final bool hasMore;

  /// Общее количество страниц.
  final int totalPages;

  /// Текущая страница.
  final int currentPage;
}

/// Описание источника данных для поиска.
///
/// Каждый источник объявляет свои фильтры, API-методы
/// и UI-конфигурацию. Добавление нового источника —
/// создать реализацию и зарегистрировать в списке.
abstract class SearchSource {
  /// Уникальный идентификатор.
  String get id;

  /// Отображаемое имя (локализованное).
  String label(S l);

  /// Иконка для дропдауна.
  IconData get icon;

  /// Список фильтров, которые поддерживает этот источник.
  /// Порядок = порядок отображения в фильтр-баре.
  List<SearchFilter> get filters;

  /// Есть ли Browse mode (Discover без поискового запроса).
  bool get supportsBrowse;

  /// Загрузить контент для Browse mode с фильтрами.
  Future<BrowseResult> browse(
    Ref ref, {
    required Map<String, Object?> filterValues,
    required String sortBy,
    required int page,
  });

  /// Поиск по текстовому запросу.
  Future<BrowseResult> search(
    Ref ref, {
    required String query,
    required int page,
  });

  /// Виджет Discover feed для режима без фильтров (null = нет Discover).
  Widget? buildDiscoverFeed(BuildContext context, WidgetRef ref);

  /// Доступные варианты сортировки.
  List<BrowseSortOption> get sortOptions;

  /// Сортировка по умолчанию.
  BrowseSortOption get defaultSort => sortOptions.first;

  /// Подсказка для поля поиска (локализованная).
  String searchHint(S l);
}
