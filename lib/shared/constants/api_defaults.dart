/// Built-in API credentials injected at build time via `--dart-define`.
/// Empty string when not provided. Lookup order is user setting → built-in → null.
abstract final class ApiDefaults {
  static const String tmdbApiKey = String.fromEnvironment('TMDB_API_KEY');

  static const String steamGridDbApiKey =
      String.fromEnvironment('STEAMGRIDDB_API_KEY');

  static const String igdbClientId =
      String.fromEnvironment('IGDB_CLIENT_ID');

  static const String igdbClientSecret =
      String.fromEnvironment('IGDB_CLIENT_SECRET');

  static const String screenScraperDevId =
      String.fromEnvironment('SCREENSCRAPER_DEV_ID');

  static const String screenScraperDevPassword =
      String.fromEnvironment('SCREENSCRAPER_DEV_PASSWORD');

  /// `softname` is sent with every ScreenScraper request to identify the app.
  static const String screenScraperSoftname = 'tonkatsuBox';

  static bool get hasTmdbKey => tmdbApiKey.isNotEmpty;

  static bool get hasSteamGridDbKey => steamGridDbApiKey.isNotEmpty;

  static bool get hasIgdbKey =>
      igdbClientId.isNotEmpty && igdbClientSecret.isNotEmpty;

  static bool get hasScreenScraperDevCreds =>
      screenScraperDevId.isNotEmpty && screenScraperDevPassword.isNotEmpty;
}
