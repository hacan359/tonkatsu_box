import 'collection.dart';

/// Sort mode for the collection list on the Home screen.
enum CollectionListSortMode {
  /// By creation date (created_at, newest first by default).
  createdDate('created_date'),

  /// Alphabetical (name, A→Z by default).
  alphabetical('alphabetical');

  const CollectionListSortMode(this.value);

  /// Stored value for SharedPreferences.
  final String value;

  /// Orders collections for every place that lists them — the Collections
  /// screen and the collection picker share this so they can't drift apart.
  ///
  /// [descending] is the stored `collection_list_sort_desc` flag. It reads as
  /// Z→A for [alphabetical] and as oldest-first for [createdDate]: the date
  /// meaning is the opposite of the flag's name, but it is what users already
  /// have persisted and what `localizedDescription` says, so it stays.
  int compare(Collection a, Collection b, {required bool descending}) {
    switch (this) {
      case CollectionListSortMode.createdDate:
        return descending
            ? a.createdAt.compareTo(b.createdAt)
            : b.createdAt.compareTo(a.createdAt);
      case CollectionListSortMode.alphabetical:
        return descending
            ? b.name.toLowerCase().compareTo(a.name.toLowerCase())
            : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    }
  }

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
