// Ранняя инициализация API ключей до runApp().

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/settings/providers/settings_provider.dart';
import '../../shared/constants/api_defaults.dart';

/// Данные API ключей, загруженные из SharedPreferences + ApiDefaults.
///
/// Создаётся в main() до runApp() и передаётся через ProviderScope override.
class ApiKeys {
  /// Создаёт [ApiKeys].
  const ApiKeys({
    this.tmdbApiKey,
    this.steamGridDbApiKey,
    this.igdbClientId,
    this.igdbAccessToken,
  });

  /// Загружает ключи из SharedPreferences с fallback на встроенные.
  ///
  /// Приоритет: пользовательский ключ → встроенный (ApiDefaults) → null.
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

    // IGDB: client ID + access token из prefs
    final String? igdbClientId = prefs.getString(SettingsKeys.clientId);
    final String? igdbAccessToken = prefs.getString(SettingsKeys.accessToken);

    return ApiKeys(
      tmdbApiKey: tmdbApiKey,
      steamGridDbApiKey: steamGridDbApiKey,
      igdbClientId: (igdbClientId != null && igdbClientId.isNotEmpty)
          ? igdbClientId
          : null,
      igdbAccessToken: (igdbAccessToken != null && igdbAccessToken.isNotEmpty)
          ? igdbAccessToken
          : null,
    );
  }

  /// API ключ для TMDB.
  final String? tmdbApiKey;

  /// API ключ для SteamGridDB.
  final String? steamGridDbApiKey;

  /// Client ID для IGDB.
  final String? igdbClientId;

  /// OAuth access token для IGDB.
  final String? igdbAccessToken;
}

/// Провайдер загруженных API ключей.
///
/// Override в main() через `apiKeysProvider.overrideWithValue(...)`.
/// Без override возвращает пустые ключи (безопасно для тестов).
final Provider<ApiKeys> apiKeysProvider = Provider<ApiKeys>((Ref ref) {
  return const ApiKeys();
});
