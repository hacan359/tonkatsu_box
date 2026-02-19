import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';
import 'package:xerabora/features/settings/screens/database_screen.dart';
import 'package:xerabora/shared/widgets/breadcrumb_scope.dart';

void main() {
  group('DatabaseScreen', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferences.getInstance();
    });

    Widget createWidget() {
      return ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          home: BreadcrumbScope(
            label: 'Settings',
            child: DatabaseScreen(),
          ),
        ),
      );
    }

    testWidgets('Показывает хлебные крошки Settings и Database',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Database'), findsOneWidget);
    });

    testWidgets('Показывает заголовок секции Configuration',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Configuration'), findsOneWidget);
    });

    testWidgets('Показывает кнопку Export Config', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Export Config'), findsOneWidget);
    });

    testWidgets('Показывает кнопку Import Config', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Import Config'), findsOneWidget);
    });

    testWidgets('Показывает заголовок секции Danger Zone',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Danger Zone'), findsOneWidget);
    });

    testWidgets('Показывает кнопку Reset Database', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Reset Database'), findsOneWidget);
    });

    testWidgets('Показывает иконку предупреждения в Danger Zone',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final Finder warningIcon = find.byIcon(Icons.warning_amber);
      expect(warningIcon, findsOneWidget);
    });

    testWidgets('Reset Database показывает диалог подтверждения',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final Finder resetButton = find.text('Reset Database');
      await tester.tap(resetButton);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Reset Database?'), findsOneWidget);
    });

    testWidgets('Cancel закрывает диалог', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final Finder resetButton = find.text('Reset Database');
      await tester.tap(resetButton);
      await tester.pumpAndSettle();

      final Finder cancelButton = find.text('Cancel');
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('Export/Import кнопки имеют правильные иконки',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.upload), findsOneWidget);
      expect(find.byIcon(Icons.download), findsOneWidget);
    });

    testWidgets('Configuration секция имеет иконку settings_backup_restore',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.settings_backup_restore), findsOneWidget);
    });
  });
}
