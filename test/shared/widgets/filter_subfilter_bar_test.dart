import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/widgets/filter_subfilter_bar.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('SubfilterBar', () {
    SubfilterChipData chip(
      String label, {
      bool selected = false,
      VoidCallback? onTap,
    }) =>
        SubfilterChipData(
          label: label,
          accent: const Color(0xFF3DB4F2),
          selected: selected,
          onTap: onTap ?? () {},
        );

    testWidgets('renders one chip per item across all groups', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        SubfilterBar(
          groups: <List<SubfilterChipData>>[
            <SubfilterChipData>[chip('A'), chip('B')],
            <SubfilterChipData>[chip('C')],
          ],
        ),
      );

      expect(find.byType(FilterTabChip), findsNWidgets(3));
    });

    testWidgets('drops empty groups', (WidgetTester tester) async {
      await tester.pumpApp(
        SubfilterBar(
          groups: <List<SubfilterChipData>>[
            <SubfilterChipData>[chip('A')],
            const <SubfilterChipData>[],
          ],
        ),
      );

      expect(find.byType(FilterTabChip), findsOneWidget);
    });

    testWidgets('renders nothing when every group is empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        const SubfilterBar(
          groups: <List<SubfilterChipData>>[
            <SubfilterChipData>[],
            <SubfilterChipData>[],
          ],
        ),
      );

      expect(find.byType(FilterTabChip), findsNothing);
    });

    testWidgets('fires onTap when a chip is tapped', (
      WidgetTester tester,
    ) async {
      bool tapped = false;
      await tester.pumpApp(
        SubfilterBar(
          groups: <List<SubfilterChipData>>[
            <SubfilterChipData>[chip('A', onTap: () => tapped = true)],
          ],
        ),
      );

      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    BoxDecoration stripDecoration(WidgetTester tester) {
      return tester
              .widget<AnimatedContainer>(
                find.descendant(
                  of: find.byType(SubfilterBar),
                  matching: find.byType(AnimatedContainer),
                ),
              )
              .decoration!
          as BoxDecoration;
    }

    testWidgets('strip is not highlighted when nothing is selected', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        SubfilterBar(
          groups: <List<SubfilterChipData>>[
            <SubfilterChipData>[chip('A'), chip('B')],
          ],
        ),
      );

      expect(stripDecoration(tester).color, Colors.transparent);
    });

    testWidgets('strip is highlighted when any subfilter is selected', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        SubfilterBar(
          groups: <List<SubfilterChipData>>[
            <SubfilterChipData>[chip('A', selected: true), chip('B')],
          ],
        ),
      );

      expect(stripDecoration(tester).color, isNot(Colors.transparent));
    });
  });
}
