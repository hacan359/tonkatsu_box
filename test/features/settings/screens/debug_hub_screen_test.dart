import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';
import 'package:xerabora/features/settings/screens/debug_hub_screen.dart';
import 'package:xerabora/features/settings/widgets/settings_group.dart';
import 'package:xerabora/features/settings/widgets/settings_tile.dart';
import 'package:xerabora/l10n/app_localizations.dart';

void main() {
  group('DebugHubScreen', () {
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
          home: DebugHubScreen(),
        ),
      );
    }

    testWidgets('shows SettingsGroup widget', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(SettingsGroup), findsOneWidget);
    });

    testWidgets('shows 4 SettingsTile widgets', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(SettingsTile), findsNWidgets(4));
    });

    testWidgets('shows SteamGridDB Debug Panel tile',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('SteamGridDB Debug Panel'), findsOneWidget);
    });

    testWidgets('shows Image Debug Panel tile', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Image Debug Panel'), findsOneWidget);
    });

    testWidgets('shows Gamepad Debug Panel tile',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Gamepad Debug Panel'), findsOneWidget);
    });

    testWidgets('shows Demo Collections Generator tile',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Demo Collections Generator'), findsOneWidget);
    });

    testWidgets(
        'SteamGridDB tile shows "Set API key first" when no key',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Set API key first'), findsOneWidget);
    });

    testWidgets('SteamGridDB tile is not tappable when no API key',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // SettingsTile with onTap: null → no chevron, not tappable
      final Finder steamGridTile = find.ancestor(
        of: find.text('SteamGridDB Debug Panel'),
        matching: find.byType(SettingsTile),
      );
      final SettingsTile tile = tester.widget<SettingsTile>(steamGridTile);
      expect(tile.onTap, isNull);
    });

    testWidgets('SteamGridDB tile is tappable when API key is set',
        (WidgetTester tester) async {
      await prefs.setString('steamgriddb_api_key', 'test_key');

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final Finder steamGridTile = find.ancestor(
        of: find.text('SteamGridDB Debug Panel'),
        matching: find.byType(SettingsTile),
      );
      final SettingsTile tile = tester.widget<SettingsTile>(steamGridTile);
      expect(tile.onTap, isNotNull);
      expect(find.text('Set API key first'), findsNothing);
    });

    testWidgets('shows "Test API endpoints" when SteamGridDB key is set',
        (WidgetTester tester) async {
      await prefs.setString('steamgriddb_api_key', 'test_key');

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Test API endpoints'), findsOneWidget);
    });

    testWidgets('Image Debug Panel shows subtitle',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Check poster URLs and loading'), findsOneWidget);
    });

    testWidgets('Gamepad Debug Panel shows subtitle',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Test controller input events'), findsOneWidget);
    });

    testWidgets('Demo Collections is not tappable without IGDB and TMDB keys',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final Finder demoTile = find.ancestor(
        of: find.text('Demo Collections Generator'),
        matching: find.byType(SettingsTile),
      );
      final SettingsTile tile = tester.widget<SettingsTile>(demoTile);
      expect(tile.onTap, isNull);
    });

    testWidgets('shows chevron icons on tappable tiles',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Image Debug + Gamepad Debug are always tappable = 2 chevrons
      // SteamGridDB + Demo are disabled (no key) = 0 chevrons
      expect(find.byIcon(Icons.chevron_right), findsAtLeastNWidgets(2));
    });
  });
}
