import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';
import 'package:xerabora/features/settings/screens/cache_screen.dart';
import 'package:xerabora/l10n/app_localizations.dart';

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
          home: Scaffold(body: CacheScreen()),
        ),
      );
    }

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
  });
}
