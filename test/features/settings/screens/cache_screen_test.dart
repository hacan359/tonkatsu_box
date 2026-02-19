import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';
import 'package:xerabora/features/settings/screens/cache_screen.dart';
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
          home: BreadcrumbScope(
            label: 'Settings',
            child: CacheScreen(),
          ),
        ),
      );
    }

    testWidgets('Показывает хлебные крошки Settings и Cache',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Cache'), findsOneWidget);
    });

    testWidgets('Показывает заголовок секции Image Cache',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Image Cache'), findsOneWidget);
    });

    testWidgets('Показывает переключатель Offline mode',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Offline mode'), findsOneWidget);
      expect(find.byType(SwitchListTile), findsOneWidget);
    });

    testWidgets('Показывает метку Cache folder', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Cache folder'), findsOneWidget);
    });

    testWidgets('Показывает метку Cache size', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Cache size'), findsOneWidget);
    });

    testWidgets('Переключатель Offline mode имеет начальное значение false',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final Finder switchTile = find.byType(SwitchListTile);
      expect(switchTile, findsOneWidget);

      final SwitchListTile tile =
          tester.widget<SwitchListTile>(switchTile);
      expect(tile.value, false);
    });

    testWidgets('Показывает иконки', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.folder), findsOneWidget);
      expect(find.byIcon(Icons.folder_open), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });
  });
}
