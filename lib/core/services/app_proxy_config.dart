/// In-app outbound proxy configuration.
///
/// TonkatsuBox's only HTTP outlet is [createApiDio], which never reads the
/// system proxy — Dart's [HttpClient] ignores OS proxy settings unless told
/// otherwise. A tunnel-mode VPN (Clash VpnService / Surge / etc.) is the only
/// thing that normally carries Dart traffic out of a restricted network, and
/// on some setups that capture path fails for every request (every source
/// drops to "unreachable" the moment the VPN is on).
///
/// Letting the user point Dart at the local proxy port their VPN app also
/// exposes (e.g. Clash's mixed port 7890) routes traffic through the proxy
/// directly, bypassing the fragile TUN-capture path entirely.
class AppProxyConfig {
  const AppProxyConfig({
    required this.enabled,
    required this.type,
    required this.host,
    required this.port,
  });

  const AppProxyConfig.disabled()
      : enabled = false,
        type = AppProxyType.http,
        host = '127.0.0.1',
        port = 7890;

  /// The live configuration [AppHttpOverrides] reads on every request.
  static AppProxyConfig current = const AppProxyConfig.disabled();

  final bool enabled;
  final AppProxyType type;
  final String host;
  final int port;

  /// The routing decision for a single request, in the syntax
  /// [HttpClient.findProxy] expects.
  ///
  /// Loopback always goes DIRECT so the self-host server (and anything on
  /// localhost) is never sent to the proxy. When the proxy is enabled we
  /// append DIRECT as a fallback: if the local proxy port is closed (app left
  /// on but VPN off) requests degrade to the same direct behavior they had
  /// before this setting existed, instead of hanging on a dead port.
  String findProxyForUri(Uri uri) {
    if (uri.host == 'localhost' ||
        uri.host == '127.0.0.1' ||
        uri.host == '::1') {
      return 'DIRECT';
    }
    if (!enabled) return 'DIRECT';
    final String authority = '$host:$port';
    final String primary = switch (type) {
      AppProxyType.http => 'PROXY $authority',
      AppProxyType.socks5 => 'SOCKS5 $authority',
    };
    return '$primary; DIRECT';
  }
}

/// The proxy protocol Dart's [HttpClient.findProxy] understands.
enum AppProxyType {
  http,
  socks5;

  String get id => switch (this) {
        AppProxyType.http => 'http',
        AppProxyType.socks5 => 'socks5',
      };

  String get label => switch (this) {
        AppProxyType.http => 'HTTP',
        AppProxyType.socks5 => 'SOCKS5',
      };

  static AppProxyType fromId(String id) =>
      id == 'socks5' ? AppProxyType.socks5 : AppProxyType.http;
}
