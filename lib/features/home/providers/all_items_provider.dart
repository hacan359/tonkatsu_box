import 'package:core/models/collection.dart';
import 'package:core/models/collection_item.dart';
import 'package:core/models/collection_sort_mode.dart';
import 'package:core/models/item_status.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/platform.dart';
import 'package:core/models/tag.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/database/database_service.dart';
import '../../../data/repositories/collection_repository.dart';
import '../../collections/providers/collections_provider.dart';
import '../../collections/providers/global_tags_provider.dart';
import '../../collections/providers/sort_utils.dart';
import '../../settings/providers/settings_provider.dart';


const String _allItemsSortModeKey = 'all_items_sort_mode';

const String _allItemsSortDescKey = 'all_items_sort_desc';

final NotifierProvider<AllItemsSortNotifier, CollectionSortMode>
    allItemsSortProvider =
    NotifierProvider<AllItemsSortNotifier, CollectionSortMode>(
  AllItemsSortNotifier.new,
);

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

final NotifierProvider<AllItemsSortDescNotifier, bool>
    allItemsSortDescProvider =
    NotifierProvider<AllItemsSortDescNotifier, bool>(
  AllItemsSortDescNotifier.new,
);

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

  Future<void> toggle() async {
    state = !state;
    final SharedPreferences prefs =
        ref.read(sharedPreferencesProvider);
    await prefs.setBool(_allItemsSortDescKey, state);
  }
}


final NotifierProvider<AllItemsNotifier, AsyncValue<List<CollectionItem>>>
    allItemsNotifierProvider =
    NotifierProvider<AllItemsNotifier, AsyncValue<List<CollectionItem>>>(
  AllItemsNotifier.new,
);

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

  Future<void> refresh() async {
    final CollectionSortMode sortMode = ref.read(allItemsSortProvider);
    final bool isDescending = ref.read(allItemsSortDescProvider);
    await _loadItems(sortMode, isDescending: isDescending);
  }

  /// Patches status locally (from `CollectionItemsNotifier.updateStatus`) —
  /// invalidating the whole provider would flash the list through AsyncLoading.
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

  /// Writes the DB, patches this list, and *invalidates* the per-collection
  /// notifier: patching it raced with a still-loading pre-write snapshot.
  Future<void> toggleFavorite(int id) async {
    final CollectionItem? target =
        state.valueOrNull?.where((CollectionItem i) => i.id == id).firstOrNull;
    if (target == null) return;
    final bool newValue = !target.isFavorite;
    await _repository.setItemFavorite(id, isFavorite: newValue);
    updateFavoriteLocally(id, isFavorite: newValue);
    ref.invalidate(collectionItemsNotifierProvider(target.collectionId));
  }

  /// Patches progress locally (from `CollectionItemsNotifier.updateProgress`)
  /// so the pill on All Items cards stays in sync without a full reload.
  void updateProgressLocally(
    int id, {
    int? currentSeason,
    int? currentEpisode,
    DateTime? lastActivityAt,
  }) {
    final List<CollectionItem>? items = state.valueOrNull;
    if (items == null) return;
    state = AsyncData<List<CollectionItem>>(
      items
          .map((CollectionItem i) => i.id == id
              ? i.copyWith(
                  currentSeason: currentSeason ?? i.currentSeason,
                  currentEpisode: currentEpisode ?? i.currentEpisode,
                  lastActivityAt: lastActivityAt ?? i.lastActivityAt,
                )
              : i)
          .toList(),
    );
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


/// A `Set` compares by identity, so only a String key lets `select` swallow an
/// unrelated collection edit instead of churning every item list.
String _hiddenCollectionsKey(AsyncValue<List<Collection>> collections) {
  final List<int> ids = <int>[
    for (final Collection c in collections.valueOrNull ?? <Collection>[])
      if (c.isHidden) c.id,
  ]..sort();
  return ids.join(',');
}

/// Ids of collections the user flagged hidden.
final Provider<Set<int>> hiddenCollectionIdsProvider =
    Provider<Set<int>>((Ref ref) {
  final String key = ref.watch(
    collectionsProvider.select(_hiddenCollectionsKey),
  );
  if (key.isEmpty) return const <int>{};
  return <int>{for (final String id in key.split(',')) int.parse(id)};
});

/// Filtering above [AllItemsNotifier] keeps toggling off the database, and
/// leaves `CacheCleanupService` seeing every item — else it deletes the covers.
final Provider<AsyncValue<List<CollectionItem>>> visibleAllItemsProvider =
    Provider<AsyncValue<List<CollectionItem>>>((Ref ref) {
  final AsyncValue<List<CollectionItem>> all =
      ref.watch(allItemsNotifierProvider);
  final Set<int> hidden = ref.watch(hiddenCollectionIdsProvider);
  if (hidden.isEmpty) return all;
  return all.whenData(
    (List<CollectionItem> items) => items
        .where((CollectionItem i) =>
            i.collectionId == null || !hidden.contains(i.collectionId))
        .toList(),
  );
});


/// Unique platforms from game items, loaded from the DB and sorted by name,
/// for the All Items filter.
final FutureProvider<List<Platform>> allItemsPlatformsProvider =
    FutureProvider<List<Platform>>((Ref ref) async {
  final AsyncValue<List<CollectionItem>> itemsAsync =
      ref.watch(allItemsNotifierProvider);
  final List<CollectionItem>? items = itemsAsync.valueOrNull;
  if (items == null) return <Platform>[];

  final Set<int> uniqueIds = items
      .where((CollectionItem i) =>
          i.displayMediaType == MediaType.game &&
          i.effectivePlatformId != null &&
          i.effectivePlatformId != -1)
      .map((CollectionItem i) => i.effectivePlatformId!)
      .toSet();

  if (uniqueIds.isEmpty) return <Platform>[];

  final DatabaseService db = ref.read(databaseServiceProvider);
  final List<Platform> platforms =
      await db.gameDao.getPlatformsByIds(uniqueIds.toList());
  platforms.sort(
    (Platform a, Platform b) => a.name.compareTo(b.name),
  );
  return platforms;
});


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


/// Map of tagId -> Tag for display and tag search on All Items.
/// Derived from [globalTagsProvider] so the tags table is loaded once.
final Provider<Map<int, Tag>> allTagsMapProvider =
    Provider<Map<int, Tag>>((Ref ref) {
  final List<Tag> tags =
      ref.watch(globalTagsProvider).valueOrNull ?? <Tag>[];
  return <int, Tag>{
    for (final Tag tag in tags) tag.id: tag,
  };
});
