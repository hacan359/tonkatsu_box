import 'package:core/models/collection_item.dart';
import 'package:core/models/collection_sort_mode.dart';
import 'package:core/utils/anime_manga_title_language.dart';

/// Item plus its precomputed lowercase name: a comparator recomputing
/// `displayName` costs O(n·log n) calls, keying costs exactly n.
typedef _Keyed = ({String name, CollectionItem item});

int _byName(_Keyed a, _Keyed b) {
  final int byName = a.name.compareTo(b.name);
  // List.sort is unstable; id keeps duplicate names deterministic.
  return byName != 0 ? byName : a.item.id.compareTo(b.item.id);
}

List<CollectionItem> _sortKeyed(
  List<CollectionItem> items,
  String lang,
  int Function(_Keyed a, _Keyed b) compare,
) {
  final List<_Keyed> keyed = <_Keyed>[
    for (final CollectionItem i in items)
      (name: i.displayName(lang).toLowerCase(), item: i),
  ];
  keyed.sort(compare);
  return <CollectionItem>[for (final _Keyed e in keyed) e.item];
}

/// Recent first; undated items sink last, kept stable by [tieBreaker].
int _compareNullableDatesDesc(
  DateTime? a,
  DateTime? b,
  int Function() tieBreaker,
) {
  if (a == null && b == null) return tieBreaker();
  if (a == null) return 1;
  if (b == null) return -1;
  final int byDate = b.compareTo(a);
  return byDate != 0 ? byDate : tieBreaker();
}

/// [CollectionSortMode.manual] returns the user-defined `sortOrder` as is;
/// [isDescending] inverts every other mode but never manual.
List<CollectionItem> applySortMode(
  List<CollectionItem> items,
  CollectionSortMode sortMode, {
  bool isDescending = false,
  String animeMangaTitleLanguage = AnimeMangaTitleLanguage.defaultId,
}) {
  final String lang = animeMangaTitleLanguage;
  final List<CollectionItem> sorted;
  switch (sortMode) {
    case CollectionSortMode.manual:
      sorted = List<CollectionItem>.of(items)
        ..sort(
          (CollectionItem a, CollectionItem b) =>
              a.sortOrder.compareTo(b.sortOrder),
        );
      // Manual is never inverted: the order is user-defined.
      return sorted;
    case CollectionSortMode.addedDate:
      sorted = List<CollectionItem>.of(items)
        ..sort(
          (CollectionItem a, CollectionItem b) =>
              b.addedAt.compareTo(a.addedAt),
        );
    case CollectionSortMode.status:
      sorted = _sortKeyed(items, lang, (_Keyed a, _Keyed b) {
        final int cmp = a.item.status.statusSortPriority
            .compareTo(b.item.status.statusSortPriority);
        return cmp != 0 ? cmp : _byName(a, b);
      });
    case CollectionSortMode.name:
      sorted = _sortKeyed(items, lang, _byName);
    case CollectionSortMode.rating:
      sorted = _sortKeyed(items, lang, (_Keyed a, _Keyed b) {
        // User rating only (API rating is a separate mode); unrated items
        // sort last by name so the bucket stays stable across re-sorts.
        final double? rA = a.item.userRating?.toDouble();
        final double? rB = b.item.userRating?.toDouble();
        if (rA == null && rB == null) return _byName(a, b);
        if (rA == null) return 1;
        if (rB == null) return -1;
        final int byRating = rB.compareTo(rA);
        return byRating != 0 ? byRating : _byName(a, b);
      });
    case CollectionSortMode.favorite:
      sorted = _sortKeyed(items, lang, (_Keyed a, _Keyed b) {
        if (a.item.isFavorite != b.item.isFavorite) {
          return a.item.isFavorite ? -1 : 1;
        }
        return _byName(a, b);
      });
    case CollectionSortMode.externalRating:
      sorted = List<CollectionItem>.of(items)
        ..sort((CollectionItem a, CollectionItem b) {
          // Null ratings sort last.
          if (a.apiRating == null && b.apiRating == null) return 0;
          if (a.apiRating == null) return 1;
          if (b.apiRating == null) return -1;
          return b.apiRating!.compareTo(a.apiRating!);
        });
    case CollectionSortMode.lastActivity:
      sorted = List<CollectionItem>.of(items)
        ..sort((CollectionItem a, CollectionItem b) {
          // An item untouched since it was added has no activity date yet;
          // fall back to added so fresh items don't sink below older ones.
          final DateTime aAt = a.lastActivityAt ?? a.addedAt;
          final DateTime bAt = b.lastActivityAt ?? b.addedAt;
          return bAt.compareTo(aAt);
        });
    case CollectionSortMode.startDate:
      sorted = _sortKeyed(
        items,
        lang,
        (_Keyed a, _Keyed b) => _compareNullableDatesDesc(
          a.item.startedAt,
          b.item.startedAt,
          () => _byName(a, b),
        ),
      );
    case CollectionSortMode.completionDate:
      sorted = _sortKeyed(
        items,
        lang,
        (_Keyed a, _Keyed b) => _compareNullableDatesDesc(
          a.item.completedAt,
          b.item.completedAt,
          () => _byName(a, b),
        ),
      );
  }
  if (isDescending) {
    return sorted.reversed.toList();
  }
  return sorted;
}
