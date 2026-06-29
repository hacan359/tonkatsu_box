// Режим сортировки элементов коллекции.

import '../../l10n/app_localizations.dart';

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
  rating('rating', 'My Rating', 'Rating', 'Highest first'),

  /// Favorites first (isFavorite DESC, then by name).
  favorite('favorite', 'Favorite', 'Favorite', 'Favorites first'),

  /// По внешнему API-рейтингу (apiRating DESC, IGDB/TMDB).
  externalRating('external_rating', 'External Rating', 'IGDB/TMDB', 'Highest first'),

  /// По дате последней активности (lastActivityAt DESC, недавние первыми).
  lastActivity('last_activity', 'Last Activity', 'Activity', 'Recent first');

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

  /// Локализованное отображаемое название.
  String localizedDisplayLabel(S l) {
    switch (this) {
      case CollectionSortMode.manual:
        return l.sortManualDisplay;
      case CollectionSortMode.addedDate:
        return l.sortDateDisplay;
      case CollectionSortMode.status:
        return l.sortStatusDisplay;
      case CollectionSortMode.name:
        return l.sortNameDisplay;
      case CollectionSortMode.rating:
        return l.sortRatingDisplay;
      case CollectionSortMode.favorite:
        return l.sortFavoriteDisplay;
      case CollectionSortMode.externalRating:
        return l.sortExternalRatingDisplay;
      case CollectionSortMode.lastActivity:
        return l.sortLastActivityDisplay;
    }
  }

  /// Локализованный короткий лейбл.
  String localizedShortLabel(S l) {
    switch (this) {
      case CollectionSortMode.manual:
        return l.sortManualShort;
      case CollectionSortMode.addedDate:
        return l.sortDateShort;
      case CollectionSortMode.status:
        return l.sortStatusShort;
      case CollectionSortMode.name:
        return l.sortNameShort;
      case CollectionSortMode.rating:
        return l.sortRatingShort;
      case CollectionSortMode.favorite:
        return l.sortFavoriteShort;
      case CollectionSortMode.externalRating:
        return l.sortExternalRatingShort;
      case CollectionSortMode.lastActivity:
        return l.sortLastActivityShort;
    }
  }

  /// Direction-toggle label that spells out what ends up on top for the
  /// current direction, instead of an ambiguous ascending/descending (which
  /// reads backwards for date/rating/activity modes).
  String localizedDirectionLabel(S l, {required bool descending}) {
    if (!descending) return localizedDescription(l);
    switch (this) {
      case CollectionSortMode.manual:
        return l.sortManualDesc; // custom order does not reverse
      case CollectionSortMode.addedDate:
        return l.sortDateOldest;
      case CollectionSortMode.status:
        return l.sortStatusFinished;
      case CollectionSortMode.name:
        return l.sortNameZa;
      case CollectionSortMode.rating:
        return l.sortRatingLowest;
      case CollectionSortMode.favorite:
        return l.sortFavoriteLast;
      case CollectionSortMode.externalRating:
        return l.sortExternalRatingLowest;
      case CollectionSortMode.lastActivity:
        return l.sortLastActivityOldest;
    }
  }

  /// Локализованное описание порядка сортировки.
  String localizedDescription(S l) {
    switch (this) {
      case CollectionSortMode.manual:
        return l.sortManualDesc;
      case CollectionSortMode.addedDate:
        return l.sortDateDesc;
      case CollectionSortMode.status:
        return l.sortStatusDesc;
      case CollectionSortMode.name:
        return l.sortNameDesc;
      case CollectionSortMode.rating:
        return l.sortRatingDesc;
      case CollectionSortMode.favorite:
        return l.sortFavoriteDesc;
      case CollectionSortMode.externalRating:
        return l.sortExternalRatingDesc;
      case CollectionSortMode.lastActivity:
        return l.sortLastActivityDesc;
    }
  }
}
