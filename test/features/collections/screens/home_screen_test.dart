import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xerabora/features/collections/screens/home_screen.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';

void main() {
  group('HomeScreen', () {
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
          home: HomeScreen(),
        ),
      );
    }

    testWidgets('должен показывать заголовок xeRAbora',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('xeRAbora'), findsOneWidget);
    });

    testWidgets('должен показывать кнопку настроек',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('должен показывать текст Your Collections',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Your Collections'), findsOneWidget);
    });

    testWidgets('должен показывать сообщение Coming soon',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Coming soon in Stage 3'), findsOneWidget);
    });

    testWidgets('должен показывать FAB New Collection',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('New Collection'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('должен показывать статус API', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('API Status'), findsOneWidget);
    });

    testWidgets('должен показывать счётчик платформ',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Platforms'), findsOneWidget);
      expect(find.text('0 synced'), findsOneWidget);
    });

    testWidgets('должен показывать Not Connected когда API не готов',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Not Connected'), findsOneWidget);
    });

    testWidgets('должен показывать Connected когда API готов',
        (WidgetTester tester) async {
      final int futureExpiry =
          DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600;

      SharedPreferences.setMockInitialValues(<String, Object>{
        'igdb_client_id': 'test_client_id',
        'igdb_client_secret': 'test_client_secret',
        'igdb_access_token': 'test_access_token',
        'igdb_token_expires': futureExpiry,
      });
      prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Connected'), findsOneWidget);
    });

    testWidgets('FAB должен показывать snackbar при нажатии',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(
        find.text('Collection creation coming in Stage 3'),
        findsOneWidget,
      );
    });

    testWidgets('кнопка настроек должна открывать SettingsScreen',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Проверяем что открылся SettingsScreen
      expect(find.text('IGDB API Setup'), findsOneWidget);
    });

    testWidgets('должен показывать иконку коллекций',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.collections_bookmark), findsOneWidget);
    });
  });
}
