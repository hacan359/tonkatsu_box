import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/widgets/logo_loader.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('LogoLoader', () {
    testWidgets('renders and keeps animating without errors',
        (WidgetTester tester) async {
      await tester.pumpApp(
        const Center(child: LogoLoader()),
        wrapInScaffold: true,
        settle: false, // the loader animates forever; pumpAndSettle would hang
      );
      expect(find.byType(LogoLoader), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Advance through several full pulse cycles: the looping animation
      // must keep building without throwing.
      for (int i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('honours the size parameter', (WidgetTester tester) async {
      await tester.pumpApp(
        const Center(child: LogoLoader(size: 96)),
        wrapInScaffold: true,
        settle: false,
      );
      expect(tester.getSize(find.byType(LogoLoader)), const Size(96, 96));
    });

    testWidgets('disposes cleanly mid-animation', (WidgetTester tester) async {
      await tester.pumpApp(
        const Center(child: LogoLoader()),
        wrapInScaffold: true,
        settle: false,
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpApp(const SizedBox.shrink(), settle: false);
      expect(find.byType(LogoLoader), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
