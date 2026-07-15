import '../../../shared/models/collection_item.dart';
import '../../../shared/models/item_status.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/tag.dart';
import '../../../shared/utils/media_format.dart';

class CollectionFilters {
  const CollectionFilters({
    this.mediaTypes = const <MediaType>{},
    this.platformIds = const <int>{},
    this.mangaFormats = const <String>{},
    this.animeFormats = const <String>{},
    this.tagIds = const <int>{},
    this.status,
    this.searchQuery = '',
  });

  final Set<MediaType> mediaTypes;
  final Set<int> platformIds;

  /// Manga `format` codes; scoped to manga items only (other types pass).
  final Set<String> mangaFormats;

  /// Anime `format` codes; scoped to anime items only (other types pass).
  final Set<String> animeFormats;

  /// Selected global tag ids; an item passes when it carries ANY of them (OR).
  final Set<int> tagIds;
  final ItemStatus? status;
  final String searchQuery;

  /// [itemTags] is the item id → global tag ids map from `itemTagsProvider`.
  List<CollectionItem> apply(
    List<CollectionItem> items,
    List<Tag> tags,
    Map<int, List<int>> itemTags, {
    String animeMangaTitleLanguage = 'romaji',
  }) {
    List<CollectionItem> result = items;

    if (mediaTypes.isNotEmpty) {
      // Match by the item's filter buckets so a custom item masquerading as
      // e.g. anime survives both the "Anime" and the "Custom" filter.
      result = result
          .where((CollectionItem item) => item.matchesTypeFilter(mediaTypes))
          .toList();
    }

    if (platformIds.isNotEmpty) {
      result = result
          .where((CollectionItem item) =>
              item.effectivePlatformId != null &&
              platformIds.contains(item.effectivePlatformId))
          .toList();
    }

    if (mangaFormats.isNotEmpty || animeFormats.isNotEmpty) {
      result = result
          .where((CollectionItem item) => MediaFormat.matchesFormatFilter(
                item,
                mangaFormats: mangaFormats,
                animeFormats: animeFormats,
              ))
          .toList();
    }

    if (tagIds.isNotEmpty) {
      result = result
          .where((CollectionItem item) =>
              itemTags[item.id]?.any(tagIds.contains) ?? false)
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
      for (final Tag tag in tags) tag.id: tag.name.toLowerCase(),
    };
    bool matchesTagName(CollectionItem item) {
      final List<int>? ids = itemTags[item.id];
      if (ids == null) return false;
      return ids.any((int id) => tagNames[id]?.contains(query) ?? false);
    }

    return result
        .where(
          (CollectionItem item) =>
              item
                      .displayName(animeMangaTitleLanguage)
                      .toLowerCase()
                      .contains(query) ||
              matchesTagName(item) ||
              (item.userComment?.toLowerCase().contains(query) ?? false) ||
              (item.authorComment?.toLowerCase().contains(query) ?? false),
        )
        .toList();
  }
}
