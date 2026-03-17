import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xerabora/core/services/api_key_initializer.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';
import 'package:xerabora/features/settings/screens/credentials_screen.dart';
import 'package:xerabora/features/settings/widgets/inline_text_field.dart';
import 'package:xerabora/features/settings/widgets/settings_group.dart';
import 'package:xerabora/features/settings/widgets/status_dot.dart';
import 'package:xerabora/l10n/app_localizations.dart';
import 'package:xerabora/shared/widgets/breadcrumb_scope.dart';
import 'package:xerabora/shared/widgets/source_badge.dart';

void main() {
  group('CredentialsScreen', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferences.getInstance();
    });

    Widget createWidget({bool isInitialSetup = false}) {
      return ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
          apiKeysProvider.overrideWithValue(const ApiKeys()),
        ],
        child: MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: BreadcrumbScope(
            label: 'Settings',
            child: CredentialsScreen(isInitialSetup: isInitialSetup),
          ),
        ),
      );
    }

    group('Breadcrumbs', () {
      testWidgets('should show Settings breadcrumb',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Settings'), findsOneWidget);
      });

      testWidgets('should show Credentials breadcrumb',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Credentials'), findsOneWidget);
      });
    });

    group('SettingsGroup widgets', () {
      testWidgets('should use SettingsGroup for sections',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // IGDB + Connection + SteamGridDB + TMDB = 4 groups minimum
        expect(find.byType(SettingsGroup), findsAtLeastNWidgets(4));
      });
    });

    group('IGDB section', () {
      testWidgets('should show InlineTextField for Client ID',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Client ID'), findsOneWidget);
        expect(find.byType(InlineTextField), findsAtLeastNWidgets(1));
      });

      testWidgets('should show InlineTextField for Client Secret',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Client Secret'), findsOneWidget);
      });

      testWidgets('should show SourceBadge for IGDB',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final List<SourceBadge> badges =
            tester.widgetList<SourceBadge>(find.byType(SourceBadge)).toList();
        expect(
          badges.any((SourceBadge badge) => badge.source == DataSource.igdb),
          isTrue,
        );
      });

      testWidgets('Client Secret should be obscured',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.visibility), findsAtLeastNWidgets(1));
      });
    });

    group('SteamGridDB section', () {
      testWidgets('should show InlineTextField for API Key',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await _scrollDown(tester);
        await tester.pumpAndSettle();

        expect(find.text('API Key'), findsAtLeastNWidgets(1));
      });

      testWidgets('should show SourceBadge for SteamGridDB',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await _scrollDown(tester);
        await tester.pumpAndSettle();

        final List<SourceBadge> badges =
            tester.widgetList<SourceBadge>(find.byType(SourceBadge)).toList();
        expect(
          badges.any(
              (SourceBadge badge) => badge.source == DataSource.steamGridDb),
          isTrue,
        );
      });

      testWidgets('should show StatusDot for SteamGridDB key',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await _scrollDown(tester);
        await tester.pumpAndSettle();

        expect(find.byType(StatusDot), findsAtLeastNWidgets(1));
      });

      testWidgets('should show "No API key" status when no key',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await _scrollDown(tester);
        await tester.pumpAndSettle();

        expect(find.text('No API key'), findsAtLeastNWidgets(1));
      });
    });

    group('TMDB section', () {
      testWidgets('should show InlineTextField for TMDB API Key',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await _scrollDown(tester);
        await tester.pumpAndSettle();

        // API Key label appears for SteamGridDB and TMDB
        expect(find.text('API Key'), findsAtLeastNWidgets(2));
      });

      testWidgets('should show SourceBadge for TMDB',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await _scrollDown(tester);
        await tester.pumpAndSettle();

        final List<SourceBadge> badges =
            tester.widgetList<SourceBadge>(find.byType(SourceBadge)).toList();
        expect(
          badges.any((SourceBadge badge) => badge.source == DataSource.tmdb),
          isTrue,
        );
      });

      testWidgets('should show StatusDot for TMDB key',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await _scrollDown(tester);
        await tester.pumpAndSettle();

        // StatusDot: connection + steamgriddb + tmdb
        expect(find.byType(StatusDot), findsAtLeastNWidgets(2));
      });
    });

    group('Actions section', () {
      testWidgets('should show Verify Connection button',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Verify Connection'), findsOneWidget);
      });

      testWidgets('should show snackbar when fields are empty',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Verify Connection'));
        await tester.pumpAndSettle();

        expect(
          find.text('Please enter both Client ID and Client Secret'),
          findsOneWidget,
        );
      });
    });

    group('Status section', () {
      testWidgets('should show Not Connected by default',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Not Connected'), findsOneWidget);
      });

      testWidgets('should show Platforms available count',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.textContaining('Platforms available'), findsOneWidget);
        expect(find.textContaining(': 0'), findsOneWidget);
      });

      testWidgets('should show StatusDot for connection',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.byType(StatusDot), findsAtLeastNWidgets(1));
        expect(find.text('?'), findsAtLeastNWidgets(1));
      });

      testWidgets('should show platforms icon', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.videogame_asset), findsOneWidget);
      });
    });

    group('Welcome section', () {
      testWidgets('should show Welcome section when isInitialSetup=true',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(isInitialSetup: true));
        await tester.pumpAndSettle();

        // SettingsGroup renders title in uppercase
        expect(
          find.text('WELCOME TO TONKATSU BOX!'),
          findsOneWidget,
        );
      });

      testWidgets('should hide Welcome section when isInitialSetup=false',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(isInitialSetup: false));
        await tester.pumpAndSettle();

        expect(find.text('WELCOME TO TONKATSU BOX!'), findsNothing);
      });

      testWidgets('should show Copy Twitch Console URL button',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(isInitialSetup: true));
        await tester.pumpAndSettle();

        expect(find.text('Copy Twitch Console URL'), findsOneWidget);
      });

      testWidgets('should copy URL when button is tapped',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(isInitialSetup: true));
        await tester.pumpAndSettle();

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          SystemChannels.platform,
          (MethodCall methodCall) async {
            if (methodCall.method == 'Clipboard.setData') {
              return null;
            }
            return null;
          },
        );

        await tester.tap(find.text('Copy Twitch Console URL'));
        await tester.pumpAndSettle();

        expect(find.textContaining('URL copied'), findsOneWidget);
      });
    });

    group('Loading existing credentials', () {
      testWidgets('should load Client ID from SharedPreferences',
          (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'igdb_client_id': 'existing_client_id',
        });
        prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('existing_client_id'), findsOneWidget);
      });

      testWidgets('should load Client Secret (obscured by default)',
          (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'igdb_client_secret': 'existing_secret',
        });
        prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('existing_secret'), findsNothing);
        expect(
          find.text(
              '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022'),
          findsOneWidget,
        );
      });

      testWidgets('should load all credentials simultaneously',
          (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'igdb_client_id': 'full_client_id',
          'igdb_client_secret': 'full_secret',
          'steamgriddb_api_key': 'full_sgdb_key',
          'tmdb_api_key': 'full_tmdb_key',
        });
        prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('full_client_id'), findsOneWidget);
        expect(
          find.text(
              '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022'),
          findsAtLeastNWidgets(1),
        );
      });
    });

    group('Auto-save API keys', () {
      testWidgets('SteamGridDB InlineTextField shows placeholder',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await _scrollDown(tester);
        await tester.pumpAndSettle();

        expect(find.byType(InlineTextField), findsAtLeastNWidgets(1));
      });

      testWidgets('TMDB InlineTextField shows placeholder',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await _scrollDown(tester);
        await tester.pumpAndSettle();

        expect(find.byType(InlineTextField), findsAtLeastNWidgets(2));
      });
    });

    group('Test button', () {
      testWidgets('does not show Test button without API key',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await _scrollDown(tester);
        await tester.pumpAndSettle();

        expect(find.byTooltip('Test'), findsNothing);
      });

      testWidgets('shows Test button when SteamGridDB key is saved',
          (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'steamgriddb_api_key': 'saved_key',
        });
        prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await _scrollDown(tester);
        await tester.pumpAndSettle();

        expect(find.byTooltip('Test'), findsAtLeastNWidgets(1));
      });

      testWidgets('shows Test button when TMDB key is saved',
          (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'tmdb_api_key': 'saved_key',
        });
        prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await _scrollDown(tester);
        await tester.pumpAndSettle();

        expect(find.byTooltip('Test'), findsAtLeastNWidgets(1));
      });

      testWidgets('shows 2 Test buttons when both keys are saved',
          (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'steamgriddb_api_key': 'sgdb_key',
          'tmdb_api_key': 'tmdb_key',
        });
        prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await _scrollDown(tester);
        await tester.pumpAndSettle();

        expect(find.byTooltip('Test'), findsNWidgets(2));
      });
    });

    group('Error section', () {
      testWidgets('does not show Error section by default',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await _scrollDown(tester);
        await tester.pumpAndSettle();

        expect(find.text('Error'), findsNothing);
      });
    });

    group('SourceBadge widgets', () {
      testWidgets('should show 3 SourceBadge widgets',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await _scrollDown(tester);
        await tester.pumpAndSettle();

        expect(find.byType(SourceBadge), findsNWidgets(3));
      });

      testWidgets('all SourceBadge should be large size',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await _scrollDown(tester);
        await tester.pumpAndSettle();

        final List<SourceBadge> badges =
            tester.widgetList<SourceBadge>(find.byType(SourceBadge)).toList();

        for (final SourceBadge badge in badges) {
          expect(badge.size, equals(SourceBadgeSize.large));
        }
      });

      testWidgets('should show correct sources',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await _scrollDown(tester);
        await tester.pumpAndSettle();

        final List<SourceBadge> badges =
            tester.widgetList<SourceBadge>(find.byType(SourceBadge)).toList();
        final List<DataSource> sources =
            badges.map((SourceBadge badge) => badge.source).toList();

        expect(sources, contains(DataSource.igdb));
        expect(sources, contains(DataSource.steamGridDb));
        expect(sources, contains(DataSource.tmdb));
      });
    });
  });
}

/// Скроллит вниз основной Scrollable.
Future<void> _scrollDown(WidgetTester tester) async {
  final Finder scrollable = find.byType(SingleChildScrollView);
  if (scrollable.evaluate().isNotEmpty) {
    await tester.drag(scrollable.first, const Offset(0, -500));
  }
}
