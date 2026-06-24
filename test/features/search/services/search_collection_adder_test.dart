import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tonkatsu_box/core/services/image_cache_service.dart';
import 'package:tonkatsu_box/features/collections/providers/collections_provider.dart';
import 'package:tonkatsu_box/features/search/services/search_collection_adder.dart';
import 'package:tonkatsu_box/shared/models/collection.dart';
import 'package:tonkatsu_box/shared/models/collection_item.dart';
import 'package:tonkatsu_box/shared/models/data_source.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';

import '../../../helpers/test_helpers.dart';

/// Collections 1 and 2 exist; the batch add filters its targets against these.
final List<Collection> _testCollections = <Collection>[
  createTestCollection(id: 1, name: 'One'),
  createTestCollection(id: 2, name: 'Two'),
];

class _FakeCollectionsNotifier extends CollectionsNotifier {
  _FakeCollectionsNotifier(this._collections);

  final List<Collection> _collections;

  @override
  Future<List<Collection>> build() async => _collections;
}

/// Fake items notifier: records which collection each `addItem` targets and
/// returns a per-collection success flag (false = item already present there).
class _FakeItemsNotifier extends CollectionItemsNotifier {
  _FakeItemsNotifier(this._addedReturns, this._calls);

  final Map<int?, bool> _addedReturns;
  final List<int?> _calls;

  @override
  AsyncValue<List<CollectionItem>> build(int? arg) =>
      const AsyncData<List<CollectionItem>>(<CollectionItem>[]);

  @override
  Future<bool> addItem({
    required MediaType mediaType,
    required int externalId,
    int? platformId,
    DataSource? source,
    String? authorComment,
  }) async {
    _calls.add(arg);
    return _addedReturns[arg] ?? true;
  }
}

class _Harness extends ConsumerWidget {
  const _Harness(this.action);

  final Future<void> Function(WidgetRef ref, BuildContext context) action;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Resolve collectionsProvider before the action runs (the batch add filters
    // its targets against it); pumpApp's pumpAndSettle waits for it.
    ref.watch(collectionsProvider);
    // Own Scaffold so the button has a Material ancestor and snackbars have a
    // ScaffoldMessenger to land in.
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => action(ref, context),
          child: const Text('go'),
        ),
      ),
    );
  }
}

void main() {
  group('SearchCollectionAdder.addToCollections', () {
    testWidgets('adds to every selected collection, one success snackbar',
        (WidgetTester tester) async {
      final List<int?> calls = <int?>[];
      int upsertCount = 0;

      await tester.pumpApp(
        _Harness((WidgetRef ref, BuildContext context) {
          return SearchCollectionAdder(ref).addToCollections(
            context: context,
            collectionIds: <int>{1, 2},
            mediaType: MediaType.game,
            externalId: 42,
            title: 'Zelda',
            upsert: () async => upsertCount++,
            imageType: ImageType.gameCover,
            imageId: '42',
          );
        }),
        overrides: <Override>[
          collectionsProvider.overrideWith(
            () => _FakeCollectionsNotifier(_testCollections),
          ),
          collectionItemsNotifierProvider.overrideWith(
            () => _FakeItemsNotifier(const <int?, bool>{}, calls),
          ),
        ],
      );

      await tester.tap(find.text('go'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(upsertCount, 1);
      expect(calls.toSet(), <int?>{1, 2});
      expect(find.text('Zelda added to 2 collections'), findsOneWidget);
    });

    testWidgets('counts only the collections it was actually added to',
        (WidgetTester tester) async {
      final List<int?> calls = <int?>[];

      await tester.pumpApp(
        _Harness((WidgetRef ref, BuildContext context) {
          return SearchCollectionAdder(ref).addToCollections(
            context: context,
            collectionIds: <int>{1, 2},
            mediaType: MediaType.game,
            externalId: 42,
            title: 'Zelda',
            upsert: () async {},
            imageType: ImageType.gameCover,
            imageId: '42',
          );
        }),
        overrides: <Override>[
          collectionsProvider.overrideWith(
            () => _FakeCollectionsNotifier(_testCollections),
          ),
          collectionItemsNotifierProvider.overrideWith(
            // Collection 2 already has the item → not counted.
            () => _FakeItemsNotifier(const <int?, bool>{1: true, 2: false}, calls),
          ),
        ],
      );

      await tester.tap(find.text('go'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Zelda added to 1 collection'), findsOneWidget);
    });

    testWidgets('ignores a selected id whose collection was deleted',
        (WidgetTester tester) async {
      final List<int?> calls = <int?>[];

      await tester.pumpApp(
        _Harness((WidgetRef ref, BuildContext context) {
          return SearchCollectionAdder(ref).addToCollections(
            context: context,
            // 99 no longer exists → filtered out; only 1 is added.
            collectionIds: <int>{1, 99},
            mediaType: MediaType.game,
            externalId: 42,
            title: 'Zelda',
            upsert: () async {},
            imageType: ImageType.gameCover,
            imageId: '42',
          );
        }),
        overrides: <Override>[
          collectionsProvider.overrideWith(
            () => _FakeCollectionsNotifier(_testCollections),
          ),
          collectionItemsNotifierProvider.overrideWith(
            () => _FakeItemsNotifier(const <int?, bool>{}, calls),
          ),
        ],
      );

      await tester.tap(find.text('go'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(calls, <int?>[1]);
      expect(find.text('Zelda added to 1 collection'), findsOneWidget);
    });

    testWidgets('already in all selected → info snackbar, no count',
        (WidgetTester tester) async {
      final List<int?> calls = <int?>[];

      await tester.pumpApp(
        _Harness((WidgetRef ref, BuildContext context) {
          return SearchCollectionAdder(ref).addToCollections(
            context: context,
            collectionIds: <int>{1, 2},
            mediaType: MediaType.game,
            externalId: 42,
            title: 'Zelda',
            upsert: () async {},
            imageType: ImageType.gameCover,
            imageId: '42',
          );
        }),
        overrides: <Override>[
          collectionsProvider.overrideWith(
            () => _FakeCollectionsNotifier(_testCollections),
          ),
          collectionItemsNotifierProvider.overrideWith(
            () =>
                _FakeItemsNotifier(const <int?, bool>{1: false, 2: false}, calls),
          ),
        ],
      );

      await tester.tap(find.text('go'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('Zelda already in the selected collections'),
        findsOneWidget,
      );
    });

    testWidgets('empty set is a no-op (no upsert, no add, no snackbar)',
        (WidgetTester tester) async {
      final List<int?> calls = <int?>[];
      int upsertCount = 0;

      await tester.pumpApp(
        _Harness((WidgetRef ref, BuildContext context) {
          return SearchCollectionAdder(ref).addToCollections(
            context: context,
            collectionIds: const <int>{},
            mediaType: MediaType.game,
            externalId: 42,
            title: 'Zelda',
            upsert: () async => upsertCount++,
            imageType: ImageType.gameCover,
            imageId: '42',
          );
        }),
        overrides: <Override>[
          collectionsProvider.overrideWith(
            () => _FakeCollectionsNotifier(_testCollections),
          ),
          collectionItemsNotifierProvider.overrideWith(
            () => _FakeItemsNotifier(const <int?, bool>{}, calls),
          ),
        ],
      );

      await tester.tap(find.text('go'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(upsertCount, 0);
      expect(calls, isEmpty);
      expect(find.byType(SnackBar), findsNothing);
    });
  });
}
