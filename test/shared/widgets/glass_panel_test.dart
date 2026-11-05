import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/widgets/glass_panel.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('GlassPanel', () {
    testWidgets('без размытия не ставит BackdropFilter', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        const GlassPanel(blurSigma: 0, child: SizedBox(width: 10, height: 10)),
      );

      expect(find.byType(BackdropFilter), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('с размытием ставит ровно один BackdropFilter', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        const GlassPanel(blurSigma: 5, child: SizedBox(width: 10, height: 10)),
      );

      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('рисует ребёнка', (WidgetTester tester) async {
      await tester.pumpApp(const GlassPanel(child: Text('inside')));

      expect(find.text('inside'), findsOneWidget);
    });
  });

  group('GlassTile', () {
    testWidgets('кладёт фон под ребёнка', (WidgetTester tester) async {
      const Key bg = Key('bg');
      await tester.pumpApp(
        const GlassTile(
          background: ColoredBox(key: bg, color: Colors.red),
          child: Text('inside'),
        ),
      );

      expect(find.byKey(bg), findsOneWidget);
      expect(find.text('inside'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('без фона обходится без Stack', (WidgetTester tester) async {
      await tester.pumpApp(const GlassTile(child: Text('inside')));

      expect(
        find.descendant(
          of: find.byType(GlassTile),
          matching: find.byType(Stack),
        ),
        findsNothing,
      );
    });
  });
}
