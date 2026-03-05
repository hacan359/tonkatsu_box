import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';
import 'package:xerabora/features/settings/screens/cache_screen.dart';
import 'package:xerabora/features/settings/widgets/settings_group.dart';
import 'package:xerabora/features/settings/widgets/settings_tile.dart';
import 'package:xerabora/l10n/app_localizations.dart';
import 'package:xerabora/shared/widgets/breadcrumb_scope.dart';

void main() {
  group('CacheScreen', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'image_cache_enabled': false,
      });
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
            child: CacheScreen(),
          ),
        ),
      );
    }

    testWidgets('shows breadcrumbs Settings and Cache',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Cache'), findsOneWidget);
    });

    testWidgets('shows SettingsGroup for Image Cache',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(SettingsGroup), findsOneWidget);
    });

    testWidgets('shows Offline mode switch', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('shows SettingsTile widgets for cache options',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Offline mode + Cache folder + Cache size = 3 tiles
      expect(find.byType(SettingsTile), findsAtLeastNWidgets(3));
    });

    testWidgets('Offline mode switch has initial value false',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final Finder switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);

      final Switch switchWidget = tester.widget<Switch>(switchFinder);
      expect(switchWidget.value, false);
    });

    testWidgets('shows cache stats with 0 files',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('0 files'), findsOneWidget);
    });

    testWidgets('shows delete icon for cache clearing',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('shows folder picker icon', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.folder_open), findsOneWidget);
    });
  });
}
