import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Family arg is `collectionId` (null for uncategorized); each collection
/// keeps its own set, so switching collections resets the other's selection.
final NotifierProviderFamily<CollectionSelectionNotifier, Set<int>, int?>
    collectionSelectionProvider =
    NotifierProvider.family<CollectionSelectionNotifier, Set<int>, int?>(
  CollectionSelectionNotifier.new,
);

class CollectionSelectionNotifier extends FamilyNotifier<Set<int>, int?> {
  @override
  Set<int> build(int? arg) => <int>{};

  void toggle(int id) {
    final Set<int> next = Set<int>.of(state);
    if (!next.add(id)) next.remove(id);
    state = next;
  }

  void selectAll(Iterable<int> ids) {
    state = Set<int>.of(ids);
  }

  void clear() {
    if (state.isEmpty) return;
    state = <int>{};
  }

  void removeIds(Iterable<int> ids) {
    if (state.isEmpty) return;
    final Set<int> next = Set<int>.of(state)..removeAll(ids);
    if (next.length == state.length) return;
    state = next;
  }
}
