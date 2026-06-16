import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/collection_repository.dart';
import '../../shared/models/collection_item.dart';
import 'image_cache_service.dart';

final Provider<CacheCleanupService> cacheCleanupServiceProvider =
    Provider<CacheCleanupService>((Ref ref) {
  return CacheCleanupService(
    ref.read(collectionRepositoryProvider),
    ref.read(imageCacheServiceProvider),
  );
});

/// Removes downloaded cover images for media that is no longer in any
/// collection. The metadata cache tables (games, *_cache, custom_items) only
/// ever grow — they aren't pruned when an item or whole collection is removed
/// — so the presence of a cache row means nothing; only membership in
/// `collection_items` (a named collection or the uncategorized library) counts.
///
/// Only the re-downloadable cover folders are scanned. Custom covers (often
/// user-uploaded local images that can't be fetched again) and canvas board
/// images are never touched.
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
  };

  Future<CacheCleanupResult> removeOrphans() async {
    final Map<ImageType, Set<String>> keep = <ImageType, Set<String>>{
      for (final ImageType type in _cleanableTypes) type: <String>{},
    };

    // `imageType` / `coverImageId` are the same getters the display and
    // download sides use, so the kept ids line up exactly with the files on
    // disk. Items outside the cleanable set (custom) are ignored here.
    final List<CollectionItem> items = await _collections.getAllItemsWithData();
    for (final CollectionItem item in items) {
      final Set<String>? bucket = keep[item.imageType];
      if (bucket != null) bucket.add(item.coverImageId);
    }

    return _cache.removeOrphans(keep);
  }
}
