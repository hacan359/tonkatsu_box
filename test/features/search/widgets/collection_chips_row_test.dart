import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tonkatsu_box/features/collections/providers/collections_provider.dart';
import 'package:tonkatsu_box/features/search/widgets/collection_chips_row.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';
import 'package:tonkatsu_box/shared/models/collection.dart';
import 'package:tonkatsu_box/shared/navigation/search_providers.dart';
import 'package:tonkatsu_box/shared/widgets/filter_subfilter_bar.dart';
import 'package:tonkatsu_box/shared/widgets/selected_count_chip.dart';

import '../../../helpers/test_helpers.dart';

class _FakeCollectionsNotifier extends CollectionsNotifier {
  _FakeCollectionsNotifier(this._collections);

  final List<Collection> _collections;

  @override
  Future<List<Collection>> build() async => _collections;
}

ProviderContainer _pump(
  WidgetTester tester, {
  required List<Collection> collections,
}) {
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      collectionsProvider.overrideWith(
        () => _FakeCollectionsNotifier(collections),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<void> _pumpRow(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        locale: Locale('en'),
        home: Scaffold(body: CollectionChipsRow()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('CollectionChipsRow', () {
    testWidgets('renders nothing when there are no collections',
        (WidgetTester tester) async {
      final ProviderContainer container =
          _pump(tester, collections: <Collection>[]);
      await _pumpRow(tester, container);

      expect(find.byType(FilterTabChip), findsNothing);
    });

    testWidgets('renders one chip per collection',
        (WidgetTester tester) async {
      final ProviderContainer container = _pump(
        tester,
        collections: createTestCollections(count: 3),
      );
      await _pumpRow(tester, container);

      expect(find.byType(FilterTabChip), findsNWidgets(3));
    });

    testWidgets('tapping a chip selects its collection',
        (WidgetTester tester) async {
      final List<Collection> collections = <Collection>[
        createTestCollection(id: 5, name: 'Alpha'),
      ];
      final ProviderContainer container =
          _pump(tester, collections: collections);
      await _pumpRow(tester, container);

      expect(container.read(searchTargetCollectionsProvider), isEmpty);

      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();

      expect(container.read(searchTargetCollectionsProvider), <int>{5});
    });

    testWidgets('tapping a selected chip deselects it',
        (WidgetTester tester) async {
      final List<Collection> collections = <Collection>[
        createTestCollection(id: 5, name: 'Alpha'),
      ];
      final ProviderContainer container =
          _pump(tester, collections: collections);
      container.read(searchTargetCollectionsProvider.notifier).state = <int>{5};
      await _pumpRow(tester, container);

      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();

      expect(container.read(searchTargetCollectionsProvider), isEmpty);
    });

    testWidgets('selection is multi-select', (WidgetTester tester) async {
      final List<Collection> collections = <Collection>[
        createTestCollection(id: 1, name: 'Alpha'),
        createTestCollection(id: 2, name: 'Beta'),
      ];
      final ProviderContainer container =
          _pump(tester, collections: collections);
      await _pumpRow(tester, container);

      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Beta'));
      await tester.pumpAndSettle();

      expect(container.read(searchTargetCollectionsProvider), <int>{1, 2});
    });

    testWidgets('no count chip when nothing is selected',
        (WidgetTester tester) async {
      final ProviderContainer container = _pump(
        tester,
        collections: createTestCollections(count: 2),
      );
      await _pumpRow(tester, container);

      expect(find.byType(SelectedCountChip), findsNothing);
    });

    testWidgets('count chip appears and shows the number selected',
        (WidgetTester tester) async {
      final ProviderContainer container = _pump(
        tester,
        collections: createTestCollections(count: 3),
      );
      await _pumpRow(tester, container);

      await tester.tap(find.text('Collection 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Collection 2'));
      await tester.pumpAndSettle();

      expect(find.byType(SelectedCountChip), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('tapping the count chip clears the selection',
        (WidgetTester tester) async {
      final ProviderContainer container = _pump(
        tester,
        collections: createTestCollections(count: 2),
      );
      container.read(searchTargetCollectionsProvider.notifier).state =
          <int>{1, 2};
      await _pumpRow(tester, container);

      await tester.tap(find.byType(SelectedCountChip));
      await tester.pumpAndSettle();

      expect(container.read(searchTargetCollectionsProvider), isEmpty);
    });
  });
}
