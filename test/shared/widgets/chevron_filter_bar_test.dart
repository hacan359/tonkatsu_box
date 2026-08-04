import 'package:core/models/item_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/widgets/chevron_filter_bar.dart';

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

  group('DropdownChevronSegment', () {
    String? captured;
    bool fired = false;

    Future<void> openMenu(
      WidgetTester tester, {
      required int itemCount,
    }) async {
      captured = null;
      fired = false;
      await tester.pumpApp(
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 200,
            height: 40,
            child: DropdownChevronSegment<String>(
              label: 'Source',
              icon: Icons.search,
              selected: true,
              accentColor: Colors.blue,
              isFirst: true,
              isLast: true,
              menuBuilder: (BuildContext ctx) => <PopupMenuEntry<String>>[
                for (int i = 0; i < itemCount; i++)
                  PopupMenuItem<String>(
                    value: 'item_$i',
                    height: 36,
                    child: Text('Item $i'),
                  ),
              ],
              onSelected: (String? v) {
                captured = v;
                fired = true;
              },
            ),
          ),
        ),
        wrapInScaffold: true,
      );
      await tester.tap(find.byType(DropdownChevronSegment<String>));
      await tester.pumpAndSettle();
    }

    testWidgets('selecting an item reports its value and closes the menu',
        (WidgetTester tester) async {
      await openMenu(tester, itemCount: 3);

      await tester.tap(find.text('Item 1'));
      await tester.pumpAndSettle();

      expect(captured, 'item_1');
      expect(find.text('Item 1'), findsNothing);
    });

    testWidgets('dismissing without a choice does not fire onSelected',
        (WidgetTester tester) async {
      await openMenu(tester, itemCount: 3);

      await tester.tapAt(const Offset(790, 590));
      await tester.pumpAndSettle();

      expect(fired, isFalse);
      expect(find.text('Item 1'), findsNothing);
    });

    testWidgets('shows scroll arrows immediately when the list overflows',
        (WidgetTester tester) async {
      await openMenu(tester, itemCount: 20);

      expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    });

    testWidgets('shows no scroll arrows when the list fits',
        (WidgetTester tester) async {
      await openMenu(tester, itemCount: 3);

      expect(find.byIcon(Icons.keyboard_arrow_up), findsNothing);
      expect(find.byIcon(Icons.keyboard_arrow_down), findsNothing);
    });

    testWidgets('tapping the down arrow scrolls the menu',
        (WidgetTester tester) async {
      await openMenu(tester, itemCount: 20);
      final double topBefore = tester.getTopLeft(find.text('Item 0')).dy;

      await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
      await tester.pumpAndSettle();

      final double topAfter = tester.getTopLeft(find.text('Item 0')).dy;
      expect(topAfter, lessThan(topBefore));
    });
  });
}
