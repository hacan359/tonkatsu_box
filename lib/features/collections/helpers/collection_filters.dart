import '../../../shared/models/collection_item.dart';
import '../../../shared/models/collection_tag.dart';
import '../../../shared/models/item_status.dart';
import '../../../shared/models/media_type.dart';
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

  final Set<int> tagIds;
  final ItemStatus? status;
  final String searchQuery;

  List<CollectionItem> apply(
    List<CollectionItem> items,
    List<CollectionTag> tags, {
    String animeMangaTitleLanguage = 'romaji',
  }) {
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
              item
                      .displayName(animeMangaTitleLanguage)
                      .toLowerCase()
                      .contains(query) ||
              (item.tagId != null &&
                  (tagNames[item.tagId]?.contains(query) ?? false)) ||
              (item.userComment?.toLowerCase().contains(query) ?? false) ||
              (item.authorComment?.toLowerCase().contains(query) ?? false),
        )
        .toList();
  }
}
