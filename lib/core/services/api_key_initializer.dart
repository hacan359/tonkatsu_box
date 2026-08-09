import 'package:core/api/credential_names.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/settings/providers/settings_provider.dart';
import '../../shared/constants/api_defaults.dart';
import '../selfhost/server_managed_keys.dart';

/// API key data loaded from SharedPreferences + ApiDefaults.
///
/// Built in main() before runApp() and passed via ProviderScope override.
class ApiKeys {
  const ApiKeys({
    this.tmdbApiKey,
    this.tvdbApiKey,
    this.steamGridDbApiKey,
    this.igdbClientId,
    this.igdbClientSecret,
    this.igdbAccessToken,
    this.raUsername,
    this.raApiKey,
    this.comicVineApiKey,
    this.googleBooksApiKey,
    this.hardcoverApiKey,
  });

  /// Key precedence: user key → built-in (ApiDefaults) → null.
  factory ApiKeys.fromPrefs(SharedPreferences prefs) {
    // TMDB: user key → built-in → null
    final String? userTmdbKey = prefs.getString(SettingsKeys.tmdbApiKey);
    final String? tmdbApiKey =
        (userTmdbKey != null && userTmdbKey.isNotEmpty)
            ? userTmdbKey
            : (ApiDefaults.hasTmdbKey ? ApiDefaults.tmdbApiKey : null);

    // TheTVDB: user key → built-in → null
    final String? userTvdbKey = prefs.getString(SettingsKeys.tvdbApiKey);
    final String? tvdbApiKey = (userTvdbKey != null && userTvdbKey.isNotEmpty)
        ? userTvdbKey
        : (ApiDefaults.hasTvdbKey ? ApiDefaults.tvdbApiKey : null);

    // SteamGridDB: user key → built-in → null
    final String? userSteamGridDbKey =
        prefs.getString(SettingsKeys.steamGridDbApiKey);
    final String? steamGridDbApiKey =
        (userSteamGridDbKey != null && userSteamGridDbKey.isNotEmpty)
            ? userSteamGridDbKey
            : (ApiDefaults.hasSteamGridDbKey
                ? ApiDefaults.steamGridDbApiKey
                : null);

    // IGDB: user key → built-in → null
    final String? userClientId = prefs.getString(SettingsKeys.clientId);
    final String? igdbClientId =
        (userClientId != null && userClientId.isNotEmpty)
            ? userClientId
            : (ApiDefaults.hasIgdbKey ? ApiDefaults.igdbClientId : null);
    final String? userClientSecret =
        prefs.getString(SettingsKeys.clientSecret);
    final String? igdbClientSecret =
        (userClientSecret != null && userClientSecret.isNotEmpty)
            ? userClientSecret
            : (ApiDefaults.hasIgdbKey ? ApiDefaults.igdbClientSecret : null);
    final String? igdbAccessToken = prefs.getString(SettingsKeys.accessToken);

    // RetroAchievements: username + API key from prefs only, no built-in.
    final String? raUsername = prefs.getString(SettingsKeys.raUsername);
    final String? raApiKey = prefs.getString(SettingsKeys.raApiKey);

    // ComicVine: user key from prefs only, no built-in.
    final String? comicVineApiKey =
        prefs.getString(SettingsKeys.comicVineApiKey);

    // Google Books: optional user key from prefs only, no built-in. Search
    // works without it; a key only raises the quota.
    final String? googleBooksApiKey =
        prefs.getString(SettingsKeys.googleBooksApiKey);

    // Hardcover: personal token from prefs only, no built-in.
    final String? hardcoverApiKey =
        prefs.getString(SettingsKeys.hardcoverApiKey);

    return ApiKeys(
      tmdbApiKey: tmdbApiKey,
      tvdbApiKey: tvdbApiKey,
      steamGridDbApiKey: steamGridDbApiKey,
      igdbClientId: igdbClientId,
      igdbClientSecret: igdbClientSecret,
      igdbAccessToken: (igdbAccessToken != null && igdbAccessToken.isNotEmpty)
          ? igdbAccessToken
          : null,
      raUsername: (raUsername != null && raUsername.isNotEmpty)
          ? raUsername
          : null,
      raApiKey: (raApiKey != null && raApiKey.isNotEmpty) ? raApiKey : null,
      comicVineApiKey:
          (comicVineApiKey != null && comicVineApiKey.isNotEmpty)
              ? comicVineApiKey
              : null,
      googleBooksApiKey:
          (googleBooksApiKey != null && googleBooksApiKey.isNotEmpty)
              ? googleBooksApiKey
              : null,
      hardcoverApiKey:
          (hardcoverApiKey != null && hardcoverApiKey.isNotEmpty)
              ? hardcoverApiKey
              : null,
    );
  }

  /// Web: the server holds the secrets, so every key it reports as configured
  /// becomes a placeholder the proxy substitutes on its way out.
  factory ApiKeys.serverManaged(Map<String, bool> availability) {
    String? managed(String name) =>
        availability[name] == true ? kServerManagedKey : null;

    return ApiKeys(
      tmdbApiKey: managed(CredentialNames.tmdb),
      tvdbApiKey: managed(CredentialNames.tvdb),
      steamGridDbApiKey: managed(CredentialNames.steamGridDb),
      igdbClientId: managed(CredentialNames.igdbClientId),
      igdbClientSecret: managed(CredentialNames.igdbClientSecret),
      // Non-null keeps the client from running the Twitch exchange itself; the
      // proxy attaches the token it holds.
      igdbAccessToken: managed(CredentialNames.igdbClientId),
      raUsername: managed(CredentialNames.raUsername),
      raApiKey: managed(CredentialNames.ra),
      comicVineApiKey: managed(CredentialNames.comicVine),
      googleBooksApiKey: managed(CredentialNames.googleBooks),
      hardcoverApiKey: managed(CredentialNames.hardcover),
    );
  }

  final String? tmdbApiKey;

  final String? tvdbApiKey;

  final String? steamGridDbApiKey;

  final String? igdbClientId;

  final String? igdbClientSecret;

  final String? igdbAccessToken;

  final String? raUsername;

  final String? raApiKey;

  final String? comicVineApiKey;

  final String? googleBooksApiKey;

  final String? hardcoverApiKey;
}

/// Overridden in main() via `apiKeysProvider.overrideWithValue(...)`.
/// Without an override it returns empty keys (safe for tests).
final Provider<ApiKeys> apiKeysProvider = Provider<ApiKeys>((Ref ref) {
  return const ApiKeys();
});
