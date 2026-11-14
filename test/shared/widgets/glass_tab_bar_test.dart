import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/widgets/glass_tab_bar.dart';

import '../../helpers/test_helpers.dart';

void main() {
  const List<GlassTabOption<int>> options = <GlassTabOption<int>>[
    GlassTabOption<int>(value: 0, label: 'One', icon: Icons.looks_one),
    GlassTabOption<int>(value: 1, label: 'Two', icon: Icons.looks_two),
    GlassTabOption<int>(value: 2, label: 'Three', icon: Icons.looks_3),
  ];

  group('GlassTabBar', () {
    testWidgets('renders every option and reports taps', (
      WidgetTester tester,
    ) async {
      int? tapped;
      await tester.pumpApp(
        GlassTabBar<int>(
          options: options,
          selected: 0,
          onChanged: (int v) => tapped = v,
        ),
      );

      expect(find.text('One'), findsOneWidget);
      expect(find.text('Three'), findsOneWidget);

      await tester.tap(find.text('Two'));
      expect(tapped, 1);
    });

    testWidgets('selection change animates without exceptions', (
      WidgetTester tester,
    ) async {
      int selected = 0;
      await tester.pumpApp(
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) =>
              GlassTabBar<int>(
                options: options,
                selected: selected,
                onChanged: (int v) => setState(() => selected = v),
              ),
        ),
      );

      await tester.tap(find.text('Three'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('a selected value outside the options hides the pill', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        GlassTabBar<int>(options: options, selected: 9, onChanged: (_) {}),
      );

      expect(
        find.descendant(
          of: find.byType(GlassTabBar<int>),
          matching: find.byType(Positioned),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
