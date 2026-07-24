/// Sort mode for the collection list on the Home screen.
enum CollectionListSortMode {
  /// By creation date (created_at, newest first by default).
  createdDate('created_date'),

  /// Alphabetical (name, A→Z by default).
  alphabetical('alphabetical');

  const CollectionListSortMode(this.value);

  /// Stored value for SharedPreferences.
  final String value;

  /// Returns [createdDate] for unknown stored values.
  static CollectionListSortMode fromString(String value) {
    for (final CollectionListSortMode mode
        in CollectionListSortMode.values) {
      if (mode.value == value) {
        return mode;
      }
    }
    return CollectionListSortMode.createdDate;
  }
}
