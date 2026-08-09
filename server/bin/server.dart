import 'dart:io';

import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tonkatsu_server/src/api_credentials.dart';
import 'package:tonkatsu_server/src/app_handler.dart';
import 'package:tonkatsu_server/src/database_bootstrap.dart';
import 'package:tonkatsu_server/src/image_handler.dart';
import 'package:tonkatsu_server/src/proxy_handler.dart';
import 'package:tonkatsu_server/src/rpc_handler.dart';
import 'package:tonkatsu_server/src/server_config.dart';

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
  final List<String> configured = credentials.availability.entries
      .where((MapEntry<String, bool> e) => e.value)
      .map((MapEntry<String, bool> e) => e.key)
      .toList();
  stdout.writeln(
    configured.isEmpty
        ? 'No API credentials configured — the proxy will answer 503 for them'
        : 'API credentials: ${configured.join(', ')}',
  );

  final HttpServer server = await shelf_io.serve(
    buildAppHandler(
      schemaVersion: bootstrap.schemaVersion,
      daos: DaoRegistry(bootstrap.db),
      proxy: ApiProxy(credentials: credentials),
      images: ImageCache(dataDir: config.dataDir),
      webRoot: config.webRoot,
    ),
    config.address,
    config.port,
  );
  server.autoCompress = true;

  stdout.writeln('Listening on http://${server.address.host}:${server.port}');
}
