import 'package:flutter_riverpod/flutter_riverpod.dart';

// Deliberately not part of the collectionSelectionProvider family: the All
// Items selection is not tied to any single collection.
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

  /// Replaces the selection with [ids] (select-all semantics).
  void selectAll(Iterable<int> ids) {
    state = Set<int>.of(ids);
  }

  void clear() {
    if (state.isEmpty) return;
    state = <int>{};
  }
}
