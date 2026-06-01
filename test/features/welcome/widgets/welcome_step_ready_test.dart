import 'package:tonkatsu_box/l10n/app_localizations.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/welcome/widgets/welcome_step_ready.dart';

void main() {
  Widget createWidget({
    VoidCallback? onGoToSettings,
    VoidCallback? onSkip,
  }) {
    return MaterialApp(
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: Scaffold(
        body: WelcomeStepReady(
          onGoToSettings: onGoToSettings ?? () {},
          onSkip: onSkip ?? () {},
        ),
      ),
    );
  }

  group('WelcomeStepReady', () {
    testWidgets('renders without exceptions',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      expect(tester.takeException(), isNull);
    });

    testWidgets('fires onGoToSettings when the primary button is tapped',
        (WidgetTester tester) async {
      bool called = false;
      await tester.pumpWidget(
        createWidget(onGoToSettings: () => called = true),
      );

      await tester.tap(find.byType(FilledButton));
      expect(called, isTrue);
    });

    testWidgets('fires onSkip when the secondary button is tapped',
        (WidgetTester tester) async {
      bool called = false;
      await tester.pumpWidget(createWidget(onSkip: () => called = true));

      await tester.tap(find.byType(OutlinedButton));
      expect(called, isTrue);
    });
  });
}
