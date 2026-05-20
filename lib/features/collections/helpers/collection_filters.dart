import '../../../shared/models/collection_item.dart';
import '../../../shared/models/collection_tag.dart';
import '../../../shared/models/item_status.dart';
import '../../../shared/models/media_type.dart';

class CollectionFilters {
  const CollectionFilters({
    this.mediaTypes = const <MediaType>{},
    this.platformIds = const <int>{},
    this.tagIds = const <int>{},
    this.status,
    this.searchQuery = '',
  });

  final Set<MediaType> mediaTypes;
  final Set<int> platformIds;
  final Set<int> tagIds;
  final ItemStatus? status;
  final String searchQuery;

  List<CollectionItem> apply(
    List<CollectionItem> items,
    List<CollectionTag> tags,
  ) {
    List<CollectionItem> result = items;

    if (mediaTypes.isNotEmpty) {
      result = result
          .where((CollectionItem item) => mediaTypes.contains(item.mediaType))
          .toList();
    }

    if (platformIds.isNotEmpty) {
      result = result
          .where((CollectionItem item) =>
              item.platformId != null &&
              platformIds.contains(item.platformId))
          .toList();
    }

    if (tagIds.isNotEmpty) {
      result = result
          .where((CollectionItem item) =>
              item.tagId != null && tagIds.contains(item.tagId))
          .toList();
    }

    if (status != null) {
      result = result
          .where((CollectionItem item) => item.status == status)
          .toList();
    }

    if (searchQuery.isEmpty) return result;

    final String query = searchQuery.toLowerCase();
    final Map<int, String> tagNames = <int, String>{
      for (final CollectionTag tag in tags) tag.id: tag.name.toLowerCase(),
    };
    return result
        .where(
          (CollectionItem item) =>
              item.itemName.toLowerCase().contains(query) ||
              (item.tagId != null &&
                  (tagNames[item.tagId]?.contains(query) ?? false)) ||
              (item.userComment?.toLowerCase().contains(query) ?? false) ||
              (item.authorComment?.toLowerCase().contains(query) ?? false),
        )
        .toList();
  }
}
