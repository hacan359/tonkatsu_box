// Shared bulk-operation helpers for CollectionItem, used anywhere with a
// selection (a collection, All Items). Each method runs the low-level ops in
// a loop and invalidates every affected provider exactly once at the end.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/dao/global_tag_dao.dart';
import '../../../core/database/dao/tier_list_dao.dart';
import '../../../core/database/database_service.dart';
import '../../../data/repositories/collection_repository.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/item_status.dart';
import '../../../shared/models/media_type.dart';
import '../../home/providers/all_items_provider.dart';
import '../../tier_lists/providers/tier_list_detail_provider.dart';
import '../providers/collection_covers_provider.dart';
import '../providers/episode_tracker_provider.dart';
import '../providers/item_tags_provider.dart';
import '../providers/collections_provider.dart';

/// Bulk operations over collection items.
///
/// Each method derives the affected collections / media types / tier lists
/// from the item fields, so it works both inside one collection and on All
/// Items where items come from different collections.
class BulkOperations {
  BulkOperations._();

  /// Removes [items] from the DB. Returns how many were removed.
  static Future<int> removeItems(
    WidgetRef ref,
    List<CollectionItem> items,
  ) async {
    if (items.isEmpty) return 0;
    final CollectionRepository repo =
        ref.read(collectionRepositoryProvider);
    final TierListDao tierDao = ref.read(tierListDaoProvider);

    final Set<int?> affectedCollections = <int?>{};
    final Set<MediaType> affectedTypes = <MediaType>{};
    final Set<int> affectedTierLists = <int>{};
    int removed = 0;

    for (final CollectionItem item in items) {
      affectedTierLists
          .addAll(await tierDao.getTierListIdsForItem(item.id));
      await repo.removeItem(item.id);
      affectedCollections.add(item.collectionId);
      affectedTypes.add(item.mediaType);
      removed++;
    }

    _invalidateAfterMutation(
      ref,
      affectedCollections: affectedCollections,
      affectedTypes: affectedTypes,
      affectedTierLists: affectedTierLists,
    );
    return removed;
  }

  /// Moves items to [targetCollectionId] (`null` -> uncategorized).
  /// Returns `(moved, skipped)`.
  static Future<({int moved, int skipped})> moveItemsToCollection(
    WidgetRef ref,
    List<CollectionItem> items,
    int? targetCollectionId,
  ) async {
    if (items.isEmpty) return (moved: 0, skipped: 0);
    final CollectionRepository repo =
        ref.read(collectionRepositoryProvider);
    final TierListDao tierDao = ref.read(tierListDaoProvider);

    final Set<int?> affectedCollections = <int?>{targetCollectionId};
    final Set<MediaType> affectedTypes = <MediaType>{};
    final Set<int> affectedTierLists = <int>{};
    int moved = 0;
    int skipped = 0;

    for (final CollectionItem item in items) {
      affectedTierLists
          .addAll(await tierDao.getTierListIdsForItem(item.id));
      if (item.collectionId != null) {
        await tierDao.removeItemFromCollectionTierLists(
          item.id,
          item.collectionId!,
        );
      }

      // Tags are global — they stay with the item across collections.
      final bool ok = await repo.moveItemToCollection(
        item.id,
        targetCollectionId,
      );
      if (!ok) {
        skipped++;
        continue;
      }

      affectedCollections.add(item.collectionId);
      affectedTypes.add(item.mediaType);
      moved++;
    }

    _invalidateAfterMutation(
      ref,
      affectedCollections: affectedCollections,
      affectedTypes: affectedTypes,
      affectedTierLists: affectedTierLists,
    );
    return (moved: moved, skipped: skipped);
  }

  /// Clones items into [targetCollectionId]. Returns `(cloned, skipped)`.
  static Future<({int cloned, int skipped})> cloneItemsToCollection(
    WidgetRef ref,
    List<CollectionItem> items,
    int targetCollectionId,
  ) async {
    if (items.isEmpty) return (cloned: 0, skipped: 0);
    final CollectionRepository repo =
        ref.read(collectionRepositoryProvider);
    final GlobalTagDao tagDao = ref.read(globalTagDaoProvider);

    final Set<int?> affectedCollections = <int?>{targetCollectionId};
    final Set<MediaType> affectedTypes = <MediaType>{};
    bool tagsCopiedAny = false;
    int cloned = 0;
    int skipped = 0;

    for (final CollectionItem item in items) {
      final int? newId = await repo.cloneItemToCollection(
        item.id,
        targetCollectionId,
      );
      if (newId == null) {
        skipped++;
        continue;
      }
      // Tags are global — the copy carries the links with their manual order.
      final int copiedTags = await tagDao.copyItemTags(item.id, newId);
      if (copiedTags > 0) tagsCopiedAny = true;
      affectedTypes.add(item.mediaType);
      cloned++;
    }

    _invalidateAfterMutation(
      ref,
      affectedCollections: affectedCollections,
      affectedTypes: affectedTypes,
      affectedTierLists: const <int>{},
      tagsChanged: tagsCopiedAny,
    );
    return (cloned: cloned, skipped: skipped);
  }

  /// Changes the status of every item. Returns how many actually changed
  /// (skipped = already in the target status).
  static Future<int> updateItemsStatus(
    WidgetRef ref,
    List<CollectionItem> items,
    ItemStatus status,
  ) async {
    if (items.isEmpty) return 0;
    final CollectionRepository repo =
        ref.read(collectionRepositoryProvider);

    final Set<int?> affectedCollections = <int?>{};
    final Set<int> changedIds = <int>{};

    for (final CollectionItem item in items) {
      if (item.status == status) continue;
      await repo.updateItemStatus(
        item.id,
        status,
        mediaType: item.mediaType,
      );
      changedIds.add(item.id);
      affectedCollections.add(item.collectionId);
    }
    if (changedIds.isEmpty) return 0;

    // Local all-items update, so the list doesn't reload and flash.
    final AllItemsNotifier allItems =
        ref.read(allItemsNotifierProvider.notifier);
    for (final int id in changedIds) {
      allItems.updateStatusLocally(id, status);
    }

    for (final int? cid in affectedCollections) {
      ref.invalidate(collectionItemsNotifierProvider(cid));
      ref.invalidate(collectionStatsProvider(cid));
    }
    return changedIds.length;
  }

  static void _invalidateAfterMutation(
    WidgetRef ref, {
    required Set<int?> affectedCollections,
    required Set<MediaType> affectedTypes,
    required Set<int> affectedTierLists,
    bool tagsChanged = false,
  }) {
    for (final int? cid in affectedCollections) {
      ref.invalidate(collectionItemsNotifierProvider(cid));
      ref.invalidate(collectionStatsProvider(cid));
      ref.invalidate(collectionCoversProvider(cid));
    }
    if (tagsChanged) {
      ref.invalidate(itemTagsProvider);
    }
    // Bulk moves transfer watched marks in the DB; live trackers keep the
    // old in-memory state until invalidated.
    if (affectedTypes.any((MediaType t) => t.mayUseEpisodeTracker)) {
      ref.invalidate(episodeTrackerNotifierProvider);
    }
    for (final MediaType t in affectedTypes) {
      _invalidateCollectedIds(ref, t);
    }
    ref.invalidate(uncategorizedItemCountProvider);
    ref.invalidate(allItemsNotifierProvider);
    for (final int tlId in affectedTierLists) {
      ref.invalidate(tierListDetailProvider(tlId));
    }
  }

  static void _invalidateCollectedIds(WidgetRef ref, MediaType type) {
    switch (type) {
      case MediaType.game:
        ref.invalidate(collectedGameIdsProvider);
      case MediaType.movie:
        ref.invalidate(collectedMovieIdsProvider);
      case MediaType.tvShow:
        ref.invalidate(collectedTvShowIdsProvider);
      case MediaType.animation:
        ref.invalidate(collectedAnimationIdsProvider);
      case MediaType.visualNovel:
        ref.invalidate(collectedVisualNovelIdsProvider);
      case MediaType.manga:
        ref.invalidate(collectedMangaIdsProvider);
      case MediaType.anime:
        ref.invalidate(collectedAnimeIdsProvider);
      case MediaType.book:
        ref.invalidate(collectedBookIdsProvider);
      case MediaType.custom:
        break;
    }
  }
}
