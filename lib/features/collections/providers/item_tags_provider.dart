import 'package:core/database/dao/global_tag_dao.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_service.dart';

/// Item → tag ids in display order (the DAO bakes it in). The junction is
/// small, so the full in-memory map spares per-item queries.
final AsyncNotifierProvider<ItemTagsNotifier, Map<int, List<int>>>
    itemTagsProvider =
    AsyncNotifierProvider<ItemTagsNotifier, Map<int, List<int>>>(
  ItemTagsNotifier.new,
);

/// Tag id → how many items carry it, derived from [itemTagsProvider].
final Provider<Map<int, int>> tagUsageCountsProvider =
    Provider<Map<int, int>>((Ref ref) {
  final Map<int, List<int>> itemTags =
      ref.watch(itemTagsProvider).valueOrNull ?? <int, List<int>>{};
  final Map<int, int> usage = <int, int>{};
  for (final List<int> ids in itemTags.values) {
    for (final int id in ids) {
      usage[id] = (usage[id] ?? 0) + 1;
    }
  }
  return usage;
});

class ItemTagsNotifier extends AsyncNotifier<Map<int, List<int>>> {
  @override
  Future<Map<int, List<int>>> build() async {
    final GlobalTagDao dao = ref.watch(globalTagDaoProvider);
    return dao.getAllItemTags();
  }

  /// Replaces the item's tag set; the list is re-read from the DAO — only it
  /// knows whether the item has manual positions or the global fallback.
  Future<void> setItemTags(int itemId, Set<int> tagIds) async {
    final GlobalTagDao dao = ref.read(globalTagDaoProvider);
    await dao.setItemTags(itemId, tagIds);
    final Map<int, List<int>> next = _copy();
    if (tagIds.isEmpty) {
      next.remove(itemId);
    } else {
      next[itemId] = await dao.getTagIdsByItem(itemId);
    }
    state = AsyncData<Map<int, List<int>>>(next);
  }

  /// Returns how many links were actually created — items already carrying
  /// a tag are not counted.
  Future<int> addTagsToItems(Iterable<int> itemIds, Set<int> tagIds) async {
    final List<int> targets = itemIds.toList(growable: false);
    if (targets.isEmpty || tagIds.isEmpty) return 0;
    final GlobalTagDao dao = ref.read(globalTagDaoProvider);
    await dao.addTagsToItems(targets, tagIds);
    return _syncItems(dao, targets);
  }

  /// Removes [tagIds] from every item in [itemIds]. Returns how many links
  /// were actually dropped.
  Future<int> removeTagsFromItems(
    Iterable<int> itemIds,
    Set<int> tagIds,
  ) async {
    final List<int> targets = itemIds.toList(growable: false);
    if (targets.isEmpty || tagIds.isEmpty) return 0;
    final GlobalTagDao dao = ref.read(globalTagDaoProvider);
    await dao.removeTagsFromItems(targets, tagIds);
    return _syncItems(dao, targets);
  }

  /// Reads back rather than guessing so the in-memory order stays identical
  /// to the DAO's, which mixes manual positions with the global fallback.
  Future<int> _syncItems(GlobalTagDao dao, List<int> itemIds) async {
    final Map<int, List<int>> fresh = await dao.getTagIdsForItems(itemIds);
    final Map<int, List<int>> next = _copy();
    int changed = 0;
    for (final int itemId in itemIds) {
      final int before = next[itemId]?.length ?? 0;
      final List<int>? after = fresh[itemId];
      if (after == null || after.isEmpty) {
        next.remove(itemId);
        changed += before;
      } else {
        next[itemId] = after;
        changed += (after.length - before).abs();
      }
    }
    state = AsyncData<Map<int, List<int>>>(next);
    return changed;
  }

  /// Persists a manual per-item reorder of the item's tags.
  Future<void> reorderItemTags(int itemId, List<int> orderedTagIds) async {
    final GlobalTagDao dao = ref.read(globalTagDaoProvider);
    await dao.setItemTagPositions(itemId, orderedTagIds);
    final Map<int, List<int>> next = _copy();
    next[itemId] = List<int>.of(orderedTagIds);
    state = AsyncData<Map<int, List<int>>>(next);
  }

  /// Reloads from the DB without an intermediate loading state — used after
  /// a global tag reorder shifts the fallback order of unpositioned links.
  Future<void> refreshFromDb() async {
    final GlobalTagDao dao = ref.read(globalTagDaoProvider);
    state = AsyncData<Map<int, List<int>>>(await dao.getAllItemTags());
  }

  /// In-memory cleanup after a tag was deleted (DB rows are already gone).
  void dropTagEverywhere(int tagId) {
    final Map<int, List<int>> next = <int, List<int>>{};
    for (final MapEntry<int, List<int>> entry in _copy().entries) {
      final List<int> tags =
          entry.value.where((int id) => id != tagId).toList();
      if (tags.isNotEmpty) next[entry.key] = tags;
    }
    state = AsyncData<Map<int, List<int>>>(next);
  }

  Map<int, List<int>> _copy() {
    final Map<int, List<int>> current =
        state.valueOrNull ?? <int, List<int>>{};
    return <int, List<int>>{
      for (final MapEntry<int, List<int>> e in current.entries)
        e.key: List<int>.of(e.value),
    };
  }
}
