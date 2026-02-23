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

  /// Есть ли встроенный TMDB ключ.
  static bool get hasTmdbKey => tmdbApiKey.isNotEmpty;

  /// Есть ли встроенный SteamGridDB ключ.
  static bool get hasSteamGridDbKey => steamGridDbApiKey.isNotEmpty;
}
