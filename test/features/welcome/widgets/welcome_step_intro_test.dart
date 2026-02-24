import 'package:xerabora/l10n/app_localizations.dart';
// Тесты для WelcomeStepIntro — шаг 1 Welcome Wizard.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/welcome/widgets/welcome_step_intro.dart';
import 'package:xerabora/shared/theme/app_colors.dart';

void main() {
  Widget createWidget() {
    return const MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
      home: Scaffold(
        body: WelcomeStepIntro(),
      ),
    );
  }

  group('WelcomeStepIntro', () {
    group('header', () {
      testWidgets('shows app logo', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.byType(Image), findsOneWidget);
      });

      testWidgets('shows welcome title', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.text('Welcome to Tonkatsu Box'), findsOneWidget);
      });

      testWidgets('shows subtitle text', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(
          find.textContaining('Organize your collections'),
          findsOneWidget,
        );
      });
    });

    group('What you can do section', () {
      testWidgets('shows section title', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.text('What you can do'), findsOneWidget);
      });

      testWidgets('shows 5 feature descriptions',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(
          find.textContaining('Create collections'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Search games'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Track progress'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Visual canvas boards'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Export & import'),
          findsOneWidget,
        );
      });

      testWidgets('shows feature icons', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
        expect(find.byIcon(Icons.search), findsOneWidget);
        expect(find.byIcon(Icons.bar_chart), findsOneWidget);
        expect(find.byIcon(Icons.palette_outlined), findsOneWidget);
        expect(find.byIcon(Icons.upload_outlined), findsOneWidget);
      });
    });

    group('Works without keys section', () {
      testWidgets('shows section title', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.text('Works without API keys'), findsOneWidget);
      });

      testWidgets('shows check circle icon', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      });

      testWidgets('shows feature chips', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.text('Collections'), findsOneWidget);
        expect(find.text('Wishlist'), findsOneWidget);
        expect(find.text('Import .xcoll'), findsOneWidget);
        expect(find.text('Canvas boards'), findsOneWidget);
        expect(find.text('Ratings & notes'), findsOneWidget);
      });

      testWidgets('shows explanation text', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(
          find.textContaining('API keys are only needed'),
          findsOneWidget,
        );
      });
    });

    group('Media type chips', () {
      testWidgets('shows all 4 media types', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.text('Games (IGDB)'), findsOneWidget);
        expect(find.text('Movies (TMDB)'), findsOneWidget);
        expect(find.text('TV Shows (TMDB)'), findsOneWidget);
        expect(find.text('Anime (TMDB)'), findsOneWidget);
      });

      testWidgets('media chips use correct colors',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        // Games chip should have gameAccent color
        final Text gamesText =
            tester.widget<Text>(find.text('Games (IGDB)'));
        expect(gamesText.style?.color, equals(AppColors.gameAccent));

        // Movies chip should have movieAccent color
        final Text moviesText =
            tester.widget<Text>(find.text('Movies (TMDB)'));
        expect(moviesText.style?.color, equals(AppColors.movieAccent));
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
