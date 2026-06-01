import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/collections/widgets/bulk_action_bar.dart';
import 'package:tonkatsu_box/shared/models/collection_item.dart';

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
}
