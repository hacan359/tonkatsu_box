import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/widgets/glass_popup_menu.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('GlassPopupMenuButton', () {
    Future<void> openMenu(
      WidgetTester tester, {
      required List<Widget> Function(BuildContext) rows,
      ValueChanged<int>? onSelected,
    }) async {
      await tester.pumpApp(
        Center(
          child: GlassPopupMenuButton<int>(
            tooltip: 'menu',
            onSelected: onSelected,
            rows: rows,
          ),
        ),
      );
      await tester.tap(find.byTooltip('menu'));
      await tester.pumpAndSettle();
    }

    testWidgets('should report the row value and close when a row is tapped', (
      WidgetTester tester,
    ) async {
      int? selected;
      await openMenu(
        tester,
        onSelected: (int v) => selected = v,
        rows: (BuildContext _) => const <Widget>[
          GlassMenuRow<int>(label: 'one', value: 1),
          GlassMenuDivider(),
          GlassMenuRow<int>(label: 'two', value: 2),
        ],
      );

      await tester.tap(find.text('two'));
      await tester.pumpAndSettle();

      expect(selected, 2);
      expect(find.text('one'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should run onTap and stay open when closeOnTap is false', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      int? selected;
      await openMenu(
        tester,
        onSelected: (int v) => selected = v,
        rows: (BuildContext _) => <Widget>[
          GlassMenuRow<int>(
            label: 'toggle',
            closeOnTap: false,
            onTap: () => taps++,
          ),
        ],
      );

      await tester.tap(find.text('toggle'));
      await tester.pumpAndSettle();

      expect(taps, 1);
      expect(selected, isNull);
      expect(find.text('toggle'), findsOneWidget);
    });

    testWidgets('should rebuild rows on every open', (
      WidgetTester tester,
    ) async {
      int builds = 0;
      await openMenu(
        tester,
        rows: (BuildContext _) {
          builds++;
          return <Widget>[GlassMenuRow<int>(label: 'b$builds', value: 0)];
        },
      );
      await tester.tap(find.text('b1'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('menu'));
      await tester.pumpAndSettle();

      expect(find.text('b2'), findsOneWidget);
    });
  });
}
