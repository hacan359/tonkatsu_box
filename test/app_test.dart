import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xerabora/app.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';

void main() {
  group('XeraboraApp', () {
    testWidgets('должен рендерить MaterialApp', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const XeraboraApp(),
        ),
      );

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('должен показывать SettingsScreen когда нет API ключа',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const XeraboraApp(),
        ),
      );

      await tester.pumpAndSettle();

      // SettingsScreen показывается для initial setup
      expect(find.text('IGDB API Setup'), findsOneWidget);
    });

    testWidgets('должен показывать HomeScreen когда есть валидный API ключ',
        (WidgetTester tester) async {
      final int futureExpiry =
          DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600;

      SharedPreferences.setMockInitialValues(<String, Object>{
        'igdb_client_id': 'test_client_id',
        'igdb_client_secret': 'test_client_secret',
        'igdb_access_token': 'test_access_token',
        'igdb_token_expires': futureExpiry,
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const XeraboraApp(),
        ),
      );

      await tester.pumpAndSettle();

      // HomeScreen показывает заголовок xeRAbora
      expect(find.text('xeRAbora'), findsOneWidget);
    });

    testWidgets('должен использовать Material 3', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const XeraboraApp(),
        ),
      );

      final MaterialApp app =
          tester.widget<MaterialApp>(find.byType(MaterialApp));

      expect(app.theme?.useMaterial3, isTrue);
    });

    testWidgets('должен скрывать debug banner', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const XeraboraApp(),
        ),
      );

      final MaterialApp app =
          tester.widget<MaterialApp>(find.byType(MaterialApp));

      expect(app.debugShowCheckedModeBanner, isFalse);
    });
  });
}
