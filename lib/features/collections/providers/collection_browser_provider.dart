import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/collection_browser_service.dart';
import '../models/collections_index.dart';

final AsyncNotifierProvider<CollectionsIndexNotifier, CollectionsIndex>
    collectionsIndexProvider =
    AsyncNotifierProvider<CollectionsIndexNotifier, CollectionsIndex>(
  CollectionsIndexNotifier.new,
);

class CollectionsIndexNotifier extends AsyncNotifier<CollectionsIndex> {
  @override
  Future<CollectionsIndex> build() async {
    final CollectionBrowserService service =
        ref.watch(collectionBrowserServiceProvider);
    return service.fetchIndex();
  }

  Future<void> refresh() async {
    final CollectionBrowserService service =
        ref.read(collectionBrowserServiceProvider);
    state = const AsyncLoading<CollectionsIndex>();
    state = await AsyncValue.guard(
      () => service.fetchIndex(forceRefresh: true),
    );
  }
}

/// null = all platforms.
final StateProvider<String?> browserPlatformFilterProvider =
    StateProvider<String?>((Ref ref) => null);

/// null = all categories.
final StateProvider<String?> browserCategoryFilterProvider =
    StateProvider<String?>((Ref ref) => null);

final StateProvider<String> browserSearchQueryProvider =
    StateProvider<String>((Ref ref) => '');

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
