import 'package:core/models/collection_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/collections/widgets/bulk_action_bar.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('BulkActionBar select-all action', () {
    final List<CollectionItem> oneSelected = <CollectionItem>[
      createTestCollectionItem(id: 1),
    ];

    Finder selectAllButton() => find.byWidgetPredicate(
          (Widget w) => w is TextButton && w.onPressed != null,
        );

    testWidgets(
        'should show a tappable Select all button when callback is set and '
        'visibleCount exceeds selection', (WidgetTester tester) async {
      int taps = 0;

      await tester.pumpApp(
        BulkActionBar(
          items: oneSelected,
          visibleCount: 5,
          onSelectAllVisible: () => taps++,
          onClearSelection: () {},
        ),
        wrapInScaffold: true,
      );

      final Finder button = selectAllButton();
      expect(button, findsOneWidget);

      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets(
        'should hide Select all when everything visible is already selected',
        (WidgetTester tester) async {
      await tester.pumpApp(
        BulkActionBar(
          items: oneSelected,
          visibleCount: 1,
          onSelectAllVisible: () {},
          onClearSelection: () {},
        ),
        wrapInScaffold: true,
      );

      expect(selectAllButton(), findsNothing);
    });

    testWidgets(
        'should hide Select all when no callback is provided',
        (WidgetTester tester) async {
      await tester.pumpApp(
        BulkActionBar(
          items: oneSelected,
          visibleCount: 99,
          onClearSelection: () {},
        ),
        wrapInScaffold: true,
      );

      expect(selectAllButton(), findsNothing);
    });
  });

  group('BulkActionBar tag actions', () {
    final List<CollectionItem> twoSelected = <CollectionItem>[
      createTestCollectionItem(id: 1),
      createTestCollectionItem(id: 2),
    ];

    testWidgets('should offer both add-tags and remove-tags actions',
        (WidgetTester tester) async {
      await tester.pumpApp(
        BulkActionBar(
          items: twoSelected,
          onClearSelection: () {},
        ),
        wrapInScaffold: true,
      );

      expect(find.byIcon(Icons.new_label_outlined), findsOneWidget);
      expect(find.byIcon(Icons.label_off_outlined), findsOneWidget);
    });

    testWidgets('should open the tag picker from the add-tags action',
        (WidgetTester tester) async {
      await tester.pumpApp(
        BulkActionBar(
          items: twoSelected,
          onClearSelection: () {},
        ),
        wrapInScaffold: true,
      );

      await tester.tap(find.byIcon(Icons.new_label_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('BulkActionBar layout', () {
    final List<CollectionItem> oneSelected = <CollectionItem>[
      createTestCollectionItem(id: 1),
    ];

    Future<void> pumpAt(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpApp(
        BulkActionBar(
          items: oneSelected,
          visibleCount: 9,
          onSelectAllVisible: () {},
          onClearSelection: () {},
        ),
        wrapInScaffold: true,
      );
    }

    testWidgets('should stack the counter above the actions on a phone',
        (WidgetTester tester) async {
      await pumpAt(tester, const Size(360, 640));

      // Two rows: the counter keeps its width and the actions get their own
      // line instead of being squeezed into a sliver of scrollable space.
      expect(find.byType(Column), findsWidgets);
      final Offset counter = tester.getCenter(find.byType(Text).first);
      final Offset actions =
          tester.getCenter(find.byIcon(Icons.delete_outline));
      expect(actions.dy, greaterThan(counter.dy));
      expect(tester.takeException(), isNull);
    });

    testWidgets('should keep everything on one line on a wide window',
        (WidgetTester tester) async {
      await pumpAt(tester, const Size(1280, 800));

      final Offset counter = tester.getCenter(find.byType(Text).first);
      final Offset actions =
          tester.getCenter(find.byIcon(Icons.delete_outline));
      expect(actions.dy, closeTo(counter.dy, 1.0));
      expect(tester.takeException(), isNull);
    });
  });
}
