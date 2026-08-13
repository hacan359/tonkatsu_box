import 'platform_features.dart';

/// Built-in API credentials injected at build time via `--dart-define`.
/// Empty string when not provided. Lookup order is user setting → built-in → null.
abstract final class ApiDefaults {
  static const String tmdbApiKey = String.fromEnvironment('TMDB_API_KEY');

  static const String tvdbApiKey = String.fromEnvironment('TVDB_API_KEY');

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

  /// Simkl OAuth client id (PIN flow needs no secret in the build).
  static const String simklClientId = String.fromEnvironment('SIMKL_CLIENT_ID');

  static const String podcastIndexApiKey =
      String.fromEnvironment('PODCASTINDEX_API_KEY');

  static const String podcastIndexApiSecret =
      String.fromEnvironment('PODCASTINDEX_API_SECRET');

  static bool get hasTmdbKey => tmdbApiKey.isNotEmpty;

  static bool get hasTvdbKey => tvdbApiKey.isNotEmpty;

  static bool get hasSteamGridDbKey => steamGridDbApiKey.isNotEmpty;

  static bool get hasIgdbKey =>
      igdbClientId.isNotEmpty && igdbClientSecret.isNotEmpty;

  // On web the dev pair lives on the server and the proxy injects it; the
  // dart-defines never reach main.dart.js on purpose.
  static bool get hasScreenScraperDevCreds =>
      kIsWebBuild ||
      (screenScraperDevId.isNotEmpty && screenScraperDevPassword.isNotEmpty);

  static bool get hasSimklClientId => simklClientId.isNotEmpty;

  // On web the pair lives on the server and the proxy signs requests; the
  // dart-defines never reach main.dart.js on purpose.
  static bool get hasPodcastIndexKey =>
      kIsWebBuild ||
      (podcastIndexApiKey.isNotEmpty && podcastIndexApiSecret.isNotEmpty);
}
