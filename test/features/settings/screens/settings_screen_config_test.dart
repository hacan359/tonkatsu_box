// Тесты для SettingsScreen — секции Configuration и Danger Zone.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';
import 'package:xerabora/features/settings/screens/settings_screen.dart';

void main() {
  group('SettingsScreen Configuration & Danger Zone', () {
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
          home: SettingsScreen(),
        ),
      );
    }

    group('Configuration section', () {
      testWidgets('должен показывать заголовок Configuration',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Configuration'), findsOneWidget);
      });

      testWidgets('должен показывать описание секции',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(
          find.text('Export or import your API keys and settings.'),
          findsOneWidget,
        );
      });

      testWidgets('должен показывать кнопку Export Config',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Export Config'), findsOneWidget);
      });

      testWidgets('должен показывать кнопку Import Config',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Import Config'), findsOneWidget);
      });

      testWidgets('должен показывать иконки upload и download',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.upload), findsOneWidget);
        expect(find.byIcon(Icons.download), findsOneWidget);
      });

      testWidgets('должен показывать иконку settings_backup_restore',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.settings_backup_restore), findsOneWidget);
      });
    });

    group('Danger Zone section', () {
      testWidgets('должен показывать заголовок Danger Zone',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Danger Zone'), findsOneWidget);
      });

      testWidgets('должен показывать описание секции',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Clears all collections, games, movies, TV shows and canvas data. '
            'Settings and API keys will be preserved.',
          ),
          findsOneWidget,
        );
      });

      testWidgets('должен показывать кнопку Reset Database',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Reset Database'), findsOneWidget);
      });

      testWidgets('должен показывать иконку delete_forever',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.delete_forever), findsOneWidget);
      });

      testWidgets('должен показывать иконку warning_amber',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.warning_amber), findsAtLeastNWidgets(1));
      });

      testWidgets('нажатие Reset Database должно показать диалог подтверждения',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Reset Database'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Reset Database'));
        await tester.pumpAndSettle();

        expect(find.text('Reset Database?'), findsOneWidget);
        expect(
          find.text(
            'This will permanently delete all your collections, games, '
            'movies, TV shows, episode progress, and canvas data.\n\n'
            'Your API keys and settings will be preserved.\n\n'
            'This action cannot be undone.',
          ),
          findsOneWidget,
        );
      });

      testWidgets('диалог должен иметь кнопки Cancel и Reset',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Reset Database'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Reset Database'));
        await tester.pumpAndSettle();

        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Reset'), findsOneWidget);
      });

      testWidgets('нажатие Cancel должно закрыть диалог',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Reset Database'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Reset Database'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(find.text('Reset Database?'), findsNothing);
      });
    });

    group('секции расположены в правильном порядке', () {
      testWidgets('Configuration и Danger Zone видны на экране',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Обе секции должны присутствовать
        expect(find.text('Configuration'), findsOneWidget);
        expect(find.text('Danger Zone'), findsOneWidget);
      });
    });
  });
}
