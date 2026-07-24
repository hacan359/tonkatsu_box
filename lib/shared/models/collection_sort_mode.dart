enum CollectionSortMode {
  /// Manual order (drag-and-drop, sort_order ASC).
  manual('manual'),

  /// By added date (added_at DESC, newest first).
  addedDate('added_date'),

  /// By status (active first, finished last).
  status('status'),

  /// Alphabetical (itemName ASC).
  name('name'),

  /// By user rating (userRating DESC, highest first).
  rating('rating'),

  /// Favorites first (isFavorite DESC, then by name).
  favorite('favorite'),

  /// By external API rating (apiRating DESC, IGDB/TMDB).
  externalRating('external_rating'),

  /// By last activity (lastActivityAt DESC, recent first).
  lastActivity('last_activity'),

  /// By start date (startedAt DESC, recent first, undated last).
  startDate('start_date'),

  /// By completion date (completedAt DESC, recent first, undated last).
  completionDate('completion_date');

  const CollectionSortMode(this.value);

  /// Stored value for SharedPreferences.
  final String value;

  /// Returns [addedDate] for unknown stored values.
  static CollectionSortMode fromString(String value) {
    for (final CollectionSortMode mode in CollectionSortMode.values) {
      if (mode.value == value) {
        return mode;
      }
    }
    return CollectionSortMode.addedDate;
  }
}
