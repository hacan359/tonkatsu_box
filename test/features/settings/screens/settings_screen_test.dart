// Тесты для SettingsScreen (hub с секциями Profile и Settings).

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';
import 'package:xerabora/features/settings/screens/settings_screen.dart';
import 'package:xerabora/l10n/app_localizations.dart';
import 'package:xerabora/features/settings/widgets/inline_text_field.dart';
import 'package:xerabora/features/settings/widgets/settings_nav_row.dart';
import 'package:xerabora/features/settings/widgets/settings_section.dart';
import 'package:xerabora/shared/widgets/auto_breadcrumb_app_bar.dart';
import 'package:xerabora/shared/widgets/breadcrumb_scope.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
  });

  Widget createWidget() {
    return ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: BreadcrumbScope(
          label: 'Settings',
          child: SettingsScreen(),
        ),
      ),
    );
  }

  group('SettingsScreen', () {
    group('UI components', () {
      testWidgets('shows breadcrumb with Settings label',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.byType(AutoBreadcrumbAppBar), findsOneWidget);
        // "Settings" appears in breadcrumb and as section title
        expect(find.text('Settings'), findsAtLeastNWidgets(1));
      });

      testWidgets('shows Profile and Settings sections',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.byType(SettingsSection), findsAtLeastNWidgets(2));
        expect(find.text('Profile'), findsOneWidget);
        // "Settings" appears both as breadcrumb label and section title
        expect(find.text('Settings'), findsAtLeastNWidgets(1));
      });

      testWidgets('shows Help section after scrolling',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Scroll down to reveal Help section
        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pumpAndSettle();

        expect(find.text('Help'), findsOneWidget);
      });

      testWidgets('shows InlineTextField for author name',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.byType(InlineTextField), findsOneWidget);
        expect(find.text('Author name'), findsOneWidget);
        // Default author name
        expect(find.text('User'), findsOneWidget);
      });

      testWidgets('shows Credentials nav row with correct icon and subtitle',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Credentials'), findsOneWidget);
        expect(
          find.text('IGDB, SteamGridDB, TMDB API keys'),
          findsOneWidget,
        );

        final Finder credentialsTile = find.ancestor(
          of: find.text('Credentials'),
          matching: find.byType(ListTile),
        );
        final ListTile tile = tester.widget<ListTile>(credentialsTile);
        final Icon? leadingIcon = tile.leading as Icon?;
        expect(leadingIcon!.icon, equals(Icons.key));
      });

      testWidgets('shows Cache nav row with correct icon and subtitle',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Cache'), findsOneWidget);
        expect(find.text('Image cache settings'), findsOneWidget);

        final Finder cacheTile = find.ancestor(
          of: find.text('Cache'),
          matching: find.byType(ListTile),
        );
        final ListTile tile = tester.widget<ListTile>(cacheTile);
        final Icon? leadingIcon = tile.leading as Icon?;
        expect(leadingIcon!.icon, equals(Icons.cached));
      });

      testWidgets('shows Database nav row with correct icon and subtitle',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Database'), findsOneWidget);
        expect(find.text('Export, import, reset'), findsOneWidget);

        final Finder databaseTile = find.ancestor(
          of: find.text('Database'),
          matching: find.byType(ListTile),
        );
        final ListTile tile = tester.widget<ListTile>(databaseTile);
        final Icon? leadingIcon = tile.leading as Icon?;
        expect(leadingIcon!.icon, equals(Icons.storage));
      });

      testWidgets('shows Trakt Import nav row text',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Trakt Import'), findsOneWidget);
      });

      testWidgets('shows "Import from Trakt.tv ZIP export" subtitle',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(
          find.text('Import from Trakt.tv ZIP export'),
          findsOneWidget,
        );
      });

      testWidgets('shows movie_filter icon for Trakt Import row',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final Finder traktTile = find.ancestor(
          of: find.text('Trakt Import'),
          matching: find.byType(ListTile),
        );
        final ListTile tile = tester.widget<ListTile>(traktTile);
        final Icon? leadingIcon = tile.leading as Icon?;
        expect(leadingIcon!.icon, equals(Icons.movie_filter));
      });

      testWidgets(
          'shows Debug nav row with correct icon and subtitle when in debug mode',
          (WidgetTester tester) async {
        expect(kDebugMode, isTrue);

        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Debug'), findsOneWidget);
        expect(
          find.text('Set SteamGridDB key first for some tools'),
          findsOneWidget,
        );

        final Finder debugTile = find.ancestor(
          of: find.text('Debug'),
          matching: find.byType(ListTile),
        );
        final ListTile tile = tester.widget<ListTile>(debugTile);
        final Icon? leadingIcon = tile.leading as Icon?;
        expect(leadingIcon!.icon, equals(Icons.bug_report));
      });

      testWidgets('Debug nav row subtitle changes when SteamGridDB key is set',
          (WidgetTester tester) async {
        await prefs.setString(SettingsKeys.steamGridDbApiKey, 'test-key');

        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Developer tools'), findsOneWidget);
        expect(
          find.text('Set SteamGridDB key first for some tools'),
          findsNothing,
        );
      });

      testWidgets('shows chevron_right trailing icons for nav rows',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // 5 visible SettingsNavRow (Credentials + Cache + Database
        // + Trakt Import + Debug). Welcome Guide is below the fold.
        expect(find.byType(SettingsNavRow), findsNWidgets(5));

        // 5 nav row chevrons + 1 breadcrumb separator
        expect(find.byIcon(Icons.chevron_right), findsNWidgets(6));
      });

      testWidgets('Author name shows custom name when set',
          (WidgetTester tester) async {
        await prefs.setString(SettingsKeys.defaultAuthor, 'Hacan');

        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Hacan'), findsOneWidget);
      });
    });

    group('Section icons', () {
      testWidgets('shows person icon for Profile section',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.person), findsOneWidget);
      });

      testWidgets('shows tune icon for Settings section',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.tune), findsOneWidget);
      });
    });

    group('Navigation', () {
      testWidgets('nav rows have onTap callbacks',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final Iterable<ListTile> tiles = tester.widgetList<ListTile>(
          find.byType(ListTile),
        );

        // All ListTile instances (from SettingsNavRow) should have onTap
        for (final ListTile tile in tiles) {
          expect(tile.onTap, isNotNull,
              reason: 'Tile "${tile.title}" should have onTap');
        }
      });

      testWidgets('Credentials tile is tappable',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final Finder credentialsTile = find.ancestor(
          of: find.text('Credentials'),
          matching: find.byType(ListTile),
        );

        await tester.tap(credentialsTile);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('Cache tile is tappable', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final Finder cacheTile = find.ancestor(
          of: find.text('Cache'),
          matching: find.byType(ListTile),
        );

        await tester.tap(cacheTile);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('Database tile is tappable', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final Finder databaseTile = find.ancestor(
          of: find.text('Database'),
          matching: find.byType(ListTile),
        );

        await tester.tap(databaseTile);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('Trakt Import tile is tappable',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final Finder traktTile = find.ancestor(
          of: find.text('Trakt Import'),
          matching: find.byType(ListTile),
        );

        await tester.tap(traktTile);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('Debug tile is tappable', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final Finder debugTile = find.ancestor(
          of: find.text('Debug'),
          matching: find.byType(ListTile),
        );

        await tester.tap(debugTile);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    });

    group('Help section', () {
      testWidgets('shows Help section with help_outline icon',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Scroll down to reveal Help section
        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pumpAndSettle();

        expect(find.text('Help'), findsOneWidget);
        expect(find.byIcon(Icons.help_outline), findsOneWidget);
      });

      testWidgets('shows Welcome Guide nav row',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pumpAndSettle();

        expect(find.text('Welcome Guide'), findsOneWidget);
        expect(
          find.text('Getting started with Tonkatsu Box'),
          findsOneWidget,
        );
      });

      testWidgets('Welcome Guide has school icon',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pumpAndSettle();

        final Finder welcomeTile = find.ancestor(
          of: find.text('Welcome Guide'),
          matching: find.byType(ListTile),
        );
        final ListTile tile = tester.widget<ListTile>(welcomeTile);
        final Icon? leadingIcon = tile.leading as Icon?;
        expect(leadingIcon!.icon, equals(Icons.school));
      });

      testWidgets('Welcome Guide tile is tappable',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pumpAndSettle();

        final Finder welcomeTile = find.ancestor(
          of: find.text('Welcome Guide'),
          matching: find.byType(ListTile),
        );

        await tester.tap(welcomeTile);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    });

    group('About section', () {
      testWidgets('shows About section after scrolling',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pumpAndSettle();

        expect(find.text('About'), findsOneWidget);
        expect(find.byIcon(Icons.info_outline), findsOneWidget);
      });

      testWidgets('shows Version nav row',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pumpAndSettle();

        expect(find.text('Version'), findsOneWidget);
      });

      testWidgets('shows version placeholder before PackageInfo loads',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        // Только pump() — не ждём async _loadVersion
        await tester.pump();

        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pump();

        // До загрузки PackageInfo subtitle = '...'
        expect(find.text('...'), findsOneWidget);
      });

      testWidgets('shows Credits & Licenses nav row',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pumpAndSettle();

        expect(find.text('Credits & Licenses'), findsOneWidget);
        expect(
          find.text('TMDB, IGDB, SteamGridDB, open-source licenses'),
          findsOneWidget,
        );
      });

      testWidgets('Credits & Licenses tile is tappable',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pumpAndSettle();

        final Finder creditsTile = find.ancestor(
          of: find.text('Credits & Licenses'),
          matching: find.byType(ListTile),
        );

        await tester.tap(creditsTile);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('Version has tag icon', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pumpAndSettle();

        final Finder versionTile = find.ancestor(
          of: find.text('Version'),
          matching: find.byType(ListTile),
        );
        final ListTile tile = tester.widget<ListTile>(versionTile);
        final Icon? leadingIcon = tile.leading as Icon?;
        expect(leadingIcon!.icon, equals(Icons.tag));
      });

      testWidgets('Credits & Licenses has favorite_outline icon',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pumpAndSettle();

        final Finder creditsTile = find.ancestor(
          of: find.text('Credits & Licenses'),
          matching: find.byType(ListTile),
        );
        final ListTile tile = tester.widget<ListTile>(creditsTile);
        final Icon? leadingIcon = tile.leading as Icon?;
        expect(leadingIcon!.icon, equals(Icons.favorite_outline));
      });
    });

    group('Error handling', () {
      testWidgets('does not show error section by default',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Profile + Language + Settings visible; Help + About below fold
        // No Error section should be present
        expect(find.byIcon(Icons.warning_amber), findsNothing);
      });

      testWidgets('shows error section when errorMessage is set',
          (WidgetTester tester) async {
        const String errorMessage = 'Test error message';

        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              sharedPreferencesProvider.overrideWithValue(prefs),
              settingsNotifierProvider.overrideWith(
                () => _TestSettingsNotifier(errorMessage),
              ),
            ],
            child: const MaterialApp(
              localizationsDelegates: S.localizationsDelegates,
              supportedLocales: S.supportedLocales,
              home: BreadcrumbScope(
                label: 'Settings',
                child: SettingsScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Scroll down to make error section visible (past all sections)
        await tester.drag(find.byType(ListView), const Offset(0, -1200));
        await tester.pumpAndSettle();

        // Error section should show warning icon and error text
        expect(find.byIcon(Icons.warning_amber), findsOneWidget);
        expect(find.text(errorMessage), findsOneWidget);
      });
    });
  });
}

/// Тестовый notifier с кастомным errorMessage.
class _TestSettingsNotifier extends SettingsNotifier {
  _TestSettingsNotifier(this._errorMessage);

  final String _errorMessage;

  @override
  SettingsState build() {
    ref.watch(sharedPreferencesProvider);
    return SettingsState(errorMessage: _errorMessage);
  }
}
