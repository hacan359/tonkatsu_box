// Провайдеры для экрана All Items (Home tab).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/repositories/collection_repository.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/collection_sort_mode.dart';
import '../../collections/providers/collections_provider.dart';
import '../../collections/providers/sort_utils.dart';
import '../../settings/providers/settings_provider.dart';

// ==================== Sort Providers ====================

/// Ключ SharedPreferences для режима сортировки All Items.
const String _allItemsSortModeKey = 'all_items_sort_mode';

/// Ключ SharedPreferences для направления сортировки All Items.
const String _allItemsSortDescKey = 'all_items_sort_desc';

/// Провайдер режима сортировки для All Items.
final NotifierProvider<AllItemsSortNotifier, CollectionSortMode>
    allItemsSortProvider =
    NotifierProvider<AllItemsSortNotifier, CollectionSortMode>(
  AllItemsSortNotifier.new,
);

/// Notifier для режима сортировки All Items.
class AllItemsSortNotifier extends Notifier<CollectionSortMode> {
  @override
  CollectionSortMode build() {
    _loadFromPrefs();
    return CollectionSortMode.addedDate;
  }

  Future<void> _loadFromPrefs() async {
    // Defer чтобы state = не перезаписывался return в build().
    await Future<void>.value();
    final SharedPreferences prefs =
        ref.read(sharedPreferencesProvider);
    final String? value = prefs.getString(_allItemsSortModeKey);
    if (value != null) {
      state = CollectionSortMode.fromString(value);
    }
  }

  /// Устанавливает режим сортировки и сохраняет в SharedPreferences.
  Future<void> setSortMode(CollectionSortMode mode) async {
    state = mode;
    final SharedPreferences prefs =
        ref.read(sharedPreferencesProvider);
    await prefs.setString(_allItemsSortModeKey, mode.value);
  }
}

/// Провайдер направления сортировки для All Items.
final NotifierProvider<AllItemsSortDescNotifier, bool>
    allItemsSortDescProvider =
    NotifierProvider<AllItemsSortDescNotifier, bool>(
  AllItemsSortDescNotifier.new,
);

/// Notifier для направления сортировки (ascending/descending).
class AllItemsSortDescNotifier extends Notifier<bool> {
  @override
  bool build() {
    _loadFromPrefs();
    return false;
  }

  Future<void> _loadFromPrefs() async {
    // Defer чтобы state = не перезаписывался return в build().
    await Future<void>.value();
    final SharedPreferences prefs =
        ref.read(sharedPreferencesProvider);
    final bool? value = prefs.getBool(_allItemsSortDescKey);
    if (value != null) {
      state = value;
    }
  }

  /// Переключает направление сортировки.
  Future<void> toggle() async {
    state = !state;
    final SharedPreferences prefs =
        ref.read(sharedPreferencesProvider);
    await prefs.setBool(_allItemsSortDescKey, state);
  }
}

// ==================== All Items ====================

/// Провайдер для всех элементов из всех коллекций.
final NotifierProvider<AllItemsNotifier, AsyncValue<List<CollectionItem>>>
    allItemsNotifierProvider =
    NotifierProvider<AllItemsNotifier, AsyncValue<List<CollectionItem>>>(
  AllItemsNotifier.new,
);

/// Notifier для загрузки и сортировки всех элементов.
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
      // manual не имеет смысла для all items — используем addedDate
      final CollectionSortMode effectiveMode =
          sortMode == CollectionSortMode.manual
              ? CollectionSortMode.addedDate
              : sortMode;
      return applySortMode(items, effectiveMode, isDescending: isDescending);
    });
  }

  /// Перезагружает все элементы.
  Future<void> refresh() async {
    final CollectionSortMode sortMode = ref.read(allItemsSortProvider);
    final bool isDescending = ref.read(allItemsSortDescProvider);
    await _loadItems(sortMode, isDescending: isDescending);
  }
}

// ==================== Collection Names ====================

/// Карта collectionId → collectionName для отображения в UI.
final Provider<Map<int, String>> collectionNamesProvider =
    Provider<Map<int, String>>((Ref ref) {
  final List<Collection>? collections =
      ref.watch(collectionsProvider).valueOrNull;
  if (collections == null) return <int, String>{};
  return <int, String>{
    for (final Collection c in collections) c.id: c.name,
  };
});
