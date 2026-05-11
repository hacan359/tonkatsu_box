// Шаренный bulk-helper для массовых операций над CollectionItem.
//
// Работает на любом экране, где есть selection: коллекция, All Items.
// Каждый метод вызывает низкоуровневые операции в цикле и инвалидирует
// все затронутые провайдеры ровно один раз в конце.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/dao/tag_dao.dart';
import '../../../core/database/dao/tier_list_dao.dart';
import '../../../core/database/database_service.dart';
import '../../../data/repositories/collection_repository.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/collection_tag.dart';
import '../../../shared/models/item_status.dart';
import '../../../shared/models/media_type.dart';
import '../../home/providers/all_items_provider.dart';
import '../../tier_lists/providers/tier_list_detail_provider.dart';
import '../providers/collection_covers_provider.dart';
import '../providers/collection_tags_provider.dart';
import '../providers/collections_provider.dart';

/// Static-namespace для bulk-операций над элементами коллекций.
///
/// Каждый метод принимает [WidgetRef] и [List<CollectionItem>] и сам
/// определяет затронутые коллекции / медиа-типы / тир-листы по полям
/// элементов — поэтому работает и внутри одной коллекции, и на All Items,
/// где элементы из разных коллекций.
class BulkOperations {
  BulkOperations._();

  /// Удаляет элементы из БД, инвалидирует затронутые провайдеры.
  /// Возвращает количество удалённых.
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

  /// Перемещает элементы в [targetCollectionId] (`null` → uncategorized).
  /// Возвращает `(moved, skipped)`.
  static Future<({int moved, int skipped})> moveItemsToCollection(
    WidgetRef ref,
    List<CollectionItem> items,
    int? targetCollectionId,
  ) async {
    if (items.isEmpty) return (moved: 0, skipped: 0);
    final CollectionRepository repo =
        ref.read(collectionRepositoryProvider);
    final TierListDao tierDao = ref.read(tierListDaoProvider);
    final TagDao tagDao = ref.read(tagDaoProvider);

    final Set<int?> affectedCollections = <int?>{targetCollectionId};
    final Set<MediaType> affectedTypes = <MediaType>{};
    final Set<int> affectedTierLists = <int>{};
    bool tagAssignedAny = false;
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

      final int? resolvedTagId = await _resolveTargetTagId(
        tagDao: tagDao,
        sourceTagId: item.tagId,
        targetCollectionId: targetCollectionId,
      );

      final bool ok = await repo.moveItemToCollection(
        item.id,
        targetCollectionId,
      );
      if (!ok) {
        skipped++;
        continue;
      }

      if (item.tagId != null) {
        await tagDao.setItemTag(item.id, resolvedTagId);
      }
      if (resolvedTagId != null) tagAssignedAny = true;

      affectedCollections.add(item.collectionId);
      affectedTypes.add(item.mediaType);
      moved++;
    }

    _invalidateAfterMutation(
      ref,
      affectedCollections: affectedCollections,
      affectedTypes: affectedTypes,
      affectedTierLists: affectedTierLists,
      tagAssignedTargetId:
          tagAssignedAny ? targetCollectionId : null,
    );
    return (moved: moved, skipped: skipped);
  }

  /// Клонирует элементы в [targetCollectionId].
  /// Возвращает `(cloned, skipped)`.
  static Future<({int cloned, int skipped})> cloneItemsToCollection(
    WidgetRef ref,
    List<CollectionItem> items,
    int targetCollectionId,
  ) async {
    if (items.isEmpty) return (cloned: 0, skipped: 0);
    final CollectionRepository repo =
        ref.read(collectionRepositoryProvider);
    final TagDao tagDao = ref.read(tagDaoProvider);

    final Set<int?> affectedCollections = <int?>{targetCollectionId};
    final Set<MediaType> affectedTypes = <MediaType>{};
    bool tagAssignedAny = false;
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
      final int? resolvedTagId = await _resolveTargetTagId(
        tagDao: tagDao,
        sourceTagId: item.tagId,
        targetCollectionId: targetCollectionId,
      );
      if (resolvedTagId != null) {
        await tagDao.setItemTag(newId, resolvedTagId);
        tagAssignedAny = true;
      }
      affectedTypes.add(item.mediaType);
      cloned++;
    }

    _invalidateAfterMutation(
      ref,
      affectedCollections: affectedCollections,
      affectedTypes: affectedTypes,
      affectedTierLists: const <int>{},
      tagAssignedTargetId:
          tagAssignedAny ? targetCollectionId : null,
    );
    return (cloned: cloned, skipped: skipped);
  }

  /// Меняет статус у всех переданных элементов.
  /// Возвращает количество реально изменённых (skipped — те, что уже
  /// были в целевом статусе).
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

    // Локальный апдейт all-items без перезагрузки списка.
    final AllItemsNotifier allItems =
        ref.read(allItemsNotifierProvider.notifier);
    for (final int id in changedIds) {
      allItems.updateStatusLocally(id, status);
    }

    // Каждая затронутая коллекция: инвалидация состояния списка + статов.
    for (final int? cid in affectedCollections) {
      ref.invalidate(collectionItemsNotifierProvider(cid));
      ref.invalidate(collectionStatsProvider(cid));
    }
    return changedIds.length;
  }

  // ---------------------------------------------------------------------------

  static Future<int?> _resolveTargetTagId({
    required TagDao tagDao,
    required int? sourceTagId,
    required int? targetCollectionId,
  }) async {
    if (sourceTagId == null || targetCollectionId == null) return null;
    final CollectionTag? sourceTag = await tagDao.getTagById(sourceTagId);
    if (sourceTag == null) return null;
    return tagDao.resolveOrCreateInCollection(
      targetCollectionId,
      sourceTag.name,
      color: sourceTag.color,
    );
  }

  /// Единая инвалидация после bulk-операции — touch'ает все затронутые
  /// коллекции + глобальные счётчики.
  static void _invalidateAfterMutation(
    WidgetRef ref, {
    required Set<int?> affectedCollections,
    required Set<MediaType> affectedTypes,
    required Set<int> affectedTierLists,
    int? tagAssignedTargetId,
  }) {
    for (final int? cid in affectedCollections) {
      ref.invalidate(collectionItemsNotifierProvider(cid));
      ref.invalidate(collectionStatsProvider(cid));
      ref.invalidate(collectionCoversProvider(cid));
    }
    if (tagAssignedTargetId != null) {
      ref.invalidate(collectionTagsProvider(tagAssignedTargetId));
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
      case MediaType.custom:
        break;
    }
  }
}
