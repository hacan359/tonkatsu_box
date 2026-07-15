import '../../l10n/app_localizations.dart';

enum CollectionSortMode {
  /// Manual order (drag-and-drop, sort_order ASC).
  manual('manual', 'Manual', 'Manual', 'Custom order'),

  /// By added date (added_at DESC, newest first).
  addedDate('added_date', 'Date Added', 'Date', 'Newest first'),

  /// By status (active first, finished last).
  status('status', 'Status', 'Status', 'Active first'),

  /// Alphabetical (itemName ASC).
  name('name', 'Name', 'A-Z', 'A to Z'),

  /// By user rating (userRating DESC, highest first).
  rating('rating', 'My Rating', 'Rating', 'Highest first'),

  /// Favorites first (isFavorite DESC, then by name).
  favorite('favorite', 'Favorite', 'Favorite', 'Favorites first'),

  /// By external API rating (apiRating DESC, IGDB/TMDB).
  externalRating('external_rating', 'External Rating', 'IGDB/TMDB', 'Highest first'),

  /// By last activity (lastActivityAt DESC, recent first).
  lastActivity('last_activity', 'Last Activity', 'Activity', 'Recent first'),

  /// By start date (startedAt DESC, recent first, undated last).
  startDate('start_date', 'Start Date', 'Started', 'Recent first'),

  /// By completion date (completedAt DESC, recent first, undated last).
  completionDate('completion_date', 'Completion Date', 'Finished',
      'Recent first');

  const CollectionSortMode(
    this.value,
    this.displayLabel,
    this.shortLabel,
    this.description,
  );

  /// Stored value for SharedPreferences.
  final String value;

  final String displayLabel;

  /// Short label for compact UI (2-6 chars).
  final String shortLabel;

  final String description;

  /// Returns [addedDate] for unknown stored values.
  static CollectionSortMode fromString(String value) {
    for (final CollectionSortMode mode in CollectionSortMode.values) {
      if (mode.value == value) {
        return mode;
      }
    }
    return CollectionSortMode.addedDate;
  }

  String localizedDisplayLabel(S l) {
    switch (this) {
      case CollectionSortMode.manual:
        return l.sortManualDisplay;
      case CollectionSortMode.addedDate:
        return l.sortDateDisplay;
      case CollectionSortMode.status:
        return l.status;
      case CollectionSortMode.name:
        return l.name;
      case CollectionSortMode.rating:
        return l.detailMyRating;
      case CollectionSortMode.favorite:
        return l.favorite;
      case CollectionSortMode.externalRating:
        return l.sortExternalRatingDisplay;
      case CollectionSortMode.lastActivity:
        return l.sortLastActivityDisplay;
      case CollectionSortMode.startDate:
        return l.sortStartDateDisplay;
      case CollectionSortMode.completionDate:
        return l.sortCompletionDateDisplay;
    }
  }

  String localizedShortLabel(S l) {
    switch (this) {
      case CollectionSortMode.manual:
        return l.sortManualDisplay;
      case CollectionSortMode.addedDate:
        return l.date;
      case CollectionSortMode.status:
        return l.status;
      case CollectionSortMode.name:
        return l.sortNameShort;
      case CollectionSortMode.rating:
        return l.rating;
      case CollectionSortMode.favorite:
        return l.favorite;
      case CollectionSortMode.externalRating:
        return l.sortExternalRatingShort;
      case CollectionSortMode.lastActivity:
        return l.sortLastActivityShort;
      case CollectionSortMode.startDate:
        return l.sortStartDateShort;
      case CollectionSortMode.completionDate:
        return l.sortCompletionDateShort;
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
        return l.collectionListSortAlphabeticalZA;
      case CollectionSortMode.rating:
        return l.sortRatingLowest;
      case CollectionSortMode.favorite:
        return l.sortFavoriteLast;
      case CollectionSortMode.externalRating:
        return l.sortRatingLowest;
      case CollectionSortMode.lastActivity:
        return l.sortDateOldest;
      case CollectionSortMode.startDate:
      case CollectionSortMode.completionDate:
        return l.sortDateOldest;
    }
  }

  String localizedDescription(S l) {
    switch (this) {
      case CollectionSortMode.manual:
        return l.sortManualDesc;
      case CollectionSortMode.addedDate:
        return l.sortDateDesc;
      case CollectionSortMode.status:
        return l.sortStatusDesc;
      case CollectionSortMode.name:
        return l.collectionListSortAlphabeticalAZ;
      case CollectionSortMode.rating:
        return l.sortRatingDesc;
      case CollectionSortMode.favorite:
        return l.sortFavoriteDesc;
      case CollectionSortMode.externalRating:
        return l.sortRatingDesc;
      case CollectionSortMode.lastActivity:
        return l.sortLastActivityDesc;
      case CollectionSortMode.startDate:
      case CollectionSortMode.completionDate:
        return l.sortLastActivityDesc;
    }
  }
}
