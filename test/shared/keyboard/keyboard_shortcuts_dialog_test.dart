import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';
import 'package:tonkatsu_box/shared/keyboard/keyboard_shortcuts.dart';
import 'package:tonkatsu_box/shared/keyboard/keyboard_shortcuts_dialog.dart';

Widget _wrap(Widget home) => MaterialApp(
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      locale: const Locale('ru'),
      home: home,
    );

void main() {
  group('KeyboardShortcutsDialog', () {
    testWidgets('should display global shortcuts group',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          const Scaffold(
            body: KeyboardShortcutsDialog(screenGroups: <ShortcutGroup>[]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Навигация'), findsOneWidget);
      expect(find.text('Клавиатурные сочетания'), findsOneWidget);
    });

    testWidgets('should display screen-specific groups',
        (WidgetTester tester) async {
      const List<ShortcutGroup> groups = <ShortcutGroup>[
        ShortcutGroup(
          title: 'Коллекции',
          entries: <ShortcutEntry>[
            ShortcutEntry(keys: 'Ctrl+N', description: 'Создать коллекцию'),
          ],
        ),
      ];

      await tester.pumpWidget(
        _wrap(
          const Scaffold(
            body: KeyboardShortcutsDialog(screenGroups: groups),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Коллекции'), findsOneWidget);
      expect(find.text('Создать коллекцию'), findsOneWidget);
    });

    testWidgets('should display key badges with separator',
        (WidgetTester tester) async {
      const List<ShortcutGroup> groups = <ShortcutGroup>[
        ShortcutGroup(
          title: 'Тест',
          entries: <ShortcutEntry>[
            ShortcutEntry(keys: 'Ctrl+N', description: 'Действие'),
          ],
        ),
      ];

      await tester.pumpWidget(
        _wrap(
          const Scaffold(
            body: KeyboardShortcutsDialog(screenGroups: groups),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ctrl'), findsWidgets);
      expect(find.text('N'), findsOneWidget);
      expect(find.text('+'), findsWidgets);
    });

    testWidgets('should close on button tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (BuildContext context) => ElevatedButton(
              onPressed: () => KeyboardShortcutsDialog.show(context),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Клавиатурные сочетания'), findsOneWidget);

      await tester.tap(find.text('Закрыть'));
      await tester.pumpAndSettle();
      expect(find.text('Клавиатурные сочетания'), findsNothing);
    });

    testWidgets('should display multiple screen groups',
        (WidgetTester tester) async {
      const List<ShortcutGroup> groups = <ShortcutGroup>[
        ShortcutGroup(
          title: 'Группа 1',
          entries: <ShortcutEntry>[
            ShortcutEntry(keys: 'F2', description: 'Переименовать'),
          ],
        ),
        ShortcutGroup(
          title: 'Группа 2',
          entries: <ShortcutEntry>[
            ShortcutEntry(keys: 'Delete', description: 'Удалить'),
          ],
        ),
      ];

      await tester.pumpWidget(
        _wrap(
          const Scaffold(
            body: KeyboardShortcutsDialog(screenGroups: groups),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Группа 1'), findsOneWidget);
      expect(find.text('Группа 2'), findsOneWidget);
      expect(find.text('Переименовать'), findsOneWidget);
      expect(find.text('Удалить'), findsOneWidget);
    });

    testWidgets('show() should open dialog with screen groups',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (BuildContext context) => ElevatedButton(
              onPressed: () => KeyboardShortcutsDialog.show(
                context,
                screenGroups: const <ShortcutGroup>[
                  ShortcutGroup(
                    title: 'Экран',
                    entries: <ShortcutEntry>[
                      ShortcutEntry(keys: 'V', description: 'Вид'),
                    ],
                  ),
                ],
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Экран'), findsOneWidget);
      expect(find.text('Вид'), findsOneWidget);
    });
  });
}
