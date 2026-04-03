// Tests for ScreenAppBar — unified compact AppBar widget.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/widgets/screen_app_bar.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('ScreenAppBar', () {
    group('preferredSize', () {
      test('returns kScreenAppBarHeight when no bottom', () {
        const ScreenAppBar appBar = ScreenAppBar();
        expect(appBar.preferredSize.height, kScreenAppBarHeight);
      });

      test('includes bottom height when bottom is provided', () {
        const ScreenAppBar appBar = ScreenAppBar(
          bottom: TabBar(
            tabs: <Widget>[Tab(text: 'A'), Tab(text: 'B')],
          ),
        );
        const double tabBarHeight = kTextTabBarHeight;
        expect(
          appBar.preferredSize.height,
          kScreenAppBarHeight + tabBarHeight,
        );
      });
    });

    group('title', () {
      testWidgets('renders title text when provided',
          (WidgetTester tester) async {
        await tester.pumpApp(
          const Scaffold(appBar: ScreenAppBar(title: 'Test Title')),
        );

        expect(find.text('Test Title'), findsOneWidget);
      });

      testWidgets('renders no title when null',
          (WidgetTester tester) async {
        await tester.pumpApp(
          const Scaffold(appBar: ScreenAppBar()),
        );

        final AppBar appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.title, isNull);
      });
    });

    group('actions', () {
      testWidgets('renders action widgets', (WidgetTester tester) async {
        await tester.pumpApp(
          Scaffold(
            appBar: ScreenAppBar(
              actions: <Widget>[
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        );

        expect(find.byIcon(Icons.settings), findsOneWidget);
      });
    });

    group('back button', () {
      testWidgets('shows back button on mobile when can pop',
          (WidgetTester tester) async {
        // Use a Navigator with two routes to ensure canPop() is true.
        // Wrap in small MediaQuery to simulate mobile.
        await tester.pumpApp(
          MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Navigator(
              onGenerateRoute: (_) => MaterialPageRoute<void>(
                builder: (_) => Builder(
                  builder: (BuildContext context) {
                    // Push second route immediately
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const Scaffold(
                            appBar: ScreenAppBar(title: 'Child'),
                          ),
                        ),
                      );
                    });
                    return const Scaffold(
                      appBar: ScreenAppBar(title: 'Root'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      });

      testWidgets('shows back button on desktop when can pop',
          (WidgetTester tester) async {
        await tester.pumpApp(
          MediaQuery(
            data: const MediaQueryData(size: Size(1200, 800)),
            child: Navigator(
              onGenerateRoute: (_) => MaterialPageRoute<void>(
                builder: (_) => Builder(
                  builder: (BuildContext context) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const Scaffold(
                            appBar: ScreenAppBar(title: 'Child'),
                          ),
                        ),
                      );
                    });
                    return const Scaffold(
                      appBar: ScreenAppBar(title: 'Root'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      });

      testWidgets('hides back button on mobile at root route',
          (WidgetTester tester) async {
        await tester.pumpApp(
          const Scaffold(appBar: ScreenAppBar(title: 'Root')),
          mediaQuerySize: const Size(400, 800),
        );

        expect(find.byIcon(Icons.arrow_back), findsNothing);
      });

      testWidgets('back button pops navigator', (WidgetTester tester) async {
        bool didPop = false;

        await tester.pumpApp(
          MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Navigator(
              onGenerateRoute: (_) => MaterialPageRoute<void>(
                builder: (_) => Builder(
                  builder: (BuildContext context) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PopScope(
                            onPopInvokedWithResult:
                                (bool popped, Object? result) {
                              if (popped) didPop = true;
                            },
                            child: const Scaffold(
                              appBar: ScreenAppBar(title: 'Child'),
                            ),
                          ),
                        ),
                      );
                    });
                    return const Scaffold(
                      appBar: ScreenAppBar(title: 'Root'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        expect(didPop, isTrue);
      });
    });

    group('bottom', () {
      testWidgets('renders TabBar as bottom widget',
          (WidgetTester tester) async {
        await tester.pumpApp(
          const DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: ScreenAppBar(
                title: 'Tabs',
                bottom: TabBar(
                  tabs: <Widget>[Tab(text: 'Tab 1'), Tab(text: 'Tab 2')],
                ),
              ),
              body: TabBarView(
                children: <Widget>[
                  Center(child: Text('Page 1')),
                  Center(child: Text('Page 2')),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Tab 1'), findsOneWidget);
        expect(find.text('Tab 2'), findsOneWidget);
      });
    });

    group('visual styling', () {
      testWidgets('uses transparent AppBar background',
          (WidgetTester tester) async {
        await tester.pumpApp(
          const Scaffold(appBar: ScreenAppBar(title: 'Styled')),
        );

        final AppBar appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.backgroundColor, Colors.transparent);
        expect(appBar.surfaceTintColor, Colors.transparent);
      });

      testWidgets('uses kScreenAppBarHeight as toolbar height',
          (WidgetTester tester) async {
        await tester.pumpApp(
          const Scaffold(appBar: ScreenAppBar(title: 'Height')),
        );

        final AppBar appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.toolbarHeight, kScreenAppBarHeight);
      });

      testWidgets('wraps AppBar in Container with gradient',
          (WidgetTester tester) async {
        await tester.pumpApp(
          const Scaffold(appBar: ScreenAppBar(title: 'Gradient')),
        );

        final Container container = tester.widget<Container>(
          find.ancestor(
            of: find.byType(AppBar),
            matching: find.byType(Container),
          ).first,
        );

        final BoxDecoration decoration =
            container.decoration! as BoxDecoration;
        expect(decoration.gradient, isA<LinearGradient>());
        expect(decoration.border, isNotNull);
      });

      testWidgets('disables automaticallyImplyLeading',
          (WidgetTester tester) async {
        await tester.pumpApp(
          const Scaffold(appBar: ScreenAppBar()),
        );

        final AppBar appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.automaticallyImplyLeading, isFalse);
      });
    });
  });
}
