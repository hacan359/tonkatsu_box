import '../../../shared/models/collection_item.dart';
import '../../../shared/models/collection_sort_mode.dart';

int _compareByDisplayName(CollectionItem a, CollectionItem b, String lang) =>
    a.displayName(lang).toLowerCase().compareTo(
          b.displayName(lang).toLowerCase(),
        );

/// [CollectionSortMode.manual] returns the user-defined `sortOrder` as is;
/// [isDescending] inverts every other mode but never manual.
List<CollectionItem> applySortMode(
  List<CollectionItem> items,
  CollectionSortMode sortMode, {
  bool isDescending = false,
  String animeMangaTitleLanguage = 'romaji',
}) {
  final List<CollectionItem> sorted = List<CollectionItem>.of(items);
  switch (sortMode) {
    case CollectionSortMode.manual:
      sorted.sort(
        (CollectionItem a, CollectionItem b) =>
            a.sortOrder.compareTo(b.sortOrder),
      );
      // Manual is never inverted: the order is user-defined.
      return sorted;
    case CollectionSortMode.addedDate:
      sorted.sort(
        (CollectionItem a, CollectionItem b) =>
            b.addedAt.compareTo(a.addedAt),
      );
    case CollectionSortMode.status:
      sorted.sort((CollectionItem a, CollectionItem b) {
        final int cmp =
            a.status.statusSortPriority.compareTo(b.status.statusSortPriority);
        if (cmp != 0) return cmp;
        return _compareByDisplayName(a, b, animeMangaTitleLanguage);
      });
    case CollectionSortMode.name:
      sorted.sort(
        (CollectionItem a, CollectionItem b) =>
            _compareByDisplayName(a, b, animeMangaTitleLanguage),
      );
    case CollectionSortMode.rating:
      sorted.sort((CollectionItem a, CollectionItem b) {
        // "My Rating" ranks by the user's own rating only — the external API
        // rating is a separate mode. Items the user hasn't rated sort last,
        // ordered by name so the unrated bucket stays stable across re-sorts.
        final double? rA = a.userRating?.toDouble();
        final double? rB = b.userRating?.toDouble();
        if (rA == null && rB == null) {
          return _compareByDisplayName(a, b, animeMangaTitleLanguage);
        }
        if (rA == null) return 1;
        if (rB == null) return -1;
        final int byRating = rB.compareTo(rA);
        return byRating != 0
            ? byRating
            : _compareByDisplayName(a, b, animeMangaTitleLanguage);
      });
    case CollectionSortMode.favorite:
      sorted.sort((CollectionItem a, CollectionItem b) {
        if (a.isFavorite != b.isFavorite) {
          return a.isFavorite ? -1 : 1;
        }
        return _compareByDisplayName(a, b, animeMangaTitleLanguage);
      });
    case CollectionSortMode.externalRating:
      sorted.sort((CollectionItem a, CollectionItem b) {
        // Null ratings sort last.
        if (a.apiRating == null && b.apiRating == null) return 0;
        if (a.apiRating == null) return 1;
        if (b.apiRating == null) return -1;
        return b.apiRating!.compareTo(a.apiRating!);
      });
    case CollectionSortMode.lastActivity:
      sorted.sort((CollectionItem a, CollectionItem b) {
        // An item untouched since it was added has no activity date yet; fall
        // back to its added date so fresh items don't sink below older ones.
        final DateTime aAt = a.lastActivityAt ?? a.addedAt;
        final DateTime bAt = b.lastActivityAt ?? b.addedAt;
        return bAt.compareTo(aAt);
      });
  }
  if (isDescending) {
    return sorted.reversed.toList();
  }
  return sorted;
}
