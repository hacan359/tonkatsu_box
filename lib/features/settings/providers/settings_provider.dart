import 'package:core/models/collection_item.dart';
import 'package:core/utils/anime_manga_title_language.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/constants/api_defaults.dart';
import '../../../core/selfhost/server_credentials.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/theme/app_theme_id.dart';
import '../../../core/services/discord_rpc_service.dart';
import '../../../core/api/comicvine_api.dart';
import '../../../core/api/google_books_api.dart';
import '../../../core/api/hardcover_api.dart';
import '../../../core/api/igdb_api.dart';
import '../../../core/api/ra_api.dart';
import '../../../core/api/screenscraper_api.dart';
import '../../../core/api/steamgriddb_api.dart';
import '../../../core/api/tmdb_api.dart';
import '../../../core/api/tvdb_api.dart';
import '../../../core/database/database_service.dart';
import '../../../core/services/config_service.dart';

abstract class SettingsKeys {
  static const String clientId = 'igdb_client_id';
  static const String clientSecret = 'igdb_client_secret';
  static const String accessToken = 'igdb_access_token';
  static const String tokenExpires = 'igdb_token_expires';
  static const String lastSync = 'igdb_last_sync';
  // One-shot: consumed by the splash to land on home after an app remount.
  static const String skipPickerOnce = 'skip_picker_once';

  static const String steamGridDbApiKey = 'steamgriddb_api_key';

  static const String tmdbApiKey = 'tmdb_api_key';

  static const String tvdbApiKey = 'tvdb_api_key';

  static const String comicVineApiKey = 'comicvine_api_key';

  static const String googleBooksApiKey = 'google_books_api_key';

  /// Personal Bearer token from hardcover.app/account/api.
  static const String hardcoverApiKey = 'hardcover_api_key';

  static const String screenScraperSsid = 'screenscraper_ssid';

  static const String screenScraperSspassword = 'screenscraper_sspassword';

  /// Prefix; suffixed per-collection id at call site.
  static const String collectionViewModePrefix = 'collection_view_mode_';

  /// Prefix; suffixed per-collection id at call site.
  static const String collectionTableModePrefix = 'collection_table_mode_';

  static const String defaultAuthor = 'default_author';

  /// TMDB content language (ru-RU or en-US).
  static const String tmdbLanguage = 'tmdb_language';

  static const String tmdbLanguageDefault = 'en-US';

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

  /// Simkl access token from the PIN flow. Persisted only if user opts in
  /// via the Simkl Import checkbox (the token lives ~forever server-side).
  static const String simklAccessToken = 'simkl_access_token';

  static const String simklRememberToken = 'simkl_remember_token';

  /// User-provided Simkl client id, overriding the build-time default.
  /// Entered on the import screen (the Steam pattern); saved by default.
  static const String simklClientId = 'simkl_client_id';

  static const String simklRememberClientId = 'simkl_remember_client_id';

  /// Last AniList username used in import dialog. Persisted on successful import.
  static const String aniListUsername = 'anilist_username';

  /// Last Hardcover username used in import dialog. Persisted on successful import.
  static const String hardcoverUsername = 'hardcover_username';

  static const String richCollectionsEnabled = 'rich_collections_enabled';

  static const String hideEmptyMediaTypeChevrons =
      'hide_empty_media_type_chevrons';

  /// Always show subcategory subfilters (game platforms, anime/manga formats)
  /// even when their media-type chevron is not selected.
  static const String alwaysShowSubcategories = 'always_show_subcategories';

  /// Date display format id (see [DateFormatPreset]).
  static const String dateFormat = 'date_format';

  static const String dateFormatDefault = 'month_day_year';

  /// AniList title language (romaji / english / native).
  static const String animeMangaTitleLanguage = 'anime_manga_title_language';

  static const String animeMangaTitleLanguageDefault =
      AnimeMangaTitleLanguage.defaultId;

  /// App theme id (see [AppThemeId]).
  static const String appTheme = 'app_theme';

  /// Grid card size multiplier.
  static const String cardScale = 'card_scale';

  static const double cardScaleDefault = 1.0;

  static const double cardScaleMin = 0.7;

  static const double cardScaleMax = 1.6;
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
    this.tvdbApiKey,
    this.comicVineApiKey,
    this.googleBooksApiKey,
    this.hardcoverApiKey,
    this.screenScraperSsid,
    this.screenScraperSspassword,
    this.defaultAuthor,
    this.tmdbLanguage = SettingsKeys.tmdbLanguageDefault,
    this.appLanguage = SettingsKeys.appLanguageDefault,
    this.showRecommendations = true,
    this.showBlurayOverlay = true,
    this.showPlatformOverlay = true,
    this.discordRpcEnabled = false,
    this.discordRaSyncEnabled = false,
    this.richCollectionsEnabled = false,
    this.hideEmptyMediaTypeChevrons = false,
    this.alwaysShowSubcategories = false,
    this.dateFormat = SettingsKeys.dateFormatDefault,
    this.animeMangaTitleLanguage = SettingsKeys.animeMangaTitleLanguageDefault,
    this.cardScale = SettingsKeys.cardScaleDefault,
    this.appTheme = AppThemeId.dark,
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

  final String? tvdbApiKey;

  final String? comicVineApiKey;

  final String? googleBooksApiKey;

  final String? hardcoverApiKey;

  final String? screenScraperSsid;

  final String? screenScraperSspassword;

  bool get hasScreenScraperCreds =>
      screenScraperSsid != null &&
      screenScraperSsid!.isNotEmpty &&
      screenScraperSspassword != null &&
      screenScraperSspassword!.isNotEmpty;

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

  /// Hide media-type chevrons with zero items in the current filter bar.
  final bool hideEmptyMediaTypeChevrons;

  /// Always show subcategory subfilters (platforms, formats) without first
  /// selecting their media-type chevron.
  final bool alwaysShowSubcategories;

  /// Date display format preset id.
  final String dateFormat;

  /// AniList title language preference.
  final String animeMangaTitleLanguage;

  /// Grid card size multiplier (1.0 = default size).
  final double cardScale;

  /// Selected app theme.
  final AppThemeId appTheme;

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

  bool get hasTvdbKey => tvdbApiKey != null && tvdbApiKey!.isNotEmpty;

  bool get hasComicVineKey =>
      comicVineApiKey != null && comicVineApiKey!.isNotEmpty;

  bool get hasGoogleBooksKey =>
      googleBooksApiKey != null && googleBooksApiKey!.isNotEmpty;

  bool get hasHardcoverKey =>
      hardcoverApiKey != null && hardcoverApiKey!.isNotEmpty;

  bool get hasSteamGridDbKey =>
      steamGridDbApiKey != null && steamGridDbApiKey!.isNotEmpty;

  bool get isTmdbKeyBuiltIn =>
      hasTmdbKey &&
      ApiDefaults.hasTmdbKey &&
      tmdbApiKey == ApiDefaults.tmdbApiKey;

  bool get isTvdbKeyBuiltIn =>
      hasTvdbKey &&
      ApiDefaults.hasTvdbKey &&
      tvdbApiKey == ApiDefaults.tvdbApiKey;

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
    String? tvdbApiKey,
    String? comicVineApiKey,
    String? googleBooksApiKey,
    String? hardcoverApiKey,
    String? screenScraperSsid,
    String? screenScraperSspassword,
    String? defaultAuthor,
    String? tmdbLanguage,
    String? appLanguage,
    bool? showRecommendations,
    bool? showBlurayOverlay,
    bool? showPlatformOverlay,
    bool? discordRpcEnabled,
    bool? discordRaSyncEnabled,
    bool? richCollectionsEnabled,
    bool? hideEmptyMediaTypeChevrons,
    bool? alwaysShowSubcategories,
    String? dateFormat,
    String? animeMangaTitleLanguage,
    double? cardScale,
    AppThemeId? appTheme,
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
      tvdbApiKey: tvdbApiKey ?? this.tvdbApiKey,
      comicVineApiKey: comicVineApiKey ?? this.comicVineApiKey,
      googleBooksApiKey: googleBooksApiKey ?? this.googleBooksApiKey,
      hardcoverApiKey: hardcoverApiKey ?? this.hardcoverApiKey,
      screenScraperSsid: screenScraperSsid ?? this.screenScraperSsid,
      screenScraperSspassword:
          screenScraperSspassword ?? this.screenScraperSspassword,
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
      hideEmptyMediaTypeChevrons:
          hideEmptyMediaTypeChevrons ?? this.hideEmptyMediaTypeChevrons,
      alwaysShowSubcategories:
          alwaysShowSubcategories ?? this.alwaysShowSubcategories,
      dateFormat: dateFormat ?? this.dateFormat,
      animeMangaTitleLanguage:
          animeMangaTitleLanguage ?? this.animeMangaTitleLanguage,
      cardScale: cardScale ?? this.cardScale,
      appTheme: appTheme ?? this.appTheme,
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

extension AnimeMangaTitleLanguagePrefs on SharedPreferences {
  /// Current AniList title language with default fallback. Use this from
  /// non-UI callers that already hold a [SharedPreferences] instance to
  /// avoid taking a dependency on the heavy [SettingsNotifier].
  String get animeMangaTitleLanguage =>
      getString(SettingsKeys.animeMangaTitleLanguage) ??
      SettingsKeys.animeMangaTitleLanguageDefault;
}

class SettingsNotifier extends Notifier<SettingsState> {
  late SharedPreferences _prefs;
  late IgdbApi _igdbApi;
  late SteamGridDbApi _steamGridDbApi;
  late TmdbApi _tmdbApi;
  late TvdbApi _tvdbApi;
  late ComicVineApi _comicVineApi;
  late GoogleBooksApi _googleBooksApi;
  late HardcoverApi _hardcoverApi;
  late ScreenScraperApi _screenScraperApi;
  late DatabaseService _dbService;

  /// Web keeps no keys file: the proxy reads them on the server, so a change
  /// here has to travel there or the next request goes out unauthenticated.
  Future<void> _writeCredential(String prefKey, String value) async {
    if (value.isEmpty) {
      await _prefs.remove(prefKey);
    } else {
      await _prefs.setString(prefKey, value);
    }
    if (!kIsWebBuild) return;
    final String? name = kConfigKeyToCredential[prefKey];
    if (name != null) {
      await uploadCredentials(<String, String>{name: value});
    }
  }

  @override
  SettingsState build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    _igdbApi = ref.watch(igdbApiProvider);
    _steamGridDbApi = ref.watch(steamGridDbApiProvider);
    _tmdbApi = ref.watch(tmdbApiProvider);
    _tvdbApi = ref.watch(tvdbApiProvider);
    _comicVineApi = ref.watch(comicVineApiProvider);
    _googleBooksApi = ref.watch(googleBooksApiProvider);
    _hardcoverApi = ref.watch(hardcoverApiProvider);
    _screenScraperApi = ref.watch(screenScraperApiProvider);
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
    // TheTVDB: user key → built-in key → null
    final String? userTvdbKey = _prefs.getString(SettingsKeys.tvdbApiKey);
    final String? tvdbApiKey = (userTvdbKey != null && userTvdbKey.isNotEmpty)
        ? userTvdbKey
        : (ApiDefaults.hasTvdbKey ? ApiDefaults.tvdbApiKey : null);
    // ComicVine: user key from prefs only, no built-in.
    final String? comicVineApiKey =
        _prefs.getString(SettingsKeys.comicVineApiKey);
    // Google Books: optional user key from prefs only, no built-in.
    final String? googleBooksApiKey =
        _prefs.getString(SettingsKeys.googleBooksApiKey);
    // Hardcover: personal token from prefs only, no built-in.
    final String? hardcoverApiKey =
        _prefs.getString(SettingsKeys.hardcoverApiKey);
    final String? screenScraperSsid =
        _prefs.getString(SettingsKeys.screenScraperSsid);
    final String? screenScraperSspassword =
        _prefs.getString(SettingsKeys.screenScraperSspassword);
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
    final bool hideEmptyMediaTypeChevrons =
        _prefs.getBool(SettingsKeys.hideEmptyMediaTypeChevrons) ?? false;
    final bool alwaysShowSubcategories =
        _prefs.getBool(SettingsKeys.alwaysShowSubcategories) ?? false;
    final String dateFormat =
        _prefs.getString(SettingsKeys.dateFormat) ??
            SettingsKeys.dateFormatDefault;
    final String animeMangaTitleLanguage =
        _prefs.getString(SettingsKeys.animeMangaTitleLanguage) ??
            SettingsKeys.animeMangaTitleLanguageDefault;
    final double cardScale = (_prefs.getDouble(SettingsKeys.cardScale) ??
            SettingsKeys.cardScaleDefault)
        .clamp(SettingsKeys.cardScaleMin, SettingsKeys.cardScaleMax);
    final AppThemeId appTheme =
        AppThemeId.fromId(_prefs.getString(SettingsKeys.appTheme));

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
      tvdbApiKey: tvdbApiKey,
      comicVineApiKey: comicVineApiKey,
      googleBooksApiKey: googleBooksApiKey,
      hardcoverApiKey: hardcoverApiKey,
      screenScraperSsid: screenScraperSsid,
      screenScraperSspassword: screenScraperSspassword,
      defaultAuthor: defaultAuthor,
      tmdbLanguage: tmdbLanguage,
      appLanguage: appLanguage,
      showRecommendations: showRecommendations,
      showBlurayOverlay: showBlurayOverlay,
      showPlatformOverlay: showPlatformOverlay,
      discordRpcEnabled: discordRpcEnabled,
      discordRaSyncEnabled: discordRaSyncEnabled,
      richCollectionsEnabled: richCollectionsEnabled,
      hideEmptyMediaTypeChevrons: hideEmptyMediaTypeChevrons,
      alwaysShowSubcategories: alwaysShowSubcategories,
      dateFormat: dateFormat,
      animeMangaTitleLanguage: animeMangaTitleLanguage,
      cardScale: cardScale,
      appTheme: appTheme,
    );

    // API keys already wired by apiKeysProvider; only the request-time language param is set here.
    _tmdbApi.setLanguage(tmdbLanguage);
    // TheTVDB never localizes a response; the locale only picks which
    // translation the mappers read, so it follows the app language.
    _tvdbApi.setLocale(appLanguage);
    _screenScraperApi.setUserCredentials(
      ssid: screenScraperSsid ?? '',
      sspassword: screenScraperSspassword ?? '',
    );

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
    if (state.tvdbApiKey != null && state.tvdbApiKey!.isNotEmpty) {
      _tvdbApi.setApiKey(state.tvdbApiKey!);
    }
    if (state.comicVineApiKey != null && state.comicVineApiKey!.isNotEmpty) {
      _comicVineApi.setApiKey(state.comicVineApiKey!);
    }
    if (state.googleBooksApiKey != null &&
        state.googleBooksApiKey!.isNotEmpty) {
      _googleBooksApi.setApiKey(state.googleBooksApiKey!);
    }
    if (state.hardcoverApiKey != null && state.hardcoverApiKey!.isNotEmpty) {
      _hardcoverApi.setApiKey(state.hardcoverApiKey!);
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
    final int count = await _dbService.gameDao.getPlatformCount();
    if (count != state.platformCount) {
      state = state.copyWith(platformCount: count);
    }
  }

  Future<void> setCredentials({
    required String clientId,
    required String clientSecret,
  }) async {
    await _writeCredential(SettingsKeys.clientId, clientId);
    await _writeCredential(SettingsKeys.clientSecret, clientSecret);

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
      await _writeCredential(SettingsKeys.steamGridDbApiKey, apiKey);
      _steamGridDbApi.setApiKey(apiKey);
    } else {
      await _writeCredential(SettingsKeys.steamGridDbApiKey, '');
      _steamGridDbApi.clearApiKey();
    }

    state = state.copyWith(steamGridDbApiKey: apiKey);
  }

  Future<void> setScreenScraperCredentials({
    required String ssid,
    required String sspassword,
  }) async {
    if (ssid.isNotEmpty) {
      await _writeCredential(SettingsKeys.screenScraperSsid, ssid);
    } else {
      await _writeCredential(SettingsKeys.screenScraperSsid, '');
    }
    if (sspassword.isNotEmpty) {
      await _writeCredential(SettingsKeys.screenScraperSspassword, sspassword);
    } else {
      await _writeCredential(SettingsKeys.screenScraperSspassword, '');
    }
    _screenScraperApi.setUserCredentials(ssid: ssid, sspassword: sspassword);
    state = state.copyWith(
      screenScraperSsid: ssid,
      screenScraperSspassword: sspassword,
    );
  }

  Future<void> setTmdbApiKey(String apiKey) async {
    if (apiKey.isNotEmpty) {
      await _writeCredential(SettingsKeys.tmdbApiKey, apiKey);
      _tmdbApi.setApiKey(apiKey);
    } else {
      await _writeCredential(SettingsKeys.tmdbApiKey, '');
      _tmdbApi.clearApiKey();
    }

    state = state.copyWith(tmdbApiKey: apiKey);
  }

  Future<void> setTvdbApiKey(String apiKey) async {
    if (apiKey.isNotEmpty) {
      await _writeCredential(SettingsKeys.tvdbApiKey, apiKey);
      _tvdbApi.setApiKey(apiKey);
    } else {
      await _writeCredential(SettingsKeys.tvdbApiKey, '');
      _tvdbApi.clearApiKey();
    }

    state = state.copyWith(tvdbApiKey: apiKey);
  }

  Future<void> setComicVineApiKey(String apiKey) async {
    if (apiKey.isNotEmpty) {
      await _writeCredential(SettingsKeys.comicVineApiKey, apiKey);
      _comicVineApi.setApiKey(apiKey);
    } else {
      await _writeCredential(SettingsKeys.comicVineApiKey, '');
      _comicVineApi.clearApiKey();
    }

    state = state.copyWith(comicVineApiKey: apiKey);
  }

  Future<void> setGoogleBooksApiKey(String apiKey) async {
    if (apiKey.isNotEmpty) {
      await _writeCredential(SettingsKeys.googleBooksApiKey, apiKey);
      _googleBooksApi.setApiKey(apiKey);
    } else {
      await _writeCredential(SettingsKeys.googleBooksApiKey, '');
      _googleBooksApi.clearApiKey();
    }

    state = state.copyWith(googleBooksApiKey: apiKey);
  }

  /// The account page shows the token with a `Bearer ` prefix — strip it so
  /// a full copy-paste still works.
  Future<void> setHardcoverApiKey(String apiKey) async {
    final String token = apiKey
        .replaceFirst(RegExp(r'^\s*Bearer\s+', caseSensitive: false), '')
        .trim();
    if (token.isNotEmpty) {
      await _writeCredential(SettingsKeys.hardcoverApiKey, token);
      _hardcoverApi.setApiKey(token);
    } else {
      await _writeCredential(SettingsKeys.hardcoverApiKey, '');
      _hardcoverApi.clearApiKey();
    }

    state = state.copyWith(hardcoverApiKey: token);
  }

  /// Genres are pre-seeded for both EN + RU — no cache clear needed on switch.
  Future<void> setTmdbLanguage(String language) async {
    await _prefs.setString(SettingsKeys.tmdbLanguage, language);
    _tmdbApi.setLanguage(language);
    state = state.copyWith(tmdbLanguage: language);
  }

  Future<void> setAppLanguage(String language) async {
    await _prefs.setString(SettingsKeys.appLanguage, language);
    _tvdbApi.setLocale(language);
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

  Future<void> setHideEmptyMediaTypeChevrons({required bool enabled}) async {
    await _prefs.setBool(SettingsKeys.hideEmptyMediaTypeChevrons, enabled);
    state = state.copyWith(hideEmptyMediaTypeChevrons: enabled);
  }

  Future<void> setAlwaysShowSubcategories({required bool enabled}) async {
    await _prefs.setBool(SettingsKeys.alwaysShowSubcategories, enabled);
    state = state.copyWith(alwaysShowSubcategories: enabled);
  }

  Future<void> setDateFormat(String presetId) async {
    await _prefs.setString(SettingsKeys.dateFormat, presetId);
    state = state.copyWith(dateFormat: presetId);
  }

  Future<void> setAnimeMangaTitleLanguage(String lang) async {
    await _prefs.setString(SettingsKeys.animeMangaTitleLanguage, lang);
    state = state.copyWith(animeMangaTitleLanguage: lang);
  }

  Future<void> setAppTheme(AppThemeId theme) async {
    await _prefs.setString(SettingsKeys.appTheme, theme.id);
    // The theme ValueKey remounts the app through the splash — don't let
    // that replay surface the profile picker.
    await _prefs.setBool(SettingsKeys.skipPickerOnce, true);
    state = state.copyWith(appTheme: theme);
  }

  /// Set [persist] to false for live slider preview; the final value must be
  /// saved with a persisting call.
  Future<void> setCardScale(double scale, {bool persist = true}) async {
    final double clamped =
        scale.clamp(SettingsKeys.cardScaleMin, SettingsKeys.cardScaleMax);
    state = state.copyWith(cardScale: clamped);
    if (persist) {
      await _prefs.setDouble(SettingsKeys.cardScale, clamped);
    }
  }

  /// Falls back to built-in key if available, otherwise clears.
  Future<void> resetTmdbApiKeyToDefault() async {
    await _writeCredential(SettingsKeys.tmdbApiKey, '');
    if (ApiDefaults.hasTmdbKey) {
      _tmdbApi.setApiKey(ApiDefaults.tmdbApiKey);
      state = state.copyWith(tmdbApiKey: ApiDefaults.tmdbApiKey);
    } else {
      _tmdbApi.clearApiKey();
      state = state.copyWith(tmdbApiKey: '');
    }
  }

  /// Falls back to built-in key if available, otherwise clears.
  Future<void> resetTvdbApiKeyToDefault() async {
    await _writeCredential(SettingsKeys.tvdbApiKey, '');
    if (ApiDefaults.hasTvdbKey) {
      _tvdbApi.setApiKey(ApiDefaults.tvdbApiKey);
      state = state.copyWith(tvdbApiKey: ApiDefaults.tvdbApiKey);
    } else {
      _tvdbApi.clearApiKey();
      state = state.copyWith(tvdbApiKey: '');
    }
  }

  /// Falls back to built-in credentials if available, otherwise clears.
  Future<void> resetIgdbCredentialsToDefault() async {
    await _writeCredential(SettingsKeys.clientId, '');
    await _writeCredential(SettingsKeys.clientSecret, '');
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
    await _writeCredential(SettingsKeys.steamGridDbApiKey, '');
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

  Future<bool> validateTvdbKey() async {
    if (!state.hasTvdbKey) return false;
    return _tvdbApi.validateApiKey(state.tvdbApiKey!);
  }

  Future<bool> validateSteamGridDbKey() async {
    if (!state.hasSteamGridDbKey) return false;
    return _steamGridDbApi.validateApiKey(state.steamGridDbApiKey!);
  }

  Future<bool> validateComicVineKey() async {
    if (!state.hasComicVineKey) return false;
    return _comicVineApi.validateApiKey(state.comicVineApiKey!);
  }

  Future<bool> validateGoogleBooksKey() async {
    if (!state.hasGoogleBooksKey) return false;
    return _googleBooksApi.validateApiKey(state.googleBooksApiKey!);
  }

  Future<bool> validateHardcoverKey() async {
    if (!state.hasHardcoverKey) return false;
    return _hardcoverApi.validateApiKey(state.hardcoverApiKey!);
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
      // The config lands in prefs; on web the proxy reads keys on the server,
      // so they have to travel there too.
      await syncCredentialsToServer(_prefs);
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
    await _writeCredential(SettingsKeys.clientId, '');
    await _writeCredential(SettingsKeys.clientSecret, '');
    await _prefs.remove(SettingsKeys.accessToken);
    await _prefs.remove(SettingsKeys.tokenExpires);
    await _prefs.remove(SettingsKeys.lastSync);
    await _writeCredential(SettingsKeys.steamGridDbApiKey, '');
    await _writeCredential(SettingsKeys.tmdbApiKey, '');
    await _writeCredential(SettingsKeys.tvdbApiKey, '');
    await _writeCredential(SettingsKeys.comicVineApiKey, '');
    await _writeCredential(SettingsKeys.googleBooksApiKey, '');
    await _writeCredential(SettingsKeys.hardcoverApiKey, '');
    await _writeCredential(SettingsKeys.screenScraperSsid, '');
    await _writeCredential(SettingsKeys.screenScraperSspassword, '');
    await _prefs.remove(SettingsKeys.defaultAuthor);
    await _prefs.remove(SettingsKeys.showRecommendations);
    await _prefs.remove(SettingsKeys.showBlurayOverlay);
    await _prefs.remove(SettingsKeys.showPlatformOverlay);
    await _prefs.remove(SettingsKeys.discordRpcEnabled);
    await _prefs.remove(SettingsKeys.discordRaSyncEnabled);
    await _prefs.remove(SettingsKeys.richCollectionsEnabled);
    await _prefs.remove(SettingsKeys.hideEmptyMediaTypeChevrons);
    await _prefs.remove(SettingsKeys.alwaysShowSubcategories);
    await _prefs.remove(SettingsKeys.dateFormat);
    await _prefs.remove(SettingsKeys.animeMangaTitleLanguage);
    await _prefs.remove(SettingsKeys.cardScale);
    await _prefs.remove(SettingsKeys.appTheme);
    await _writeCredential(SettingsKeys.raUsername, '');
    await _writeCredential(SettingsKeys.raApiKey, '');

    _igdbApi.clearCredentials();
    _steamGridDbApi.clearApiKey();
    _tmdbApi.clearApiKey();
    _tvdbApi.clearApiKey();
    _comicVineApi.clearApiKey();
    _googleBooksApi.clearApiKey();
    _hardcoverApi.clearApiKey();

    state = const SettingsState();
  }
}
