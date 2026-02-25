// Widget-тесты для ScrollableRowWithArrows.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/widgets/scrollable_row_with_arrows.dart';

void main() {
  group('ScrollableRowWithArrows', () {
    /// Создаёт тестовый виджет с заданной шириной экрана.
    ///
    /// [screenWidth] — ширина окна (>= 600 для десктопа, < 600 для мобильного).
    /// [itemCount] — количество элементов в горизонтальном списке.
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

        // 50 элементов по 120px = 6000px, экран 800px → есть переполнение.
        // Правая стрелка должна быть видна.
        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
        // Левая стрелка не видна — мы в начале списка.
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

        // На мобильных стрелки не показываются вне зависимости от переполнения.
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

        // Изначально левой стрелки нет.
        expect(find.byIcon(Icons.chevron_left), findsNothing);

        // Прокручиваем вправо программно.
        controller.jumpTo(200);
        await tester.pumpAndSettle();

        // Теперь левая стрелка должна появиться.
        expect(find.byIcon(Icons.chevron_left), findsOneWidget);
        // Правая стрелка всё ещё видна (не достигли конца).
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

        // Прокручиваем до конца.
        controller.jumpTo(controller.position.maxScrollExtent);
        await tester.pumpAndSettle();

        // Правая стрелка должна исчезнуть.
        expect(find.byIcon(Icons.chevron_right), findsNothing);
        // Левая стрелка должна быть видна.
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

        // Начальная позиция — 0.
        expect(controller.offset, equals(0.0));

        // Нажимаем на правую стрелку.
        await tester.tap(find.byIcon(Icons.chevron_right));
        await tester.pumpAndSettle();

        // Позиция должна сдвинуться вправо (на 300px — значение из _scrollBy).
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

        // Прокручиваем в середину.
        controller.jumpTo(600);
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.chevron_left), findsOneWidget);

        // Нажимаем на левую стрелку.
        await tester.tap(find.byIcon(Icons.chevron_left));
        await tester.pumpAndSettle();

        // Должно сместиться на 300 назад: 600 - 300 = 300.
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
            // 3 элемента по 120px = 360px < 800px — без переполнения.
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
            // 10 элементов по 120px = 1200px, maxScrollExtent = 1200 - 800 = 400.
            itemCount: 10,
          ),
        );
        await tester.pumpAndSettle();

        final double maxExtent = controller.position.maxScrollExtent;

        // Прокручиваем близко к концу (меньше 300 до конца).
        controller.jumpTo(maxExtent - 100);
        await tester.pumpAndSettle();

        // Нажимаем правую стрелку — должно прокрутить до maxExtent, а не дальше.
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

        // Прокручиваем на 100px (меньше чем шаг 300).
        controller.jumpTo(100);
        await tester.pumpAndSettle();

        // Нажимаем левую стрелку — должно остановиться на 0, а не уйти в минус.
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

        // Ровно 600px — десктопный режим, стрелки должны быть.
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

        // 599px — мобильный режим, стрелки скрыты.
        expect(find.byIcon(Icons.chevron_left), findsNothing);
        expect(find.byIcon(Icons.chevron_right), findsNothing);
      },
    );
  });
}
