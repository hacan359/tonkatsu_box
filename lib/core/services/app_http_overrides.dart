import 'dart:io';

/// AniList 403s the anonymous default `Dart/x.x` user agent, so a descriptive
/// one is installed via [HttpOverrides.global] to cover every transport.
class AppHttpOverrides extends HttpOverrides {
  static const String userAgent =
      'TonkatsuBox (https://github.com/hacan359/tonkatsu_box)';

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)..userAgent = userAgent;
  }
}
