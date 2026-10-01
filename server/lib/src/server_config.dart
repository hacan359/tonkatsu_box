import 'package:args/args.dart';

/// Where the server listens and which directories it works with.
class ServerConfig {
  const ServerConfig({
    required this.address,
    required this.port,
    required this.dataDir,
    required this.webRoot,
  });

  /// Command line wins over [env] so a container can be overridden without
  /// rebuilding its image.
  factory ServerConfig.parse(
    List<String> args, {
    Map<String, String> env = const <String, String>{},
  }) {
    final ArgResults parsed = buildParser().parse(args);

    return ServerConfig(
      // Loopback by default: a selfhost server on 0.0.0.0 is one firewall mis-
      // step from handing the whole database to the LAN. Anyone who genuinely
      // needs LAN/Internet access passes --address 0.0.0.0 explicitly, which
      // then also flips on the bearer-token gate.
      address: _pick(parsed, 'address', env['TONKATSU_ADDRESS'], '127.0.0.1'),
      port: int.parse(_pick(parsed, 'port', env['TONKATSU_PORT'], '8080')),
      dataDir: _pick(parsed, 'data-dir', env['TONKATSU_DATA_DIR'], 'data'),
      webRoot: _pick(parsed, 'web-root', env['TONKATSU_WEB_ROOT'], 'web'),
    );
  }

  /// Loopback addresses never need the token; anything else does.
  bool get requiresAuth => _isLoopback(address) == false;

  static bool _isLoopback(String address) =>
      address == '127.0.0.1' || address == 'localhost' || address == '::1';

  /// The parser is public so `--help` can be rendered without a config.
  static ArgParser buildParser() {
    return ArgParser()
      ..addOption('address', help: 'Interface to bind (TONKATSU_ADDRESS)')
      ..addOption('port', help: 'TCP port to listen on (TONKATSU_PORT)')
      ..addOption('data-dir',
          help: 'Directory holding the database (TONKATSU_DATA_DIR)')
      ..addOption('web-root',
          help: 'Directory with the built web client (TONKATSU_WEB_ROOT)')
      ..addFlag('help', negatable: false, help: 'Print usage and exit');
  }

  final String address;
  final int port;
  final String dataDir;

  /// Directory with `flutter build web` output; absent or empty means the
  /// server runs API-only.
  final String webRoot;

  static String _pick(
    ArgResults parsed,
    String name,
    String? fromEnv,
    String fallback,
  ) {
    final String? fromArgs = parsed.option(name);
    if (fromArgs != null && fromArgs.isNotEmpty) return fromArgs;
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    return fallback;
  }
}
