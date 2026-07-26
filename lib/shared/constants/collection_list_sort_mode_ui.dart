import '../../l10n/app_localizations.dart';
import '../models/collection_list_sort_mode.dart';

/// Presentation extras for [CollectionListSortMode].
extension CollectionListSortModeUi on CollectionListSortMode {
  String localizedDisplayLabel(S l) {
    switch (this) {
      case CollectionListSortMode.createdDate:
        return l.collectionListSortCreatedDate;
      case CollectionListSortMode.alphabetical:
        return l.name;
    }
  }

  String localizedDescription(S l, {required bool descending}) {
    switch (this) {
      case CollectionListSortMode.createdDate:
        return descending ? l.sortDateOldest : l.sortDateDesc;
      case CollectionListSortMode.alphabetical:
        return descending
            ? l.collectionListSortAlphabeticalZA
            : l.collectionListSortAlphabeticalAZ;
    }
  }
}
