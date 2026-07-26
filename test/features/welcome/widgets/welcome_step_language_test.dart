import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tonkatsu_box/features/settings/providers/settings_provider.dart';
import 'package:tonkatsu_box/features/welcome/widgets/welcome_step_language.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';

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

    testWidgets(
        'shows English, Russian, Chinese, Spanish, Portuguese and French '
        'options', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      expect(find.text('English'), findsWidgets);
      expect(find.text('Русский'), findsWidgets);
      expect(find.text('中文'), findsWidgets);
      expect(find.text('Español'), findsWidgets);
      expect(find.text('Português (Brasil)'), findsWidgets);
      expect(find.text('Français'), findsWidgets);
    });

    testWidgets('does not overflow on a phone-sized screen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createWidget());
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Français'), findsWidgets);
    });

    testWidgets('English is selected by default in UI radio',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(5));
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

      await tester.ensureVisible(find.byType(DropdownButton<String>));
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

    testWidgets('tapping Chinese selects it and sets tmdbLanguage to zh-CN',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      await tester.tap(find.text('中文').first);
      await tester.pump();

      expect(prefs.getString(SettingsKeys.appLanguage), 'zh');
      expect(prefs.getString(SettingsKeys.tmdbLanguage), 'zh-CN');
    });

    testWidgets('tapping Spanish selects it and sets tmdbLanguage to es-ES',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      await tester.tap(find.text('Español').first);
      await tester.pump();

      expect(prefs.getString(SettingsKeys.appLanguage), 'es');
      expect(prefs.getString(SettingsKeys.tmdbLanguage), 'es-ES');
    });

    testWidgets('tapping Portuguese selects it and sets tmdbLanguage to pt-BR',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      await tester.tap(find.text('Português (Brasil)').first);
      await tester.pump();

      expect(prefs.getString(SettingsKeys.appLanguage), 'pt');
      expect(prefs.getString(SettingsKeys.tmdbLanguage), 'pt-BR');
    });

    testWidgets('tapping French selects it and sets tmdbLanguage to fr-FR',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      await tester.tap(find.text('Français').first);
      await tester.pump();

      expect(prefs.getString(SettingsKeys.appLanguage), 'fr');
      expect(prefs.getString(SettingsKeys.tmdbLanguage), 'fr-FR');
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
      await tester.ensureVisible(find.byType(DropdownButton<String>));
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
      expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(5));
    });
  });
}
