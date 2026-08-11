import 'dart:convert';
import 'dart:io';

import 'package:core/database/migrations/migration_registry.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';
import 'package:tonkatsu_server/src/app_handler.dart';
import 'package:tonkatsu_server/src/database_bootstrap.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test('should answer /health over a real socket against a fresh database',
      () async {
    final Directory dataDir =
        Directory.systemTemp.createTempSync('tonkatsu_serve_test');
    addTearDown(() => dataDir.deleteSync(recursive: true));

    final DatabaseBootstrap bootstrap = await bootstrapDatabase(
      factory: databaseFactoryFfi,
      dataDir: dataDir.path,
    );
    addTearDown(bootstrap.db.close);

    final HttpServer server = await shelf_io.serve(
      buildAppHandler(
        schemaVersion: bootstrap.schemaVersion,
        logger: (Handler inner) => inner,
      ),
      InternetAddress.loopbackIPv4,
      0,
    );
    addTearDown(() => server.close(force: true));

    final HttpClient client = HttpClient();
    addTearDown(client.close);
    final HttpClientRequest request = await client.getUrl(
      Uri.parse('http://${server.address.address}:${server.port}/health'),
    );
    final HttpClientResponse response = await request.close();
    final Map<String, Object?> body = jsonDecode(
      await response.transform(utf8.decoder).join(),
    ) as Map<String, Object?>;

    expect(response.statusCode, HttpStatus.ok);
    expect(body['status'], 'ok');
    expect(body['schemaVersion'], MigrationRegistry.latestVersion);
  });
}
