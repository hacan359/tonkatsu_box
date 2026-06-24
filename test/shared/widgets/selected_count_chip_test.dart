import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/widgets/selected_count_chip.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('SelectedCountChip', () {
    testWidgets('shows the selected count', (WidgetTester tester) async {
      await tester.pumpApp(
        SelectedCountChip(
          count: 3,
          onClear: () {},
          clearTooltip: 'Clear',
        ),
        wrapInScaffold: true,
      );

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('invokes onClear when tapped', (WidgetTester tester) async {
      int cleared = 0;
      await tester.pumpApp(
        SelectedCountChip(
          count: 2,
          onClear: () => cleared++,
          clearTooltip: 'Clear',
        ),
        wrapInScaffold: true,
      );

      await tester.tap(find.byType(SelectedCountChip));
      await tester.pump();

      expect(cleared, 1);
    });
  });
}
