enum SearchSortField {
  /// Best match for the query.
  relevance,

  /// By release date.
  date,

  /// By rating.
  rating,
}

enum SearchSortOrder {
  ascending,
  descending,
}

/// Search result sort settings.
class SearchSort {
  const SearchSort({
    this.field = SearchSortField.relevance,
    this.order = SearchSortOrder.descending,
  });

  final SearchSortField field;

  final SearchSortOrder order;

  /// Default: relevance, descending.
  static const SearchSort defaultSort = SearchSort();

  bool get isDefault => field == SearchSortField.relevance;

  SearchSort copyWith({
    SearchSortField? field,
    SearchSortOrder? order,
  }) {
    return SearchSort(
      field: field ?? this.field,
      order: order ?? this.order,
    );
  }

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
