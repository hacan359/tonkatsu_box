import 'package:core/database/dao/global_tag_dao.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_service.dart';

/// Item → global tag ids for the whole database, each list in the item's
/// display order (manual positions first, global-order fallback for the
/// rest — the DAO bakes that in).
///
/// The junction is small (one row per link), so keeping the full map in
/// memory lets filters, cards and the table resolve an item's tags
/// synchronously without per-item queries.
final AsyncNotifierProvider<ItemTagsNotifier, Map<int, List<int>>>
    itemTagsProvider =
    AsyncNotifierProvider<ItemTagsNotifier, Map<int, List<int>>>(
  ItemTagsNotifier.new,
);

class ItemTagsNotifier extends AsyncNotifier<Map<int, List<int>>> {
  @override
  Future<Map<int, List<int>>> build() async {
    final GlobalTagDao dao = ref.watch(globalTagDaoProvider);
    return dao.getAllItemTags();
  }

  /// Replaces the item's tag set; surviving links keep their manual order.
  ///
  /// The item's list is re-read from the DAO: only it knows whether the item
  /// has manual positions (new tags go last) or follows the global fallback.
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

  /// Adds [tagIds] to every item in [itemIds], leaving their other tags
  /// alone. Returns how many links were actually created — items that
  /// already carried a tag are not counted.
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

  /// Re-reads the tag lists of [itemIds] in one query and patches the map in
  /// a single state update. Reading back rather than guessing keeps the
  /// in-memory order identical to the DAO's, which mixes manual positions
  /// with the global-order fallback.
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
