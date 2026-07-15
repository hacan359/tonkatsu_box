import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/dao/global_tag_dao.dart';
import '../../../core/database/database_service.dart';
import '../../../shared/models/tag.dart';
import 'item_tags_provider.dart';

/// All global tags in display order (manual sort_order, then name).
final AsyncNotifierProvider<GlobalTagsNotifier, List<Tag>> globalTagsProvider =
    AsyncNotifierProvider<GlobalTagsNotifier, List<Tag>>(
  GlobalTagsNotifier.new,
);

class GlobalTagsNotifier extends AsyncNotifier<List<Tag>> {
  @override
  Future<List<Tag>> build() async {
    final GlobalTagDao dao = ref.watch(globalTagDaoProvider);
    return dao.getAll();
  }

  Future<Tag> create(String name, {int? color, int? textColor}) async {
    final GlobalTagDao dao = ref.read(globalTagDaoProvider);
    final Tag tag = await dao.create(name, color: color, textColor: textColor);
    final List<Tag> current = state.valueOrNull ?? <Tag>[];
    state = AsyncData<List<Tag>>(<Tag>[...current, tag]);
    return tag;
  }

  /// Finds a tag by name (case-insensitive) or creates it.
  Future<int> resolveOrCreate(String name, {int? color, int? textColor}) async {
    final List<Tag> current = state.valueOrNull ?? await future;
    final Tag? existing = Tag.findByNameCaseInsensitive(current, name);
    if (existing != null) return existing.id;
    final Tag created = await create(name, color: color, textColor: textColor);
    return created.id;
  }

  Future<void> rename(int tagId, String name) async {
    final GlobalTagDao dao = ref.read(globalTagDaoProvider);
    await dao.rename(tagId, name);
    _patch(tagId, (Tag t) => t.copyWith(name: name));
  }

  Future<void> updateColor(int tagId, int? color) async {
    final GlobalTagDao dao = ref.read(globalTagDaoProvider);
    await dao.updateColor(tagId, color);
    _patch(tagId, (Tag t) => t.copyWith(color: color, clearColor: color == null));
  }

  Future<void> updateTextColor(int tagId, int? textColor) async {
    final GlobalTagDao dao = ref.read(globalTagDaoProvider);
    await dao.updateTextColor(tagId, textColor);
    _patch(
      tagId,
      (Tag t) =>
          t.copyWith(textColor: textColor, clearTextColor: textColor == null),
    );
  }

  /// Deletes the tag and drops it from every item's tag set.
  Future<void> delete(int tagId) async {
    final GlobalTagDao dao = ref.read(globalTagDaoProvider);
    await dao.delete(tagId);
    final List<Tag> current = state.valueOrNull ?? <Tag>[];
    state = AsyncData<List<Tag>>(
      current.where((Tag t) => t.id != tagId).toList(),
    );
    ref.read(itemTagsProvider.notifier).dropTagEverywhere(tagId);
  }

  /// Persists a manual reorder: [orderedIds] in their new display order.
  Future<void> reorder(List<int> orderedIds) async {
    final GlobalTagDao dao = ref.read(globalTagDaoProvider);
    await dao.setSortOrders(orderedIds);
    // Items without a manual per-item order follow the global sort, and
    // itemTagsProvider caches resolved per-item lists — refresh them.
    await ref.read(itemTagsProvider.notifier).refreshFromDb();
    final Map<int, Tag> byId = <int, Tag>{
      for (final Tag t in state.valueOrNull ?? <Tag>[]) t.id: t,
    };
    final List<Tag> reordered = <Tag>[];
    for (int i = 0; i < orderedIds.length; i++) {
      final Tag? tag = byId.remove(orderedIds[i]);
      if (tag != null) reordered.add(tag.copyWith(sortOrder: i));
    }
    reordered.addAll(byId.values);
    state = AsyncData<List<Tag>>(reordered);
  }

  Future<void> refresh() async {
    final GlobalTagDao dao = ref.read(globalTagDaoProvider);
    state = AsyncData<List<Tag>>(await dao.getAll());
  }

  void _patch(int tagId, Tag Function(Tag) update) {
    final List<Tag> current = state.valueOrNull ?? <Tag>[];
    state = AsyncData<List<Tag>>(
      current.map((Tag t) => t.id == tagId ? update(t) : t).toList(),
    );
  }
}
