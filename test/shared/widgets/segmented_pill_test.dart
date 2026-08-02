import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/widgets/segmented_pill.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('SegmentedPill', () {
    testWidgets('renders every option label', (WidgetTester tester) async {
      await tester.pumpApp(
        SegmentedPill<String>(
          selected: 'a',
          onChanged: (_) {},
          options: const <SegmentedPillOption<String>>[
            SegmentedPillOption<String>(value: 'a', label: 'Alpha'),
            SegmentedPillOption<String>(value: 'b', label: 'Beta'),
            SegmentedPillOption<String>(value: 'c', label: 'Gamma'),
          ],
        ),
      );

      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
      expect(find.text('Gamma'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fires onChanged with the tapped value',
        (WidgetTester tester) async {
      String? tapped;
      await tester.pumpApp(
        SegmentedPill<String>(
          selected: 'a',
          onChanged: (String v) => tapped = v,
          options: const <SegmentedPillOption<String>>[
            SegmentedPillOption<String>(value: 'a', label: 'Alpha'),
            SegmentedPillOption<String>(value: 'b', label: 'Beta'),
          ],
        ),
      );

      await tester.tap(find.text('Beta'));
      await tester.pump();

      expect(tapped, 'b');
    });

    group('expand', () {
      // Options of deliberately unequal label length, so "equal widths" can
      // only come from the layout and not from the text.
      const List<SegmentedPillOption<String>> options =
          <SegmentedPillOption<String>>[
        SegmentedPillOption<String>(value: 'a', label: 'A'),
        SegmentedPillOption<String>(value: 'b', label: 'Considerably longer'),
      ];

      Iterable<double> segmentWidths(WidgetTester tester) => tester
          .widgetList<GestureDetector>(
            find.descendant(
              of: find.byWidgetPredicate((Widget w) => w is SegmentedPill),
              matching: find.byType(GestureDetector),
            ),
          )
          .map((GestureDetector d) => tester.getSize(find.byWidget(d)).width);

      testWidgets('should give segments equal widths when true', (
        WidgetTester tester,
      ) async {
        await tester.pumpApp(
          SegmentedPill<String>(
            expand: true,
            selected: 'a',
            onChanged: (_) {},
            options: options,
          ),
        );

        final List<double> widths = segmentWidths(tester).toList();
        expect(widths, hasLength(2));
        expect(widths.first, moreOrLessEquals(widths.last, epsilon: 0.5));
      });

      testWidgets('should size segments to their content when false', (
        WidgetTester tester,
      ) async {
        await tester.pumpApp(
          SegmentedPill<String>(
            selected: 'a',
            onChanged: (_) {},
            options: options,
          ),
        );

        final List<double> widths = segmentWidths(tester).toList();
        expect(widths, hasLength(2));
        expect(widths.first, lessThan(widths.last));
      });
    });
  });
}
