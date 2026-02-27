// Тесты для SettingsScreen (новый дизайн с SettingsGroup/SettingsTile).

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';
import 'package:xerabora/features/settings/screens/settings_screen.dart';
import 'package:xerabora/features/settings/widgets/settings_group.dart';
import 'package:xerabora/features/settings/widgets/settings_sidebar.dart';
import 'package:xerabora/features/settings/widgets/settings_tile.dart';
import 'package:xerabora/l10n/app_localizations.dart';
import 'package:xerabora/features/settings/widgets/inline_text_field.dart';
import 'package:xerabora/shared/widgets/auto_breadcrumb_app_bar.dart';
import 'package:xerabora/shared/widgets/breadcrumb_scope.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
  });

  Widget createWidget({double width = 400}) {
    return ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(size: Size(width, 800)),
          child: const BreadcrumbScope(
            label: 'Settings',
            child: SettingsScreen(),
          ),
        ),
      ),
    );
  }

  group('SettingsScreen', () {
    group('Mobile layout (< 800px)', () {
      testWidgets('shows breadcrumb with Settings label',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.byType(AutoBreadcrumbAppBar), findsOneWidget);
        expect(find.text('Settings'), findsAtLeastNWidgets(1));
      });

      testWidgets('shows SettingsGroup widgets',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // At least Profile, Connections, Data, About groups
        expect(find.byType(SettingsGroup), findsAtLeastNWidgets(4));
      });

      testWidgets('shows SettingsTile widgets',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Multiple SettingsTile widgets in groups
        expect(find.byType(SettingsTile), findsAtLeastNWidgets(5));
      });

      testWidgets('shows Profile group with InlineTextField',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('PROFILE'), findsOneWidget);
        expect(find.byType(InlineTextField), findsOneWidget);
        expect(find.text('Author name'), findsOneWidget);
        expect(find.text('User'), findsOneWidget);
      });

      testWidgets('shows Connections group with API Keys tile',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('CONNECTIONS'), findsOneWidget);
        expect(find.text('API Keys'), findsOneWidget);
      });

      testWidgets('shows Data group with Cache, Database, Trakt Import',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('DATA'), findsOneWidget);
        expect(find.text('Cache'), findsOneWidget);
        expect(find.text('Database'), findsOneWidget);
        expect(find.text('Trakt Import'), findsOneWidget);
      });

      testWidgets('shows About group after scrolling',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pumpAndSettle();

        expect(find.text('ABOUT'), findsOneWidget);
        expect(find.text('Welcome Guide'), findsOneWidget);
        expect(find.text('Credits & Licenses'), findsOneWidget);
        expect(find.text('Version'), findsOneWidget);
      });

      testWidgets('shows App Language tile with current value',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('App Language'), findsOneWidget);
        expect(find.text('English'), findsOneWidget);
      });

      testWidgets('shows Recommendations switch',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Recommendations'), findsOneWidget);
        expect(find.byType(Switch), findsOneWidget);
      });

      testWidgets('shows Debug group in debug mode',
          (WidgetTester tester) async {
        expect(kDebugMode, isTrue);

        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pumpAndSettle();

        // Debug title appears as group header and tile text
        expect(find.text('DEBUG'), findsOneWidget);
      });

      testWidgets('Debug tile shows correct subtitle when no key',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pumpAndSettle();

        expect(
          find.text('Set SteamGridDB key first for some tools'),
          findsOneWidget,
        );
      });

      testWidgets('Debug tile shows "Developer tools" when key set',
          (WidgetTester tester) async {
        await prefs.setString(SettingsKeys.steamGridDbApiKey, 'test-key');

        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pumpAndSettle();

        expect(find.text('Developer tools'), findsOneWidget);
      });

      testWidgets('Author name shows custom name when set',
          (WidgetTester tester) async {
        await prefs.setString(SettingsKeys.defaultAuthor, 'Hacan');

        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Hacan'), findsOneWidget);
      });

      testWidgets('shows no sidebar on mobile',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(width: 400));
        await tester.pumpAndSettle();

        expect(find.byType(SettingsSidebar), findsNothing);
      });

      testWidgets('shows chevrons on tiles with onTap',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Chevrons on tiles that navigate: API Keys, Cache, Database, etc.
        expect(find.byIcon(Icons.chevron_right), findsAtLeastNWidgets(3));
      });
    });

    group('Desktop layout (>= 800px)', () {
      testWidgets('shows sidebar on desktop',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(width: 900));
        await tester.pumpAndSettle();

        expect(find.byType(SettingsSidebar), findsOneWidget);
      });

      testWidgets('shows content panel on desktop',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(width: 900));
        await tester.pumpAndSettle();

        // Default selected index=0 shows Profile content
        expect(find.text('Profile'), findsAtLeastNWidgets(1));
        expect(find.byType(InlineTextField), findsOneWidget);
      });

      testWidgets('sidebar has expected items',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(width: 900));
        await tester.pumpAndSettle();

        expect(find.text('API Keys'), findsOneWidget);
        expect(find.text('Cache'), findsOneWidget);
        expect(find.text('Database'), findsOneWidget);
        expect(find.text('Trakt Import'), findsOneWidget);
        expect(find.text('Credits & Licenses'), findsOneWidget);
      });

      testWidgets('does not show SettingsGroup/SettingsTile on desktop',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(width: 900));
        await tester.pumpAndSettle();

        // Desktop layout uses sidebar + content, not SettingsGroup/SettingsTile
        expect(find.byType(SettingsGroup), findsNothing);
        expect(find.byType(SettingsTile), findsNothing);
      });

      testWidgets('has VerticalDivider between sidebar and content',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(width: 900));
        await tester.pumpAndSettle();

        expect(find.byType(VerticalDivider), findsOneWidget);
      });
    });

    group('Navigation (mobile)', () {
      testWidgets('API Keys tile is tappable',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final Finder apiKeysTile = find.ancestor(
          of: find.text('API Keys'),
          matching: find.byType(SettingsTile),
        );
        await tester.tap(apiKeysTile);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('Cache tile is tappable', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final Finder cacheTile = find.ancestor(
          of: find.text('Cache'),
          matching: find.byType(SettingsTile),
        );
        await tester.tap(cacheTile);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('Database tile is tappable',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final Finder databaseTile = find.ancestor(
          of: find.text('Database'),
          matching: find.byType(SettingsTile),
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
          matching: find.byType(SettingsTile),
        );
        await tester.tap(traktTile);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    });

    group('Error handling', () {
      testWidgets('does not show error section by default',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Scroll all the way down
        await tester.drag(find.byType(ListView), const Offset(0, -1500));
        await tester.pumpAndSettle();

        // No error text should be present
        expect(find.text('ERROR'), findsNothing);
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
              home: MediaQuery(
                data: MediaQueryData(size: Size(400, 800)),
                child: BreadcrumbScope(
                  label: 'Settings',
                  child: SettingsScreen(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Scroll down to make error section visible
        await tester.drag(find.byType(ListView), const Offset(0, -1500));
        await tester.pumpAndSettle();

        expect(find.text('ERROR'), findsOneWidget);
        expect(find.text(errorMessage), findsOneWidget);
      });
    });

    group('Version', () {
      testWidgets('shows version placeholder before PackageInfo loads',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pump();

        expect(find.text('...'), findsOneWidget);
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
