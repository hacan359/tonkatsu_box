// Режим сортировки элементов коллекции.

/// Режим сортировки элементов в коллекции.
enum CollectionSortMode {
  /// Ручной порядок (drag-and-drop, sort_order ASC).
  manual('manual', 'Manual', 'Manual', 'Custom order'),

  /// По дате добавления (added_at DESC, новые первыми).
  addedDate('added_date', 'Date Added', 'Date', 'Newest first'),

  /// По статусу (активные первыми, завершённые последними).
  status('status', 'Status', 'Status', 'Active first'),

  /// По алфавиту (itemName ASC).
  name('name', 'Name', 'A-Z', 'A to Z'),

  /// По пользовательскому рейтингу (userRating DESC, высшие первыми).
  rating('rating', 'My Rating', 'Rating', 'Highest first');

  const CollectionSortMode(
    this.value,
    this.displayLabel,
    this.shortLabel,
    this.description,
  );

  /// Строковое значение для хранения в SharedPreferences.
  final String value;

  /// Отображаемое название.
  final String displayLabel;

  /// Короткий лейбл для компактного UI (2-6 символов).
  final String shortLabel;

  /// Краткое описание порядка сортировки.
  final String description;

  /// Создаёт [CollectionSortMode] из строки.
  ///
  /// Возвращает [addedDate] для неизвестных значений.
  static CollectionSortMode fromString(String value) {
    for (final CollectionSortMode mode in CollectionSortMode.values) {
      if (mode.value == value) {
        return mode;
      }
    }
    return CollectionSortMode.addedDate;
  }
}
