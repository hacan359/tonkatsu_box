/// The outbound HTTP proxy every request is routed through; Dart's HttpClient
/// never reads the OS proxy, so the app carries its own.
class AppProxyConfig {
  const AppProxyConfig({
    required this.enabled,
    required this.host,
    required this.port,
  });

  const AppProxyConfig.disabled()
    : enabled = false,
      host = defaultHost,
      port = defaultPort;

  static const String defaultHost = '127.0.0.1';

  /// The mixed port Clash-style apps open by default.
  static const int defaultPort = 7890;

  static const int maxPort = 65535;

  /// Read on every request, so a change applies without a restart.
  static AppProxyConfig current = const AppProxyConfig.disabled();

  static final RegExp _hostPattern = RegExp(r'^[A-Za-z0-9]([A-Za-z0-9.-]*)$');

  final bool enabled;
  final String host;
  final int port;

  /// A host name or IPv4 address only: a scheme, a port or a space in it
  /// makes HttpClient throw on every request.
  static bool isValidHost(String host) => _hostPattern.hasMatch(host);

  static bool isValidPort(int port) => port > 0 && port <= maxPort;

  /// HttpClient.findProxy syntax. DIRECT trails the proxy so a closed proxy
  /// port falls back to a plain connection.
  String findProxyForUri(Uri uri) {
    if (!enabled || !isValidHost(host) || !isValidPort(port)) return _direct;
    if (isLocalHost(uri.host)) return _direct;
    return 'PROXY $host:$port; $_direct';
  }

  static const String _direct = 'DIRECT';

  /// Loopback, private ranges and bare LAN names: a proxy cannot reach Kodi,
  /// LAN sync or a selfhost server on the user's own network.
  static bool isLocalHost(String host) {
    final String h = host.toLowerCase();
    if (h.isEmpty) return true;
    if (h.contains(':')) {
      return h == '::1' ||
          h.startsWith('fe80:') ||
          h.startsWith('fc') ||
          h.startsWith('fd');
    }
    final List<int>? ip = _parseIpv4(h);
    if (ip != null) {
      return ip[0] == 127 ||
          ip[0] == 10 ||
          (ip[0] == 172 && ip[1] >= 16 && ip[1] <= 31) ||
          (ip[0] == 192 && ip[1] == 168) ||
          (ip[0] == 169 && ip[1] == 254);
    }
    return !h.contains('.') || h.endsWith('.local') || h.endsWith('.localhost');
  }

  static List<int>? _parseIpv4(String host) {
    final List<String> parts = host.split('.');
    if (parts.length != 4) return null;
    final List<int> octets = <int>[];
    for (final String part in parts) {
      final int? octet = int.tryParse(part);
      if (octet == null || octet < 0 || octet > 255) return null;
      octets.add(octet);
    }
    return octets;
  }
}
