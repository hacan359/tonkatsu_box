import 'package:core/database/dao/custom_media_dao.dart';
import 'package:core/models/collection_item.dart';
import 'package:core/models/custom_media.dart';
import 'package:core/utils/cover_image_id.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/collection_repository.dart';
import '../database/database_service.dart';
import 'image_cache_service.dart';

final Provider<CacheCleanupService> cacheCleanupServiceProvider =
    Provider<CacheCleanupService>((Ref ref) {
  return CacheCleanupService(
    ref.read(collectionRepositoryProvider),
    ref.read(imageCacheServiceProvider),
    ref.read(customMediaDaoProvider),
  );
});

/// Deletes covers for media absent from `collection_items` — cache tables only
/// grow, so a cache row proves nothing. Canvas images are never touched.
class CacheCleanupService {
  CacheCleanupService(this._collections, this._cache, this._customMedia);

  final CollectionRepository _collections;
  final ImageCacheService _cache;
  final CustomMediaDao _customMedia;

  static const Set<ImageType> _cleanableTypes = <ImageType>{
    ImageType.gameCover,
    ImageType.moviePoster,
    ImageType.tvShowPoster,
    ImageType.animeCover,
    ImageType.vnCover,
    ImageType.mangaCover,
    ImageType.bookCover,
    ImageType.audioCover,
    ImageType.coverOverride,
    ImageType.customCover,
  };

  Future<CacheCleanupResult> removeOrphans() async {
    final Map<ImageType, Set<String>> keep = <ImageType, Set<String>>{
      for (final ImageType type in _cleanableTypes) type: <String>{},
    };

    // A live item keeps both files: its override and the API cover under it,
    // so restoring the original needs no download. Custom items are ignored.
    final List<CollectionItem> items = await _collections.getAllItemsWithData();
    for (final CollectionItem item in items) {
      keep[item.cachedImageType]?.add(item.cachedCoverImageId);
      if (item.overrideCoverUrl != null) {
        keep[ImageType.coverOverride]?.add(item.coverImageId);
      }
    }

    // Every card counts, not only collection items: a board or a mood grid
    // alone keeps a card alive.
    final List<CustomMedia> cards = await _customMedia.getAll();
    for (final CustomMedia card in cards) {
      keep[ImageType.customCover]
          ?.add(customCoverImageId(id: card.id, coverUrl: card.coverUrl));
    }

    return _cache.removeOrphans(keep);
  }
}
