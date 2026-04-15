// Тесты для CreditsScreen (атрибуция API-провайдеров и лицензии).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/settings/screens/credits_screen.dart';
import 'package:xerabora/l10n/app_localizations.dart';

void main() {
  Widget createWidget() {
    return const MaterialApp(
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: Scaffold(body: CreditsScreen()),
    );
  }

  group('CreditsScreen', () {
    testWidgets('View Open Source Licenses button is tappable',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();

      await tester.tap(find.text('View Open Source Licenses'));
      await tester.pumpAndSettle();

      // showLicensePage opens a page route — no exception thrown
      expect(tester.takeException(), isNull);
    });
  });
}
