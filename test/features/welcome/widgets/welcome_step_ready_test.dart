// Тесты для WelcomeStepReady — шаг 4 Welcome Wizard.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/welcome/widgets/welcome_step_ready.dart';
import 'package:xerabora/shared/theme/app_colors.dart';

void main() {
  Widget createWidget({
    VoidCallback? onGoToSettings,
    VoidCallback? onSkip,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: WelcomeStepReady(
          onGoToSettings: onGoToSettings ?? () {},
          onSkip: onSkip ?? () {},
        ),
      ),
    );
  }

  group('WelcomeStepReady', () {
    group('header', () {
      testWidgets('shows celebration icon', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.byIcon(Icons.celebration), findsOneWidget);
      });

      testWidgets('celebration icon uses brand color',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        final Icon icon = tester.widget<Icon>(
          find.byIcon(Icons.celebration),
        );
        expect(icon.color, equals(AppColors.brand));
      });

      testWidgets('celebration icon is size 56',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        final Icon icon = tester.widget<Icon>(
          find.byIcon(Icons.celebration),
        );
        expect(icon.size, equals(56));
      });

      testWidgets('shows title text', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.text("You're all set!"), findsOneWidget);
      });

      testWidgets('shows description text', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(
          find.textContaining('Head to Settings'),
          findsOneWidget,
        );
      });
    });

    group('Go to Settings button', () {
      testWidgets('shows button text', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.text('Go to Settings'), findsOneWidget);
      });

      testWidgets('shows arrow_forward icon', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      });

      testWidgets('calls onGoToSettings when tapped',
          (WidgetTester tester) async {
        bool called = false;
        await tester.pumpWidget(
          createWidget(onGoToSettings: () => called = true),
        );

        await tester.tap(find.text('Go to Settings'));
        expect(called, isTrue);
      });

      testWidgets('is a FilledButton', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.byType(FilledButton), findsOneWidget);
      });
    });

    group('Skip button', () {
      testWidgets('shows button text', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(
          find.text('Skip — explore on my own'),
          findsOneWidget,
        );
      });

      testWidgets('calls onSkip when tapped',
          (WidgetTester tester) async {
        bool called = false;
        await tester.pumpWidget(
          createWidget(onSkip: () => called = true),
        );

        await tester.tap(find.text('Skip — explore on my own'));
        expect(called, isTrue);
      });

      testWidgets('is an OutlinedButton', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.byType(OutlinedButton), findsOneWidget);
      });
    });

    group('footer', () {
      testWidgets('shows hint about returning from Settings',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(
          find.text('You can always return here from Settings'),
          findsOneWidget,
        );
      });
    });

    group('layout', () {
      testWidgets('content is centered', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        // WelcomeStepReady wraps content in Center
        // (FilledButton/OutlinedButton also have internal Centers)
        final Finder centeredContent = find.descendant(
          of: find.byType(WelcomeStepReady),
          matching: find.byType(Center),
        );
        expect(centeredContent, findsAtLeastNWidgets(1));
      });

      testWidgets('buttons have fixed width 280',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        final Iterable<SizedBox> sizedBoxes = tester.widgetList<SizedBox>(
          find.byWidgetPredicate(
            (Widget w) => w is SizedBox && w.width == 280,
          ),
        );
        expect(sizedBoxes.length, equals(2));
      });
    });
  });
}
