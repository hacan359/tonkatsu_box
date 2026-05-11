// Глобальный селекшн для экрана All Items (все коллекции вместе).
//
// Отдельный провайдер, не часть family `collectionSelectionProvider`,
// потому что он логически не привязан к одной коллекции.

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Набор выделенных id на экране All Items.
final NotifierProvider<AllItemsSelectionNotifier, Set<int>>
    allItemsSelectionProvider =
    NotifierProvider<AllItemsSelectionNotifier, Set<int>>(
  AllItemsSelectionNotifier.new,
);

/// Управляет селекшном на All Items.
class AllItemsSelectionNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() => <int>{};

  /// Переключает выделение для [id].
  void toggle(int id) {
    final Set<int> next = Set<int>.of(state);
    if (!next.add(id)) next.remove(id);
    state = next;
  }

  /// Заменяет селекшн на [ids] (select-all).
  void selectAll(Iterable<int> ids) {
    state = Set<int>.of(ids);
  }

  /// Очищает селекшн.
  void clear() {
    if (state.isEmpty) return;
    state = <int>{};
  }
}
