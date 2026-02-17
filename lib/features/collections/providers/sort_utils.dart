// Утилита сортировки элементов коллекций.

import '../../../shared/models/collection_item.dart';
import '../../../shared/models/collection_sort_mode.dart';

/// Применяет режим сортировки к списку элементов.
///
/// Для [CollectionSortMode.manual] возвращает порядок по `sortOrder`,
/// направление не инвертируется (порядок определяется пользователем).
/// Для остальных режимов [isDescending] инвертирует результат.
List<CollectionItem> applySortMode(
  List<CollectionItem> items,
  CollectionSortMode sortMode, {
  bool isDescending = false,
}) {
  final List<CollectionItem> sorted = List<CollectionItem>.of(items);
  switch (sortMode) {
    case CollectionSortMode.manual:
      sorted.sort(
        (CollectionItem a, CollectionItem b) =>
            a.sortOrder.compareTo(b.sortOrder),
      );
      // Manual не инвертируется — порядок всегда от пользователя
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
        return a.itemName.toLowerCase().compareTo(b.itemName.toLowerCase());
      });
    case CollectionSortMode.name:
      sorted.sort(
        (CollectionItem a, CollectionItem b) =>
            a.itemName.toLowerCase().compareTo(b.itemName.toLowerCase()),
      );
    case CollectionSortMode.rating:
      sorted.sort((CollectionItem a, CollectionItem b) {
        // null рейтинг в конец
        if (a.userRating == null && b.userRating == null) return 0;
        if (a.userRating == null) return 1;
        if (b.userRating == null) return -1;
        return b.userRating!.compareTo(a.userRating!);
      });
  }
  if (isDescending) {
    return sorted.reversed.toList();
  }
  return sorted;
}
