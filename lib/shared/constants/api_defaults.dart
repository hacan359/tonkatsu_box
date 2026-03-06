// Встроенные API ключи, инжектируемые при сборке через --dart-define.

/// Встроенные значения API ключей по умолчанию.
///
/// Значения подставляются при сборке через `--dart-define`.
/// Если `--dart-define` не указан, возвращается пустая строка.
///
/// Приоритет: пользовательский ключ (SharedPreferences) → встроенный → null.
abstract final class ApiDefaults {
  /// Встроенный TMDB API ключ.
  static const String tmdbApiKey = String.fromEnvironment('TMDB_API_KEY');

  /// Встроенный SteamGridDB API ключ.
  static const String steamGridDbApiKey =
      String.fromEnvironment('STEAMGRIDDB_API_KEY');

  /// Встроенный IGDB Client ID.
  static const String igdbClientId =
      String.fromEnvironment('IGDB_CLIENT_ID');

  /// Встроенный IGDB Client Secret.
  static const String igdbClientSecret =
      String.fromEnvironment('IGDB_CLIENT_SECRET');

  /// Есть ли встроенный TMDB ключ.
  static bool get hasTmdbKey => tmdbApiKey.isNotEmpty;

  /// Есть ли встроенный SteamGridDB ключ.
  static bool get hasSteamGridDbKey => steamGridDbApiKey.isNotEmpty;

  /// Есть ли встроенный IGDB ключ (оба поля заполнены).
  static bool get hasIgdbKey =>
      igdbClientId.isNotEmpty && igdbClientSecret.isNotEmpty;
}
