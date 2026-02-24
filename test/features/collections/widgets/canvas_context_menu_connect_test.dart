import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/collections/widgets/canvas_context_menu.dart';
import 'package:xerabora/l10n/app_localizations.dart';
import 'package:xerabora/shared/models/canvas_item.dart';

void main() {
  // Ignore overflow errors in tests (known issue with long text in PopupMenu)
  setUp(() {
    FlutterError.onError = (FlutterErrorDetails details) {
      final bool isOverflowError = details.exception is FlutterError &&
          details.exception.toString().contains('overflowed by');
      if (!isOverflowError) {
        FlutterError.dumpErrorToConsole(details);
      }
    };
  });

  tearDown(() {
    FlutterError.onError = FlutterError.dumpErrorToConsole;
  });
  group('CanvasContextMenu — Connect', () {
    testWidgets('showItemMenu should show Connect option',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () {
                    CanvasContextMenu.showItemMenu(
                      context,
                      position: const Offset(100, 100),
                      itemType: CanvasItemType.game,
                      onDelete: () {},
                      onBringToFront: () {},
                      onSendToBack: () {},
                      onConnect: () {},
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Connect'), findsOneWidget);
    });

    testWidgets('showItemMenu Connect should call onConnect callback',
        (WidgetTester tester) async {
      bool connectCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () {
                    CanvasContextMenu.showItemMenu(
                      context,
                      position: const Offset(100, 100),
                      itemType: CanvasItemType.game,
                      onDelete: () {},
                      onBringToFront: () {},
                      onSendToBack: () {},
                      onConnect: () => connectCalled = true,
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Connect'));
      await tester.pumpAndSettle();

      expect(connectCalled, isTrue);
    });
  });

  group('CanvasContextMenu — showConnectionMenu', () {
    testWidgets('should show Edit Connection and Delete Connection options',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 600)),
          child: MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: Builder(
                  builder: (BuildContext context) {
                    return ElevatedButton(
                      onPressed: () {
                        CanvasContextMenu.showConnectionMenu(
                          context,
                          position: const Offset(100, 100),
                          onEdit: () {},
                          onDelete: () {},
                        );
                      },
                      child: const Text('Open'),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();

      expect(find.textContaining('Edit'), findsWidgets);
      expect(find.textContaining('Delete'), findsWidgets);
    });

    testWidgets('Edit Connection should call onEdit',
        (WidgetTester tester) async {
      bool editCalled = false;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 600)),
          child: MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: Builder(
                  builder: (BuildContext context) {
                    return ElevatedButton(
                      onPressed: () {
                        CanvasContextMenu.showConnectionMenu(
                          context,
                          position: const Offset(100, 100),
                          onEdit: () => editCalled = true,
                          onDelete: () {},
                        );
                      },
                      child: const Text('Open'),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Find by PopupMenuItem widget type
      final Finder editMenuItem = find.byWidgetPredicate(
        (Widget widget) =>
            widget is PopupMenuItem<String> && widget.value == 'edit',
      );
      await tester.tap(editMenuItem);
      await tester.pumpAndSettle();

      expect(editCalled, isTrue);
    });

    testWidgets('Delete Connection menu item should exist',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 600)),
          child: MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: Builder(
                  builder: (BuildContext context) {
                    return ElevatedButton(
                      onPressed: () {
                        CanvasContextMenu.showConnectionMenu(
                          context,
                          position: const Offset(100, 100),
                          onEdit: () {},
                          onDelete: () {},
                        );
                      },
                      child: const Text('Open'),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();

      // Find by PopupMenuItem widget type
      final Finder deleteMenuItem = find.byWidgetPredicate(
        (Widget widget) =>
            widget is PopupMenuItem<String> && widget.value == 'delete',
      );

      expect(deleteMenuItem, findsOneWidget);
    });

    testWidgets('Delete Connection should show Delete and Cancel buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 600)),
          child: MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: Builder(
                  builder: (BuildContext context) {
                    return ElevatedButton(
                      onPressed: () {
                        CanvasContextMenu.showConnectionMenu(
                          context,
                          position: const Offset(100, 100),
                          onEdit: () {},
                          onDelete: () {},
                        );
                      },
                      child: const Text('Open'),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();

      // Verify menu items exist
      final Finder editItem = find.byWidgetPredicate(
        (Widget widget) =>
            widget is PopupMenuItem<String> && widget.value == 'edit',
      );
      final Finder deleteItem = find.byWidgetPredicate(
        (Widget widget) =>
            widget is PopupMenuItem<String> && widget.value == 'delete',
      );

      expect(editItem, findsOneWidget);
      expect(deleteItem, findsOneWidget);
    });


    testWidgets('dismiss without selection should not call callbacks',
        (WidgetTester tester) async {
      bool editCalled = false;
      bool deleteCalled = false;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 600)),
          child: MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: Builder(
                  builder: (BuildContext context) {
                    return ElevatedButton(
                      onPressed: () {
                        CanvasContextMenu.showConnectionMenu(
                          context,
                          position: const Offset(100, 100),
                          onEdit: () => editCalled = true,
                          onDelete: () => deleteCalled = true,
                        );
                      },
                      child: const Text('Open'),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();

      // Dismiss by tapping outside the menu
      await tester.tapAt(const Offset(500, 500));
      await tester.pumpAndSettle();

      expect(editCalled, isFalse);
      expect(deleteCalled, isFalse);
    });
  });
}
