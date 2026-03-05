// Тесты для CreditsScreen (атрибуция API-провайдеров и лицензии).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/settings/screens/credits_screen.dart';
import 'package:xerabora/features/settings/widgets/settings_group.dart';
import 'package:xerabora/l10n/app_localizations.dart';
import 'package:xerabora/shared/widgets/breadcrumb_scope.dart';

void main() {
  Widget createWidget() {
    return const MaterialApp(
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: BreadcrumbScope(
        label: 'Settings',
        child: BreadcrumbScope(
          label: 'Credits',
          child: CreditsScreen(),
        ),
      ),
    );
  }

  group('CreditsScreen', () {
    group('Data Providers section', () {
      testWidgets('shows Data Providers group', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // SettingsGroup renders title.toUpperCase()
        expect(find.text('DATA PROVIDERS'), findsOneWidget);
        expect(find.byType(SettingsGroup), findsNWidgets(2));
      });

      testWidgets('shows TMDB attribution text',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(
          find.text(
            'This product uses the TMDB API but is not '
            'endorsed or certified by TMDB.',
          ),
          findsOneWidget,
        );
      });

      testWidgets('shows TMDB link', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('themoviedb.org'), findsOneWidget);
      });

      testWidgets('shows IGDB attribution text',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(
          find.text('Game data provided by IGDB.'),
          findsOneWidget,
        );
      });

      testWidgets('shows IGDB link', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('igdb.com'), findsOneWidget);
      });

      testWidgets('shows SteamGridDB attribution text',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.drag(find.byType(ListView), const Offset(0, -200));
        await tester.pumpAndSettle();

        expect(
          find.text('Artwork provided by SteamGridDB.'),
          findsOneWidget,
        );
      });

      testWidgets('shows SteamGridDB link', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.drag(find.byType(ListView), const Offset(0, -200));
        await tester.pumpAndSettle();

        expect(find.text('steamgriddb.com'), findsOneWidget);
      });

      testWidgets('shows AniList attribution text',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pumpAndSettle();

        expect(
          find.text('Manga data provided by AniList.'),
          findsOneWidget,
        );
      });

      testWidgets('shows AniList link', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pumpAndSettle();

        expect(find.text('anilist.co'), findsOneWidget);
      });

      testWidgets('shows open_in_new icons for provider links',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // At least TMDB and IGDB open_in_new icons visible
        expect(
          find.byIcon(Icons.open_in_new),
          findsAtLeastNWidgets(2),
        );
      });
    });

    group('Open Source section', () {
      testWidgets('shows Open Source group', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pumpAndSettle();

        // SettingsGroup renders title.toUpperCase()
        expect(find.text('OPEN SOURCE'), findsOneWidget);
      });

      testWidgets('shows MIT License text', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Tonkatsu Box is free and open source software, '
            'released under the MIT License.',
          ),
          findsOneWidget,
        );
      });

      testWidgets('shows GitHub link', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pumpAndSettle();

        expect(
          find.text('hacan359/tonkatsu_box'),
          findsOneWidget,
        );
      });

      testWidgets('shows View Open Source Licenses button',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pumpAndSettle();

        expect(
          find.text('View Open Source Licenses'),
          findsOneWidget,
        );
        expect(find.byType(OutlinedButton), findsOneWidget);
      });

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

      testWidgets('shows description_outlined icon on licenses button',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pumpAndSettle();

        expect(
          find.byIcon(Icons.description_outlined),
          findsOneWidget,
        );
      });
    });

    group('Layout', () {
      testWidgets('uses ListView for scrolling',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.byType(ListView), findsOneWidget);
      });

      testWidgets('shows all 5 provider links',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('themoviedb.org'), findsOneWidget);
        expect(find.text('igdb.com'), findsOneWidget);

        await tester.drag(find.byType(ListView), const Offset(0, -200));
        await tester.pumpAndSettle();

        expect(find.text('steamgriddb.com'), findsOneWidget);

        await tester.drag(find.byType(ListView), const Offset(0, -200));
        await tester.pumpAndSettle();

        expect(find.text('vndb.org'), findsOneWidget);
        expect(find.text('anilist.co'), findsOneWidget);
      });
    });

    group('Compact layout', () {
      Widget createCompactWidget() {
        return const MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: MediaQuery(
            data: MediaQueryData(size: Size(400, 800)),
            child: BreadcrumbScope(
              label: 'Settings',
              child: BreadcrumbScope(
                label: 'Credits',
                child: CreditsScreen(),
              ),
            ),
          ),
        );
      }

      testWidgets('renders in compact mode on narrow screens',
          (WidgetTester tester) async {
        await tester.pumpWidget(createCompactWidget());
        await tester.pumpAndSettle();

        expect(find.text('DATA PROVIDERS'), findsOneWidget);
        expect(find.text('themoviedb.org'), findsOneWidget);
      });

      testWidgets('shows all providers in compact mode',
          (WidgetTester tester) async {
        await tester.pumpWidget(createCompactWidget());
        await tester.pumpAndSettle();

        await tester.drag(find.byType(ListView), const Offset(0, -200));
        await tester.pumpAndSettle();

        expect(find.text('igdb.com'), findsOneWidget);
        expect(find.text('steamgriddb.com'), findsOneWidget);
      });

      testWidgets('shows Open Source section in compact mode',
          (WidgetTester tester) async {
        await tester.pumpWidget(createCompactWidget());
        await tester.pumpAndSettle();

        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pumpAndSettle();

        expect(find.text('OPEN SOURCE'), findsOneWidget);
        expect(
          find.text('View Open Source Licenses'),
          findsOneWidget,
        );
      });
    });
  });
}
