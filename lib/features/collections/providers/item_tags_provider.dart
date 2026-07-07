import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/dao/global_tag_dao.dart';
import '../../../core/database/database_service.dart';

/// Item → global tag ids map for the whole database.
///
/// The junction is small (one row per link), so keeping the full map in
/// memory lets filters, cards and the table resolve an item's tags
/// synchronously without per-item queries.
final AsyncNotifierProvider<ItemTagsNotifier, Map<int, Set<int>>>
    itemTagsProvider =
    AsyncNotifierProvider<ItemTagsNotifier, Map<int, Set<int>>>(
  ItemTagsNotifier.new,
);

class ItemTagsNotifier extends AsyncNotifier<Map<int, Set<int>>> {
  @override
  Future<Map<int, Set<int>>> build() async {
    final GlobalTagDao dao = ref.watch(globalTagDaoProvider);
    return dao.getAllItemTags();
  }

  /// Replaces the item's tag set.
  Future<void> setItemTags(int itemId, Set<int> tagIds) async {
    final GlobalTagDao dao = ref.read(globalTagDaoProvider);
    await dao.setItemTags(itemId, tagIds);
    final Map<int, Set<int>> next = _copy();
    if (tagIds.isEmpty) {
      next.remove(itemId);
    } else {
      next[itemId] = Set<int>.of(tagIds);
    }
    state = AsyncData<Map<int, Set<int>>>(next);
  }

  /// In-memory cleanup after a tag was deleted (DB rows are already gone).
  void dropTagEverywhere(int tagId) {
    final Map<int, Set<int>> next = <int, Set<int>>{};
    for (final MapEntry<int, Set<int>> entry in _copy().entries) {
      final Set<int> tags = Set<int>.of(entry.value)..remove(tagId);
      if (tags.isNotEmpty) next[entry.key] = tags;
    }
    state = AsyncData<Map<int, Set<int>>>(next);
  }

  Map<int, Set<int>> _copy() {
    final Map<int, Set<int>> current =
        state.valueOrNull ?? <int, Set<int>>{};
    return <int, Set<int>>{
      for (final MapEntry<int, Set<int>> e in current.entries)
        e.key: Set<int>.of(e.value),
    };
  }
}
