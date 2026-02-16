// Модель сортировки результатов поиска.

/// Поле сортировки.
enum SearchSortField {
  /// По релевантности (совпадение с запросом).
  relevance('Rel', 'Relevance'),

  /// По дате выпуска.
  date('Date', 'Date'),

  /// По рейтингу.
  rating('Rate', 'Rating');

  const SearchSortField(this.shortLabel, this.displayLabel);

  /// Короткий лейбл для компактного UI (3-4 символа).
  final String shortLabel;

  /// Полное отображаемое название.
  final String displayLabel;
}

/// Направление сортировки.
enum SearchSortOrder {
  /// По возрастанию.
  ascending,

  /// По убыванию.
  descending,
}

/// Настройки сортировки результатов поиска.
class SearchSort {
  /// Создаёт [SearchSort].
  const SearchSort({
    this.field = SearchSortField.relevance,
    this.order = SearchSortOrder.descending,
  });

  /// Поле сортировки.
  final SearchSortField field;

  /// Направление сортировки.
  final SearchSortOrder order;

  /// Значение по умолчанию (релевантность, по убыванию).
  static const SearchSort defaultSort = SearchSort();

  /// Проверяет, является ли сортировка значением по умолчанию.
  bool get isDefault => field == SearchSortField.relevance;

  /// Создаёт копию с изменённым полем.
  SearchSort copyWith({
    SearchSortField? field,
    SearchSortOrder? order,
  }) {
    return SearchSort(
      field: field ?? this.field,
      order: order ?? this.order,
    );
  }

  /// Переключает направление сортировки.
  SearchSort toggleOrder() {
    return copyWith(
      order: order == SearchSortOrder.ascending
          ? SearchSortOrder.descending
          : SearchSortOrder.ascending,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchSort &&
        other.field == field &&
        other.order == order;
  }

  @override
  int get hashCode => Object.hash(field, order);

  @override
  String toString() => 'SearchSort($field, $order)';
}
