// Widget tests for HorizontalMouseScroll.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/widgets/horizontal_mouse_scroll.dart';

void main() {
  group('HorizontalMouseScroll', () {
    testWidgets('renders child widget', (WidgetTester tester) async {
      final ScrollController controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HorizontalMouseScroll(
              controller: controller,
              child: const Text('Hello'),
            ),
          ),
        ),
      );

      expect(find.text('Hello'), findsOneWidget);
      expect(find.byType(HorizontalMouseScroll), findsOneWidget);
    });

    testWidgets('forwards vertical scroll delta to horizontal controller',
        (WidgetTester tester) async {
      final ScrollController controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HorizontalMouseScroll(
              controller: controller,
              child: SizedBox(
                height: 100,
                child: ListView.builder(
                  controller: controller,
                  scrollDirection: Axis.horizontal,
                  itemCount: 50,
                  itemBuilder: (BuildContext context, int index) {
                    return SizedBox(
                      width: 100,
                      child: Text('Item $index'),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      expect(controller.offset, equals(0.0));

      // Simulate a mouse scroll event on the HorizontalMouseScroll widget.
      final Offset center =
          tester.getCenter(find.byType(HorizontalMouseScroll));
      final TestPointer pointer = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(pointer.hover(center));
      await tester.sendEventToBinding(
        pointer.scroll(const Offset(0, 50)),
      );
      await tester.pump();

      expect(controller.offset, equals(50.0));
    });

    testWidgets('clamps scroll offset to valid range',
        (WidgetTester tester) async {
      final ScrollController controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HorizontalMouseScroll(
              controller: controller,
              child: SizedBox(
                height: 100,
                child: ListView.builder(
                  controller: controller,
                  scrollDirection: Axis.horizontal,
                  itemCount: 50,
                  itemBuilder: (BuildContext context, int index) {
                    return SizedBox(
                      width: 100,
                      child: Text('Item $index'),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      // Try to scroll backwards beyond 0 — should clamp to 0.
      final Offset center =
          tester.getCenter(find.byType(HorizontalMouseScroll));
      final TestPointer pointer = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(pointer.hover(center));
      await tester.sendEventToBinding(
        pointer.scroll(const Offset(0, -200)),
      );
      await tester.pump();

      expect(controller.offset, equals(0.0));
    });

    testWidgets('does nothing when controller has no clients',
        (WidgetTester tester) async {
      final ScrollController controller = ScrollController();
      addTearDown(controller.dispose);

      // Build a widget where the controller is NOT attached to any scrollable.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HorizontalMouseScroll(
              controller: controller,
              child: const SizedBox(
                width: 200,
                height: 100,
                child: Text('No scrollable'),
              ),
            ),
          ),
        ),
      );

      expect(controller.hasClients, isFalse);

      // Sending a scroll event should not throw.
      final Offset center =
          tester.getCenter(find.byType(HorizontalMouseScroll));
      final TestPointer pointer = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(pointer.hover(center));
      await tester.sendEventToBinding(
        pointer.scroll(const Offset(0, 50)),
      );
      await tester.pump();

      // No crash, controller still has no clients.
      expect(controller.hasClients, isFalse);
    });
  });
}
