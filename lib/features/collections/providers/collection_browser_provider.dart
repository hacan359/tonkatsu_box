// Провайдеры для каталога онлайн-коллекций.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/collection_browser_service.dart';
import '../models/collections_index.dart';

/// Провайдер индекса коллекций (загружается при первом обращении).
final AsyncNotifierProvider<CollectionsIndexNotifier, CollectionsIndex>
    collectionsIndexProvider =
    AsyncNotifierProvider<CollectionsIndexNotifier, CollectionsIndex>(
  CollectionsIndexNotifier.new,
);

/// Нотифаер для загрузки и обновления индекса коллекций.
class CollectionsIndexNotifier extends AsyncNotifier<CollectionsIndex> {
  @override
  Future<CollectionsIndex> build() async {
    final CollectionBrowserService service =
        ref.watch(collectionBrowserServiceProvider);
    return service.fetchIndex();
  }

  /// Принудительно обновляет индекс с сервера.
  Future<void> refresh() async {
    final CollectionBrowserService service =
        ref.read(collectionBrowserServiceProvider);
    state = const AsyncLoading<CollectionsIndex>();
    state = await AsyncValue.guard(
      () => service.fetchIndex(forceRefresh: true),
    );
  }
}

/// Фильтр по платформе (null = все платформы).
final StateProvider<String?> browserPlatformFilterProvider =
    StateProvider<String?>((Ref ref) => null);

/// Фильтр по категории (null = все категории).
final StateProvider<String?> browserCategoryFilterProvider =
    StateProvider<String?>((Ref ref) => null);

/// Поисковый запрос.
final StateProvider<String> browserSearchQueryProvider =
    StateProvider<String>((Ref ref) => '');

/// Отфильтрованный список коллекций.
final Provider<List<RemoteCollection>> filteredRemoteCollectionsProvider =
    Provider<List<RemoteCollection>>((Ref ref) {
  final AsyncValue<CollectionsIndex> indexAsync =
      ref.watch(collectionsIndexProvider);
  final CollectionsIndex? index = indexAsync.valueOrNull;
  if (index == null) return const <RemoteCollection>[];

  final String? platformFilter = ref.watch(browserPlatformFilterProvider);
  final String? categoryFilter = ref.watch(browserCategoryFilterProvider);
  final String searchQuery =
      ref.watch(browserSearchQueryProvider).toLowerCase();

  List<RemoteCollection> result = index.collections;

  if (platformFilter != null) {
    result = result
        .where(
          (RemoteCollection c) =>
              c.platform == platformFilter ||
              c.mediaType == platformFilter,
        )
        .toList();
  }

  if (categoryFilter != null) {
    result = result
        .where((RemoteCollection c) => c.category == categoryFilter)
        .toList();
  }

  if (searchQuery.isNotEmpty) {
    result = result
        .where(
          (RemoteCollection c) =>
              c.name.toLowerCase().contains(searchQuery) ||
              c.description.toLowerCase().contains(searchQuery) ||
              (c.platformName?.toLowerCase().contains(searchQuery) ?? false),
        )
        .toList();
  }

  return result;
});
