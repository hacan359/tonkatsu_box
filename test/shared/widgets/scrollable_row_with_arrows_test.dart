import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/widgets/scrollable_row_with_arrows.dart';

void main() {
  group('ScrollableRowWithArrows', () {
    Widget buildTestWidget({
      required ScrollController controller,
      double screenWidth = 800,
      int itemCount = 50,
    }) {
      return MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(screenWidth, 600)),
          child: Scaffold(
            body: ScrollableRowWithArrows(
              controller: controller,
              height: 200,
              child: SizedBox(
                height: 200,
                child: ListView.builder(
                  controller: controller,
                  scrollDirection: Axis.horizontal,
                  itemCount: itemCount,
                  itemBuilder: (BuildContext context, int index) {
                    return SizedBox(
                      width: 120,
                      child: Text('Item $index'),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('отображает дочерний виджет', (WidgetTester tester) async {
      final ScrollController controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        buildTestWidget(controller: controller, itemCount: 3),
      );

      expect(find.byType(ScrollableRowWithArrows), findsOneWidget);
      expect(find.text('Item 0'), findsOneWidget);
    });

    testWidgets(
      'показывает правую стрелку при переполнении на десктопе (width >= 600)',
      (WidgetTester tester) async {
        final ScrollController controller = ScrollController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          buildTestWidget(
            controller: controller,
            screenWidth: 800,
            itemCount: 50,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
        expect(find.byIcon(Icons.chevron_left), findsNothing);
      },
    );

    testWidgets(
      'не показывает стрелки на мобильном (width < 600)',
      (WidgetTester tester) async {
        final ScrollController controller = ScrollController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          buildTestWidget(
            controller: controller,
            screenWidth: 500,
            itemCount: 50,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.chevron_left), findsNothing);
        expect(find.byIcon(Icons.chevron_right), findsNothing);
      },
    );

    testWidgets(
      'левая стрелка появляется после скролла вправо',
      (WidgetTester tester) async {
        final ScrollController controller = ScrollController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          buildTestWidget(
            controller: controller,
            screenWidth: 800,
            itemCount: 50,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.chevron_left), findsNothing);

        controller.jumpTo(200);
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.chevron_left), findsOneWidget);
        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      },
    );

    testWidgets(
      'правая стрелка исчезает при прокрутке до конца',
      (WidgetTester tester) async {
        final ScrollController controller = ScrollController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          buildTestWidget(
            controller: controller,
            screenWidth: 800,
            itemCount: 50,
          ),
        );
        await tester.pumpAndSettle();

        controller.jumpTo(controller.position.maxScrollExtent);
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.chevron_right), findsNothing);
        expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      },
    );

    testWidgets(
      'нажатие на правую стрелку прокручивает контент',
      (WidgetTester tester) async {
        final ScrollController controller = ScrollController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          buildTestWidget(
            controller: controller,
            screenWidth: 800,
            itemCount: 50,
          ),
        );
        await tester.pumpAndSettle();

        expect(controller.offset, equals(0.0));

        await tester.tap(find.byIcon(Icons.chevron_right));
        await tester.pumpAndSettle();

        expect(controller.offset, equals(300.0));
      },
    );

    testWidgets(
      'нажатие на левую стрелку прокручивает контент назад',
      (WidgetTester tester) async {
        final ScrollController controller = ScrollController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          buildTestWidget(
            controller: controller,
            screenWidth: 800,
            itemCount: 50,
          ),
        );
        await tester.pumpAndSettle();

        controller.jumpTo(600);
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.chevron_left), findsOneWidget);

        await tester.tap(find.byIcon(Icons.chevron_left));
        await tester.pumpAndSettle();

        expect(controller.offset, equals(300.0));
      },
    );

    testWidgets(
      'стрелки не показываются когда контент помещается без прокрутки',
      (WidgetTester tester) async {
        final ScrollController controller = ScrollController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          buildTestWidget(
            controller: controller,
            screenWidth: 800,
            itemCount: 3,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.chevron_left), findsNothing);
        expect(find.byIcon(Icons.chevron_right), findsNothing);
      },
    );

    testWidgets(
      'правая стрелка не прокручивает дальше maxScrollExtent',
      (WidgetTester tester) async {
        final ScrollController controller = ScrollController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          buildTestWidget(
            controller: controller,
            screenWidth: 800,
            itemCount: 10,
          ),
        );
        await tester.pumpAndSettle();

        final double maxExtent = controller.position.maxScrollExtent;

        controller.jumpTo(maxExtent - 100);
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.chevron_right));
        await tester.pumpAndSettle();

        expect(controller.offset, equals(maxExtent));
      },
    );

    testWidgets(
      'левая стрелка не прокручивает ниже 0',
      (WidgetTester tester) async {
        final ScrollController controller = ScrollController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          buildTestWidget(
            controller: controller,
            screenWidth: 800,
            itemCount: 50,
          ),
        );
        await tester.pumpAndSettle();

        controller.jumpTo(100);
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.chevron_left));
        await tester.pumpAndSettle();

        expect(controller.offset, equals(0.0));
      },
    );

    testWidgets(
      'граница 600px — при ровно 600 стрелки показываются',
      (WidgetTester tester) async {
        final ScrollController controller = ScrollController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          buildTestWidget(
            controller: controller,
            screenWidth: 600,
            itemCount: 50,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      },
    );

    testWidgets(
      'граница 599px — стрелки не показываются',
      (WidgetTester tester) async {
        final ScrollController controller = ScrollController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          buildTestWidget(
            controller: controller,
            screenWidth: 599,
            itemCount: 50,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.chevron_left), findsNothing);
        expect(find.byIcon(Icons.chevron_right), findsNothing);
      },
    );
  });
}
