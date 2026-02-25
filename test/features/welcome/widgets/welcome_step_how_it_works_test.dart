import 'package:xerabora/l10n/app_localizations.dart';
// Тесты для WelcomeStepHowItWorks — шаг 3 Welcome Wizard.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/welcome/widgets/welcome_step_how_it_works.dart';

void main() {
  Widget createWidget() {
    return const MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
      home: Scaffold(
        body: WelcomeStepHowItWorks(),
      ),
    );
  }

  group('WelcomeStepHowItWorks', () {
    group('header', () {
      testWidgets('shows menu_book icon', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.byIcon(Icons.menu_book), findsOneWidget);
      });

      testWidgets('shows title', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.text('How it works'), findsOneWidget);
      });
    });

    group('App structure section', () {
      testWidgets('shows section title', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.text('App structure'), findsOneWidget);
      });

      testWidgets('shows all 5 tab names', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.text('Main'), findsOneWidget);
        expect(find.text('Collections'), findsOneWidget);
        expect(find.text('Wishlist'), findsOneWidget);
        expect(find.text('Search'), findsOneWidget);
        expect(find.text('Settings'), findsOneWidget);
      });

      testWidgets('shows tab descriptions', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(
          find.textContaining('All items from all collections'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Your collections'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Quick list'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Find games'),
          findsOneWidget,
        );
        expect(
          find.textContaining('API keys, cache'),
          findsOneWidget,
        );
      });

      testWidgets('shows tab icons', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.byIcon(Icons.home), findsOneWidget);
        expect(find.byIcon(Icons.shelves), findsOneWidget);
        expect(find.byIcon(Icons.bookmark), findsOneWidget);
        expect(find.byIcon(Icons.search), findsOneWidget);
        expect(find.byIcon(Icons.settings), findsOneWidget);
      });
    });

    group('Quick Start section', () {
      testWidgets('shows section title', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.text('Quick Start'), findsOneWidget);
      });

      testWidgets('shows 5 numbered steps', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.text('1'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
        expect(find.text('4'), findsOneWidget);
        expect(find.text('5'), findsOneWidget);
      });

      testWidgets('shows step texts', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(
          find.textContaining('Settings'),
          findsWidgets,
        );
        expect(
          find.textContaining('Verify Connection'),
          findsOneWidget,
        );
        expect(
          find.textContaining('New Collection'),
          findsOneWidget,
        );
      });
    });

    group('Sharing section', () {
      testWidgets('shows sharing title', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.text('Sharing'), findsOneWidget);
      });

      testWidgets('shows upload icon', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.byIcon(Icons.upload), findsOneWidget);
      });

      testWidgets('shows .xcoll format', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.text('.xcoll'), findsOneWidget);
      });

      testWidgets('shows .xcollx format', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.text('.xcollx'), findsOneWidget);
      });

      testWidgets('shows sharing description via RichText',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        // Sharing description uses RichText with mixed TextSpan+WidgetSpan
        expect(find.byType(RichText), findsWidgets);
      });
    });

    group('scrollability', () {
      testWidgets('is scrollable', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.byType(SingleChildScrollView), findsOneWidget);
      });
    });
  });
}
