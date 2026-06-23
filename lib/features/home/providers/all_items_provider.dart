// Providers for the All Items screen (Home tab).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/database/database_service.dart';
import '../../../core/database/dao/tag_dao.dart';
import '../../../data/repositories/collection_repository.dart';
import '../../../shared/models/collection_tag.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/collection_sort_mode.dart';
import '../../../shared/models/item_status.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/platform.dart';
import '../../collections/providers/collections_provider.dart';
import '../../collections/providers/sort_utils.dart';
import '../../settings/providers/settings_provider.dart';

// ==================== Sort Providers ====================

/// SharedPreferences key for the All Items sort mode.
const String _allItemsSortModeKey = 'all_items_sort_mode';

/// SharedPreferences key for the All Items sort direction.
const String _allItemsSortDescKey = 'all_items_sort_desc';

/// All Items sort mode provider.
final NotifierProvider<AllItemsSortNotifier, CollectionSortMode>
    allItemsSortProvider =
    NotifierProvider<AllItemsSortNotifier, CollectionSortMode>(
  AllItemsSortNotifier.new,
);

/// Notifier for the All Items sort mode.
class AllItemsSortNotifier extends Notifier<CollectionSortMode> {
  @override
  CollectionSortMode build() {
    _loadFromPrefs();
    return CollectionSortMode.addedDate;
  }

  Future<void> _loadFromPrefs() async {
    // Deferred so build()'s return value isn't overwritten by state =.
    await Future<void>.value();
    final SharedPreferences prefs =
        ref.read(sharedPreferencesProvider);
    final String? value = prefs.getString(_allItemsSortModeKey);
    if (value != null) {
      state = CollectionSortMode.fromString(value);
    }
  }

  /// Sets the sort mode and persists it to SharedPreferences.
  Future<void> setSortMode(CollectionSortMode mode) async {
    state = mode;
    final SharedPreferences prefs =
        ref.read(sharedPreferencesProvider);
    await prefs.setString(_allItemsSortModeKey, mode.value);
  }
}

/// All Items sort direction provider.
final NotifierProvider<AllItemsSortDescNotifier, bool>
    allItemsSortDescProvider =
    NotifierProvider<AllItemsSortDescNotifier, bool>(
  AllItemsSortDescNotifier.new,
);

/// Notifier for the sort direction (ascending/descending).
class AllItemsSortDescNotifier extends Notifier<bool> {
  @override
  bool build() {
    _loadFromPrefs();
    return false;
  }

  Future<void> _loadFromPrefs() async {
    // Deferred so build()'s return value isn't overwritten by state =.
    await Future<void>.value();
    final SharedPreferences prefs =
        ref.read(sharedPreferencesProvider);
    final bool? value = prefs.getBool(_allItemsSortDescKey);
    if (value != null) {
      state = value;
    }
  }

  /// Toggles the sort direction.
  Future<void> toggle() async {
    state = !state;
    final SharedPreferences prefs =
        ref.read(sharedPreferencesProvider);
    await prefs.setBool(_allItemsSortDescKey, state);
  }
}

// ==================== All Items ====================

/// Provider for all items across every collection.
final NotifierProvider<AllItemsNotifier, AsyncValue<List<CollectionItem>>>
    allItemsNotifierProvider =
    NotifierProvider<AllItemsNotifier, AsyncValue<List<CollectionItem>>>(
  AllItemsNotifier.new,
);

/// Notifier that loads and sorts all items.
class AllItemsNotifier extends Notifier<AsyncValue<List<CollectionItem>>> {
  late CollectionRepository _repository;

  @override
  AsyncValue<List<CollectionItem>> build() {
    _repository = ref.watch(collectionRepositoryProvider);

    final CollectionSortMode sortMode = ref.watch(allItemsSortProvider);
    final bool isDescending = ref.watch(allItemsSortDescProvider);

    _loadItems(sortMode, isDescending: isDescending);
    return const AsyncLoading<List<CollectionItem>>();
  }

  Future<void> _loadItems(
    CollectionSortMode sortMode, {
    bool isDescending = false,
  }) async {
    state = const AsyncLoading<List<CollectionItem>>();
    state = await AsyncValue.guard(() async {
      final List<CollectionItem> items =
          await _repository.getAllItemsWithData();
      // manual sort is meaningless for all items, fall back to addedDate
      final CollectionSortMode effectiveMode =
          sortMode == CollectionSortMode.manual
              ? CollectionSortMode.addedDate
              : sortMode;
      final String lang =
          ref.read(sharedPreferencesProvider).animeMangaTitleLanguage;
      return applySortMode(
        items,
        effectiveMode,
        isDescending: isDescending,
        animeMangaTitleLanguage: lang,
      );
    });
  }

  /// Reloads all items.
  Future<void> refresh() async {
    final CollectionSortMode sortMode = ref.read(allItemsSortProvider);
    final bool isDescending = ref.read(allItemsSortDescProvider);
    await _loadItems(sortMode, isDescending: isDescending);
  }

  /// Patches an item's status locally without re-querying the DB.
  ///
  /// Called from `CollectionItemsNotifier.updateStatus` to avoid invalidating
  /// the whole provider (which would flash the list through AsyncLoading).
  void updateStatusLocally(int id, ItemStatus status) {
    final List<CollectionItem>? items = state.valueOrNull;
    if (items == null) return;
    final DateTime now = DateTime.now();
    state = AsyncData<List<CollectionItem>>(
      items
          .map((CollectionItem i) =>
              i.id == id ? i.withStatus(status, now: now) : i)
          .toList(),
    );
  }

  /// Flips the favorite flag from the All Items screen: writes the DB, patches
  /// this (visible) list, and invalidates the item's per-collection notifier so
  /// it reloads from the DB when next shown. Invalidating (rather than patching
  /// that notifier) avoids a race where a freshly-built, still-loading
  /// collection notifier would overwrite the new flag with its pre-write
  /// snapshot — which left the item detail screen showing a stale state.
  Future<void> toggleFavorite(int id) async {
    final CollectionItem? target =
        state.valueOrNull?.where((CollectionItem i) => i.id == id).firstOrNull;
    if (target == null) return;
    final bool newValue = !target.isFavorite;
    await _repository.setItemFavorite(id, isFavorite: newValue);
    updateFavoriteLocally(id, isFavorite: newValue);
    ref.invalidate(collectionItemsNotifierProvider(target.collectionId));
  }

  /// Patches an item's favorite flag locally without re-querying the DB.
  void updateFavoriteLocally(int id, {required bool isFavorite}) {
    final List<CollectionItem>? items = state.valueOrNull;
    if (items == null) return;
    state = AsyncData<List<CollectionItem>>(
      items
          .map((CollectionItem i) =>
              i.id == id ? i.copyWith(isFavorite: isFavorite) : i)
          .toList(),
    );
  }
}

// ==================== Platform Filter ====================

/// Unique platforms from games in collections, for filtering.
///
/// Pulls platformId from every game item and loads the [Platform] models
/// from the DB. Sorted by name.
final FutureProvider<List<Platform>> allItemsPlatformsProvider =
    FutureProvider<List<Platform>>((Ref ref) async {
  final AsyncValue<List<CollectionItem>> itemsAsync =
      ref.watch(allItemsNotifierProvider);
  final List<CollectionItem>? items = itemsAsync.valueOrNull;
  if (items == null) return <Platform>[];

  final Set<int> uniqueIds = items
      .where((CollectionItem i) =>
          i.mediaType == MediaType.game &&
          i.platformId != null &&
          i.platformId != -1)
      .map((CollectionItem i) => i.platformId!)
      .toSet();

  if (uniqueIds.isEmpty) return <Platform>[];

  final DatabaseService db = ref.read(databaseServiceProvider);
  final List<Platform> platforms = <Platform>[];
  for (final int id in uniqueIds) {
    final Platform? p = await db.gameDao.getPlatformById(id);
    if (p != null) platforms.add(p);
  }
  platforms.sort(
    (Platform a, Platform b) => a.name.compareTo(b.name),
  );
  return platforms;
});

// ==================== Collection Names ====================

/// Map of collectionId -> collectionName for display in the UI.
final Provider<Map<int, String>> collectionNamesProvider =
    Provider<Map<int, String>>((Ref ref) {
  final List<Collection>? collections =
      ref.watch(collectionsProvider).valueOrNull;
  if (collections == null) return <int, String>{};
  return <int, String>{
    for (final Collection c in collections) c.id: c.name,
  };
});

// ==================== Tags ====================

/// Map of tagId -> CollectionTag for display and tag search on All Items.
final FutureProvider<Map<int, CollectionTag>> allTagsMapProvider =
    FutureProvider<Map<int, CollectionTag>>((Ref ref) async {
  final TagDao tagDao = ref.watch(tagDaoProvider);
  final List<CollectionTag> tags = await tagDao.getAll();
  return <int, CollectionTag>{
    for (final CollectionTag tag in tags) tag.id: tag,
  };
});
