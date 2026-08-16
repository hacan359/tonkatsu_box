import 'package:core/models/item_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';
import 'package:tonkatsu_box/shared/constants/item_status_ui.dart';
import 'package:tonkatsu_box/shared/widgets/chevron_filter_bar.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('StatusDropdownSegment', () {
    late List<Set<ItemStatus>> reported;

    Future<void> openMenu(
      WidgetTester tester, {
      Set<ItemStatus> initial = const <ItemStatus>{},
    }) async {
      reported = <Set<ItemStatus>>[];
      await tester.pumpApp(
        StatusDropdownSegment(
          statuses: initial,
          compact: false,
          onChanged: reported.add,
        ),
        wrapInScaffold: true,
      );

      await tester.tap(find.byType(PopupMenuButton<void>));
      await tester.pumpAndSettle();
    }

    Finder rowFor(WidgetTester tester, ItemStatus status) {
      final S l = S.of(
        tester.element(find.byType(StatusDropdownSegment)),
      );
      return find.descendant(
        of: find.byType(PopupMenuItem<void>),
        matching: find.text(status.genericLabel(l)),
      );
    }

    testWidgets('picking a status reports a single-element set',
        (WidgetTester tester) async {
      await openMenu(tester);

      await tester.tap(rowFor(tester, ItemStatus.completed));
      await tester.pumpAndSettle();

      expect(reported, <Set<ItemStatus>>[
        <ItemStatus>{ItemStatus.completed},
      ]);
    });

    testWidgets('the menu stays open so several statuses accumulate',
        (WidgetTester tester) async {
      await openMenu(tester);

      await tester.tap(rowFor(tester, ItemStatus.completed));
      await tester.pumpAndSettle();
      await tester.tap(rowFor(tester, ItemStatus.inProgress));
      await tester.pumpAndSettle();

      expect(reported.last, <ItemStatus>{
        ItemStatus.completed,
        ItemStatus.inProgress,
      });
    });

    testWidgets('tapping a selected status removes it',
        (WidgetTester tester) async {
      await openMenu(
        tester,
        initial: <ItemStatus>{ItemStatus.completed, ItemStatus.dropped},
      );

      await tester.tap(rowFor(tester, ItemStatus.completed));
      await tester.pumpAndSettle();

      expect(reported.last, <ItemStatus>{ItemStatus.dropped});
    });

    testWidgets('"All" clears the selection', (WidgetTester tester) async {
      await openMenu(tester, initial: <ItemStatus>{ItemStatus.completed});

      final S l = S.of(
        tester.element(find.byType(StatusDropdownSegment)),
      );
      await tester.tap(find.descendant(
        of: find.byType(PopupMenuItem<void>),
        matching: find.text(l.all),
      ));
      await tester.pumpAndSettle();

      expect(reported.last, isEmpty);
    });

    testWidgets('offers a row for every status', (WidgetTester tester) async {
      await openMenu(tester);

      for (final ItemStatus status in ItemStatus.values) {
        expect(
          rowFor(tester, status),
          findsOneWidget,
          reason: '${status.name} row missing',
        );
      }
    });

    testWidgets('the ignored status is offered', (WidgetTester tester) async {
      await openMenu(tester);

      await tester.tap(rowFor(tester, ItemStatus.ignored));
      await tester.pumpAndSettle();

      expect(reported.last, <ItemStatus>{ItemStatus.ignored});
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
