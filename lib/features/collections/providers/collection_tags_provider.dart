// Провайдеры для тегов коллекций.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/dao/tag_dao.dart';
import '../../../core/database/database_service.dart';
import '../../../shared/models/collection_tag.dart';

/// Провайдер списка тегов для конкретной коллекции.
final AsyncNotifierProviderFamily<CollectionTagsNotifier, List<CollectionTag>,
        int> collectionTagsProvider =
    AsyncNotifierProvider.family<CollectionTagsNotifier, List<CollectionTag>,
        int>(
  CollectionTagsNotifier.new,
);

/// Notifier для управления тегами коллекции.
class CollectionTagsNotifier
    extends FamilyAsyncNotifier<List<CollectionTag>, int> {
  @override
  Future<List<CollectionTag>> build(int arg) async {
    final TagDao dao = ref.watch(tagDaoProvider);
    return dao.getTagsByCollection(arg);
  }

  /// Создаёт новый тег.
  Future<CollectionTag> create(String name, {int? color}) async {
    final TagDao dao = ref.read(tagDaoProvider);
    final CollectionTag tag = await dao.createTag(arg, name, color: color);
    final List<CollectionTag> current = state.valueOrNull ?? <CollectionTag>[];
    state = AsyncData<List<CollectionTag>>(<CollectionTag>[...current, tag]);
    return tag;
  }

  /// Переименовывает тег.
  Future<void> rename(int tagId, String name) async {
    final TagDao dao = ref.read(tagDaoProvider);
    await dao.renameTag(tagId, name);
    final List<CollectionTag> current = state.valueOrNull ?? <CollectionTag>[];
    state = AsyncData<List<CollectionTag>>(
      current.map((CollectionTag t) {
        if (t.id == tagId) return t.copyWith(name: name);
        return t;
      }).toList(),
    );
  }

  /// Обновляет цвет тега.
  Future<void> updateColor(int tagId, int? color) async {
    final TagDao dao = ref.read(tagDaoProvider);
    await dao.updateTagColor(tagId, color);
    final List<CollectionTag> current = state.valueOrNull ?? <CollectionTag>[];
    state = AsyncData<List<CollectionTag>>(
      current.map((CollectionTag t) {
        if (t.id == tagId) return t.copyWith(color: color, clearColor: color == null);
        return t;
      }).toList(),
    );
  }

  /// Удаляет тег.
  Future<void> delete(int tagId) async {
    final TagDao dao = ref.read(tagDaoProvider);
    await dao.deleteTag(tagId);
    final List<CollectionTag> current = state.valueOrNull ?? <CollectionTag>[];
    state = AsyncData<List<CollectionTag>>(
      current.where((CollectionTag t) => t.id != tagId).toList(),
    );
  }

  /// Обновляет список тегов.
  Future<void> refresh() async {
    final TagDao dao = ref.read(tagDaoProvider);
    state = AsyncData<List<CollectionTag>>(
      await dao.getTagsByCollection(arg),
    );
  }
}
