import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/keyboard/keyboard_shortcuts.dart';

void main() {
  group('buildGlobalShortcuts', () {
    late int switchedTab;
    late bool nextTabCalled;
    late bool previousTabCalled;
    late bool backCalled;
    late bool searchCalled;
    late bool refreshCalled;
    late bool helpCalled;

    Map<ShortcutActivator, VoidCallback> buildTestShortcuts() {
      return buildGlobalShortcuts(
        onSwitchTab: (int index) => switchedTab = index,
        onNextTab: () => nextTabCalled = true,
        onPreviousTab: () => previousTabCalled = true,
        onBack: () => backCalled = true,
        onSearch: () => searchCalled = true,
        onRefresh: () => refreshCalled = true,
        onShowHelp: () => helpCalled = true,
      );
    }

    setUp(() {
      switchedTab = -1;
      nextTabCalled = false;
      previousTabCalled = false;
      backCalled = false;
      searchCalled = false;
      refreshCalled = false;
      helpCalled = false;
    });

    test('should contain all expected shortcut activators', () {
      final Map<ShortcutActivator, VoidCallback> shortcuts =
          buildTestShortcuts();

      // 6 табов + Ctrl+Tab + Ctrl+Shift+Tab + Escape + Alt+Left + Ctrl+F + F5 + F1
      expect(shortcuts.length, 13);
    });

    test('should map Ctrl+1 to tab 0', () {
      final Map<ShortcutActivator, VoidCallback> shortcuts =
          buildTestShortcuts();
      const SingleActivator activator = SingleActivator(
        LogicalKeyboardKey.digit1,
        control: true,
      );

      shortcuts[activator]!();

      expect(switchedTab, 0);
    });

    test('should map Ctrl+6 to tab 5', () {
      final Map<ShortcutActivator, VoidCallback> shortcuts =
          buildTestShortcuts();
      const SingleActivator activator = SingleActivator(
        LogicalKeyboardKey.digit6,
        control: true,
      );

      shortcuts[activator]!();

      expect(switchedTab, 5);
    });

    test('should map Ctrl+Tab to next tab', () {
      final Map<ShortcutActivator, VoidCallback> shortcuts =
          buildTestShortcuts();
      const SingleActivator activator = SingleActivator(
        LogicalKeyboardKey.tab,
        control: true,
      );

      shortcuts[activator]!();

      expect(nextTabCalled, isTrue);
    });

    test('should map Ctrl+Shift+Tab to previous tab', () {
      final Map<ShortcutActivator, VoidCallback> shortcuts =
          buildTestShortcuts();
      const SingleActivator activator = SingleActivator(
        LogicalKeyboardKey.tab,
        control: true,
        shift: true,
      );

      shortcuts[activator]!();

      expect(previousTabCalled, isTrue);
    });

    test('should map Escape to back', () {
      final Map<ShortcutActivator, VoidCallback> shortcuts =
          buildTestShortcuts();
      const SingleActivator activator = SingleActivator(
        LogicalKeyboardKey.escape,
      );

      shortcuts[activator]!();

      expect(backCalled, isTrue);
    });

    test('should map Alt+Left to back', () {
      final Map<ShortcutActivator, VoidCallback> shortcuts =
          buildTestShortcuts();
      const SingleActivator activator = SingleActivator(
        LogicalKeyboardKey.arrowLeft,
        alt: true,
      );

      shortcuts[activator]!();

      expect(backCalled, isTrue);
    });

    test('should map Ctrl+F to search', () {
      final Map<ShortcutActivator, VoidCallback> shortcuts =
          buildTestShortcuts();
      const SingleActivator activator = SingleActivator(
        LogicalKeyboardKey.keyF,
        control: true,
      );

      shortcuts[activator]!();

      expect(searchCalled, isTrue);
    });

    test('should map F5 to refresh', () {
      final Map<ShortcutActivator, VoidCallback> shortcuts =
          buildTestShortcuts();
      const SingleActivator activator = SingleActivator(
        LogicalKeyboardKey.f5,
      );

      shortcuts[activator]!();

      expect(refreshCalled, isTrue);
    });

    test('should map F1 to show help', () {
      final Map<ShortcutActivator, VoidCallback> shortcuts =
          buildTestShortcuts();
      const SingleActivator activator = SingleActivator(
        LogicalKeyboardKey.f1,
      );

      shortcuts[activator]!();

      expect(helpCalled, isTrue);
    });
  });

  group('isTextFieldFocused', () {
    testWidgets('should return false when no widget is focused',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('hello')),
        ),
      );

      expect(isTextFieldFocused(), isFalse);
    });

    testWidgets('should return true when TextField is focused',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TextField(autofocus: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(isTextFieldFocused(), isTrue);
    });

    testWidgets('should return false when non-TextField is focused',
        (WidgetTester tester) async {
      final FocusNode focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Focus(
              focusNode: focusNode,
              autofocus: true,
              child: const Text('hello'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(isTextFieldFocused(), isFalse);
    });
  });

  group('ShortcutEntry', () {
    test('should store keys and description', () {
      const ShortcutEntry entry = ShortcutEntry(
        keys: 'Ctrl+N',
        description: 'Создать',
      );

      expect(entry.keys, 'Ctrl+N');
      expect(entry.description, 'Создать');
    });
  });

  group('ShortcutGroup', () {
    test('should store title and entries', () {
      const ShortcutGroup group = ShortcutGroup(
        title: 'Навигация',
        entries: <ShortcutEntry>[
          ShortcutEntry(keys: 'F1', description: 'Справка'),
        ],
      );

      expect(group.title, 'Навигация');
      expect(group.entries, hasLength(1));
    });
  });

  group('globalShortcutGroup', () {
    test('should contain navigation entries', () {
      expect(globalShortcutGroup.title, 'Навигация');
      expect(globalShortcutGroup.entries, isNotEmpty);
      expect(
        globalShortcutGroup.entries.any(
          (ShortcutEntry e) => e.keys == 'F1',
        ),
        isTrue,
      );
    });
  });
}
