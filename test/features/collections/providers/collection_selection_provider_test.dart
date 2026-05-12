import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/collections/providers/collection_selection_provider.dart';

void main() {
  ProviderContainer makeContainer() {
    final ProviderContainer c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  group('CollectionSelectionNotifier', () {
    test('initial state is empty', () {
      final ProviderContainer c = makeContainer();
      expect(c.read(collectionSelectionProvider(1)), isEmpty);
    });

    test('toggle adds id when absent and removes when present', () {
      final ProviderContainer c = makeContainer();
      final CollectionSelectionNotifier n =
          c.read(collectionSelectionProvider(1).notifier);
      n.toggle(10);
      n.toggle(20);
      expect(c.read(collectionSelectionProvider(1)), <int>{10, 20});
      n.toggle(10);
      expect(c.read(collectionSelectionProvider(1)), <int>{20});
    });

    test('selectAll replaces the set', () {
      final ProviderContainer c = makeContainer();
      final CollectionSelectionNotifier n =
          c.read(collectionSelectionProvider(1).notifier);
      n.toggle(10);
      n.selectAll(<int>[1, 2, 3]);
      expect(c.read(collectionSelectionProvider(1)), <int>{1, 2, 3});
    });

    test('clear empties the set', () {
      final ProviderContainer c = makeContainer();
      final CollectionSelectionNotifier n =
          c.read(collectionSelectionProvider(1).notifier);
      n.selectAll(<int>[1, 2]);
      n.clear();
      expect(c.read(collectionSelectionProvider(1)), isEmpty);
    });

    test('removeIds drops only the listed ids', () {
      final ProviderContainer c = makeContainer();
      final CollectionSelectionNotifier n =
          c.read(collectionSelectionProvider(1).notifier);
      n.selectAll(<int>[1, 2, 3, 4]);
      n.removeIds(<int>[2, 3, 99]);
      expect(c.read(collectionSelectionProvider(1)), <int>{1, 4});
    });

    test('selections are isolated between collections (family)', () {
      final ProviderContainer c = makeContainer();
      c.read(collectionSelectionProvider(1).notifier).toggle(10);
      c.read(collectionSelectionProvider(2).notifier).toggle(20);
      expect(c.read(collectionSelectionProvider(1)), <int>{10});
      expect(c.read(collectionSelectionProvider(2)), <int>{20});
    });
  });
}
