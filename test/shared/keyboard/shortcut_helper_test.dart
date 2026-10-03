import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/keyboard/shortcut_helper.dart';

void main() {
  group('wrapWithScreenShortcuts', () {
    testWidgets('should wrap child with CallbackShortcuts and Focus',
        (WidgetTester tester) async {
      bool called = false;
      final Widget result = wrapWithScreenShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.keyN, control: true): () {
            called = true;
          },
        },
        child: const Text('test'),
      );

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: result)));

      expect(find.byType(CallbackShortcuts), findsOneWidget);
      expect(find.byType(Focus), findsWidgets);
      expect(find.text('test'), findsOneWidget);
      expect(called, isFalse);
    });

    testWidgets('should respect autofocus parameter',
        (WidgetTester tester) async {
      final Widget result = wrapWithScreenShortcuts(
        bindings: const <ShortcutActivator, VoidCallback>{},
        autofocus: false,
        child: const Text('test'),
      );

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: result)));

      expect(find.byType(CallbackShortcuts), findsOneWidget);
      expect(find.text('test'), findsOneWidget);
    });
  });

  group('wrapWithScreenShortcuts on a pushed route', () {
    Future<int> pushAndPress(WidgetTester tester, {required bool wrapped}) async {
      int calls = 0;
      final Map<ShortcutActivator, VoidCallback> bindings =
          <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () =>
            calls++,
      };
      final GlobalKey<NavigatorState> nav = GlobalKey<NavigatorState>();
      await tester.pumpWidget(MaterialApp(
        navigatorKey: nav,
        home: const Scaffold(body: Text('root')),
      ));
      unawaited(nav.currentState?.push(MaterialPageRoute<void>(
        builder: (BuildContext _) => wrapped
            ? wrapWithScreenShortcuts(
                bindings: bindings,
                child: const Scaffold(body: Text('pushed')),
              )
            : CallbackShortcuts(
                bindings: bindings,
                child: const Scaffold(body: Text('pushed')),
              ),
      )));
      await tester.pumpAndSettle();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      return calls;
    }

    testWidgets('fires without the user focusing anything first',
        (WidgetTester tester) async {
      expect(await pushAndPress(tester, wrapped: true), 1);
    });

    testWidgets('a bare CallbackShortcuts stays deaf, the bug this guards',
        (WidgetTester tester) async {
      expect(await pushAndPress(tester, wrapped: false), 0);
    });

    testWidgets('the screen Focus is kept out of traversal',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: wrapWithScreenShortcuts(
            bindings: const <ShortcutActivator, VoidCallback>{},
            child: const Text('x'),
          ),
        ),
      ));

      final Focus screenFocus = tester.widget<Focus>(find
          .ancestor(of: find.text('x'), matching: find.byType(Focus))
          .first);
      expect(screenFocus.skipTraversal, isTrue);
    });
  });

  group('tooltipWithShortcut', () {
    test('should combine label and shortcut', () {
      final String result = tooltipWithShortcut('Создать', 'Ctrl+N');

      expect(result, 'Создать (Ctrl+N)');
    });

    test('should work with complex shortcuts', () {
      final String result =
          tooltipWithShortcut('Переключить вид', 'Ctrl+Shift+V');

      expect(result, 'Переключить вид (Ctrl+Shift+V)');
    });
  });
}
