import 'dart:io';

import 'app_proxy_config.dart';

/// AniList 403s the anonymous default `Dart/x.x` user agent, so a descriptive
/// one is installed via [HttpOverrides.global] to cover every transport.
class AppHttpOverrides extends HttpOverrides {
  static const String userAgent =
      'TonkatsuBox (https://github.com/hacan359/tonkatsu_box)';

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    // Dart's HttpClient never reads the OS proxy, so the only way to push
    // traffic through a local proxy (the port a VPN app like Clash exposes)
    // is to set it here per-connection. When disabled, AppProxyConfig routes
    // everything DIRECT, matching the prior behavior.
    return super.createHttpClient(context)
      ..userAgent = userAgent
      ..findProxy = (Uri url) => AppProxyConfig.current.findProxyForUri(url);
  }
}
