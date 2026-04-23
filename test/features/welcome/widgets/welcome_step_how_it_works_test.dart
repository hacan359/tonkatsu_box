// Smoke-тесты для WelcomeStepHowItWorks — шаг 5 Welcome Wizard.
// Статичная информационная страница без интерактива; проверяем только
// что рендерится без исключений и имеет скролл для длинного контента.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/welcome/widgets/welcome_step_how_it_works.dart';
import 'package:xerabora/l10n/app_localizations.dart';

void main() {
  Widget createWidget() {
    return const MaterialApp(
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: Scaffold(body: WelcomeStepHowItWorks()),
    );
  }

  group('WelcomeStepHowItWorks', () {
    testWidgets('рендерится без исключений', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());

      expect(tester.takeException(), isNull);
      expect(find.byType(WelcomeStepHowItWorks), findsOneWidget);
    });

    testWidgets('имеет скролл-контейнер для длинного контента',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}
