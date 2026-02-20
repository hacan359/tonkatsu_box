// Тесты для WelcomeStepApiKeys — шаг 2 Welcome Wizard.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/welcome/widgets/welcome_step_api_keys.dart';
import 'package:xerabora/shared/theme/app_colors.dart';

void main() {
  Widget createWidget() {
    return const MaterialApp(
      home: Scaffold(
        body: WelcomeStepApiKeys(),
      ),
    );
  }

  group('WelcomeStepApiKeys', () {
    group('header', () {
      testWidgets('shows key icon', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.byIcon(Icons.key), findsOneWidget);
      });

      testWidgets('shows title', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.text('Getting API Keys'), findsOneWidget);
      });

      testWidgets('shows subtitle', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(
          find.text('Free registration, takes 2-3 minutes each'),
          findsOneWidget,
        );
      });
    });

    group('IGDB section', () {
      testWidgets('shows IGDB tag', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.text('IGDB'), findsOneWidget);
      });

      testWidgets('shows Game search title', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.text('Game search'), findsOneWidget);
      });

      testWidgets('shows REQUIRED badge', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.text('REQUIRED'), findsOneWidget);
      });

      testWidgets('shows 4 IGDB steps', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.textContaining('dev.twitch.tv/console'), findsWidgets);
        expect(find.textContaining('Twitch'), findsWidgets);
        expect(find.textContaining('Client ID'), findsOneWidget);
      });

      testWidgets('shows Twitch Developer Console link',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.text('Twitch Developer Console'), findsOneWidget);
      });
    });

    group('TMDB section', () {
      testWidgets('shows TMDB tag', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.text('TMDB'), findsOneWidget);
      });

      testWidgets('shows Movies, TV & Anime title',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.text('Movies, TV & Anime'), findsOneWidget);
      });

      testWidgets('shows RECOMMENDED badge', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.text('RECOMMENDED'), findsOneWidget);
      });

      testWidgets('shows TMDB steps', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.textContaining('themoviedb.org'), findsWidgets);
        expect(find.textContaining('API Key'), findsWidgets);
      });

      testWidgets('shows TMDB API link', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.text('TMDB API'), findsOneWidget);
      });
    });

    group('SteamGridDB section', () {
      testWidgets('shows SGDB tag', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.text('SGDB'), findsOneWidget);
      });

      testWidgets('shows Game artwork for boards title',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.text('Game artwork for boards'), findsOneWidget);
      });

      testWidgets('shows OPTIONAL badge', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.text('OPTIONAL'), findsOneWidget);
      });

      testWidgets('shows SteamGridDB link', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.text('SteamGridDB'), findsOneWidget);
      });
    });

    group('hint section', () {
      testWidgets('shows hint text about Settings',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(
          find.textContaining('Enter keys in Settings'),
          findsOneWidget,
        );
      });

      testWidgets('hint has brand-tinted background',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        // Find hint container by its text
        final Finder hintText =
            find.textContaining('Enter keys in Settings');
        expect(hintText, findsOneWidget);
      });
    });

    group('link cards', () {
      testWidgets('shows 3 link cards with open_in_new icons',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        // 3 open_in_new icons (one per _LinkCard)
        expect(find.byIcon(Icons.open_in_new), findsNWidgets(3));
      });

      testWidgets('shows 3 copy icons', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        // 3 content_copy icons
        expect(find.byIcon(Icons.content_copy), findsNWidgets(3));
      });

      testWidgets('IGDB link card is tappable',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        // Find the Twitch Developer Console InkWell
        final Finder linkCard = find.ancestor(
          of: find.text('Twitch Developer Console'),
          matching: find.byType(InkWell),
        );
        expect(linkCard, findsOneWidget);
      });
    });

    group('badge colors', () {
      testWidgets('REQUIRED badge uses brand color',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        final Text requiredText =
            tester.widget<Text>(find.text('REQUIRED'));
        expect(requiredText.style?.color, equals(AppColors.brand));
      });

      testWidgets('RECOMMENDED badge uses textTertiary color',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        final Text recommendedText =
            tester.widget<Text>(find.text('RECOMMENDED'));
        expect(
          recommendedText.style?.color,
          equals(AppColors.textTertiary),
        );
      });

      testWidgets('OPTIONAL badge uses textTertiary color',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        final Text optionalText =
            tester.widget<Text>(find.text('OPTIONAL'));
        expect(optionalText.style?.color, equals(AppColors.textTertiary));
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
