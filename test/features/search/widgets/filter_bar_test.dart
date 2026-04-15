import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xerabora/features/search/widgets/filter_bar.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';
import 'package:xerabora/l10n/app_localizations.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
  });

  Widget buildWidget({VoidCallback? onBeforeFilterChange}) {
    return ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: FilterBar(onBeforeFilterChange: onBeforeFilterChange),
        ),
      ),
    );
  }

  group('FilterBar', () {
    testWidgets('принимает onBeforeFilterChange callback',
        (WidgetTester tester) async {
      int callCount = 0;
      await tester.pumpWidget(
        buildWidget(onBeforeFilterChange: () => callCount++),
      );
      await tester.pumpAndSettle();

      // Виджет отрисовывается без ошибок при наличии callback
      expect(find.byType(FilterBar), findsOneWidget);
      expect(callCount, 0);
    });
  });
}
