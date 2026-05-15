import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/database/dao/collection_dao.dart';
import '../../../core/database/database_service.dart';
import '../../../data/repositories/collection_repository.dart';
import '../../../core/services/image_cache_service.dart';
import '../../../shared/models/collected_item_info.dart';
import '../../../shared/models/custom_media.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/collection_tag.dart';
import '../../../shared/models/collection_list_sort_mode.dart';
import '../../../shared/models/collection_sort_mode.dart';
import '../../../shared/models/game.dart';
import '../../../shared/models/item_status.dart';
import '../../../shared/models/item_status_logic.dart';
import '../../../shared/models/media_type.dart';
import '../../../data/repositories/game_repository.dart';
import '../../home/providers/all_items_provider.dart';
import '../../../core/database/dao/tag_dao.dart';
import '../../../core/database/dao/tier_list_dao.dart';
import '../../tier_lists/providers/tier_list_detail_provider.dart';
import '../../settings/providers/profile_provider.dart';
import '../../settings/providers/settings_provider.dart';
import 'collection_covers_provider.dart';
import 'collection_tags_provider.dart';
import 'sort_utils.dart';

final AsyncNotifierProvider<CollectionsNotifier, List<Collection>>
    collectionsProvider =
    AsyncNotifierProvider<CollectionsNotifier, List<Collection>>(
  CollectionsNotifier.new,
);

class CollectionsNotifier extends AsyncNotifier<List<Collection>> {
  late CollectionRepository _repository;

  @override
  Future<List<Collection>> build() async {
    _repository = ref.watch(collectionRepositoryProvider);
    return _repository.getAll();
  }

  Future<void> refresh() async {
    state = const AsyncLoading<List<Collection>>();
    state = await AsyncValue.guard(() => _repository.getAll());
  }

  Future<Collection> create({
    required String name,
    required String author,
  }) async {
    final Collection collection = await _repository.create(
      name: name,
      author: author,
    );

    final List<Collection> current = state.valueOrNull ?? <Collection>[];
    state = AsyncData<List<Collection>>(<Collection>[collection, ...current]);

    return collection;
  }

  Future<void> rename(int id, String newName) async {
    await _repository.updateName(id, newName);

    final List<Collection> current = state.valueOrNull ?? <Collection>[];
    state = AsyncData<List<Collection>>(
      current.map((Collection c) {
        if (c.id == id) {
          return c.copyWith(name: newName);
        }
        return c;
      }).toList(),
    );
  }

  Future<void> updatePersonalization(
    int id, {
    String? name,
    String? heroImagePath,
    String? description,
    bool clearHeroImage = false,
    bool clearDescription = false,
  }) async {
    await _repository.updatePersonalization(
      id,
      name: name,
      heroImagePath: heroImagePath,
      description: description,
      clearHeroImage: clearHeroImage,
      clearDescription: clearDescription,
    );

    final List<Collection> current = state.valueOrNull ?? <Collection>[];
    state = AsyncData<List<Collection>>(
      current.map((Collection c) {
        if (c.id != id) return c;
        return c.copyWith(
          name: name,
          heroImagePath: heroImagePath,
          description: description,
          clearHeroImage: clearHeroImage,
          clearDescription: clearDescription,
        );
      }).toList(),
    );
  }

  Future<void> delete(int id) async {
    await _repository.delete(id);

    final List<Collection> current = state.valueOrNull ?? <Collection>[];
    state = AsyncData<List<Collection>>(
      current.where((Collection c) => c.id != id).toList(),
    );

    ref.invalidate(collectionStatsProvider(id));
    ref.invalidate(collectionCoversProvider(id));
    ref.invalidate(allItemsNotifierProvider);
  }

}

/// `collectionId == null` selects uncategorized items.
final FutureProviderFamily<CollectionStats, int?> collectionStatsProvider =
    FutureProvider.family<CollectionStats, int?>(
  (Ref ref, int? collectionId) async {
    final CollectionRepository repository =
        ref.watch(collectionRepositoryProvider);
    return repository.getStats(collectionId);
  },
);

String _sortModeKey(int? collectionId) =>
    'collection_sort_mode_${collectionId ?? "uncategorized"}';

String _sortDescKey(int? collectionId) =>
    'collection_sort_desc_${collectionId ?? "uncategorized"}';

/// `collectionId == null` selects uncategorized items.
final NotifierProviderFamily<CollectionSortNotifier, CollectionSortMode, int?>
    collectionSortProvider =
    NotifierProvider.family<CollectionSortNotifier, CollectionSortMode, int?>(
  CollectionSortNotifier.new,
);

class CollectionSortNotifier extends FamilyNotifier<CollectionSortMode, int?> {
  @override
  CollectionSortMode build(int? arg) {
    _loadFromPrefs(arg);
    return CollectionSortMode.lastActivity;
  }

  Future<void> _loadFromPrefs(int? collectionId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? value = prefs.getString(_sortModeKey(collectionId));
    if (value != null) {
      state = CollectionSortMode.fromString(value);
    }
  }

  // Re-sort happens automatically: CollectionItemsNotifier watches this provider.
  Future<void> setSortMode(CollectionSortMode mode) async {
    state = mode;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sortModeKey(arg), mode.value);
  }
}

/// `collectionId == null` selects uncategorized items.
final NotifierProviderFamily<CollectionSortDescNotifier, bool, int?>
    collectionSortDescProvider =
    NotifierProvider.family<CollectionSortDescNotifier, bool, int?>(
  CollectionSortDescNotifier.new,
);

class CollectionSortDescNotifier extends FamilyNotifier<bool, int?> {
  @override
  bool build(int? arg) {
    _loadFromPrefs(arg);
    return false;
  }

  Future<void> _loadFromPrefs(int? collectionId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool? value = prefs.getBool(_sortDescKey(collectionId));
    if (value != null) {
      state = value;
    }
  }

  Future<void> toggle() async {
    state = !state;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sortDescKey(arg), state);
  }

  Future<void> setDescending({required bool descending}) async {
    state = descending;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sortDescKey(arg), descending);
  }
}

const String _collectionListSortModeKey = 'collection_list_sort_mode';
const String _collectionListSortDescKey = 'collection_list_sort_desc';
const String _collectionListGridViewKey = 'collection_list_grid_view';

final NotifierProvider<CollectionListSortNotifier, CollectionListSortMode>
    collectionListSortProvider =
    NotifierProvider<CollectionListSortNotifier, CollectionListSortMode>(
  CollectionListSortNotifier.new,
);

class CollectionListSortNotifier extends Notifier<CollectionListSortMode> {
  @override
  CollectionListSortMode build() {
    _loadFromPrefs();
    return CollectionListSortMode.createdDate;
  }

  Future<void> _loadFromPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? value = prefs.getString(_collectionListSortModeKey);
    if (value != null) {
      state = CollectionListSortMode.fromString(value);
    }
  }

  Future<void> setSortMode(CollectionListSortMode mode) async {
    state = mode;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_collectionListSortModeKey, mode.value);
  }
}

final NotifierProvider<CollectionListSortDescNotifier, bool>
    collectionListSortDescProvider =
    NotifierProvider<CollectionListSortDescNotifier, bool>(
  CollectionListSortDescNotifier.new,
);

class CollectionListSortDescNotifier extends Notifier<bool> {
  @override
  bool build() {
    _loadFromPrefs();
    return false;
  }

  Future<void> _loadFromPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool? value = prefs.getBool(_collectionListSortDescKey);
    if (value != null) {
      state = value;
    }
  }

  Future<void> toggle() async {
    state = !state;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_collectionListSortDescKey, state);
  }

  Future<void> setDescending({required bool descending}) async {
    state = descending;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_collectionListSortDescKey, descending);
  }
}

/// true = grid, false = list.
final NotifierProvider<CollectionListViewModeNotifier, bool>
    collectionListViewModeProvider =
    NotifierProvider<CollectionListViewModeNotifier, bool>(
  CollectionListViewModeNotifier.new,
);

class CollectionListViewModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    _loadFromPrefs();
    return true;
  }

  Future<void> _loadFromPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool? value = prefs.getBool(_collectionListGridViewKey);
    if (value != null) {
      state = value;
    }
  }

  Future<void> toggle() async {
    state = !state;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_collectionListGridViewKey, state);
  }
}

const String _homeStatusFilterKey = 'home_status_filter';

/// `null` means "All" (no filter); default `null`.
final NotifierProvider<HomeStatusFilterNotifier, ItemStatus?>
    homeStatusFilterProvider =
    NotifierProvider<HomeStatusFilterNotifier, ItemStatus?>(
  HomeStatusFilterNotifier.new,
);

/// Per-profile persistence: key `home_status_filter_{profileId}`.
class HomeStatusFilterNotifier extends Notifier<ItemStatus?> {
  String get _prefsKey {
    final String profileId = ref.read(currentProfileProvider).id;
    return '${_homeStatusFilterKey}_$profileId';
  }

  @override
  ItemStatus? build() {
    final SharedPreferences prefs = ref.watch(sharedPreferencesProvider);
    final String? value = prefs.getString(_prefsKey);
    if (value == null) return null;
    if (value == 'all') return null;
    return ItemStatus.fromString(value);
  }

  void setFilter(ItemStatus? status) {
    state = status;
    ref.read(sharedPreferencesProvider).setString(
      _prefsKey,
      status?.value ?? 'all',
    );
  }
}

/// Collection IDs containing items with the selected status.
final FutureProvider<Set<int?>> filteredCollectionIdsProvider =
    FutureProvider<Set<int?>>((Ref ref) async {
  final ItemStatus? status = ref.watch(homeStatusFilterProvider);
  if (status == null) return const <int?>{};

  // Watch collectionsProvider to recompute when underlying data changes.
  ref.watch(collectionsProvider);

  final CollectionDao dao = ref.read(collectionDaoProvider);
  return dao.getCollectionIdsWithStatus(status);
});

/// `collectionId == null` manages uncategorized items.
final NotifierProviderFamily<CollectionItemsNotifier,
        AsyncValue<List<CollectionItem>>, int?>
    collectionItemsNotifierProvider = NotifierProvider.family<
        CollectionItemsNotifier, AsyncValue<List<CollectionItem>>, int?>(
  CollectionItemsNotifier.new,
);

class CollectionItemsNotifier
    extends FamilyNotifier<AsyncValue<List<CollectionItem>>, int?> {
  late CollectionRepository _repository;
  late int? _collectionId;
  late CollectionSortMode _sortMode;
  late bool _isDescending;
  late DatabaseService _db;
  late GameRepository _gameRepository;

  @override
  AsyncValue<List<CollectionItem>> build(int? arg) {
    _collectionId = arg;
    _repository = ref.watch(collectionRepositoryProvider);
    _db = ref.watch(databaseServiceProvider);
    _gameRepository = ref.watch(gameRepositoryProvider);

    _sortMode = ref.watch(collectionSortProvider(_collectionId));
    _isDescending = ref.watch(collectionSortDescProvider(_collectionId));

    _loadItems(_sortMode, isDescending: _isDescending);

    return const AsyncLoading<List<CollectionItem>>();
  }

  Future<void> _loadItems(
    CollectionSortMode sortMode, {
    bool isDescending = false,
  }) async {
    state = const AsyncLoading<List<CollectionItem>>();
    state = await AsyncValue.guard(() async {
      List<CollectionItem> items =
          await _repository.getItemsWithData(_collectionId);

      // Lazy-load platforms for game items that have platformId but no platform object.
      final bool hasMissingPlatforms = items.any(
        (CollectionItem item) =>
            item.mediaType == MediaType.game &&
            item.platformId != null &&
            item.platform == null,
      );
      if (hasMissingPlatforms) {
        final List<Game> gamesWithPlatforms = items
            .where(
              (CollectionItem item) =>
                  item.mediaType == MediaType.game && item.game != null,
            )
            .map((CollectionItem item) => item.game!)
            .toList();
        if (gamesWithPlatforms.isNotEmpty) {
          await _gameRepository
              .ensurePlatformsCached(gamesWithPlatforms);
          items = await _repository.getItemsWithData(_collectionId);
        }
      }

      return _applySortMode(items, sortMode, isDescending: isDescending);
    });
  }

  List<CollectionItem> _applySortMode(
    List<CollectionItem> items,
    CollectionSortMode sortMode, {
    bool isDescending = false,
  }) {
    return applySortMode(items, sortMode, isDescending: isDescending);
  }

  /// Optimistic in-state update; avoids full reload.
  void updateItemDates(
    int itemId, {
    DateTime? startedAt,
    DateTime? lastActivityAt,
    DateTime? completedAt,
    ItemStatus? status,
  }) {
    final List<CollectionItem>? items = state.valueOrNull;
    if (items == null) return;

    state = AsyncData<List<CollectionItem>>(
      items.map((CollectionItem item) {
        if (item.id == itemId) {
          return item.copyWith(
            startedAt: startedAt,
            lastActivityAt: lastActivityAt,
            completedAt: completedAt,
            status: status ?? item.status,
          );
        }
        return item;
      }).toList(),
    );
  }

  void updateItemTag(int itemId, int? tagId) {
    final List<CollectionItem>? items = state.valueOrNull;
    if (items == null) return;

    state = AsyncData<List<CollectionItem>>(
      items.map((CollectionItem item) {
        if (item.id == itemId) {
          return item.copyWith(tagId: tagId, clearTagId: tagId == null);
        }
        return item;
      }).toList(),
    );
  }

  Future<void> refresh() async {
    await _loadItems(_sortMode, isDescending: _isDescending);
    ref.invalidate(collectionStatsProvider(_collectionId));
    ref.invalidate(collectionCoversProvider(_collectionId));
  }

  /// Optimistic UI update + batch sort_order persistence.
  Future<void> reorderItem(int oldIndex, int newIndex) async {
    final List<CollectionItem>? items = state.valueOrNull;
    if (items == null) return;

    final List<CollectionItem> reordered = List<CollectionItem>.of(items);
    final CollectionItem moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);

    final List<CollectionItem> updated = <CollectionItem>[];
    for (int i = 0; i < reordered.length; i++) {
      updated.add(reordered[i].copyWith(sortOrder: i));
    }
    state = AsyncData<List<CollectionItem>>(updated);

    final List<int> orderedIds =
        updated.map((CollectionItem item) => item.id).toList();
    await _db.reorderItems(_collectionId, orderedIds);
  }

  /// Only meaningful with manual sort; other modes will re-sort anyway.
  Future<void> moveItemToTop(int itemId) async {
    final List<CollectionItem>? items = state.valueOrNull;
    if (items == null) return;
    final int idx =
        items.indexWhere((CollectionItem i) => i.id == itemId);
    if (idx <= 0) return;
    await reorderItem(idx, 0);
  }

  Future<void> moveItemToBottom(int itemId) async {
    final List<CollectionItem>? items = state.valueOrNull;
    if (items == null) return;
    final int idx =
        items.indexWhere((CollectionItem i) => i.id == itemId);
    if (idx < 0 || idx == items.length - 1) return;
    await reorderItem(idx, items.length - 1);
  }

  /// Returns false if the item is already in the collection.
  Future<bool> addItem({
    required MediaType mediaType,
    required int externalId,
    int? platformId,
    String? authorComment,
  }) async {
    final int? id = await _repository.addItem(
      collectionId: _collectionId,
      mediaType: mediaType,
      externalId: externalId,
      platformId: platformId,
      authorComment: authorComment,
    );

    if (id == null) return false;

    await refresh();
    _invalidateCollectedIds(mediaType);
    ref.invalidate(uncategorizedItemCountProvider);
    ref.invalidate(allItemsNotifierProvider);
    return true;
  }

  /// When [localCoverPath] != null, copies the file into image cache.
  Future<bool> addCustomItem(
    CustomMedia customMedia, {
    String? localCoverPath,
  }) async {
    try {
      final int customId = await _db.customMediaDao.create(customMedia);
      final ImageCacheService cache = ref.read(imageCacheServiceProvider);

      if (localCoverPath != null) {
        final File sourceFile = File(localCoverPath);
        if (sourceFile.existsSync()) {
          final Uint8List bytes = await sourceFile.readAsBytes();
          final bool saved = await cache.saveImageBytes(
            ImageType.customCover,
            customId.toString(),
            bytes,
          );
          // Marker in cover_url: CachedImage sees non-empty imageUrl and
          // resolves from cache without hitting the network.
          if (saved) {
            await _db.customMediaDao.update(
              customMedia.copyWith(id: customId, coverUrl: CustomMedia.localCoverMarker),
            );
          }
        }
      } else if (customMedia.coverUrl != null &&
          customMedia.coverUrl!.isNotEmpty) {
        await cache.downloadImage(
          type: ImageType.customCover,
          imageId: customId.toString(),
          remoteUrl: customMedia.coverUrl!,
        );
      }

      final int? itemId = await _repository.addItem(
        collectionId: _collectionId,
        mediaType: MediaType.custom,
        externalId: customId,
      );

      if (itemId == null) return false;

      await refresh();
      ref.invalidate(uncategorizedItemCountProvider);
      ref.invalidate(allItemsNotifierProvider);
      return true;
    } catch (e, stack) {
      debugPrint('addCustomItem error: $e\n$stack'); // TODO: remove after stabilization
      return false;
    }
  }

  /// Returns false if the item is already in the target collection.
  Future<bool> cloneItem(
    int itemId, {
    required int targetCollectionId,
    required MediaType mediaType,
    int? sourceTagId,
  }) async {
    final int? newId = await _repository.cloneItemToCollection(
      itemId,
      targetCollectionId,
    );
    if (newId == null) return false;

    final int? resolvedTagId = await _resolveTargetTagId(
      sourceTagId: sourceTagId,
      targetCollectionId: targetCollectionId,
    );
    if (resolvedTagId != null) {
      await ref.read(tagDaoProvider).setItemTag(newId, resolvedTagId);
    }
    final bool tagAssigned = resolvedTagId != null;

    ref.invalidate(collectionItemsNotifierProvider(targetCollectionId));
    ref.invalidate(collectionStatsProvider(targetCollectionId));
    ref.invalidate(collectionCoversProvider(targetCollectionId));
    if (tagAssigned) {
      ref.invalidate(collectionTagsProvider(targetCollectionId));
    }
    _invalidateCollectedIds(mediaType);
    ref.invalidate(uncategorizedItemCountProvider);
    ref.invalidate(allItemsNotifierProvider);
    return true;
  }

  /// Finds or creates a tag in the target collection by case-insensitive name.
  /// Returns null if linking is not possible.
  Future<int?> _resolveTargetTagId({
    required int? sourceTagId,
    required int? targetCollectionId,
  }) async {
    if (sourceTagId == null || targetCollectionId == null) return null;
    final TagDao tagDao = ref.read(tagDaoProvider);
    final CollectionTag? sourceTag = await tagDao.getTagById(sourceTagId);
    if (sourceTag == null) return null;
    return tagDao.resolveOrCreateInCollection(
      targetCollectionId,
      sourceTag.name,
      color: sourceTag.color,
    );
  }

  /// Returns `(success: false, sourceEmpty: false)` if target already has the item.
  Future<({bool success, bool sourceEmpty})> moveItem(
    int itemId, {
    required int? targetCollectionId,
    required MediaType mediaType,
    int? sourceTagId,
  }) async {
    // Remove from tier-lists of source collection before the move.
    final TierListDao tierDao = ref.read(tierListDaoProvider);
    final List<int> affectedTierListIds =
        await tierDao.getTierListIdsForItem(itemId);
    if (_collectionId != null) {
      await tierDao.removeItemFromCollectionTierLists(
        itemId,
        _collectionId!,
      );
    }

    // Resolve target tag_id up front (case-insensitive name match).
    final int? resolvedTagId = await _resolveTargetTagId(
      sourceTagId: sourceTagId,
      targetCollectionId: targetCollectionId,
    );

    final bool success = await _repository.moveItemToCollection(
      itemId,
      targetCollectionId,
    );
    if (!success) return (success: false, sourceEmpty: false);

    // Single UPDATE: rebind to target tag or null out (old tag_id refers
    // to a tag belonging to the source collection).
    if (sourceTagId != null) {
      await ref.read(tagDaoProvider).setItemTag(itemId, resolvedTagId);
    }
    final bool tagAssigned = resolvedTagId != null;

    await refresh();

    final bool sourceEmpty = _collectionId != null &&
        (state.valueOrNull?.isEmpty ?? false);

    ref.invalidate(collectionItemsNotifierProvider(targetCollectionId));
    ref.invalidate(collectionStatsProvider(targetCollectionId));
    ref.invalidate(collectionCoversProvider(targetCollectionId));
    ref.invalidate(collectionStatsProvider(_collectionId));
    ref.invalidate(collectionCoversProvider(_collectionId));
    if (tagAssigned && targetCollectionId != null) {
      ref.invalidate(collectionTagsProvider(targetCollectionId));
    }
    ref.invalidate(uncategorizedItemCountProvider);
    _invalidateCollectedIds(mediaType);
    ref.invalidate(allItemsNotifierProvider);

    for (final int tierListId in affectedTierListIds) {
      ref.invalidate(tierListDetailProvider(tierListId));
    }

    return (success: true, sourceEmpty: sourceEmpty);
  }

  Future<void> removeItem(int id, {MediaType? mediaType}) async {
    // Capture tier-lists before delete: CASCADE wipes entries from DB.
    final TierListDao tierDao = ref.read(tierListDaoProvider);
    final List<int> affectedTierListIds =
        await tierDao.getTierListIdsForItem(id);

    await _repository.removeItem(id);
    await refresh();
    if (mediaType != null) {
      _invalidateCollectedIds(mediaType);
    }
    ref.invalidate(uncategorizedItemCountProvider);
    ref.invalidate(allItemsNotifierProvider);

    for (final int tierListId in affectedTierListIds) {
      ref.invalidate(tierListDetailProvider(tierListId));
    }
  }

  void _invalidateCollectedIds(MediaType mediaType) {
    switch (mediaType) {
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
        break; // Custom items have no collected-IDs provider.
    }
  }

  /// Date logic lives in [computeDatesForStatus] — shared with external sync
  /// (e.g. Kodi) that passes a custom `now`.
  Future<void> updateStatus(int id, ItemStatus status, MediaType mediaType) async {
    await _repository.updateItemStatus(id, status, mediaType: mediaType);

    final List<CollectionItem>? items = state.valueOrNull;
    if (items != null) {
      final DateTime now = DateTime.now();
      state = AsyncData<List<CollectionItem>>(
        items
            .map((CollectionItem i) =>
                i.id == id ? i.withStatus(status, now: now) : i)
            .toList(),
      );
    }

    ref.invalidate(collectionStatsProvider(_collectionId));
    ref
        .read(allItemsNotifierProvider.notifier)
        .updateStatusLocally(id, status);
  }

  // Bulk ops needing single-collection context (sort_order). Collection-agnostic
  // bulk ops (remove/move/clone/status) live in `BulkOperations`
  // (`helpers/bulk_operations.dart`) and are reused on All Items.

  /// Preserves relative order. Only meaningful with `sortMode == manual`.
  Future<void> moveItemsToTop(Iterable<int> ids) async {
    await _moveItemsToEdge(ids, toTop: true);
  }

  Future<void> moveItemsToBottom(Iterable<int> ids) async {
    await _moveItemsToEdge(ids, toTop: false);
  }

  Future<void> _moveItemsToEdge(
    Iterable<int> ids, {
    required bool toTop,
  }) async {
    final Set<int> idSet = ids.toSet();
    if (idSet.isEmpty) return;
    final List<CollectionItem>? items = state.valueOrNull;
    if (items == null || items.isEmpty) return;

    final List<CollectionItem> selected = <CollectionItem>[];
    final List<CollectionItem> rest = <CollectionItem>[];
    for (final CollectionItem i in items) {
      if (idSet.contains(i.id)) {
        selected.add(i);
      } else {
        rest.add(i);
      }
    }
    if (selected.isEmpty) return;

    final List<CollectionItem> reordered = toTop
        ? <CollectionItem>[...selected, ...rest]
        : <CollectionItem>[...rest, ...selected];

    bool changed = false;
    for (int i = 0; i < items.length; i++) {
      if (items[i].id != reordered[i].id) {
        changed = true;
        break;
      }
    }
    if (!changed) return;

    final List<CollectionItem> withSortOrder = <CollectionItem>[
      for (int i = 0; i < reordered.length; i++)
        reordered[i].copyWith(sortOrder: i),
    ];
    state = AsyncData<List<CollectionItem>>(withSortOrder);

    final List<int> orderedIds =
        withSortOrder.map((CollectionItem i) => i.id).toList();
    await _db.reorderItems(_collectionId, orderedIds);
  }

  /// Auto-syncs status:
  /// - setting [completedAt] forces `completed` from any state;
  /// - setting [startedAt] promotes `notStarted`/`planned` to `inProgress`
  ///   (others unchanged).
  Future<void> updateActivityDates(
    int id, {
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? lastActivityAt,
  }) async {
    await _repository.updateItemActivityDates(
      id,
      startedAt: startedAt,
      completedAt: completedAt,
      lastActivityAt: lastActivityAt,
    );

    final List<CollectionItem>? items = state.valueOrNull;
    if (items != null) {
      ItemStatus? newStatus;
      MediaType? mediaType;

      if (completedAt != null || startedAt != null) {
        final CollectionItem? target =
            items.where((CollectionItem i) => i.id == id).firstOrNull;
        if (target != null) {
          mediaType = target.mediaType;
          newStatus = computeStatusForDates(
            currentStatus: target.status,
            newCompletedAt: completedAt,
            newStartedAt: startedAt,
          );
        }
      }

      if (newStatus != null && mediaType != null) {
        await _repository.updateItemStatus(id, newStatus, mediaType: mediaType);
      }

      state = AsyncData<List<CollectionItem>>(
        items.map((CollectionItem i) {
          if (i.id == id) {
            return i.copyWith(
              startedAt: startedAt ?? i.startedAt,
              completedAt: completedAt ?? i.completedAt,
              lastActivityAt: lastActivityAt ?? i.lastActivityAt,
              status: newStatus ?? i.status,
            );
          }
          return i;
        }).toList(),
      );

      if (newStatus != null) {
        ref.invalidate(collectionStatsProvider(_collectionId));
        ref.invalidate(collectionCoversProvider(_collectionId));
        ref.invalidate(allItemsNotifierProvider);
      }
    }
  }

  /// For manga, auto-syncs status: notStarted/planned -> inProgress on first
  /// chapter; -> completed at final chapter; -> notStarted when reset to 0;
  /// `dropped` is never overwritten.
  Future<void> updateProgress(
    int id, {
    int? currentSeason,
    int? currentEpisode,
  }) async {
    await _repository.updateItemProgress(
      id,
      currentSeason: currentSeason,
      currentEpisode: currentEpisode,
    );

    final List<CollectionItem>? items = state.valueOrNull;
    if (items != null) {
      state = AsyncData<List<CollectionItem>>(
        items.map((CollectionItem i) {
          if (i.id == id) {
            return i.copyWith(
              currentSeason: currentSeason ?? i.currentSeason,
              currentEpisode: currentEpisode ?? i.currentEpisode,
            );
          }
          return i;
        }).toList(),
      );

      await _autoUpdateMangaStatus(id, currentEpisode, currentSeason);
      await _autoUpdateAnimeStatus(id, currentEpisode);
    }
  }

  Future<void> _autoUpdateMangaStatus(
    int id,
    int? newChapterValue,
    int? newVolumeValue,
  ) async {
    final CollectionItem? item =
        state.valueOrNull?.where((CollectionItem i) => i.id == id).firstOrNull;
    if (item == null || item.mediaType != MediaType.manga) return;

    final int newChapter = newChapterValue ?? item.currentEpisode;
    final int newVolume = newVolumeValue ?? item.currentSeason;
    final int? totalChapters = item.manga?.chapters;

    final ItemStatus? targetStatus = computeStatusFromProgress(
      currentStatus: item.status,
      hasAnyProgress: newChapter > 0 || newVolume > 0,
      isFullyCompleted:
          totalChapters != null && newChapter >= totalChapters,
    );

    if (targetStatus != null) {
      await updateStatus(id, targetStatus, MediaType.manga);
    }
  }

  Future<void> _autoUpdateAnimeStatus(
    int id,
    int? newEpisodeValue,
  ) async {
    final CollectionItem? item =
        state.valueOrNull?.where((CollectionItem i) => i.id == id).firstOrNull;
    if (item == null || item.mediaType != MediaType.anime) return;

    final int newEpisode = newEpisodeValue ?? item.currentEpisode;
    final int? totalEpisodes = item.anime?.episodes;

    final ItemStatus? targetStatus = computeStatusFromProgress(
      currentStatus: item.status,
      hasAnyProgress: newEpisode > 0,
      isFullyCompleted:
          totalEpisodes != null && newEpisode >= totalEpisodes,
    );

    if (targetStatus != null) {
      await updateStatus(id, targetStatus, MediaType.anime);
    }
  }

  Future<void> updateAuthorComment(int id, String? comment) async {
    await _repository.updateItemAuthorComment(id, comment);

    final List<CollectionItem>? items = state.valueOrNull;
    if (items != null) {
      state = AsyncData<List<CollectionItem>>(
        items.map((CollectionItem i) {
          if (i.id == id) {
            return comment == null
                ? i.copyWith(clearAuthorComment: true)
                : i.copyWith(authorComment: comment);
          }
          return i;
        }).toList(),
      );
    }
  }

  Future<void> updateUserComment(int id, String? comment) async {
    await _repository.updateItemUserComment(id, comment);

    final List<CollectionItem>? items = state.valueOrNull;
    if (items != null) {
      state = AsyncData<List<CollectionItem>>(
        items.map((CollectionItem i) {
          if (i.id == id) {
            return comment == null
                ? i.copyWith(clearUserComment: true)
                : i.copyWith(userComment: comment);
          }
          return i;
        }).toList(),
      );
    }
  }

  /// Empty / whitespace-only `name` clears the override.
  Future<void> setOverrideName(int id, String? name) async {
    final String? normalized =
        (name == null || name.trim().isEmpty) ? null : name.trim();
    await _repository.setItemOverrideName(id, normalized);

    final List<CollectionItem>? items = state.valueOrNull;
    if (items != null) {
      state = AsyncData<List<CollectionItem>>(
        items.map((CollectionItem i) {
          if (i.id == id) {
            return normalized == null
                ? i.copyWith(clearOverrideName: true)
                : i.copyWith(overrideName: normalized);
          }
          return i;
        }).toList(),
      );
    }
    ref.invalidate(allItemsNotifierProvider);
  }

  /// [rating] is 1-10, or null to clear.
  Future<void> updateUserRating(int id, int? rating) async {
    assert(
      rating == null || (rating >= 1 && rating <= 10),
      'Rating must be 1-10 or null, got $rating',
    );
    await _repository.updateItemUserRating(id, rating);

    final List<CollectionItem>? items = state.valueOrNull;
    if (items != null) {
      state = AsyncData<List<CollectionItem>>(
        items.map((CollectionItem i) {
          if (i.id == id) {
            return rating == null
                ? i.copyWith(clearUserRating: true)
                : i.copyWith(userRating: rating);
          }
          return i;
        }).toList(),
      );
    }
    ref.invalidate(allItemsNotifierProvider);
  }

  Future<void> addTimeSpent(int id, int minutesToAdd) async {
    final List<CollectionItem>? items = state.valueOrNull;
    final CollectionItem? item =
        items?.cast<CollectionItem?>().firstWhere(
              (CollectionItem? i) => i?.id == id,
              orElse: () => null,
            );
    final int current = item?.timeSpentMinutes ?? 0;
    final int total = current + minutesToAdd;
    await _repository.updateItemTimeSpent(id, total);

    if (items != null) {
      state = AsyncData<List<CollectionItem>>(
        items.map((CollectionItem i) {
          if (i.id == id) {
            return i.copyWith(timeSpentMinutes: total);
          }
          return i;
        }).toList(),
      );
    }
    ref.invalidate(allItemsNotifierProvider);
  }

  Future<void> setTimeSpent(int id, int totalMinutes) async {
    await _repository.updateItemTimeSpent(id, totalMinutes);

    final List<CollectionItem>? items = state.valueOrNull;
    if (items != null) {
      state = AsyncData<List<CollectionItem>>(
        items.map((CollectionItem i) {
          if (i.id == id) {
            return i.copyWith(timeSpentMinutes: totalMinutes);
          }
          return i;
        }).toList(),
      );
    }
    ref.invalidate(allItemsNotifierProvider);
  }
}

/// igdb_id -> collection entries.
final FutureProvider<Map<int, List<CollectedItemInfo>>>
    collectedGameIdsProvider =
    FutureProvider<Map<int, List<CollectedItemInfo>>>((Ref ref) async {
  final DatabaseService db = ref.watch(databaseServiceProvider);
  return db.getCollectedItemInfos(MediaType.game);
});

/// tmdb_id -> collection entries.
final FutureProvider<Map<int, List<CollectedItemInfo>>>
    collectedMovieIdsProvider =
    FutureProvider<Map<int, List<CollectedItemInfo>>>((Ref ref) async {
  final DatabaseService db = ref.watch(databaseServiceProvider);
  return db.getCollectedItemInfos(MediaType.movie);
});

/// tmdb_id -> collection entries.
final FutureProvider<Map<int, List<CollectedItemInfo>>>
    collectedTvShowIdsProvider =
    FutureProvider<Map<int, List<CollectedItemInfo>>>((Ref ref) async {
  final DatabaseService db = ref.watch(databaseServiceProvider);
  return db.getCollectedItemInfos(MediaType.tvShow);
});

/// tmdb_id -> collection entries.
final FutureProvider<Map<int, List<CollectedItemInfo>>>
    collectedAnimationIdsProvider =
    FutureProvider<Map<int, List<CollectedItemInfo>>>((Ref ref) async {
  final DatabaseService db = ref.watch(databaseServiceProvider);
  return db.getCollectedItemInfos(MediaType.animation);
});

/// numeric_id -> collection entries.
final FutureProvider<Map<int, List<CollectedItemInfo>>>
    collectedVisualNovelIdsProvider =
    FutureProvider<Map<int, List<CollectedItemInfo>>>((Ref ref) async {
  final DatabaseService db = ref.watch(databaseServiceProvider);
  return db.getCollectedItemInfos(MediaType.visualNovel);
});

/// numeric_id -> collection entries.
final FutureProvider<Map<int, List<CollectedItemInfo>>>
    collectedMangaIdsProvider =
    FutureProvider<Map<int, List<CollectedItemInfo>>>((Ref ref) async {
  final DatabaseService db = ref.watch(databaseServiceProvider);
  return db.getCollectedItemInfos(MediaType.manga);
});

/// anilist_id -> collection entries.
final FutureProvider<Map<int, List<CollectedItemInfo>>>
    collectedAnimeIdsProvider =
    FutureProvider<Map<int, List<CollectedItemInfo>>>((Ref ref) async {
  final DatabaseService db = ref.watch(databaseServiceProvider);
  return db.getCollectedItemInfos(MediaType.anime);
});

final FutureProvider<int> uncategorizedItemCountProvider =
    FutureProvider<int>((Ref ref) async {
  final CollectionRepository repository =
      ref.watch(collectionRepositoryProvider);
  return repository.getUncategorizedCount();
});

final Provider<List<Collection>> ownCollectionsProvider =
    Provider<List<Collection>>((Ref ref) {
  final AsyncValue<List<Collection>> allCollections =
      ref.watch(collectionsProvider);
  return allCollections.valueOrNull
          ?.where((Collection c) => c.type == CollectionType.own)
          .toList() ??
      <Collection>[];
});

