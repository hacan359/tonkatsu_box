import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/models/item_status.dart';
import 'package:xerabora/shared/widgets/chevron_filter_bar.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('StatusDropdownSegment', () {
    Future<ItemStatus?> pickValue(
      WidgetTester tester, {
      required ItemStatus? initial,
      required String menuValue,
    }) async {
      ItemStatus? captured;
      bool fired = false;
      await tester.pumpApp(
        StatusDropdownSegment(
          status: initial,
          compact: false,
          onChanged: (ItemStatus? s) {
            captured = s;
            fired = true;
          },
        ),
        wrapInScaffold: true,
      );

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      final Finder item = find.byWidgetPredicate(
        (Widget w) => w is PopupMenuItem<String> && w.value == menuValue,
      );
      expect(item, findsOneWidget, reason: 'menu item "$menuValue" missing');
      await tester.tap(item);
      await tester.pumpAndSettle();

      expect(fired, isTrue);
      return captured;
    }

    testWidgets('selecting a status reports that status', (WidgetTester t) async {
      final ItemStatus? r = await pickValue(
        t,
        initial: null,
        menuValue: ItemStatus.completed.value,
      );
      expect(r, ItemStatus.completed);
    });

    testWidgets('selecting "All" reports null', (WidgetTester t) async {
      final ItemStatus? r = await pickValue(
        t,
        initial: ItemStatus.completed,
        menuValue: 'all',
      );
      expect(r, isNull);
    });

    testWidgets('selecting in-progress reports inProgress', (WidgetTester t) async {
      final ItemStatus? r = await pickValue(
        t,
        initial: null,
        menuValue: ItemStatus.inProgress.value,
      );
      expect(r, ItemStatus.inProgress);
    });
  });
}
