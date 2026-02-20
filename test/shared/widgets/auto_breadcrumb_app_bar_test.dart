// Тесты для AutoBreadcrumbAppBar.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/widgets/auto_breadcrumb_app_bar.dart';
import 'package:xerabora/shared/widgets/breadcrumb_app_bar.dart';
import 'package:xerabora/shared/widgets/breadcrumb_scope.dart';

void main() {
  group('AutoBreadcrumbAppBar', () {
    group('Сборка крошек из scope', () {
      testWidgets('без scope — пустые крошки',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              appBar: AutoBreadcrumbAppBar(),
              body: SizedBox(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Должен рендериться BreadcrumbAppBar
        expect(find.byType(BreadcrumbAppBar), findsOneWidget);
        // Без крошек — только корень /
        expect(find.text('/'), findsOneWidget);
      });

      testWidgets('один scope — одна крошка (текущая, без onTap)',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: BreadcrumbScope(
              label: 'Settings',
              child: Scaffold(
                appBar: AutoBreadcrumbAppBar(),
                body: SizedBox(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Settings'), findsOneWidget);
        // Единственная крошка — текущая, не кликабельна
        final Finder mouseRegion = find.ancestor(
          of: find.text('Settings'),
          matching: find.byType(MouseRegion),
        );
        expect(mouseRegion, findsNothing);
      });

      testWidgets('два scope — первая кликабельна, вторая — текущая',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: BreadcrumbScope(
              label: 'Settings',
              child: BreadcrumbScope(
                label: 'Credentials',
                child: Scaffold(
                  appBar: AutoBreadcrumbAppBar(),
                  body: SizedBox(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Settings'), findsOneWidget);
        expect(find.text('Credentials'), findsOneWidget);

        // Settings — кликабельна (GestureDetector)
        final Finder settingsGesture = find.ancestor(
          of: find.text('Settings'),
          matching: find.byType(GestureDetector),
        );
        expect(settingsGesture, findsOneWidget);

        // Credentials — текущая, не кликабельна
        final Finder credentialsMouseRegion = find.ancestor(
          of: find.text('Credentials'),
          matching: find.byType(MouseRegion),
        );
        expect(credentialsMouseRegion, findsNothing);
      });

      testWidgets('три scope — первая и средняя кликабельны, последняя нет',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: BreadcrumbScope(
              label: 'Settings',
              child: BreadcrumbScope(
                label: 'Debug',
                child: BreadcrumbScope(
                  label: 'SteamGridDB',
                  child: Scaffold(
                    appBar: AutoBreadcrumbAppBar(),
                    body: SizedBox(),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Settings'), findsOneWidget);
        expect(find.text('Debug'), findsOneWidget);
        expect(find.text('SteamGridDB'), findsOneWidget);

        // Settings и Debug — кликабельны
        final Finder settingsGesture = find.ancestor(
          of: find.text('Settings'),
          matching: find.byType(GestureDetector),
        );
        expect(settingsGesture, findsOneWidget);

        final Finder debugGesture = find.ancestor(
          of: find.text('Debug'),
          matching: find.byType(GestureDetector),
        );
        expect(debugGesture, findsOneWidget);

        // SteamGridDB — текущая, не кликабельна
        final Finder steamMouseRegion = find.ancestor(
          of: find.text('SteamGridDB'),
          matching: find.byType(MouseRegion),
        );
        expect(steamMouseRegion, findsNothing);
      });
    });

    group('Пробрасывание параметров', () {
      testWidgets('actions передаются в BreadcrumbAppBar',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: BreadcrumbScope(
              label: 'Settings',
              child: Scaffold(
                appBar: AutoBreadcrumbAppBar(
                  actions: <Widget>[
                    IconButton(
                      icon: Icon(Icons.refresh),
                      onPressed: null,
                    ),
                  ],
                ),
                body: SizedBox(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.refresh), findsOneWidget);
      });

      testWidgets('bottom передаётся в BreadcrumbAppBar',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: DefaultTabController(
              length: 2,
              child: BreadcrumbScope(
                label: 'Search',
                child: Scaffold(
                  appBar: AutoBreadcrumbAppBar(
                    bottom: TabBar(
                      tabs: <Tab>[
                        Tab(text: 'Games'),
                        Tab(text: 'Movies'),
                      ],
                    ),
                  ),
                  body: SizedBox(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Games'), findsOneWidget);
        expect(find.text('Movies'), findsOneWidget);
      });
    });

    group('PreferredSize', () {
      testWidgets('без bottom — kBreadcrumbToolbarHeight',
          (WidgetTester tester) async {
        const AutoBreadcrumbAppBar appBar = AutoBreadcrumbAppBar();
        expect(appBar.preferredSize.height, kBreadcrumbToolbarHeight);
      });

      testWidgets('с TabBar bottom — включает его высоту',
          (WidgetTester tester) async {
        const double tabBarHeight = 48;
        const AutoBreadcrumbAppBar appBar = AutoBreadcrumbAppBar(
          bottom: TabBar(
            tabs: <Tab>[
              Tab(text: 'Tab1'),
              Tab(text: 'Tab2'),
            ],
          ),
        );
        expect(
          appBar.preferredSize.height,
          kBreadcrumbToolbarHeight + tabBarHeight,
        );
      });
    });

    group('Scope через Navigator', () {
      testWidgets('scope выше Navigator виден в pushed route',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: BreadcrumbScope(
              label: 'TabRoot',
              child: Navigator(
                onGenerateRoute: (RouteSettings settings) {
                  return MaterialPageRoute<void>(
                    builder: (BuildContext context) {
                      return const BreadcrumbScope(
                        label: 'Screen',
                        child: Scaffold(
                          appBar: AutoBreadcrumbAppBar(),
                          body: SizedBox(),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Обе крошки видны
        expect(find.text('TabRoot'), findsOneWidget);
        expect(find.text('Screen'), findsOneWidget);
      });
    });
  });
}
