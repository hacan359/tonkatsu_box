// Режим сортировки списка коллекций на Home Screen.

import '../../l10n/app_localizations.dart';

/// Режим сортировки списка коллекций.
enum CollectionListSortMode {
  /// По дате создания (created_at, новые первыми по умолчанию).
  createdDate('created_date'),

  /// По алфавиту (name, A→Z по умолчанию).
  alphabetical('alphabetical');

  const CollectionListSortMode(this.value);

  /// Строковое значение для хранения в SharedPreferences.
  final String value;

  /// Создаёт [CollectionListSortMode] из строки.
  ///
  /// Возвращает [createdDate] для неизвестных значений.
  static CollectionListSortMode fromString(String value) {
    for (final CollectionListSortMode mode
        in CollectionListSortMode.values) {
      if (mode.value == value) {
        return mode;
      }
    }
    return CollectionListSortMode.createdDate;
  }

  /// Локализованное отображаемое название.
  String localizedDisplayLabel(S l) {
    switch (this) {
      case CollectionListSortMode.createdDate:
        return l.collectionListSortCreatedDate;
      case CollectionListSortMode.alphabetical:
        return l.collectionListSortAlphabetical;
    }
  }

  /// Локализованное описание порядка сортировки.
  String localizedDescription(S l, {required bool descending}) {
    switch (this) {
      case CollectionListSortMode.createdDate:
        return descending
            ? l.collectionListSortCreatedDateOldest
            : l.collectionListSortCreatedDateNewest;
      case CollectionListSortMode.alphabetical:
        return descending
            ? l.collectionListSortAlphabeticalZA
            : l.collectionListSortAlphabeticalAZ;
    }
  }
}
