import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';

void main() {
  group('SettingsKeys', () {
    test('должен иметь правильные ключи', () {
      expect(SettingsKeys.clientId, equals('igdb_client_id'));
      expect(SettingsKeys.clientSecret, equals('igdb_client_secret'));
      expect(SettingsKeys.accessToken, equals('igdb_access_token'));
      expect(SettingsKeys.tokenExpires, equals('igdb_token_expires'));
      expect(SettingsKeys.lastSync, equals('igdb_last_sync'));
      expect(
        SettingsKeys.steamGridDbApiKey,
        equals('steamgriddb_api_key'),
      );
    });
  });

  group('ConnectionStatus', () {
    test('должен иметь все статусы', () {
      expect(ConnectionStatus.values, hasLength(4));
      expect(ConnectionStatus.unknown, isNotNull);
      expect(ConnectionStatus.connected, isNotNull);
      expect(ConnectionStatus.error, isNotNull);
      expect(ConnectionStatus.checking, isNotNull);
    });
  });

  group('SettingsState', () {
    const String testClientId = 'test_client_id';
    const String testClientSecret = 'test_client_secret';
    const String testAccessToken = 'test_access_token';

    group('constructor', () {
      test('должен создать с дефолтными значениями', () {
        const SettingsState state = SettingsState();

        expect(state.clientId, isNull);
        expect(state.clientSecret, isNull);
        expect(state.accessToken, isNull);
        expect(state.tokenExpires, isNull);
        expect(state.lastSync, isNull);
        expect(state.platformCount, equals(0));
        expect(state.connectionStatus, equals(ConnectionStatus.unknown));
        expect(state.errorMessage, isNull);
        expect(state.isLoading, isFalse);
        expect(state.steamGridDbApiKey, isNull);
      });

      test('должен создать со всеми полями', () {
        const SettingsState state = SettingsState(
          clientId: testClientId,
          clientSecret: testClientSecret,
          accessToken: testAccessToken,
          tokenExpires: 9999999999,
          lastSync: 1700000000,
          platformCount: 100,
          connectionStatus: ConnectionStatus.connected,
          errorMessage: 'Test error',
          isLoading: true,
          steamGridDbApiKey: 'sgdb_key_123',
        );

        expect(state.clientId, equals(testClientId));
        expect(state.clientSecret, equals(testClientSecret));
        expect(state.accessToken, equals(testAccessToken));
        expect(state.tokenExpires, equals(9999999999));
        expect(state.lastSync, equals(1700000000));
        expect(state.platformCount, equals(100));
        expect(state.connectionStatus, equals(ConnectionStatus.connected));
        expect(state.errorMessage, equals('Test error'));
        expect(state.isLoading, isTrue);
        expect(state.steamGridDbApiKey, equals('sgdb_key_123'));
      });
    });

    group('hasCredentials', () {
      test('должен вернуть true когда есть clientId и clientSecret', () {
        const SettingsState state = SettingsState(
          clientId: testClientId,
          clientSecret: testClientSecret,
        );

        expect(state.hasCredentials, isTrue);
      });

      test('должен вернуть false когда clientId null', () {
        const SettingsState state = SettingsState(
          clientSecret: testClientSecret,
        );

        expect(state.hasCredentials, isFalse);
      });

      test('должен вернуть false когда clientSecret null', () {
        const SettingsState state = SettingsState(
          clientId: testClientId,
        );

        expect(state.hasCredentials, isFalse);
      });

      test('должен вернуть false когда clientId пустой', () {
        const SettingsState state = SettingsState(
          clientId: '',
          clientSecret: testClientSecret,
        );

        expect(state.hasCredentials, isFalse);
      });

      test('должен вернуть false когда clientSecret пустой', () {
        const SettingsState state = SettingsState(
          clientId: testClientId,
          clientSecret: '',
        );

        expect(state.hasCredentials, isFalse);
      });
    });

    group('hasValidToken', () {
      test('должен вернуть true когда токен не истёк', () {
        final int futureExpiry =
            DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600;

        final SettingsState state = SettingsState(
          accessToken: testAccessToken,
          tokenExpires: futureExpiry,
        );

        expect(state.hasValidToken, isTrue);
      });

      test('должен вернуть false когда токен истёк', () {
        final int pastExpiry =
            DateTime.now().millisecondsSinceEpoch ~/ 1000 - 3600;

        final SettingsState state = SettingsState(
          accessToken: testAccessToken,
          tokenExpires: pastExpiry,
        );

        expect(state.hasValidToken, isFalse);
      });

      test('должен вернуть false когда accessToken null', () {
        final int futureExpiry =
            DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600;

        final SettingsState state = SettingsState(
          tokenExpires: futureExpiry,
        );

        expect(state.hasValidToken, isFalse);
      });

      test('должен вернуть false когда tokenExpires null', () {
        const SettingsState state = SettingsState(
          accessToken: testAccessToken,
        );

        expect(state.hasValidToken, isFalse);
      });
    });

    group('hasSteamGridDbKey', () {
      test('должен вернуть true когда ключ не пустой', () {
        const SettingsState state = SettingsState(
          steamGridDbApiKey: 'sgdb_key_123',
        );

        expect(state.hasSteamGridDbKey, isTrue);
      });

      test('должен вернуть false когда ключ null', () {
        const SettingsState state = SettingsState();

        expect(state.hasSteamGridDbKey, isFalse);
      });

      test('должен вернуть false когда ключ пустой', () {
        const SettingsState state = SettingsState(
          steamGridDbApiKey: '',
        );

        expect(state.hasSteamGridDbKey, isFalse);
      });
    });

    group('isApiReady', () {
      test('должен вернуть true когда есть credentials и валидный токен', () {
        final int futureExpiry =
            DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600;

        final SettingsState state = SettingsState(
          clientId: testClientId,
          clientSecret: testClientSecret,
          accessToken: testAccessToken,
          tokenExpires: futureExpiry,
        );

        expect(state.isApiReady, isTrue);
      });

      test('должен вернуть false когда нет credentials', () {
        final int futureExpiry =
            DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600;

        final SettingsState state = SettingsState(
          accessToken: testAccessToken,
          tokenExpires: futureExpiry,
        );

        expect(state.isApiReady, isFalse);
      });

      test('должен вернуть false когда нет валидного токена', () {
        const SettingsState state = SettingsState(
          clientId: testClientId,
          clientSecret: testClientSecret,
        );

        expect(state.isApiReady, isFalse);
      });
    });

    group('copyWith', () {
      test('должен копировать с изменением clientId', () {
        const SettingsState original = SettingsState();
        final SettingsState copy = original.copyWith(clientId: testClientId);

        expect(copy.clientId, equals(testClientId));
      });

      test('должен копировать с изменением clientSecret', () {
        const SettingsState original = SettingsState();
        final SettingsState copy =
            original.copyWith(clientSecret: testClientSecret);

        expect(copy.clientSecret, equals(testClientSecret));
      });

      test('должен копировать с изменением accessToken', () {
        const SettingsState original = SettingsState();
        final SettingsState copy =
            original.copyWith(accessToken: testAccessToken);

        expect(copy.accessToken, equals(testAccessToken));
      });

      test('должен копировать с изменением tokenExpires', () {
        const SettingsState original = SettingsState();
        final SettingsState copy = original.copyWith(tokenExpires: 12345);

        expect(copy.tokenExpires, equals(12345));
      });

      test('должен копировать с изменением lastSync', () {
        const SettingsState original = SettingsState();
        final SettingsState copy = original.copyWith(lastSync: 67890);

        expect(copy.lastSync, equals(67890));
      });

      test('должен копировать с изменением platformCount', () {
        const SettingsState original = SettingsState();
        final SettingsState copy = original.copyWith(platformCount: 100);

        expect(copy.platformCount, equals(100));
      });

      test('должен копировать с изменением connectionStatus', () {
        const SettingsState original = SettingsState();
        final SettingsState copy =
            original.copyWith(connectionStatus: ConnectionStatus.connected);

        expect(copy.connectionStatus, equals(ConnectionStatus.connected));
      });

      test('должен копировать с изменением errorMessage', () {
        const SettingsState original = SettingsState();
        final SettingsState copy =
            original.copyWith(errorMessage: 'Test error');

        expect(copy.errorMessage, equals('Test error'));
      });

      test('должен копировать с изменением isLoading', () {
        const SettingsState original = SettingsState();
        final SettingsState copy = original.copyWith(isLoading: true);

        expect(copy.isLoading, isTrue);
      });

      test('должен копировать с изменением steamGridDbApiKey', () {
        const SettingsState original = SettingsState();
        final SettingsState copy =
            original.copyWith(steamGridDbApiKey: 'new_key');

        expect(copy.steamGridDbApiKey, equals('new_key'));
      });

      test('должен очистить errorMessage при clearError: true', () {
        const SettingsState original = SettingsState(errorMessage: 'Error');
        final SettingsState copy = original.copyWith(clearError: true);

        expect(copy.errorMessage, isNull);
      });

      test('должен сохранить errorMessage при clearError: false', () {
        const SettingsState original = SettingsState(errorMessage: 'Error');
        final SettingsState copy = original.copyWith();

        expect(copy.errorMessage, equals('Error'));
      });

      test('должен сохранить все поля при пустом copyWith', () {
        const SettingsState original = SettingsState(
          clientId: testClientId,
          clientSecret: testClientSecret,
          accessToken: testAccessToken,
          tokenExpires: 12345,
          lastSync: 67890,
          platformCount: 100,
          connectionStatus: ConnectionStatus.connected,
          errorMessage: 'Error',
          isLoading: true,
          steamGridDbApiKey: 'sgdb_key',
        );

        final SettingsState copy = original.copyWith();

        expect(copy.clientId, equals(original.clientId));
        expect(copy.clientSecret, equals(original.clientSecret));
        expect(copy.accessToken, equals(original.accessToken));
        expect(copy.tokenExpires, equals(original.tokenExpires));
        expect(copy.lastSync, equals(original.lastSync));
        expect(copy.platformCount, equals(original.platformCount));
        expect(copy.connectionStatus, equals(original.connectionStatus));
        expect(copy.errorMessage, equals(original.errorMessage));
        expect(copy.isLoading, equals(original.isLoading));
        expect(copy.steamGridDbApiKey, equals(original.steamGridDbApiKey));
      });
    });
  });
}
