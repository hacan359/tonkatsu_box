// Тесты для WelcomeStepApiKeys — шаг 4 Welcome Wizard.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/welcome/widgets/welcome_step_api_keys.dart';
import 'package:xerabora/l10n/app_localizations.dart';

void main() {
  group('WelcomeStepApiKeys', () {
    testWidgets('renders without exceptions', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(body: WelcomeStepApiKeys()),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
