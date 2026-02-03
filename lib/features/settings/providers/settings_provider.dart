import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/igdb_api.dart';
import '../../../core/database/database_service.dart';
import '../../../shared/models/platform.dart';

/// Ключи для SharedPreferences.
abstract class SettingsKeys {
  static const String clientId = 'igdb_client_id';
  static const String clientSecret = 'igdb_client_secret';
  static const String accessToken = 'igdb_access_token';
  static const String tokenExpires = 'igdb_token_expires';
  static const String lastSync = 'igdb_last_sync';
}

/// Состояние настроек IGDB.
class SettingsState {
  /// Создаёт [SettingsState].
  const SettingsState({
    this.clientId,
    this.clientSecret,
    this.accessToken,
    this.tokenExpires,
    this.lastSync,
    this.platformCount = 0,
    this.connectionStatus = ConnectionStatus.unknown,
    this.errorMessage,
    this.isLoading = false,
  });

  /// Client ID для IGDB API.
  final String? clientId;

  /// Client Secret для IGDB API.
  final String? clientSecret;

  /// OAuth access token.
  final String? accessToken;

  /// Время истечения токена (Unix timestamp).
  final int? tokenExpires;

  /// Время последней синхронизации платформ (Unix timestamp).
  final int? lastSync;

  /// Количество синхронизированных платформ.
  final int platformCount;

  /// Статус подключения.
  final ConnectionStatus connectionStatus;

  /// Сообщение об ошибке (если есть).
  final String? errorMessage;

  /// Идёт ли процесс загрузки.
  final bool isLoading;

  /// Проверяет наличие сохранённых учётных данных.
  bool get hasCredentials =>
      clientId != null &&
      clientId!.isNotEmpty &&
      clientSecret != null &&
      clientSecret!.isNotEmpty;

  /// Проверяет, есть ли валидный токен.
  bool get hasValidToken {
    if (accessToken == null || tokenExpires == null) return false;
    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return tokenExpires! > now;
  }

  /// Проверяет готовность API к использованию.
  bool get isApiReady => hasCredentials && hasValidToken;

  /// Копирует с изменёнными полями.
  SettingsState copyWith({
    String? clientId,
    String? clientSecret,
    String? accessToken,
    int? tokenExpires,
    int? lastSync,
    int? platformCount,
    ConnectionStatus? connectionStatus,
    String? errorMessage,
    bool? isLoading,
    bool clearError = false,
  }) {
    return SettingsState(
      clientId: clientId ?? this.clientId,
      clientSecret: clientSecret ?? this.clientSecret,
      accessToken: accessToken ?? this.accessToken,
      tokenExpires: tokenExpires ?? this.tokenExpires,
      lastSync: lastSync ?? this.lastSync,
      platformCount: platformCount ?? this.platformCount,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Статус подключения к IGDB API.
enum ConnectionStatus {
  /// Статус неизвестен.
  unknown,

  /// Подключено успешно.
  connected,

  /// Ошибка подключения.
  error,

  /// Проверка подключения.
  checking,
}

/// Провайдер для SharedPreferences.
final Provider<SharedPreferences> sharedPreferencesProvider =
    Provider<SharedPreferences>((Ref ref) {
  throw UnimplementedError('SharedPreferences must be overridden');
});

/// Провайдер для проверки наличия валидного API ключа.
final Provider<bool> hasValidApiKeyProvider = Provider<bool>((Ref ref) {
  final SettingsState settings = ref.watch(settingsNotifierProvider);
  return settings.isApiReady;
});

/// Провайдер для настроек IGDB.
final NotifierProvider<SettingsNotifier, SettingsState> settingsNotifierProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);

/// Notifier для управления настройками IGDB.
class SettingsNotifier extends Notifier<SettingsState> {
  late SharedPreferences _prefs;
  late IgdbApi _igdbApi;
  late DatabaseService _dbService;

  @override
  SettingsState build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    _igdbApi = ref.watch(igdbApiProvider);
    _dbService = ref.watch(databaseServiceProvider);

    return _loadFromPrefs();
  }

  SettingsState _loadFromPrefs() {
    final String? clientId = _prefs.getString(SettingsKeys.clientId);
    final String? clientSecret = _prefs.getString(SettingsKeys.clientSecret);
    final String? accessToken = _prefs.getString(SettingsKeys.accessToken);
    final int? tokenExpires = _prefs.getInt(SettingsKeys.tokenExpires);
    final int? lastSync = _prefs.getInt(SettingsKeys.lastSync);

    final SettingsState loadedState = SettingsState(
      clientId: clientId,
      clientSecret: clientSecret,
      accessToken: accessToken,
      tokenExpires: tokenExpires,
      lastSync: lastSync,
    );

    // Устанавливаем credentials в API, если они есть
    if (loadedState.hasValidToken && clientId != null && accessToken != null) {
      _igdbApi.setCredentials(clientId: clientId, accessToken: accessToken);
    }

    // Загружаем количество платформ асинхронно
    _loadPlatformCount();

    return loadedState;
  }

  Future<void> _loadPlatformCount() async {
    final int count = await _dbService.getPlatformCount();
    if (count != state.platformCount) {
      state = state.copyWith(
        platformCount: count,
        connectionStatus:
            count > 0 ? ConnectionStatus.connected : state.connectionStatus,
      );
    }
  }

  /// Сохраняет учётные данные.
  Future<void> setCredentials({
    required String clientId,
    required String clientSecret,
  }) async {
    await _prefs.setString(SettingsKeys.clientId, clientId);
    await _prefs.setString(SettingsKeys.clientSecret, clientSecret);

    state = state.copyWith(
      clientId: clientId,
      clientSecret: clientSecret,
      clearError: true,
    );
  }

  /// Проверяет подключение и получает токен.
  Future<bool> verifyConnection() async {
    if (!state.hasCredentials) {
      state = state.copyWith(
        connectionStatus: ConnectionStatus.error,
        errorMessage: 'Please enter Client ID and Client Secret',
      );
      return false;
    }

    state = state.copyWith(
      connectionStatus: ConnectionStatus.checking,
      isLoading: true,
      clearError: true,
    );

    try {
      final TwitchAuthResult authResult = await _igdbApi.getAccessToken(
        clientId: state.clientId!,
        clientSecret: state.clientSecret!,
      );

      await _prefs.setString(SettingsKeys.accessToken, authResult.accessToken);
      await _prefs.setInt(SettingsKeys.tokenExpires, authResult.expiresAt);

      _igdbApi.setCredentials(
        clientId: state.clientId!,
        accessToken: authResult.accessToken,
      );

      state = state.copyWith(
        accessToken: authResult.accessToken,
        tokenExpires: authResult.expiresAt,
        connectionStatus: ConnectionStatus.connected,
        isLoading: false,
      );

      return true;
    } on IgdbApiException catch (e) {
      state = state.copyWith(
        connectionStatus: ConnectionStatus.error,
        errorMessage: e.message,
        isLoading: false,
      );
      return false;
    }
  }

  /// Синхронизирует платформы с IGDB.
  Future<bool> syncPlatforms() async {
    if (!state.isApiReady) {
      state = state.copyWith(
        errorMessage: 'API not ready. Please verify connection first.',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final List<Platform> platforms = await _igdbApi.fetchPlatforms();
      await _dbService.upsertPlatforms(platforms);

      final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await _prefs.setInt(SettingsKeys.lastSync, now);

      final int count = await _dbService.getPlatformCount();

      state = state.copyWith(
        lastSync: now,
        platformCount: count,
        isLoading: false,
      );

      return true;
    } on IgdbApiException catch (e) {
      state = state.copyWith(
        errorMessage: e.message,
        isLoading: false,
      );
      return false;
    }
  }

  /// Очищает все настройки.
  Future<void> clearSettings() async {
    await _prefs.remove(SettingsKeys.clientId);
    await _prefs.remove(SettingsKeys.clientSecret);
    await _prefs.remove(SettingsKeys.accessToken);
    await _prefs.remove(SettingsKeys.tokenExpires);
    await _prefs.remove(SettingsKeys.lastSync);

    _igdbApi.clearCredentials();
    await _dbService.clearPlatforms();

    state = const SettingsState();
  }
}
