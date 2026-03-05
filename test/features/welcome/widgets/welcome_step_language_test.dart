// Тесты для WelcomeStepLanguage — шаг 3 Welcome Wizard.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';
import 'package:xerabora/features/welcome/widgets/welcome_step_language.dart';
import 'package:xerabora/l10n/app_localizations.dart';

void main() {
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
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(body: WelcomeStepLanguage()),
      ),
    );
  }

  group('WelcomeStepLanguage', () {
    testWidgets('shows language icon', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      expect(find.byIcon(Icons.language), findsOneWidget);
    });

    testWidgets('shows title', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      expect(find.text('Choose your language'), findsOneWidget);
    });

    testWidgets('shows subtitle', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      expect(
        find.text('Select the app interface language'),
        findsOneWidget,
      );
    });

    testWidgets('shows hint text', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      expect(
        find.text('You can change this later in Settings'),
        findsOneWidget,
      );
    });

    testWidgets('shows English and Russian options',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      expect(find.text('English'), findsOneWidget);
      expect(find.text('Русский'), findsOneWidget);
    });

    testWidgets('English is selected by default',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      // Default language is 'en', so English should have check_circle
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
    });

    testWidgets('tapping Russian selects it', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      await tester.tap(find.text('Русский'));
      await tester.pump();

      expect(prefs.getString(SettingsKeys.appLanguage), 'ru');
    });

    testWidgets('tapping English selects it back',
        (WidgetTester tester) async {
      // Start with Russian
      await prefs.setString(SettingsKeys.appLanguage, 'ru');

      await tester.pumpWidget(createWidget());
      await tester.pump();

      await tester.tap(find.text('English'));
      await tester.pump();

      expect(prefs.getString(SettingsKeys.appLanguage), 'en');
    });

    testWidgets('selected option has check_circle icon',
        (WidgetTester tester) async {
      await prefs.setString(SettingsKeys.appLanguage, 'ru');

      await tester.pumpWidget(createWidget());
      await tester.pump();

      // Russian is selected — should have check_circle
      // English is not selected — should have radio_button_unchecked
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
    });
  });
}
