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

      expect(find.text('English'), findsWidgets);
      expect(find.text('Русский'), findsWidgets);
    });

    testWidgets('English is selected by default in UI radio',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
    });

    testWidgets('shows content language dropdown', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      expect(find.byType(DropdownButton<String>), findsOneWidget);
    });

    testWidgets('changing content language saves tmdbLanguage',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('English').last);
      await tester.pumpAndSettle();

      expect(prefs.getString(SettingsKeys.tmdbLanguage), 'en-US');
    });

    testWidgets('tapping Russian selects it', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      // first() — UI radio sits above the content dropdown in the tree.
      await tester.tap(find.text('Русский').first);
      await tester.pump();

      expect(prefs.getString(SettingsKeys.appLanguage), 'ru');
    });

    testWidgets('tapping English selects it back',
        (WidgetTester tester) async {
      await prefs.setString(SettingsKeys.appLanguage, 'ru');

      await tester.pumpWidget(createWidget());
      await tester.pump();

      await tester.tap(find.text('English').first);
      await tester.pump();

      expect(prefs.getString(SettingsKeys.appLanguage), 'en');
    });

    testWidgets('selecting English UI sets tmdbLanguage to en-US',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      await tester.tap(find.text('English').first);
      await tester.pump();

      expect(prefs.getString(SettingsKeys.appLanguage), 'en');
      expect(prefs.getString(SettingsKeys.tmdbLanguage), 'en-US');
    });

    testWidgets('selecting Russian UI sets tmdbLanguage to ru-RU',
        (WidgetTester tester) async {
      await prefs.setString(SettingsKeys.tmdbLanguage, 'en-US');

      await tester.pumpWidget(createWidget());
      await tester.pump();

      await tester.tap(find.text('Русский').first);
      await tester.pump();

      expect(prefs.getString(SettingsKeys.appLanguage), 'ru');
      expect(prefs.getString(SettingsKeys.tmdbLanguage), 'ru-RU');
    });

    testWidgets('manual content language pick disables UI→content sync',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      // User explicitly picks English as content language (default was ru-RU).
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English').last);
      await tester.pumpAndSettle();

      expect(prefs.getString(SettingsKeys.tmdbLanguage), 'en-US');

      // Switching UI to Russian must not touch content language.
      await tester.tap(find.text('Русский').first);
      await tester.pump();

      expect(prefs.getString(SettingsKeys.appLanguage), 'ru');
      expect(prefs.getString(SettingsKeys.tmdbLanguage), 'en-US');
    });

    testWidgets('selected option has check_circle icon',
        (WidgetTester tester) async {
      await prefs.setString(SettingsKeys.appLanguage, 'ru');

      await tester.pumpWidget(createWidget());
      await tester.pump();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
    });
  });
}
