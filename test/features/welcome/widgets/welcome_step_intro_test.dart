// Smoke-тесты для WelcomeStepIntro — шаг 1 Welcome Wizard.
// Статичная промо-страница без интерактива; проверяем только что
// рендерится без исключений и имеет скролл для длинного контента.
// Конкретные лейблы / иконки / цвета не проверяем — меняются с дизайном.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/welcome/widgets/welcome_step_intro.dart';
import 'package:xerabora/l10n/app_localizations.dart';

void main() {
  Widget createWidget() {
    return const MaterialApp(
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: Scaffold(body: WelcomeStepIntro()),
    );
  }

  group('WelcomeStepIntro', () {
    testWidgets('рендерится без исключений', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());

      expect(tester.takeException(), isNull);
      expect(find.byType(WelcomeStepIntro), findsOneWidget);
    });

    testWidgets('имеет скролл-контейнер для длинного контента',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}
