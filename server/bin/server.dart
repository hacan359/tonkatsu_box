import 'dart:io';

import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tonkatsu_server/src/api_credentials.dart';
import 'package:tonkatsu_server/src/app_handler.dart';
import 'package:tonkatsu_server/src/auth_token.dart';
import 'package:tonkatsu_server/src/database_bootstrap.dart';
import 'package:tonkatsu_server/src/image_handler.dart';
import 'package:tonkatsu_server/src/proxy_handler.dart';
import 'package:tonkatsu_server/src/rpc_handler.dart';
import 'package:tonkatsu_server/src/server_config.dart';
import 'package:tonkatsu_server/src/upstream_client.dart';

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(ServerConfig.buildParser().usage);
    return;
  }

  final ServerConfig config =
      ServerConfig.parse(args, env: Platform.environment);

  sqfliteFfiInit();

  final DatabaseBootstrap bootstrap;
  try {
    bootstrap = await bootstrapDatabase(
      factory: databaseFactoryFfi,
      dataDir: config.dataDir,
      onInfo: stdout.writeln,
    );
  } on ServerBootstrapException catch (e) {
    stderr.writeln(e.message);
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'Database ${bootstrap.path} ready at v${bootstrap.schemaVersion}'
    '${bootstrap.wasCreated ? ' (created)' : ''}',
  );

  final ApiCredentials credentials;
  try {
    credentials = ApiCredentials.load(
      env: Platform.environment,
      dataDir: config.dataDir,
    );
  } on ApiCredentialsException catch (e) {
    stderr.writeln(e.message);
    exitCode = 1;
    return;
  }
  final List<String> configured = credentials.values.keys.toList();
  stdout.writeln(
    configured.isEmpty
        ? 'No API credentials configured — the proxy will answer 503 for them'
        : 'API credentials: ${configured.join(', ')}',
  );

  // Beyond loopback every data endpoint demands this token; loopback installs
  // stay tokenless so the existing one-line setup keeps working.
  final AuthToken token = AuthToken.load(
    dataDir: config.dataDir,
    generate: config.requiresAuth,
  );
  if (config.requiresAuth) {
    stdout.writeln('Auth token: ${token.raw}');
    stdout.writeln(
      'Paste it into the web client\'s Settings → Credentials → "Keys stored '
      'on the server" section; the browser remembers it from then on.',
    );
  }

  final HttpServer server = await shelf_io.serve(
    buildAppHandler(
      schemaVersion: bootstrap.schemaVersion,
      daos: DaoRegistry(bootstrap.db),
      proxy: ApiProxy(credentials: credentials, dataDir: config.dataDir),
      // A short deadline frees a browser's six connection slots fast, so a
      // sick CDN costs broken thumbnails instead of a frozen app.
      images: ImageCache(
        dataDir: config.dataDir,
        upstream: HttpUpstreamClient(deadline: const Duration(seconds: 8)),
      ),
      webRoot: config.webRoot,
      authToken: config.requiresAuth ? token : null,
    ),
    config.address,
    config.port,
  );
  server.autoCompress = true;

  stdout.writeln('Listening on http://${server.address.host}:${server.port}');
}
