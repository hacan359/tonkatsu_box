import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/constants/api_defaults.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/models/collection_item.dart';
import '../../../core/services/discord_rpc_service.dart';
import '../../../core/api/igdb_api.dart';
import '../../../core/api/ra_api.dart';
import '../../../core/api/steamgriddb_api.dart';
import '../../../core/api/tmdb_api.dart';
import '../../../core/database/database_service.dart';
import '../../../core/services/config_service.dart';

abstract class SettingsKeys {
  static const String clientId = 'igdb_client_id';
  static const String clientSecret = 'igdb_client_secret';
  static const String accessToken = 'igdb_access_token';
  static const String tokenExpires = 'igdb_token_expires';
  static const String lastSync = 'igdb_last_sync';

  static const String steamGridDbApiKey = 'steamgriddb_api_key';

  static const String tmdbApiKey = 'tmdb_api_key';

  /// Prefix; suffixed per-collection id at call site.
  static const String collectionViewModePrefix = 'collection_view_mode_';

  /// Prefix; suffixed per-collection id at call site.
  static const String collectionTableModePrefix = 'collection_table_mode_';

  static const String defaultAuthor = 'default_author';

  /// TMDB content language (ru-RU or en-US).
  static const String tmdbLanguage = 'tmdb_language';

  static const String tmdbLanguageDefault = 'ru-RU';

  /// App UI language (en / ru).
  static const String appLanguage = 'app_language';

  static const String appLanguageDefault = 'en';

  static const String showRecommendations = 'show_recommendations';

  static const String showBlurayOverlay = 'show_bluray_overlay';

  static const String showPlatformOverlay = 'show_platform_overlay';

  static const String discordRpcEnabled = 'discord_rpc_enabled';

  /// Mirrors RA Rich Presence into Discord.
  static const String discordRaSyncEnabled = 'discord_ra_sync_enabled';

  static const String raUsername = 'ra_username';

  static const String raApiKey = 'ra_api_key';

  /// Persisted only if user opts in via Steam Import checkbox.
  static const String steamApiKey = 'steam_api_key';

  /// Persisted only if user opts in via Steam Import checkbox.
  static const String steamId = 'steam_id';

  static const String steamRememberCredentials = 'steam_remember_credentials';

  static const String richCollectionsEnabled = 'rich_collections_enabled';
}

class SettingsState {
  const SettingsState({
    this.clientId,
    this.clientSecret,
    this.accessToken,
    this.tokenExpires,
    this.platformCount = 0,
    this.connectionStatus = ConnectionStatus.unknown,
    this.errorMessage,
    this.isLoading = false,
    this.steamGridDbApiKey,
    this.tmdbApiKey,
    this.defaultAuthor,
    this.tmdbLanguage = SettingsKeys.tmdbLanguageDefault,
    this.appLanguage = SettingsKeys.appLanguageDefault,
    this.showRecommendations = true,
    this.showBlurayOverlay = true,
    this.showPlatformOverlay = true,
    this.discordRpcEnabled = false,
    this.discordRaSyncEnabled = false,
    this.richCollectionsEnabled = false,
  });

  final String? clientId;

  final String? clientSecret;

  final String? accessToken;

  /// Unix timestamp (seconds).
  final int? tokenExpires;

  /// Pre-seeded by migration.
  final int platformCount;

  final ConnectionStatus connectionStatus;

  final String? errorMessage;

  final bool isLoading;

  final String? steamGridDbApiKey;

  final String? tmdbApiKey;

  final String? defaultAuthor;

  final String tmdbLanguage;

  final String appLanguage;

  final bool showRecommendations;

  final bool showBlurayOverlay;

  final bool showPlatformOverlay;

  final bool discordRpcEnabled;

  final bool discordRaSyncEnabled;

  /// Hero image + description instead of mosaic.
  final bool richCollectionsEnabled;

  String? resolveOverlay({
    String? platformOverlay,
    String? mediaTypeOverlay,
  }) {
    if (platformOverlay != null && showPlatformOverlay) return platformOverlay;
    if (mediaTypeOverlay != null && showBlurayOverlay) return mediaTypeOverlay;
    return null;
  }

  String? resolveOverlayFor(CollectionItem item) {
    return resolveOverlay(
      platformOverlay: item.platform?.overlayAsset,
      mediaTypeOverlay: item.mediaType.overlayAsset,
    );
  }

  String get authorName => (defaultAuthor != null && defaultAuthor!.isNotEmpty)
      ? defaultAuthor!
      : 'User';

  bool get hasTmdbKey => tmdbApiKey != null && tmdbApiKey!.isNotEmpty;

  bool get hasSteamGridDbKey =>
      steamGridDbApiKey != null && steamGridDbApiKey!.isNotEmpty;

  bool get isTmdbKeyBuiltIn =>
      hasTmdbKey &&
      ApiDefaults.hasTmdbKey &&
      tmdbApiKey == ApiDefaults.tmdbApiKey;

  bool get isSteamGridDbKeyBuiltIn =>
      hasSteamGridDbKey &&
      ApiDefaults.hasSteamGridDbKey &&
      steamGridDbApiKey == ApiDefaults.steamGridDbApiKey;

  bool get isIgdbKeyBuiltIn =>
      hasCredentials &&
      ApiDefaults.hasIgdbKey &&
      clientId == ApiDefaults.igdbClientId &&
      clientSecret == ApiDefaults.igdbClientSecret;

  bool get hasCredentials =>
      clientId != null &&
      clientId!.isNotEmpty &&
      clientSecret != null &&
      clientSecret!.isNotEmpty;

  bool get hasValidToken {
    if (accessToken == null || tokenExpires == null) return false;
    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return tokenExpires! > now;
  }

  bool get isApiReady => hasCredentials && hasValidToken;

  SettingsState copyWith({
    String? clientId,
    String? clientSecret,
    String? accessToken,
    int? tokenExpires,
    int? platformCount,
    ConnectionStatus? connectionStatus,
    String? errorMessage,
    bool? isLoading,
    bool clearError = false,
    String? steamGridDbApiKey,
    String? tmdbApiKey,
    String? defaultAuthor,
    String? tmdbLanguage,
    String? appLanguage,
    bool? showRecommendations,
    bool? showBlurayOverlay,
    bool? showPlatformOverlay,
    bool? discordRpcEnabled,
    bool? discordRaSyncEnabled,
    bool? richCollectionsEnabled,
  }) {
    return SettingsState(
      clientId: clientId ?? this.clientId,
      clientSecret: clientSecret ?? this.clientSecret,
      accessToken: accessToken ?? this.accessToken,
      tokenExpires: tokenExpires ?? this.tokenExpires,
      platformCount: platformCount ?? this.platformCount,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isLoading: isLoading ?? this.isLoading,
      steamGridDbApiKey: steamGridDbApiKey ?? this.steamGridDbApiKey,
      tmdbApiKey: tmdbApiKey ?? this.tmdbApiKey,
      defaultAuthor: defaultAuthor ?? this.defaultAuthor,
      tmdbLanguage: tmdbLanguage ?? this.tmdbLanguage,
      appLanguage: appLanguage ?? this.appLanguage,
      showRecommendations: showRecommendations ?? this.showRecommendations,
      showBlurayOverlay: showBlurayOverlay ?? this.showBlurayOverlay,
      showPlatformOverlay: showPlatformOverlay ?? this.showPlatformOverlay,
      discordRpcEnabled: discordRpcEnabled ?? this.discordRpcEnabled,
      discordRaSyncEnabled: discordRaSyncEnabled ?? this.discordRaSyncEnabled,
      richCollectionsEnabled:
          richCollectionsEnabled ?? this.richCollectionsEnabled,
    );
  }
}

enum ConnectionStatus {
  unknown,
  connected,
  error,
  checking,
}

final Provider<SharedPreferences> sharedPreferencesProvider =
    Provider<SharedPreferences>((Ref ref) {
  throw UnimplementedError('SharedPreferences must be overridden');
});

final Provider<bool> hasValidApiKeyProvider = Provider<bool>((Ref ref) {
  final SettingsState settings = ref.watch(settingsNotifierProvider);
  return settings.isApiReady;
});

final NotifierProvider<SettingsNotifier, SettingsState> settingsNotifierProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);

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

    // Persist auto-refreshed token from IgdbApi back into prefs + state.
    _igdbApi.onTokenRefreshed = (String accessToken, int expiresAt) {
      _prefs.setString(SettingsKeys.accessToken, accessToken);
      _prefs.setInt(SettingsKeys.tokenExpires, expiresAt);
      state = state.copyWith(
        accessToken: accessToken,
        tokenExpires: expiresAt,
        connectionStatus: ConnectionStatus.connected,
      );
    };

    return _loadFromPrefs();
  }

  SettingsState _loadFromPrefs() {
    // IGDB: user key → built-in key → null
    final String? userClientId = _prefs.getString(SettingsKeys.clientId);
    final String? clientId =
        (userClientId != null && userClientId.isNotEmpty)
            ? userClientId
            : (ApiDefaults.hasIgdbKey ? ApiDefaults.igdbClientId : null);
    final String? userClientSecret =
        _prefs.getString(SettingsKeys.clientSecret);
    final String? clientSecret =
        (userClientSecret != null && userClientSecret.isNotEmpty)
            ? userClientSecret
            : (ApiDefaults.hasIgdbKey ? ApiDefaults.igdbClientSecret : null);
    final String? accessToken = _prefs.getString(SettingsKeys.accessToken);
    final int? tokenExpires = _prefs.getInt(SettingsKeys.tokenExpires);
    // SteamGridDB: user key → built-in key → null
    final String? userSteamGridDbKey =
        _prefs.getString(SettingsKeys.steamGridDbApiKey);
    final String? steamGridDbApiKey =
        (userSteamGridDbKey != null && userSteamGridDbKey.isNotEmpty)
            ? userSteamGridDbKey
            : (ApiDefaults.hasSteamGridDbKey
                ? ApiDefaults.steamGridDbApiKey
                : null);

    // TMDB: user key → built-in key → null
    final String? userTmdbKey = _prefs.getString(SettingsKeys.tmdbApiKey);
    final String? tmdbApiKey =
        (userTmdbKey != null && userTmdbKey.isNotEmpty)
            ? userTmdbKey
            : (ApiDefaults.hasTmdbKey ? ApiDefaults.tmdbApiKey : null);
    final String? defaultAuthor =
        _prefs.getString(SettingsKeys.defaultAuthor);
    final String tmdbLanguage =
        _prefs.getString(SettingsKeys.tmdbLanguage) ??
            SettingsKeys.tmdbLanguageDefault;
    final String appLanguage =
        _prefs.getString(SettingsKeys.appLanguage) ??
            SettingsKeys.appLanguageDefault;
    final bool showRecommendations =
        _prefs.getBool(SettingsKeys.showRecommendations) ?? true;
    final bool showBlurayOverlay =
        _prefs.getBool(SettingsKeys.showBlurayOverlay) ?? true;
    final bool showPlatformOverlay =
        _prefs.getBool(SettingsKeys.showPlatformOverlay) ?? true;
    final bool discordRpcEnabled =
        _prefs.getBool(SettingsKeys.discordRpcEnabled) ?? false;
    final bool discordRaSyncEnabled =
        _prefs.getBool(SettingsKeys.discordRaSyncEnabled) ?? false;
    final bool richCollectionsEnabled =
        _prefs.getBool(SettingsKeys.richCollectionsEnabled) ?? false;

    // Valid token → connected immediately (skip verify);
    // expired with credentials → trigger auto-verify below.
    final bool hasValidToken = accessToken != null &&
        tokenExpires != null &&
        tokenExpires > DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final ConnectionStatus initialStatus =
        hasValidToken ? ConnectionStatus.connected : ConnectionStatus.unknown;

    final SettingsState loadedState = SettingsState(
      clientId: clientId,
      clientSecret: clientSecret,
      accessToken: accessToken,
      tokenExpires: tokenExpires,
      connectionStatus: initialStatus,
      steamGridDbApiKey: steamGridDbApiKey,
      tmdbApiKey: tmdbApiKey,
      defaultAuthor: defaultAuthor,
      tmdbLanguage: tmdbLanguage,
      appLanguage: appLanguage,
      showRecommendations: showRecommendations,
      showBlurayOverlay: showBlurayOverlay,
      showPlatformOverlay: showPlatformOverlay,
      discordRpcEnabled: discordRpcEnabled,
      discordRaSyncEnabled: discordRaSyncEnabled,
      richCollectionsEnabled: richCollectionsEnabled,
    );

    // API keys already wired by apiKeysProvider; only the request-time language param is set here.
    _tmdbApi.setLanguage(tmdbLanguage);

    Future<void>.microtask(_loadPlatformCount);

    if (loadedState.hasCredentials && !loadedState.hasValidToken) {
      Future<void>.microtask(_autoVerifyConnection);
    }

    if (kDiscordRpcAvailable && loadedState.discordRpcEnabled) {
      Future<void>.microtask(() {
        final DiscordRpcService rpc = ref.read(discordRpcServiceProvider);
        rpc.enable();
        if (loadedState.discordRaSyncEnabled) {
          final RaApi raApi = ref.read(raApiProvider);
          final String? raUsername =
              _prefs.getString(SettingsKeys.raUsername);
          if (raUsername != null && raApi.hasCredentials) {
            rpc.enableRaSync(raApi: raApi, raUsername: raUsername);
          }
        }
      });
    }

    return loadedState;
  }

  /// Called after importConfig since keys may have changed.
  void _syncApiClients() {
    if (state.hasValidToken &&
        state.clientId != null &&
        state.accessToken != null) {
      _igdbApi.setCredentials(
        clientId: state.clientId!,
        accessToken: state.accessToken!,
        clientSecret: state.clientSecret,
      );
    }
    if (state.steamGridDbApiKey != null &&
        state.steamGridDbApiKey!.isNotEmpty) {
      _steamGridDbApi.setApiKey(state.steamGridDbApiKey!);
    }
    if (state.tmdbApiKey != null && state.tmdbApiKey!.isNotEmpty) {
      _tmdbApi.setApiKey(state.tmdbApiKey!);
    }
  }

  Future<void> _autoVerifyConnection() async {
    if (!state.hasCredentials) return;
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
        clientSecret: state.clientSecret,
      );
      state = state.copyWith(
        accessToken: authResult.accessToken,
        tokenExpires: authResult.expiresAt,
        connectionStatus: ConnectionStatus.connected,
      );
    } on IgdbApiException {
      // Swallow silently — user sees "Not connected".
    }
  }

  Future<void> _loadPlatformCount() async {
    final int count = await _dbService.getPlatformCount();
    if (count != state.platformCount) {
      state = state.copyWith(platformCount: count);
    }
  }

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
        clientSecret: state.clientSecret,
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

  Future<void> setTmdbApiKey(String apiKey) async {
    if (apiKey.isNotEmpty) {
      await _prefs.setString(SettingsKeys.tmdbApiKey, apiKey);
      _tmdbApi.setApiKey(apiKey);
    } else {
      await _prefs.remove(SettingsKeys.tmdbApiKey);
      _tmdbApi.clearApiKey();
    }

    state = state.copyWith(tmdbApiKey: apiKey);
  }

  /// Genres are pre-seeded for both EN + RU — no cache clear needed on switch.
  Future<void> setTmdbLanguage(String language) async {
    await _prefs.setString(SettingsKeys.tmdbLanguage, language);
    _tmdbApi.setLanguage(language);
    state = state.copyWith(tmdbLanguage: language);
  }

  Future<void> setAppLanguage(String language) async {
    await _prefs.setString(SettingsKeys.appLanguage, language);
    state = state.copyWith(appLanguage: language);
  }

  Future<void> setShowRecommendations({required bool enabled}) async {
    await _prefs.setBool(SettingsKeys.showRecommendations, enabled);
    state = state.copyWith(showRecommendations: enabled);
  }

  Future<void> setShowBlurayOverlay({required bool enabled}) async {
    await _prefs.setBool(SettingsKeys.showBlurayOverlay, enabled);
    state = state.copyWith(showBlurayOverlay: enabled);
  }

  Future<void> setShowPlatformOverlay({required bool enabled}) async {
    await _prefs.setBool(SettingsKeys.showPlatformOverlay, enabled);
    state = state.copyWith(showPlatformOverlay: enabled);
  }

  Future<void> setDiscordRpcEnabled({required bool enabled}) async {
    await _prefs.setBool(SettingsKeys.discordRpcEnabled, enabled);
    state = state.copyWith(discordRpcEnabled: enabled);
  }

  Future<void> setDiscordRaSyncEnabled({required bool enabled}) async {
    await _prefs.setBool(SettingsKeys.discordRaSyncEnabled, enabled);
    state = state.copyWith(discordRaSyncEnabled: enabled);
  }

  Future<void> setRichCollectionsEnabled({required bool enabled}) async {
    await _prefs.setBool(SettingsKeys.richCollectionsEnabled, enabled);
    state = state.copyWith(richCollectionsEnabled: enabled);
  }

  /// Falls back to built-in key if available, otherwise clears.
  Future<void> resetTmdbApiKeyToDefault() async {
    await _prefs.remove(SettingsKeys.tmdbApiKey);
    if (ApiDefaults.hasTmdbKey) {
      _tmdbApi.setApiKey(ApiDefaults.tmdbApiKey);
      state = state.copyWith(tmdbApiKey: ApiDefaults.tmdbApiKey);
    } else {
      _tmdbApi.clearApiKey();
      state = state.copyWith(tmdbApiKey: '');
    }
  }

  /// Falls back to built-in credentials if available, otherwise clears.
  Future<void> resetIgdbCredentialsToDefault() async {
    await _prefs.remove(SettingsKeys.clientId);
    await _prefs.remove(SettingsKeys.clientSecret);
    await _prefs.remove(SettingsKeys.accessToken);
    await _prefs.remove(SettingsKeys.tokenExpires);
    if (ApiDefaults.hasIgdbKey) {
      state = state.copyWith(
        clientId: ApiDefaults.igdbClientId,
        clientSecret: ApiDefaults.igdbClientSecret,
      );
      Future<void>.microtask(_autoVerifyConnection);
    } else {
      _igdbApi.clearCredentials();
      state = state.copyWith(
        clientId: '',
        clientSecret: '',
        accessToken: '',
        connectionStatus: ConnectionStatus.unknown,
      );
    }
  }

  /// Falls back to built-in key if available, otherwise clears.
  Future<void> resetSteamGridDbApiKeyToDefault() async {
    await _prefs.remove(SettingsKeys.steamGridDbApiKey);
    if (ApiDefaults.hasSteamGridDbKey) {
      _steamGridDbApi.setApiKey(ApiDefaults.steamGridDbApiKey);
      state = state.copyWith(steamGridDbApiKey: ApiDefaults.steamGridDbApiKey);
    } else {
      _steamGridDbApi.clearApiKey();
      state = state.copyWith(steamGridDbApiKey: '');
    }
  }

  Future<void> setDefaultAuthor(String author) async {
    final String trimmed = author.trim();
    if (trimmed.isNotEmpty) {
      await _prefs.setString(SettingsKeys.defaultAuthor, trimmed);
    } else {
      await _prefs.remove(SettingsKeys.defaultAuthor);
    }
    state = state.copyWith(defaultAuthor: trimmed);
  }

  Future<bool> validateTmdbKey() async {
    if (!state.hasTmdbKey) return false;
    return _tmdbApi.validateApiKey(state.tmdbApiKey!);
  }

  Future<bool> validateSteamGridDbKey() async {
    if (!state.hasSteamGridDbKey) return false;
    return _steamGridDbApi.validateApiKey(state.steamGridDbApiKey!);
  }

  Future<ConfigResult> exportConfig() async {
    final ConfigService configService = ref.read(configServiceProvider);
    return configService.exportToFile();
  }

  /// Reloads settings and re-syncs API clients after import.
  Future<ConfigResult> importConfig() async {
    final ConfigService configService = ref.read(configServiceProvider);
    final ConfigResult result = await configService.importFromFile();

    if (result.success) {
      state = _loadFromPrefs();
      _syncApiClients();
      await _loadPlatformCount();
    }

    return result;
  }

  /// Wipes collections/games/movies/tv/canvas; preserves settings + API keys.
  Future<void> flushDatabase() async {
    await _dbService.clearAllData();
    state = state.copyWith(platformCount: 0);
  }

  Future<void> clearSettings() async {
    await _prefs.remove(SettingsKeys.clientId);
    await _prefs.remove(SettingsKeys.clientSecret);
    await _prefs.remove(SettingsKeys.accessToken);
    await _prefs.remove(SettingsKeys.tokenExpires);
    await _prefs.remove(SettingsKeys.lastSync);
    await _prefs.remove(SettingsKeys.steamGridDbApiKey);
    await _prefs.remove(SettingsKeys.tmdbApiKey);
    await _prefs.remove(SettingsKeys.defaultAuthor);
    await _prefs.remove(SettingsKeys.showRecommendations);
    await _prefs.remove(SettingsKeys.showBlurayOverlay);
    await _prefs.remove(SettingsKeys.showPlatformOverlay);
    await _prefs.remove(SettingsKeys.discordRpcEnabled);
    await _prefs.remove(SettingsKeys.discordRaSyncEnabled);
    await _prefs.remove(SettingsKeys.richCollectionsEnabled);
    await _prefs.remove(SettingsKeys.raUsername);
    await _prefs.remove(SettingsKeys.raApiKey);

    _igdbApi.clearCredentials();
    _steamGridDbApi.clearApiKey();
    _tmdbApi.clearApiKey();

    state = const SettingsState();
  }
}
