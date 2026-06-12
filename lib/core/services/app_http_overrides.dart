import 'dart:io';

/// Stamps a descriptive User-Agent onto every [HttpClient] the app creates.
///
/// AniList manually blocks the anonymous default `Dart/x.x (dart:io)`
/// user agent when scrapers hide behind it, which 403s both their GraphQL
/// API and the image CDN. Installing this as [HttpOverrides.global] covers
/// every transport at once — Dio adapters, [NetworkImage] and
/// cached_network_image — including clients created by packages the app
/// does not construct itself. Per-client `User-Agent` headers still win
/// over this default.
class AppHttpOverrides extends HttpOverrides {
  /// User-Agent identifying the app, with a contact URL.
  static const String userAgent =
      'TonkatsuBox (https://github.com/hacan359/tonkatsu_box)';

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)..userAgent = userAgent;
  }
}
