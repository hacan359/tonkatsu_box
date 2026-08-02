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

  /// Shared by the Collections screen and the picker so they can't drift.
  /// [descending] reads as Z→A but oldest-first for dates — as already persisted.
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
