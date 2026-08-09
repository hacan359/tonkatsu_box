import 'dart:io';

import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tonkatsu_server/src/app_handler.dart';
import 'package:tonkatsu_server/src/database_bootstrap.dart';
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

  final HttpServer server = await shelf_io.serve(
    buildAppHandler(
      schemaVersion: bootstrap.schemaVersion,
      webRoot: config.webRoot,
    ),
    config.address,
    config.port,
  );
  server.autoCompress = true;

  stdout.writeln('Listening on http://${server.address.host}:${server.port}');
}
