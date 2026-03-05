// Тесты для WelcomeStepName — шаг 2 Welcome Wizard.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';
import 'package:xerabora/features/welcome/widgets/welcome_step_name.dart';
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
        home: Scaffold(body: WelcomeStepName()),
      ),
    );
  }

  group('WelcomeStepName', () {
    testWidgets('shows badge icon', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      expect(find.byIcon(Icons.badge_outlined), findsOneWidget);
    });

    testWidgets('shows title', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      expect(find.text("What's your name?"), findsOneWidget);
    });

    testWidgets('shows subtitle', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      expect(
        find.text(
            'This name will appear as the author on collections you create'),
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

    testWidgets('shows text field', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('text field is empty when author is default "User"',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      final TextField textField =
          tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
    });

    testWidgets('text field shows current author name',
        (WidgetTester tester) async {
      await prefs.setString(SettingsKeys.defaultAuthor, 'Hacan');

      await tester.pumpWidget(createWidget());
      await tester.pump();

      final TextField textField =
          tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, 'Hacan');
    });

    testWidgets('typing updates settings', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'NewName');
      await tester.pump();

      expect(prefs.getString(SettingsKeys.defaultAuthor), 'NewName');
    });

    testWidgets('shows placeholder "User"', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      // The placeholder is shown via hintText
      expect(find.text('User'), findsOneWidget);
    });
  });
}
