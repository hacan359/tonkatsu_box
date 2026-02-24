// Тесты для CreditsScreen (атрибуция API-провайдеров и лицензии).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/settings/screens/credits_screen.dart';
import 'package:xerabora/l10n/app_localizations.dart';
import 'package:xerabora/shared/widgets/breadcrumb_scope.dart';

void main() {
  setUp(() {
    // Мок для SVG-ассетов — rootBundle.loadString возвращает валидный SVG.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (ByteData? message) async {
      const String svgContent =
          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">'
          '<rect width="100" height="100" fill="blue"/></svg>';
      return ByteData.sublistView(
        Uint8List.fromList(svgContent.codeUnits),
      );
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

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
      testWidgets('shows Data Providers header',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        expect(find.text('Data Providers'), findsOneWidget);
      });

      testWidgets('shows TMDB attribution text',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

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
        await tester.pump();

        expect(find.text('themoviedb.org'), findsOneWidget);
      });

      testWidgets('shows IGDB attribution text',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        expect(
          find.text('Game data provided by IGDB.'),
          findsOneWidget,
        );
      });

      testWidgets('shows IGDB link', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        expect(find.text('igdb.com'), findsOneWidget);
      });

      testWidgets('shows SteamGridDB attribution text',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        // Scroll to see SteamGridDB card
        await tester.drag(find.byType(ListView), const Offset(0, -200));
        await tester.pump();

        expect(
          find.text('Artwork provided by SteamGridDB.'),
          findsOneWidget,
        );
      });

      testWidgets('shows SteamGridDB link', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        await tester.drag(find.byType(ListView), const Offset(0, -200));
        await tester.pump();

        expect(find.text('steamgriddb.com'), findsOneWidget);
      });

      testWidgets('shows open_in_new icons for provider links',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        // At least TMDB and IGDB open_in_new icons visible
        expect(
          find.byIcon(Icons.open_in_new),
          findsAtLeastNWidgets(2),
        );
      });
    });

    group('Open Source section', () {
      testWidgets('shows Open Source header', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        // Scroll down to Open Source section
        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pump();

        expect(find.text('Open Source'), findsOneWidget);
      });

      testWidgets('shows MIT License text', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pump();

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
        await tester.pump();

        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pump();

        expect(
          find.text('github.com/hacan359/tonkatsu_box'),
          findsOneWidget,
        );
      });

      testWidgets('shows View Open Source Licenses button',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pump();

        expect(
          find.text('View Open Source Licenses'),
          findsOneWidget,
        );
        expect(find.byType(OutlinedButton), findsOneWidget);
      });

      testWidgets('View Open Source Licenses button is tappable',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pump();

        await tester.tap(find.text('View Open Source Licenses'));
        await tester.pumpAndSettle();

        // showLicensePage opens a page route — no exception thrown
        expect(tester.takeException(), isNull);
      });

      testWidgets('shows description_outlined icon on licenses button',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pump();

        expect(
          find.byIcon(Icons.description_outlined),
          findsOneWidget,
        );
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
        await tester.pump();

        // All content still visible
        expect(find.text('Data Providers'), findsOneWidget);
        expect(find.text('themoviedb.org'), findsOneWidget);
      });

      testWidgets('shows all providers in compact mode',
          (WidgetTester tester) async {
        await tester.pumpWidget(createCompactWidget());
        await tester.pump();

        await tester.drag(find.byType(ListView), const Offset(0, -200));
        await tester.pump();

        expect(find.text('igdb.com'), findsOneWidget);
        expect(find.text('steamgriddb.com'), findsOneWidget);
      });

      testWidgets('shows Open Source section in compact mode',
          (WidgetTester tester) async {
        await tester.pumpWidget(createCompactWidget());
        await tester.pump();

        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pump();

        expect(find.text('Open Source'), findsOneWidget);
        expect(
          find.text('View Open Source Licenses'),
          findsOneWidget,
        );
      });
    });

    group('Layout', () {
      testWidgets('uses ListView for scrolling',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        expect(find.byType(ListView), findsOneWidget);
      });

      testWidgets('renders 3 provider cards',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        // All 3 providers have open_in_new icon + GitHub link also has one
        // TMDB, IGDB cards visible initially, SteamGridDB may need scroll
        await tester.drag(find.byType(ListView), const Offset(0, -200));
        await tester.pump();

        expect(find.text('themoviedb.org'), findsOneWidget);
        expect(find.text('igdb.com'), findsOneWidget);
        expect(find.text('steamgriddb.com'), findsOneWidget);
      });
    });
  });
}
