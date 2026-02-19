import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  }) async {
    final WishlistItem item = await _repository.add(
      text: text,
      mediaTypeHint: mediaTypeHint,
      note: note,
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
  }) async {
    await _repository.update(
      id,
      text: text,
      mediaTypeHint: mediaTypeHint,
      clearMediaTypeHint: clearMediaTypeHint,
      note: note,
      clearNote: clearNote,
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
