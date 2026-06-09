import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/welcome/widgets/welcome_step_menu_tour.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';
import 'package:tonkatsu_box/shared/theme/app_theme.dart';

void main() {
  // Render with the real app theme: it makes FilledButtons full-width, the trap
  // that previously crashed a button placed in a Row.
  Widget wrap({required VoidCallback onStart, required VoidCallback onSkip}) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: Scaffold(
        body: WelcomeStepMenuTour(onStart: onStart, onSkip: onSkip),
      ),
    );
  }

  group('WelcomeStepMenuTour', () {
    testWidgets('renders without exception', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(onStart: () {}, onSkip: () {}));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(WelcomeStepMenuTour), findsOneWidget);
    });

    testWidgets('Start triggers onStart', (WidgetTester tester) async {
      bool started = false;
      await tester.pumpWidget(
        wrap(onStart: () => started = true, onSkip: () {}),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(started, isTrue);
    });

    testWidgets('Skip triggers onSkip', (WidgetTester tester) async {
      bool skipped = false;
      await tester.pumpWidget(
        wrap(onStart: () {}, onSkip: () => skipped = true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Skip — explore on my own'));
      await tester.pump();

      expect(skipped, isTrue);
    });
  });
}
