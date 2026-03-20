import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/keyboard/shortcut_helper.dart';

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

      // Виджет должен содержать CallbackShortcuts
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
