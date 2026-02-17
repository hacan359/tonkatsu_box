// Тесты для виджета BreadcrumbAppBar.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/theme/app_colors.dart';
import 'package:xerabora/shared/widgets/breadcrumb_app_bar.dart';

void main() {
  group('BreadcrumbAppBar', () {
    /// Создает виджет для тестирования с заданными хлебными крошками.
    Widget createWidget({
      required List<BreadcrumbItem> crumbs,
      List<Widget>? actions,
      PreferredSizeWidget? bottom,
      Size? surfaceSize,
    }) {
      return MaterialApp(
        home: Scaffold(
          appBar: BreadcrumbAppBar(
            crumbs: crumbs,
            actions: actions,
            bottom: bottom,
          ),
          body: const SizedBox(),
        ),
      );
    }

    group('Рендеринг базовых элементов', () {
      testWidgets('отображает разделитель \'›\' для каждой хлебной крошки',
          (WidgetTester tester) async {
        const List<BreadcrumbItem> crumbs = <BreadcrumbItem>[
          BreadcrumbItem(label: 'Первый'),
          BreadcrumbItem(label: 'Второй'),
          BreadcrumbItem(label: 'Третий'),
        ];

        await tester.pumpWidget(createWidget(crumbs: crumbs));
        await tester.pumpAndSettle();

        // 3 разделителя (по одному перед каждой крошкой)
        final Finder separators = find.text('›');
        expect(separators, findsNWidgets(3));
      });

      testWidgets('отображает метки всех хлебных крошек',
          (WidgetTester tester) async {
        const List<BreadcrumbItem> crumbs = <BreadcrumbItem>[
          BreadcrumbItem(label: 'Коллекции'),
          BreadcrumbItem(label: 'Моя коллекция'),
          BreadcrumbItem(label: 'Игра'),
        ];

        await tester.pumpWidget(createWidget(crumbs: crumbs));
        await tester.pumpAndSettle();

        expect(find.text('Коллекции'), findsOneWidget);
        expect(find.text('Моя коллекция'), findsOneWidget);
        expect(find.text('Игра'), findsOneWidget);
      });

      testWidgets('отображает одну хлебную крошку корректно',
          (WidgetTester tester) async {
        const List<BreadcrumbItem> crumbs = <BreadcrumbItem>[
          BreadcrumbItem(label: 'Единственная крошка'),
        ];

        await tester.pumpWidget(createWidget(crumbs: crumbs));
        await tester.pumpAndSettle();

        expect(find.text('Единственная крошка'), findsOneWidget);
        expect(find.text('›'), findsOneWidget);
      });
    });

    group('Адаптивный корень', () {
      testWidgets('на desktop (>=800) отображает \'/\' вместо логотипа',
          (WidgetTester tester) async {
        // По умолчанию тестовое окно 800x600 — это desktop
        const List<BreadcrumbItem> crumbs = <BreadcrumbItem>[
          BreadcrumbItem(label: 'Settings'),
        ];

        await tester.pumpWidget(createWidget(crumbs: crumbs));
        await tester.pumpAndSettle();

        expect(find.text('/'), findsOneWidget);
        expect(find.byType(Image), findsNothing);
      });

      testWidgets('на mobile (<800) отображает логотип вместо \'/\'',
          (WidgetTester tester) async {
        tester.view.physicalSize = const Size(700, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const List<BreadcrumbItem> crumbs = <BreadcrumbItem>[
          BreadcrumbItem(label: 'Settings'),
        ];

        await tester.pumpWidget(createWidget(crumbs: crumbs));
        await tester.pumpAndSettle();

        expect(find.byType(Image), findsOneWidget);
        expect(find.text('/'), findsNothing);
      });

      testWidgets('на mobile логотип обёрнут в GestureDetector',
          (WidgetTester tester) async {
        tester.view.physicalSize = const Size(700, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const List<BreadcrumbItem> crumbs = <BreadcrumbItem>[
          BreadcrumbItem(label: 'Settings'),
        ];

        await tester.pumpWidget(createWidget(crumbs: crumbs));
        await tester.pumpAndSettle();

        final Finder gestureDetector = find.ancestor(
          of: find.byType(Image),
          matching: find.byType(GestureDetector),
        );
        expect(gestureDetector, findsOneWidget);
      });
    });

    group('Стилизация текста', () {
      testWidgets('последняя хлебная крошка имеет fontWeight w500',
          (WidgetTester tester) async {
        const List<BreadcrumbItem> crumbs = <BreadcrumbItem>[
          BreadcrumbItem(label: 'Первый'),
          BreadcrumbItem(label: 'Последний'),
        ];

        await tester.pumpWidget(createWidget(crumbs: crumbs));
        await tester.pumpAndSettle();

        final Finder lastCrumb = find.text('Последний');
        final Text lastCrumbWidget = tester.widget<Text>(lastCrumb);
        expect(lastCrumbWidget.style?.fontWeight, FontWeight.w500);
      });

      testWidgets('последняя крошка имеет цвет textSecondary',
          (WidgetTester tester) async {
        const List<BreadcrumbItem> crumbs = <BreadcrumbItem>[
          BreadcrumbItem(label: 'Первый'),
          BreadcrumbItem(label: 'Последний'),
        ];

        await tester.pumpWidget(createWidget(crumbs: crumbs));
        await tester.pumpAndSettle();

        final Text lastCrumb = tester.widget<Text>(find.text('Последний'));
        expect(lastCrumb.style?.color, AppColors.textSecondary);
      });

      testWidgets('не последние кликабельные крошки имеют цвет textTertiary',
          (WidgetTester tester) async {
        final List<BreadcrumbItem> crumbs = <BreadcrumbItem>[
          BreadcrumbItem(label: 'Первый', onTap: () {}),
          BreadcrumbItem(label: 'Второй', onTap: () {}),
          const BreadcrumbItem(label: 'Последний'),
        ];

        await tester.pumpWidget(createWidget(crumbs: crumbs));
        await tester.pumpAndSettle();

        final Text firstCrumb = tester.widget<Text>(find.text('Первый'));
        expect(firstCrumb.style?.color, AppColors.textTertiary);

        final Text secondCrumb = tester.widget<Text>(find.text('Второй'));
        expect(secondCrumb.style?.color, AppColors.textTertiary);
      });

      testWidgets('не последние кликабельные крошки имеют fontWeight w400',
          (WidgetTester tester) async {
        final List<BreadcrumbItem> crumbs = <BreadcrumbItem>[
          BreadcrumbItem(label: 'Первый', onTap: () {}),
          const BreadcrumbItem(label: 'Последний'),
        ];

        await tester.pumpWidget(createWidget(crumbs: crumbs));
        await tester.pumpAndSettle();

        final Text firstCrumb = tester.widget<Text>(find.text('Первый'));
        expect(firstCrumb.style?.fontWeight, FontWeight.w400);
      });

      testWidgets('разделители имеют цвет textTertiary',
          (WidgetTester tester) async {
        const List<BreadcrumbItem> crumbs = <BreadcrumbItem>[
          BreadcrumbItem(label: 'Первый'),
          BreadcrumbItem(label: 'Второй'),
        ];

        await tester.pumpWidget(createWidget(crumbs: crumbs));
        await tester.pumpAndSettle();

        final Finder separators = find.text('›');
        for (final Element element in separators.evaluate()) {
          final Text separatorWidget = element.widget as Text;
          expect(separatorWidget.style?.color, AppColors.textTertiary);
        }
      });
    });

    group('Ховер-эффект', () {
      testWidgets('кликабельная крошка обёрнута в MouseRegion',
          (WidgetTester tester) async {
        final List<BreadcrumbItem> crumbs = <BreadcrumbItem>[
          BreadcrumbItem(label: 'Кликабельная', onTap: () {}),
          const BreadcrumbItem(label: 'Последняя'),
        ];

        await tester.pumpWidget(createWidget(crumbs: crumbs));
        await tester.pumpAndSettle();

        final Finder mouseRegion = find.ancestor(
          of: find.text('Кликабельная'),
          matching: find.byType(MouseRegion),
        );
        expect(mouseRegion, findsOneWidget);
      });

      testWidgets('при наведении цвет крошки меняется на textPrimary',
          (WidgetTester tester) async {
        final List<BreadcrumbItem> crumbs = <BreadcrumbItem>[
          BreadcrumbItem(label: 'Ховер', onTap: () {}),
          const BreadcrumbItem(label: 'Последняя'),
        ];

        await tester.pumpWidget(createWidget(crumbs: crumbs));
        await tester.pumpAndSettle();

        // До ховера — textTertiary
        Text crumbText = tester.widget<Text>(find.text('Ховер'));
        expect(crumbText.style?.color, AppColors.textTertiary);

        // Симулируем наведение мыши
        final TestGesture gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);

        await gesture.moveTo(tester.getCenter(find.text('Ховер')));
        await tester.pumpAndSettle();

        // После ховера — textPrimary
        crumbText = tester.widget<Text>(find.text('Ховер'));
        expect(crumbText.style?.color, AppColors.textPrimary);

        // Убираем мышь — обратно textTertiary
        await gesture.moveTo(const Offset(0, 0));
        await tester.pumpAndSettle();

        crumbText = tester.widget<Text>(find.text('Ховер'));
        expect(crumbText.style?.color, AppColors.textTertiary);
      });

      testWidgets('кликабельная крошка показывает курсор click',
          (WidgetTester tester) async {
        final List<BreadcrumbItem> crumbs = <BreadcrumbItem>[
          BreadcrumbItem(label: 'Кликабельная', onTap: () {}),
          const BreadcrumbItem(label: 'Последняя'),
        ];

        await tester.pumpWidget(createWidget(crumbs: crumbs));
        await tester.pumpAndSettle();

        final Finder mouseRegion = find.ancestor(
          of: find.text('Кликабельная'),
          matching: find.byType(MouseRegion),
        );
        final MouseRegion region = tester.widget<MouseRegion>(mouseRegion);
        expect(region.cursor, SystemMouseCursors.click);
      });

      testWidgets('последняя крошка НЕ обёрнута в MouseRegion',
          (WidgetTester tester) async {
        final List<BreadcrumbItem> crumbs = <BreadcrumbItem>[
          BreadcrumbItem(label: 'Первый', onTap: () {}),
          const BreadcrumbItem(label: 'Последняя'),
        ];

        await tester.pumpWidget(createWidget(crumbs: crumbs));
        await tester.pumpAndSettle();

        final Finder mouseRegion = find.ancestor(
          of: find.text('Последняя'),
          matching: find.byType(MouseRegion),
        );
        expect(mouseRegion, findsNothing);
      });
    });

    group('Взаимодействие с onTap', () {
      testWidgets('срабатывает onTap при нажатии на не последнюю крошку',
          (WidgetTester tester) async {
        bool firstTapped = false;
        bool secondTapped = false;
        final List<BreadcrumbItem> crumbs = <BreadcrumbItem>[
          BreadcrumbItem(label: 'Первый', onTap: () => firstTapped = true),
          BreadcrumbItem(label: 'Второй', onTap: () => secondTapped = true),
          const BreadcrumbItem(label: 'Последний'),
        ];

        await tester.pumpWidget(createWidget(crumbs: crumbs));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Первый'));
        await tester.pumpAndSettle();

        expect(firstTapped, isTrue);
        expect(secondTapped, isFalse);

        await tester.tap(find.text('Второй'));
        await tester.pumpAndSettle();

        expect(secondTapped, isTrue);
      });

      testWidgets('НЕ срабатывает onTap на последней крошке',
          (WidgetTester tester) async {
        bool lastTapped = false;
        final List<BreadcrumbItem> crumbs = <BreadcrumbItem>[
          const BreadcrumbItem(label: 'Первый'),
          BreadcrumbItem(label: 'Последний', onTap: () => lastTapped = true),
        ];

        await tester.pumpWidget(createWidget(crumbs: crumbs));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Последний'));
        await tester.pumpAndSettle();

        expect(lastTapped, isFalse);
      });

      testWidgets('крошка без onTap не обёрнута в GestureDetector',
          (WidgetTester tester) async {
        const List<BreadcrumbItem> crumbs = <BreadcrumbItem>[
          BreadcrumbItem(label: 'Без onTap'),
          BreadcrumbItem(label: 'Последний'),
        ];

        await tester.pumpWidget(createWidget(crumbs: crumbs));
        await tester.pumpAndSettle();

        expect(find.text('Без onTap'), findsOneWidget);
        final Finder gestureDetector = find.ancestor(
          of: find.text('Без onTap'),
          matching: find.byType(GestureDetector),
        );
        expect(gestureDetector, findsNothing);
      });
    });

    group('Actions и bottom', () {
      testWidgets('поддерживает actions (кнопки справа)',
          (WidgetTester tester) async {
        const List<BreadcrumbItem> crumbs = <BreadcrumbItem>[
          BreadcrumbItem(label: 'Коллекция'),
        ];
        final List<Widget> actions = <Widget>[
          const IconButton(
            icon: Icon(Icons.search),
            onPressed: null,
          ),
          const IconButton(
            icon: Icon(Icons.settings),
            onPressed: null,
          ),
        ];

        await tester.pumpWidget(createWidget(crumbs: crumbs, actions: actions));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.search), findsOneWidget);
        expect(find.byIcon(Icons.settings), findsOneWidget);
      });

      testWidgets('поддерживает bottom widget (TabBar)',
          (WidgetTester tester) async {
        const List<BreadcrumbItem> crumbs = <BreadcrumbItem>[
          BreadcrumbItem(label: 'Поиск'),
        ];
        const TabBar bottom = TabBar(
          tabs: <Tab>[
            Tab(text: 'Игры'),
            Tab(text: 'Фильмы'),
          ],
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: DefaultTabController(
              length: 2,
              child: Scaffold(
                appBar: BreadcrumbAppBar(
                  crumbs: crumbs,
                  bottom: bottom,
                ),
                body: SizedBox(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Игры'), findsOneWidget);
        expect(find.text('Фильмы'), findsOneWidget);
      });
    });

    group('PreferredSize', () {
      testWidgets('preferredSize включает высоту bottom',
          (WidgetTester tester) async {
        const List<BreadcrumbItem> crumbs = <BreadcrumbItem>[
          BreadcrumbItem(label: 'Коллекция'),
        ];
        const double tabBarHeight = 48;
        const TabBar bottom = TabBar(
          tabs: <Tab>[
            Tab(text: 'Таб 1'),
            Tab(text: 'Таб 2'),
          ],
        );

        const BreadcrumbAppBar appBar = BreadcrumbAppBar(
          crumbs: crumbs,
          bottom: bottom,
        );

        expect(
          appBar.preferredSize.height,
          kBreadcrumbToolbarHeight + tabBarHeight,
        );
      });

      testWidgets('preferredSize без bottom равна kBreadcrumbToolbarHeight',
          (WidgetTester tester) async {
        const List<BreadcrumbItem> crumbs = <BreadcrumbItem>[
          BreadcrumbItem(label: 'Коллекция'),
        ];

        const BreadcrumbAppBar appBar = BreadcrumbAppBar(crumbs: crumbs);

        expect(appBar.preferredSize.height, kBreadcrumbToolbarHeight);
      });
    });

    group('Макет и прокрутка', () {
      testWidgets('хлебные крошки прокручиваются горизонтально',
          (WidgetTester tester) async {
        const List<BreadcrumbItem> crumbs = <BreadcrumbItem>[
          BreadcrumbItem(label: 'Очень длинная первая крошка'),
          BreadcrumbItem(label: 'Очень длинная вторая крошка'),
          BreadcrumbItem(label: 'Очень длинная третья крошка'),
          BreadcrumbItem(label: 'Очень длинная четвертая крошка'),
        ];

        await tester.pumpWidget(createWidget(crumbs: crumbs));
        await tester.pumpAndSettle();

        expect(find.byType(SingleChildScrollView), findsOneWidget);
        final SingleChildScrollView scrollView =
            tester.widget<SingleChildScrollView>(
          find.byType(SingleChildScrollView),
        );
        expect(scrollView.scrollDirection, Axis.horizontal);
      });

      testWidgets('AppBar имеет корректную высоту toolbar',
          (WidgetTester tester) async {
        const List<BreadcrumbItem> crumbs = <BreadcrumbItem>[
          BreadcrumbItem(label: 'Коллекция'),
        ];

        await tester.pumpWidget(createWidget(crumbs: crumbs));
        await tester.pumpAndSettle();

        final AppBar appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.toolbarHeight, kBreadcrumbToolbarHeight);
      });
    });

    group('Граничные случаи', () {
      testWidgets('корректно работает с пустым списком крошек',
          (WidgetTester tester) async {
        const List<BreadcrumbItem> crumbs = <BreadcrumbItem>[];

        await tester.pumpWidget(createWidget(crumbs: crumbs));
        await tester.pumpAndSettle();

        expect(find.byType(AppBar), findsOneWidget);
        expect(find.text('›'), findsNothing);
      });

      testWidgets('множественные крошки отображают все метки',
          (WidgetTester tester) async {
        const List<BreadcrumbItem> crumbs = <BreadcrumbItem>[
          BreadcrumbItem(label: 'Один'),
          BreadcrumbItem(label: 'Два'),
          BreadcrumbItem(label: 'Три'),
          BreadcrumbItem(label: 'Четыре'),
          BreadcrumbItem(label: 'Пять'),
        ];

        await tester.pumpWidget(createWidget(crumbs: crumbs));
        await tester.pumpAndSettle();

        expect(find.text('Один'), findsOneWidget);
        expect(find.text('Два'), findsOneWidget);
        expect(find.text('Три'), findsOneWidget);
        expect(find.text('Четыре'), findsOneWidget);
        expect(find.text('Пять'), findsOneWidget);
        expect(find.text('›'), findsNWidgets(5));
      });
    });

    group('Стилизация AppBar', () {
      testWidgets('AppBar имеет прозрачный surfaceTintColor',
          (WidgetTester tester) async {
        const List<BreadcrumbItem> crumbs = <BreadcrumbItem>[
          BreadcrumbItem(label: 'Коллекция'),
        ];

        await tester.pumpWidget(createWidget(crumbs: crumbs));
        await tester.pumpAndSettle();

        final AppBar appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.surfaceTintColor, Colors.transparent);
      });

      testWidgets('AppBar имеет backgroundColor из темы',
          (WidgetTester tester) async {
        const List<BreadcrumbItem> crumbs = <BreadcrumbItem>[
          BreadcrumbItem(label: 'Коллекция'),
        ];

        await tester.pumpWidget(createWidget(crumbs: crumbs));
        await tester.pumpAndSettle();

        final AppBar appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.backgroundColor, AppColors.background);
      });

      testWidgets('AppBar не имеет автоматической кнопки назад',
          (WidgetTester tester) async {
        const List<BreadcrumbItem> crumbs = <BreadcrumbItem>[
          BreadcrumbItem(label: 'Коллекция'),
        ];

        await tester.pumpWidget(createWidget(crumbs: crumbs));
        await tester.pumpAndSettle();

        final AppBar appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.automaticallyImplyLeading, isFalse);
      });
    });
  });
}
