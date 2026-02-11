import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/igdb_api.dart';
import '../../../core/api/steamgriddb_api.dart';
import '../../../core/api/tmdb_api.dart';
import '../../../core/database/database_service.dart';
import '../../../core/services/config_service.dart';
import '../../../shared/models/platform.dart';

/// Ключи для SharedPreferences.
abstract class SettingsKeys {
  static const String clientId = 'igdb_client_id';
  static const String clientSecret = 'igdb_client_secret';
  static const String accessToken = 'igdb_access_token';
  static const String tokenExpires = 'igdb_token_expires';
  static const String lastSync = 'igdb_last_sync';

  /// API ключ для SteamGridDB.
  static const String steamGridDbApiKey = 'steamgriddb_api_key';

  /// API ключ для TMDB.
  static const String tmdbApiKey = 'tmdb_api_key';
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
    this.steamGridDbApiKey,
    this.tmdbApiKey,
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

  /// API ключ для SteamGridDB.
  final String? steamGridDbApiKey;

  /// API ключ для TMDB.
  final String? tmdbApiKey;

  /// Проверяет наличие API ключа TMDB.
  bool get hasTmdbKey => tmdbApiKey != null && tmdbApiKey!.isNotEmpty;

  /// Проверяет наличие API ключа SteamGridDB.
  bool get hasSteamGridDbKey =>
      steamGridDbApiKey != null && steamGridDbApiKey!.isNotEmpty;

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
    String? steamGridDbApiKey,
    String? tmdbApiKey,
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
      steamGridDbApiKey: steamGridDbApiKey ?? this.steamGridDbApiKey,
      tmdbApiKey: tmdbApiKey ?? this.tmdbApiKey,
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
  late SteamGridDbApi _steamGridDbApi;
  late TmdbApi _tmdbApi;
  late DatabaseService _dbService;

  @override
  SettingsState build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    _igdbApi = ref.watch(igdbApiProvider);
    _steamGridDbApi = ref.watch(steamGridDbApiProvider);
    _tmdbApi = ref.watch(tmdbApiProvider);
    _dbService = ref.watch(databaseServiceProvider);

    return _loadFromPrefs();
  }

  SettingsState _loadFromPrefs() {
    final String? clientId = _prefs.getString(SettingsKeys.clientId);
    final String? clientSecret = _prefs.getString(SettingsKeys.clientSecret);
    final String? accessToken = _prefs.getString(SettingsKeys.accessToken);
    final int? tokenExpires = _prefs.getInt(SettingsKeys.tokenExpires);
    final int? lastSync = _prefs.getInt(SettingsKeys.lastSync);
    final String? steamGridDbApiKey =
        _prefs.getString(SettingsKeys.steamGridDbApiKey);
    final String? tmdbApiKey = _prefs.getString(SettingsKeys.tmdbApiKey);

    final SettingsState loadedState = SettingsState(
      clientId: clientId,
      clientSecret: clientSecret,
      accessToken: accessToken,
      tokenExpires: tokenExpires,
      lastSync: lastSync,
      steamGridDbApiKey: steamGridDbApiKey,
      tmdbApiKey: tmdbApiKey,
    );

    // Устанавливаем credentials в API, если они есть
    if (loadedState.hasValidToken && clientId != null && accessToken != null) {
      _igdbApi.setCredentials(clientId: clientId, accessToken: accessToken);
    }

    // Устанавливаем SteamGridDB API ключ, если есть
    if (steamGridDbApiKey != null && steamGridDbApiKey.isNotEmpty) {
      _steamGridDbApi.setApiKey(steamGridDbApiKey);
    }

    // Устанавливаем TMDB API ключ, если есть
    if (tmdbApiKey != null && tmdbApiKey.isNotEmpty) {
      _tmdbApi.setApiKey(tmdbApiKey);
      // Предзагружаем жанры из TMDB в БД-кэш
      _preloadTmdbGenres();
    }

    // Загружаем количество платформ асинхронно
    _loadPlatformCount();

    return loadedState;
  }

  /// Предзагружает списки жанров TMDB в БД-кэш.
  ///
  /// Запускается асинхронно при установке TMDB API ключа.
  /// Ошибки игнорируются — жанры загрузятся при первом поиске.
  Future<void> _preloadTmdbGenres() async {
    try {
      final Map<String, String> movieGenres =
          await _dbService.getTmdbGenreMap('movie');
      final Map<String, String> tvGenres =
          await _dbService.getTmdbGenreMap('tv');

      // Загружаем из API только если кэш пуст
      if (movieGenres.isEmpty) {
        final List<TmdbGenre> genres = await _tmdbApi.getMovieGenres();
        if (genres.isNotEmpty) {
          await _dbService.cacheTmdbGenres(
            'movie',
            genres
                .map((TmdbGenre g) =>
                    <String, dynamic>{'id': g.id, 'name': g.name})
                .toList(),
          );
        }
      }
      if (tvGenres.isEmpty) {
        final List<TmdbGenre> genres = await _tmdbApi.getTvGenres();
        if (genres.isNotEmpty) {
          await _dbService.cacheTmdbGenres(
            'tv',
            genres
                .map((TmdbGenre g) =>
                    <String, dynamic>{'id': g.id, 'name': g.name})
                .toList(),
          );
        }
      }
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      // Ошибки игнорируются — жанры загрузятся при первом поиске
    }
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

  /// Сохраняет API ключ SteamGridDB.
  Future<void> setSteamGridDbApiKey(String apiKey) async {
    if (apiKey.isNotEmpty) {
      await _prefs.setString(SettingsKeys.steamGridDbApiKey, apiKey);
      _steamGridDbApi.setApiKey(apiKey);
    } else {
      await _prefs.remove(SettingsKeys.steamGridDbApiKey);
      _steamGridDbApi.clearApiKey();
    }

    state = state.copyWith(steamGridDbApiKey: apiKey);
  }

  /// Сохраняет API ключ TMDB.
  Future<void> setTmdbApiKey(String apiKey) async {
    if (apiKey.isNotEmpty) {
      await _prefs.setString(SettingsKeys.tmdbApiKey, apiKey);
      _tmdbApi.setApiKey(apiKey);
      // Предзагружаем жанры при смене ключа
      _preloadTmdbGenres();
    } else {
      await _prefs.remove(SettingsKeys.tmdbApiKey);
      _tmdbApi.clearApiKey();
    }

    state = state.copyWith(tmdbApiKey: apiKey);
  }

  /// Экспортирует конфигурацию в файл.
  Future<ConfigResult> exportConfig() async {
    final ConfigService configService = ref.read(configServiceProvider);
    return configService.exportToFile();
  }

  /// Импортирует конфигурацию из файла.
  ///
  /// После импорта перезагружает настройки и обновляет API клиенты.
  Future<ConfigResult> importConfig() async {
    final ConfigService configService = ref.read(configServiceProvider);
    final ConfigResult result = await configService.importFromFile();

    if (result.success) {
      state = _loadFromPrefs();
      await _loadPlatformCount();
    }

    return result;
  }

  /// Очищает все данные из базы данных.
  ///
  /// Удаляет все коллекции, игры, фильмы, сериалы и данные канваса.
  /// Настройки и API ключи сохраняются.
  Future<void> flushDatabase() async {
    await _dbService.clearAllData();
    state = state.copyWith(platformCount: 0);
  }

  /// Очищает все настройки.
  Future<void> clearSettings() async {
    await _prefs.remove(SettingsKeys.clientId);
    await _prefs.remove(SettingsKeys.clientSecret);
    await _prefs.remove(SettingsKeys.accessToken);
    await _prefs.remove(SettingsKeys.tokenExpires);
    await _prefs.remove(SettingsKeys.lastSync);
    await _prefs.remove(SettingsKeys.steamGridDbApiKey);
    await _prefs.remove(SettingsKeys.tmdbApiKey);

    _igdbApi.clearCredentials();
    _steamGridDbApi.clearApiKey();
    _tmdbApi.clearApiKey();
    await _dbService.clearPlatforms();

    state = const SettingsState();
  }
}
