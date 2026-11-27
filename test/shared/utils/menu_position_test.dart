import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tonkatsu_box/shared/utils/menu_position.dart';

void main() {
  group('toMenuSpace', () {
    testWidgets('should subtract the offset of the navigator it sits in', (
      WidgetTester tester,
    ) async {
      late BuildContext page;
      await tester.pumpWidget(
        MaterialApp(
          home: Padding(
            padding: const EdgeInsets.only(left: 100, top: 50),
            child: Navigator(
              onGenerateRoute: (_) => MaterialPageRoute<void>(
                builder: (BuildContext context) {
                  page = context;
                  return const SizedBox.expand();
                },
              ),
            ),
          ),
        ),
      );

      expect(toMenuSpace(page, const Offset(150, 80)), const Offset(50, 30));
      expect(
        menuRectAt(page, const Offset(150, 80)),
        const RelativeRect.fromLTRB(50, 30, 50, 30),
      );
    });

    testWidgets('should leave the point alone in a full-screen navigator', (
      WidgetTester tester,
    ) async {
      late BuildContext page;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              page = context;
              return const SizedBox.expand();
            },
          ),
        ),
      );

      expect(toMenuSpace(page, const Offset(150, 80)), const Offset(150, 80));
    });
  });
}
