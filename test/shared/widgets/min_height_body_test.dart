import 'package:flutter/material.dart';
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
      expect(find.byType(SingleChildScrollView), findsNothing);
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
  });
}
