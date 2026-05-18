import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/dao/wishlist_dao.dart';
import '../../../data/repositories/wishlist_repository.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/wishlist_item.dart';

/// Провайдер для списка элементов вишлиста.
final AsyncNotifierProvider<WishlistNotifier, List<WishlistItem>>
    wishlistProvider =
    AsyncNotifierProvider<WishlistNotifier, List<WishlistItem>>(
  WishlistNotifier.new,
);

/// Notifier для управления вишлистом.
class WishlistNotifier extends AsyncNotifier<List<WishlistItem>> {
  late WishlistRepository _repository;

  @override
  Future<List<WishlistItem>> build() async {
    _repository = ref.watch(wishlistRepositoryProvider);
    return _repository.getAll();
  }

  /// Обновляет список из БД.
  Future<void> refresh() async {
    state = const AsyncLoading<List<WishlistItem>>();
    state = await AsyncValue.guard(() => _repository.getAll());
  }

  /// Добавляет элемент в вишлист.
  Future<WishlistItem> add({
    required String text,
    MediaType? mediaTypeHint,
    String? note,
    String? tag,
  }) async {
    final WishlistItem item = await _repository.add(
      text: text,
      mediaTypeHint: mediaTypeHint,
      note: note,
      tag: tag,
    );

    // Оптимистичное обновление: добавляем в начало
    final List<WishlistItem> current = state.valueOrNull ?? <WishlistItem>[];
    state = AsyncData<List<WishlistItem>>(
      <WishlistItem>[item, ...current],
    );

    return item;
  }

  /// Помечает элемент как resolved.
  Future<void> resolve(int id) async {
    await _repository.resolve(id);

    final List<WishlistItem> current = state.valueOrNull ?? <WishlistItem>[];
    state = AsyncData<List<WishlistItem>>(
      _sortItems(
        current.map((WishlistItem item) {
          if (item.id == id) {
            return item.copyWith(
              isResolved: true,
              resolvedAt: DateTime.now(),
            );
          }
          return item;
        }).toList(),
      ),
    );
  }

  /// Снимает отметку resolved.
  Future<void> unresolve(int id) async {
    await _repository.unresolve(id);

    final List<WishlistItem> current = state.valueOrNull ?? <WishlistItem>[];
    state = AsyncData<List<WishlistItem>>(
      _sortItems(
        current.map((WishlistItem item) {
          if (item.id == id) {
            return item.copyWith(
              isResolved: false,
              clearResolvedAt: true,
            );
          }
          return item;
        }).toList(),
      ),
    );
  }

  /// Обновляет элемент вишлиста.
  Future<void> updateItem(
    int id, {
    String? text,
    MediaType? mediaTypeHint,
    bool clearMediaTypeHint = false,
    String? note,
    bool clearNote = false,
    String? tag,
    bool clearTag = false,
  }) async {
    await _repository.update(
      id,
      text: text,
      mediaTypeHint: mediaTypeHint,
      clearMediaTypeHint: clearMediaTypeHint,
      note: note,
      clearNote: clearNote,
      tag: tag,
      clearTag: clearTag,
    );

    final List<WishlistItem> current = state.valueOrNull ?? <WishlistItem>[];
    state = AsyncData<List<WishlistItem>>(
      current.map((WishlistItem item) {
        if (item.id == id) {
          return item.copyWith(
            text: text,
            mediaTypeHint: mediaTypeHint,
            clearMediaTypeHint: clearMediaTypeHint,
            note: note,
            clearNote: clearNote,
            tag: tag,
            clearTag: clearTag,
          );
        }
        return item;
      }).toList(),
    );
  }

  /// Удаляет элемент.
  Future<void> delete(int id) async {
    await _repository.delete(id);

    final List<WishlistItem> current = state.valueOrNull ?? <WishlistItem>[];
    state = AsyncData<List<WishlistItem>>(
      current.where((WishlistItem item) => item.id != id).toList(),
    );
  }

  /// Удаляет все resolved элементы.
  Future<int> clearResolved() async {
    final int count = await _repository.clearResolved();

    final List<WishlistItem> current = state.valueOrNull ?? <WishlistItem>[];
    state = AsyncData<List<WishlistItem>>(
      current.where((WishlistItem item) => !item.isResolved).toList(),
    );

    return count;
  }

  /// Удаляет все записи с указанным тегом (`null` = «без тега»).
  Future<int> deleteByTag(String? tag) async {
    final int count = await _repository.deleteByTag(tag);

    final List<WishlistItem> current = state.valueOrNull ?? <WishlistItem>[];
    state = AsyncData<List<WishlistItem>>(
      current.where((WishlistItem item) => item.tag != tag).toList(),
    );

    return count;
  }

  /// Применяет [tag] (или `null` чтобы снять тег) ко всем записям из [ids].
  Future<void> applyTagToIds(Set<int> ids, String? tag) async {
    if (ids.isEmpty) return;
    for (final int id in ids) {
      await _repository.update(
        id,
        tag: tag,
        clearTag: tag == null,
      );
    }

    final List<WishlistItem> current = state.valueOrNull ?? <WishlistItem>[];
    state = AsyncData<List<WishlistItem>>(
      current
          .map((WishlistItem item) => ids.contains(item.id)
              ? item.copyWith(tag: tag, clearTag: tag == null)
              : item)
          .toList(),
    );
  }

  /// Удаляет записи с указанными ID одной пачкой.
  Future<void> deleteIds(Set<int> ids) async {
    if (ids.isEmpty) return;
    for (final int id in ids) {
      await _repository.delete(id);
    }

    final List<WishlistItem> current = state.valueOrNull ?? <WishlistItem>[];
    state = AsyncData<List<WishlistItem>>(
      current.where((WishlistItem item) => !ids.contains(item.id)).toList(),
    );
  }

  /// Переименовывает тег у всех носителей.
  Future<int> renameTag(String? from, String to) async {
    final int count = await _repository.renameTag(from, to);

    final List<WishlistItem> current = state.valueOrNull ?? <WishlistItem>[];
    state = AsyncData<List<WishlistItem>>(
      current
          .map((WishlistItem item) =>
              item.tag == from ? item.copyWith(tag: to) : item)
          .toList(),
    );

    return count;
  }

  /// Сортирует: активные первыми (по createdAt DESC),
  /// затем resolved (по createdAt DESC).
  List<WishlistItem> _sortItems(List<WishlistItem> items) {
    final List<WishlistItem> sorted = List<WishlistItem>.of(items);
    sorted.sort((WishlistItem a, WishlistItem b) {
      if (a.isResolved != b.isResolved) {
        return a.isResolved ? 1 : -1;
      }
      return b.createdAt.compareTo(a.createdAt);
    });
    return sorted;
  }
}

/// Количество активных (не resolved) элементов вишлиста.
final Provider<int> activeWishlistCountProvider = Provider<int>((Ref ref) {
  final AsyncValue<List<WishlistItem>> itemsAsync = ref.watch(wishlistProvider);
  final List<WishlistItem>? items = itemsAsync.valueOrNull;
  if (items == null) return 0;
  return items.where((WishlistItem item) => !item.isResolved).length;
});

/// Derived list of wishlist tags with item counts. Recomputed whenever the
/// wishlist list itself changes.
final Provider<List<WishlistTagCount>> wishlistTagsProvider =
    Provider<List<WishlistTagCount>>((Ref ref) {
  final AsyncValue<List<WishlistItem>> itemsAsync =
      ref.watch(wishlistProvider);
  final List<WishlistItem>? items = itemsAsync.valueOrNull;
  if (items == null) return const <WishlistTagCount>[];

  final Map<String?, ({int active, int total, int latest})> buckets =
      <String?, ({int active, int total, int latest})>{};
  for (final WishlistItem item in items) {
    final int created = item.createdAt.millisecondsSinceEpoch;
    final ({int active, int total, int latest}) entry =
        buckets[item.tag] ?? (active: 0, total: 0, latest: 0);
    buckets[item.tag] = (
      active: entry.active + (item.isResolved ? 0 : 1),
      total: entry.total + 1,
      latest: created > entry.latest ? created : entry.latest,
    );
  }

  final List<MapEntry<String?, ({int active, int total, int latest})>> sorted =
      buckets.entries.toList()
        ..sort((MapEntry<String?, ({int active, int total, int latest})> a,
            MapEntry<String?, ({int active, int total, int latest})> b) {
          // Untagged bucket always comes first.
          if ((a.key == null) != (b.key == null)) {
            return a.key == null ? -1 : 1;
          }
          // Then most-recent tag first.
          return b.value.latest.compareTo(a.value.latest);
        });

  return sorted
      .map((MapEntry<String?, ({int active, int total, int latest})> e) =>
          WishlistTagCount(
            tag: e.key,
            activeCount: e.value.active,
            totalCount: e.value.total,
          ))
      .toList();
});
