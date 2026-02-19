import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';
import 'package:xerabora/features/settings/screens/debug_hub_screen.dart';
import 'package:xerabora/shared/widgets/breadcrumb_scope.dart';

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
          home: BreadcrumbScope(
            label: 'Settings',
            child: DebugHubScreen(),
          ),
        ),
      );
    }

    testWidgets('Показывает хлебные крошки Settings и Debug',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Debug'), findsOneWidget);
    });

    testWidgets('Показывает плитку SteamGridDB Debug Panel',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('SteamGridDB Debug Panel'), findsOneWidget);
    });

    testWidgets('Показывает плитку Image Debug Panel',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Image Debug Panel'), findsOneWidget);
    });

    testWidgets('Показывает плитку Gamepad Debug Panel',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Gamepad Debug Panel'), findsOneWidget);
    });

    testWidgets('Показывает правильные иконки', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.grid_view), findsOneWidget);
      expect(find.byIcon(Icons.image_search), findsOneWidget);
      expect(find.byIcon(Icons.gamepad), findsOneWidget);
    });

    testWidgets('SteamGridDB плитка отключена когда нет API ключа',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final Finder steamGridTile = find.ancestor(
        of: find.text('SteamGridDB Debug Panel'),
        matching: find.byType(ListTile),
      );

      final ListTile tile = tester.widget<ListTile>(steamGridTile);
      expect(tile.enabled, false);
    });

    testWidgets(
        'SteamGridDB плитка показывает подзаголовок Set API key first когда нет ключа',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Set API key first'), findsOneWidget);
    });

    testWidgets('SteamGridDB плитка активна когда есть API ключ',
        (WidgetTester tester) async {
      await prefs.setString('steamgriddb_api_key', 'test_key');

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final Finder steamGridTile = find.ancestor(
        of: find.text('SteamGridDB Debug Panel'),
        matching: find.byType(ListTile),
      );

      final ListTile tile = tester.widget<ListTile>(steamGridTile);
      expect(tile.enabled, true);
      expect(find.text('Set API key first'), findsNothing);
    });

    testWidgets('Все плитки имеют иконки chevron_right',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // 3 ListTile chevrons + 2 breadcrumb separators
      expect(find.byIcon(Icons.chevron_right), findsNWidgets(5));
    });
  });
}
