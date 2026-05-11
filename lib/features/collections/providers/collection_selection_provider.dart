// Стейт выделенных элементов внутри одной коллекции.

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Провайдер набора выделенных id для конкретной коллекции.
///
/// Family-параметр — `collectionId` (null для uncategorized).
/// У каждой коллекции свой набор, переключение между коллекциями
/// автоматически сбрасывает чужой селекшн.
final NotifierProviderFamily<CollectionSelectionNotifier, Set<int>, int?>
    collectionSelectionProvider =
    NotifierProvider.family<CollectionSelectionNotifier, Set<int>, int?>(
  CollectionSelectionNotifier.new,
);

/// Управляет набором выделенных id внутри коллекции.
class CollectionSelectionNotifier extends FamilyNotifier<Set<int>, int?> {
  @override
  Set<int> build(int? arg) => <int>{};

  /// Переключает выделение для [id].
  void toggle(int id) {
    final Set<int> next = Set<int>.of(state);
    if (!next.add(id)) next.remove(id);
    state = next;
  }

  /// Заменяет селекшн на [ids] (используется для select-all).
  void selectAll(Iterable<int> ids) {
    state = Set<int>.of(ids);
  }

  /// Очищает селекшн.
  void clear() {
    if (state.isEmpty) return;
    state = <int>{};
  }

  /// Удаляет переданные [ids] из селекшна (после bulk-remove
  /// или удаления одиночного элемента).
  void removeIds(Iterable<int> ids) {
    if (state.isEmpty) return;
    final Set<int> next = Set<int>.of(state)..removeAll(ids);
    if (next.length == state.length) return;
    state = next;
  }
}
