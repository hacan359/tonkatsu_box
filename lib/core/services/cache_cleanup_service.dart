import 'package:core/models/collection_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/collection_repository.dart';
import 'image_cache_service.dart';

final Provider<CacheCleanupService> cacheCleanupServiceProvider =
    Provider<CacheCleanupService>((Ref ref) {
  return CacheCleanupService(
    ref.read(collectionRepositoryProvider),
    ref.read(imageCacheServiceProvider),
  );
});

/// Deletes covers for media absent from `collection_items` — cache tables only
/// grow, so a cache row proves nothing. Custom/canvas images are never touched.
class CacheCleanupService {
  CacheCleanupService(this._collections, this._cache);

  final CollectionRepository _collections;
  final ImageCacheService _cache;

  static const Set<ImageType> _cleanableTypes = <ImageType>{
    ImageType.gameCover,
    ImageType.moviePoster,
    ImageType.tvShowPoster,
    ImageType.animeCover,
    ImageType.vnCover,
    ImageType.mangaCover,
    ImageType.bookCover,
    ImageType.audioCover,
  };

  Future<CacheCleanupResult> removeOrphans() async {
    final Map<ImageType, Set<String>> keep = <ImageType, Set<String>>{
      for (final ImageType type in _cleanableTypes) type: <String>{},
    };

    // Same getters the display/download sides use, so kept ids line up with
    // the files on disk; items outside the cleanable set (custom) are ignored.
    final List<CollectionItem> items = await _collections.getAllItemsWithData();
    for (final CollectionItem item in items) {
      final Set<String>? bucket = keep[item.imageType];
      if (bucket != null) bucket.add(item.coverImageId);
    }

    return _cache.removeOrphans(keep);
  }
}
