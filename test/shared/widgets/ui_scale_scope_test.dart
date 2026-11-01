import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tonkatsu_box/core/api/igdb_api.dart';
import 'package:tonkatsu_box/core/api/steamgriddb_api.dart';
import 'package:tonkatsu_box/core/api/tmdb_api.dart';
import 'package:tonkatsu_box/core/database/database_service.dart';
import 'package:tonkatsu_box/core/services/api_key_initializer.dart';
import 'package:tonkatsu_box/features/settings/providers/settings_provider.dart';
import 'package:tonkatsu_box/shared/widgets/ui_scale_scope.dart';

import '../../helpers/test_helpers.dart';

void main() {
  late MockDatabaseService mockDbService;
  late MockGameDao mockGameDao;

  setUp(() {
    mockDbService = MockDatabaseService();
    mockGameDao = MockGameDao();
    when(() => mockDbService.gameDao).thenReturn(mockGameDao);
    when(() => mockGameDao.getPlatformCount()).thenAnswer((_) async => 0);
  });

  /// A button pinned to the bottom-right corner: the spot a wrong hit-test
  /// nesting leaves unreachable when zoomed out.
  Future<int Function()> pumpScoped(WidgetTester tester, double scale) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      SettingsKeys.uiScale: scale,
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    int taps = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
          apiKeysProvider.overrideWithValue(const ApiKeys()),
          igdbApiProvider.overrideWithValue(MockIgdbApi()),
          steamGridDbApiProvider.overrideWithValue(MockSteamGridDbApi()),
          tmdbApiProvider.overrideWithValue(MockTmdbApi()),
          databaseServiceProvider.overrideWithValue(mockDbService),
        ],
        child: MaterialApp(
          builder: (BuildContext context, Widget? child) =>
              UiScaleScope(child: child ?? const SizedBox.shrink()),
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomRight,
              child: Builder(
                builder: (BuildContext context) => ElevatedButton(
                  key: const ValueKey<String>('corner'),
                  onPressed: () => taps++,
                  child: Text('${MediaQuery.sizeOf(context).width.round()}'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return () => taps;
  }

  group('UiScaleScope', () {
    testWidgets('should pass the child through at the default scale',
        (WidgetTester tester) async {
      await pumpScoped(tester, SettingsKeys.uiScaleDefault);

      expect(find.byType(OverflowBox), findsNothing);
      expect(find.text('800'), findsOneWidget);
    });

    testWidgets('should hand the subtree a virtual window of size / scale',
        (WidgetTester tester) async {
      await pumpScoped(tester, 0.8);

      expect(find.text('1000'), findsOneWidget);
    });

    testWidgets('should deliver a tap to the bottom-right corner when zoomed out',
        (WidgetTester tester) async {
      final int Function() taps = await pumpScoped(tester, 0.8);

      await tester.tap(find.byKey(const ValueKey<String>('corner')));
      await tester.pump();

      expect(taps(), 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should deliver a tap to the bottom-right corner when zoomed in',
        (WidgetTester tester) async {
      final int Function() taps = await pumpScoped(tester, 1.5);

      await tester.tap(find.byKey(const ValueKey<String>('corner')));
      await tester.pump();

      expect(taps(), 1);
      expect(tester.takeException(), isNull);
    });
  });
}
