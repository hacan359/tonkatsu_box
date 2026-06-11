import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/settings/providers/settings_provider.dart';
import '../../shared/constants/api_defaults.dart';

/// API key data loaded from SharedPreferences + ApiDefaults.
///
/// Built in main() before runApp() and passed via ProviderScope override.
class ApiKeys {
  const ApiKeys({
    this.tmdbApiKey,
    this.steamGridDbApiKey,
    this.igdbClientId,
    this.igdbClientSecret,
    this.igdbAccessToken,
    this.raUsername,
    this.raApiKey,
  });

  /// Key precedence: user key → built-in (ApiDefaults) → null.
  factory ApiKeys.fromPrefs(SharedPreferences prefs) {
    // TMDB: user key → built-in → null
    final String? userTmdbKey = prefs.getString(SettingsKeys.tmdbApiKey);
    final String? tmdbApiKey =
        (userTmdbKey != null && userTmdbKey.isNotEmpty)
            ? userTmdbKey
            : (ApiDefaults.hasTmdbKey ? ApiDefaults.tmdbApiKey : null);

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

    return ApiKeys(
      tmdbApiKey: tmdbApiKey,
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
    );
  }

  final String? tmdbApiKey;

  final String? steamGridDbApiKey;

  final String? igdbClientId;

  final String? igdbClientSecret;

  final String? igdbAccessToken;

  final String? raUsername;

  final String? raApiKey;
}

/// Overridden in main() via `apiKeysProvider.overrideWithValue(...)`.
/// Without an override it returns empty keys (safe for tests).
final Provider<ApiKeys> apiKeysProvider = Provider<ApiKeys>((Ref ref) {
  return const ApiKeys();
});
