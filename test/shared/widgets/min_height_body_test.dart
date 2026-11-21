import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/widgets/min_height_body.dart';

void main() {
  group('MinHeightBody', () {
    Widget host(double height) => MaterialApp(
          home: Center(
            child: SizedBox(
              width: 400,
              height: height,
              child: const MinHeightBody(
                child: Column(
                  children: <Widget>[
                    SizedBox(height: 100, key: Key('bar')),
                    Expanded(child: SizedBox.expand(key: Key('content'))),
                  ],
                ),
              ),
            ),
          ),
        );

    testWidgets('should hand the child the full height when it is enough',
        (WidgetTester tester) async {
      await tester.pumpWidget(host(kMinBodyHeight + 200));
      expect(
        tester.getSize(find.byKey(const Key('content'))).height,
        kMinBodyHeight + 100,
      );
    });

    testWidgets('should scroll a floor-high child when the viewport is shorter',
        (WidgetTester tester) async {
      await tester.pumpWidget(host(30));
      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const Key('bar'))).height,
        100,
      );
    });

    testWidgets('should keep the child state when the viewport shrinks',
        (WidgetTester tester) async {
      Widget hostWithField(double height) => MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 400,
                  height: height,
                  child: const MinHeightBody(child: TextField()),
                ),
              ),
            ),
          );

      await tester.pumpWidget(hostWithField(kMinBodyHeight + 200));
      final State<StatefulWidget> before = tester.state(find.byType(TextField));
      await tester.tap(find.byType(TextField));
      await tester.pump();

      await tester.pumpWidget(hostWithField(kMinBodyHeight - 50));

      expect(tester.state(find.byType(TextField)), same(before));
      expect(tester.testTextInput.isVisible, isTrue);
    });

    testWidgets('should leave the primary scroll controller to the child', (
      WidgetTester tester,
    ) async {
      // Mobile is where a vertical scroll view claims the route's controller.
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MinHeightBody(
              child: ListView(
                children: const <Widget>[SizedBox(height: 50, key: Key('row'))],
              ),
            ),
          ),
        ),
      );

      final ScrollController primary = PrimaryScrollController.of(
        tester.element(find.byType(MinHeightBody)),
      );
      final ScrollPosition list = Scrollable.of(
        tester.element(find.byKey(const Key('row'))),
      ).position;
      final bool listIsPrimary =
          primary.positions.length == 1 && primary.position == list;
      debugDefaultTargetPlatformOverride = null;

      expect(listIsPrimary, isTrue);
    });
  });
}
