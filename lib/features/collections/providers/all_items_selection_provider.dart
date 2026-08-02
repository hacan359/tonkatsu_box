// Глобальный селекшн для экрана All Items (все коллекции вместе).
//
// Отдельный провайдер, не часть family `collectionSelectionProvider`,
// потому что он логически не привязан к одной коллекции.

import 'package:flutter_riverpod/flutter_riverpod.dart';

final NotifierProvider<AllItemsSelectionNotifier, Set<int>>
    allItemsSelectionProvider =
    NotifierProvider<AllItemsSelectionNotifier, Set<int>>(
  AllItemsSelectionNotifier.new,
);

class AllItemsSelectionNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() => <int>{};

  void toggle(int id) {
    final Set<int> next = Set<int>.of(state);
    if (!next.add(id)) next.remove(id);
    state = next;
  }

  /// Заменяет селекшн на [ids] (select-all).
  void selectAll(Iterable<int> ids) {
    state = Set<int>.of(ids);
  }

  void clear() {
    if (state.isEmpty) return;
    state = <int>{};
  }
}
