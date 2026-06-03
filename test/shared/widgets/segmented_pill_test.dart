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
  });
}
