import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/widgets/draggable_fab.dart';

import '../../helpers/test_helpers.dart';

Future<void> _pumpFab(
  WidgetTester tester, {
  DraggableFabItem? mainAction,
  List<DraggableFabItem> sideActions = const <DraggableFabItem>[],
  List<DraggableFabItem> items = const <DraggableFabItem>[],
}) {
  return tester.pumpApp(
    Stack(
      children: <Widget>[
        DraggableFab(
          mainAction: mainAction,
          sideActions: sideActions,
          items: items,
        ),
      ],
    ),
    wrapInScaffold: true,
  );
}

void main() {
  group('DraggableFab', () {
    group('sideActions', () {
      testWidgets('should fire the side and main callbacks separately',
          (WidgetTester tester) async {
        int mainTaps = 0;
        int sideTaps = 0;
        await _pumpFab(
          tester,
          mainAction: DraggableFabItem(
            icon: Icons.add,
            label: 'main',
            onTap: () => mainTaps++,
          ),
          sideActions: <DraggableFabItem>[
            DraggableFabItem(
              icon: Icons.add_box_outlined,
              label: 'side',
              onTap: () => sideTaps++,
            ),
          ],
        );

        await tester.tap(find.byIcon(Icons.add_box_outlined));
        expect(sideTaps, 1);
        expect(mainTaps, 0);

        await tester.tap(find.byIcon(Icons.add));
        expect(mainTaps, 1);
        expect(sideTaps, 1);
      });

      testWidgets(
          'should put side actions left of main and keep the menu above main',
          (WidgetTester tester) async {
        await _pumpFab(
          tester,
          mainAction:
              DraggableFabItem(icon: Icons.add, label: 'main', onTap: () {}),
          sideActions: <DraggableFabItem>[
            DraggableFabItem(
                icon: Icons.add_box_outlined, label: 'side', onTap: () {}),
          ],
          items: <DraggableFabItem>[
            DraggableFabItem(icon: Icons.tune, label: 'item', onTap: () {}),
          ],
        );

        final Offset main = tester.getCenter(find.byIcon(Icons.add));
        final Offset side = tester.getCenter(find.byIcon(Icons.add_box_outlined));
        final Offset menu = tester.getCenter(find.byIcon(Icons.more_vert));

        expect(side.dy, main.dy);
        expect(side.dx, lessThan(main.dx));
        expect(menu.dx, main.dx);
        expect(menu.dy, lessThan(main.dy));
        expect(tester.takeException(), isNull);
      });

      testWidgets('should render side actions alone when there is no main',
          (WidgetTester tester) async {
        int sideTaps = 0;
        await _pumpFab(
          tester,
          sideActions: <DraggableFabItem>[
            DraggableFabItem(
              icon: Icons.add_box_outlined,
              label: 'side',
              onTap: () => sideTaps++,
            ),
          ],
          items: <DraggableFabItem>[
            DraggableFabItem(icon: Icons.tune, label: 'item', onTap: () {}),
          ],
        );

        await tester.tap(find.byIcon(Icons.add_box_outlined));
        expect(sideTaps, 1);
        expect(
          tester.getCenter(find.byIcon(Icons.more_vert)).dx,
          tester.getCenter(find.byIcon(Icons.add_box_outlined)).dx,
        );
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('should open the menu from the anchor and run the picked item',
        (WidgetTester tester) async {
      int itemTaps = 0;
      await _pumpFab(
        tester,
        mainAction:
            DraggableFabItem(icon: Icons.add, label: 'main', onTap: () {}),
        sideActions: <DraggableFabItem>[
          DraggableFabItem(
              icon: Icons.add_box_outlined, label: 'side', onTap: () {}),
        ],
        items: <DraggableFabItem>[
          DraggableFabItem(
            icon: Icons.tune,
            label: 'item',
            onTap: () => itemTaps++,
          ),
        ],
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();

      expect(itemTaps, 1);
      expect(find.byIcon(Icons.tune), findsNothing);
    });

    testWidgets('should render nothing without actions or menu',
        (WidgetTester tester) async {
      await _pumpFab(tester);

      expect(
        find.descendant(
          of: find.byType(DraggableFab),
          matching: find.byType(GestureDetector),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
