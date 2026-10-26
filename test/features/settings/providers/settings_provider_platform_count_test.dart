import 'package:core/rpc/protocol.dart';
import 'package:core/rpc/rpc_transport.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tonkatsu_box/core/api/igdb_api.dart';
import 'package:tonkatsu_box/core/api/steamgriddb_api.dart';
import 'package:tonkatsu_box/core/api/tmdb_api.dart';
import 'package:tonkatsu_box/core/database/database_service.dart';
import 'package:tonkatsu_box/core/services/api_key_initializer.dart';
import 'package:tonkatsu_box/core/services/config_service.dart';
import 'package:tonkatsu_box/features/settings/providers/settings_provider.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late MockDatabaseService mockDbService;
  late MockGameDao mockGameDao;

  setUp(() {
    mockDbService = MockDatabaseService();
    mockGameDao = MockGameDao();
    when(() => mockDbService.gameDao).thenReturn(mockGameDao);
  });

  Future<ProviderContainer> createContainer() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
        apiKeysProvider.overrideWithValue(const ApiKeys()),
        igdbApiProvider.overrideWithValue(MockIgdbApi()),
        steamGridDbApiProvider.overrideWithValue(MockSteamGridDbApi()),
        tmdbApiProvider.overrideWithValue(MockTmdbApi()),
        databaseServiceProvider.overrideWithValue(mockDbService),
        configServiceProvider.overrideWithValue(MockConfigService()),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('SettingsNotifier platform count', () {
    test('should pick up the count the DAO answers', () async {
      when(() => mockGameDao.getPlatformCount()).thenAnswer((_) async => 7);

      final ProviderContainer container = await createContainer();
      container.read(settingsNotifierProvider);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(settingsNotifierProvider).platformCount, 7);
    });

    test('should keep the state when the DAO fails', () async {
      when(() => mockGameDao.getPlatformCount()).thenAnswer(
        (_) => Future<int>.error(
          const RpcException(kRpcErrorKindAuth, 'Missing or wrong token'),
        ),
      );

      final ProviderContainer container = await createContainer();
      container.read(settingsNotifierProvider);
      // An unhandled rejection here would fail the test as an uncaught error.
      await Future<void>.delayed(Duration.zero);

      expect(container.read(settingsNotifierProvider).platformCount, 0);
      verify(() => mockGameDao.getPlatformCount()).called(1);
    });
  });
}
