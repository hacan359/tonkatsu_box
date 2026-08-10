import 'package:flutter/material.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';
import 'package:tonkatsu_box/shared/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tonkatsu_box/core/api/igdb_api.dart';
import 'package:tonkatsu_box/core/api/steamgriddb_api.dart';
import 'package:tonkatsu_box/core/api/tmdb_api.dart';
import 'package:tonkatsu_box/core/database/database_service.dart';
import 'package:tonkatsu_box/core/services/api_key_initializer.dart';
import 'package:tonkatsu_box/features/settings/content/credentials_content.dart';
import 'package:tonkatsu_box/features/settings/providers/settings_provider.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late MockIgdbApi mockIgdbApi;
  late MockSteamGridDbApi mockSteamGridDbApi;
  late MockTmdbApi mockTmdbApi;
  late MockDatabaseService mockDbService;
  late MockGameDao mockGameDao;

  setUp(() {
    mockIgdbApi = MockIgdbApi();
    mockSteamGridDbApi = MockSteamGridDbApi();
    mockTmdbApi = MockTmdbApi();
    mockDbService = MockDatabaseService();
    mockGameDao = MockGameDao();
    when(() => mockDbService.gameDao).thenReturn(mockGameDao);
    when(() => mockGameDao.getPlatformCount()).thenAnswer((_) async => 0);
    when(() => mockIgdbApi.getAccessToken(
          clientId: any(named: 'clientId'),
          clientSecret: any(named: 'clientSecret'),
        )).thenThrow(const IgdbApiException('Test: no real API'));
  });

  testWidgets('a stored TheTVDB key shows as a set (obscured) field',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(const <String, Object>{
      'tvdb_api_key': 'stored-tvdb-key',
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Not pumpApp: it overrides settingsNotifierProvider with an empty stub,
    // and this test is about the real notifier reading the real prefs.
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
          apiKeysProvider.overrideWithValue(const ApiKeys()),
          igdbApiProvider.overrideWithValue(mockIgdbApi),
          steamGridDbApiProvider.overrideWithValue(mockSteamGridDbApi),
          tmdbApiProvider.overrideWithValue(mockTmdbApi),
          databaseServiceProvider.overrideWithValue(mockDbService),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          locale: const Locale('en'),
          home: const Scaffold(
            body: SingleChildScrollView(child: CredentialsContent()),
          ),
        ),
      ),
    );
    await tester.pump();

    // The obscured-dots run means the field holds a value; the enter-key
    // placeholder would mean the stored key never reached the field.
    expect(find.textContaining('••••'), findsWidgets);
    expect(find.text('Enter your TheTVDB API key'), findsNothing);
  });
}
