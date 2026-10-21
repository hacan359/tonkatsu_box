import 'package:args/args.dart';

/// `off` is the historical behaviour; `token` gates every data route behind a
/// bearer token, see [AuthToken].
enum AuthMode {
  off,
  token;

  static AuthMode parse(String value) {
    for (final AuthMode mode in values) {
      if (mode.name == value) return mode;
    }
    throw FormatException(
      'Unknown auth mode "$value"; expected one of: '
      '${values.map((AuthMode m) => m.name).join(', ')}',
    );
  }
}

/// Where the server listens and which directories it works with.
class ServerConfig {
  const ServerConfig({
    required this.address,
    required this.port,
    required this.dataDir,
    required this.webRoot,
    this.authMode = AuthMode.off,
    this.authToken,
    this.imageHosts = const <String>[],
  });

  /// Command line wins over [env] so a container can be overridden without
  /// rebuilding its image.
  factory ServerConfig.parse(
    List<String> args, {
    Map<String, String> env = const <String, String>{},
  }) {
    final ArgResults parsed = buildParser().parse(args);

    return ServerConfig(
      address: _pick(parsed, 'address', env['TONKATSU_ADDRESS'], '0.0.0.0'),
      port: int.parse(_pick(parsed, 'port', env['TONKATSU_PORT'], '8080')),
      dataDir: _pick(parsed, 'data-dir', env['TONKATSU_DATA_DIR'], 'data'),
      webRoot: _pick(parsed, 'web-root', env['TONKATSU_WEB_ROOT'], 'web'),
      authMode: AuthMode.parse(
        _pick(parsed, 'auth', env['TONKATSU_AUTH'], AuthMode.off.name),
      ),
      authToken: _pickOrNull(parsed, 'auth-token', env['TONKATSU_AUTH_TOKEN']),
      imageHosts: _splitHosts(
        _pickOrNull(parsed, 'image-hosts', env['TONKATSU_IMAGE_HOSTS']),
      ),
    );
  }

  /// The parser is public so `--help` can be rendered without a config.
  static ArgParser buildParser() {
    return ArgParser()
      ..addOption('address', help: 'Interface to bind (TONKATSU_ADDRESS)')
      ..addOption('port', help: 'TCP port to listen on (TONKATSU_PORT)')
      ..addOption('data-dir',
          help: 'Directory holding the database (TONKATSU_DATA_DIR)')
      ..addOption('web-root',
          help: 'Directory with the built web client (TONKATSU_WEB_ROOT)')
      ..addOption('auth',
          allowed: AuthMode.values.map((AuthMode m) => m.name).toList(),
          help: 'off, or token to require a bearer token (TONKATSU_AUTH)')
      ..addOption('auth-token',
          help: 'The bearer token to accept; generated and stored in the '
              'data directory when absent (TONKATSU_AUTH_TOKEN)')
      ..addOption('image-hosts',
          help: 'Comma-separated hosts /img may fetch covers from, with their '
              'subdomains; empty allows any (TONKATSU_IMAGE_HOSTS)')
      ..addFlag('help', negatable: false, help: 'Print usage and exit');
  }

  final String address;
  final int port;
  final String dataDir;

  /// Directory with `flutter build web` output; absent or empty means the
  /// server runs API-only.
  final String webRoot;

  final AuthMode authMode;

  /// An operator-supplied token; null means "load or generate one".
  final String? authToken;

  /// Lower-cased domain roots `/img?src=` may reach; empty means any host.
  final List<String> imageHosts;

  bool get requiresAuth => authMode == AuthMode.token;

  static List<String> _splitHosts(String? raw) => <String>[
        if (raw != null)
          for (final String part in raw.split(','))
            if (part.trim().isNotEmpty) part.trim().toLowerCase(),
      ];

  static String _pick(
    ArgResults parsed,
    String name,
    String? fromEnv,
    String fallback,
  ) =>
      _pickOrNull(parsed, name, fromEnv) ?? fallback;

  static String? _pickOrNull(ArgResults parsed, String name, String? fromEnv) {
    final String? fromArgs = parsed.option(name);
    if (fromArgs != null && fromArgs.isNotEmpty) return fromArgs;
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    return null;
  }
}
