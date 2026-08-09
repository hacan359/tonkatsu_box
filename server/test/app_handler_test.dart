import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:tonkatsu_server/src/app_handler.dart';
import 'package:tonkatsu_server/src/protocol.dart';

void main() {
  late Directory webRoot;

  /// The default logger writes to stdout on every request, which would bury
  /// the test output.
  Middleware silent() => (Handler inner) => inner;

  setUp(() {
    webRoot = Directory.systemTemp.createTempSync('tonkatsu_web_root');
  });

  tearDown(() {
    if (webRoot.existsSync()) webRoot.deleteSync(recursive: true);
  });

  Future<Response> get(Handler handler, String path) async {
    return handler(Request('GET', Uri.parse('http://localhost$path')));
  }

  group('buildAppHandler', () {
    test('should report the schema and protocol version on /health', () async {
      final Handler handler =
          buildAppHandler(schemaVersion: 42, logger: silent());

      final Response response = await get(handler, '/health');

      expect(response.statusCode, HttpStatus.ok);
      final Map<String, Object?> body =
          jsonDecode(await response.readAsString()) as Map<String, Object?>;
      expect(body['status'], 'ok');
      expect(body['schemaVersion'], 42);
      expect(body['protocolVersion'], kProtocolVersion);
    });

    test('should 404 an unknown path when no web client is built', () async {
      final Handler handler =
          buildAppHandler(schemaVersion: 1, logger: silent());

      final Response response = await get(handler, '/collections');

      expect(response.statusCode, HttpStatus.notFound);
    });

    test('should ignore a web root that has no index.html', () async {
      final Handler handler = buildAppHandler(
        schemaVersion: 1,
        webRoot: webRoot.path,
        logger: silent(),
      );

      final Response response = await get(handler, '/');

      expect(response.statusCode, HttpStatus.notFound);
    });

    test('should serve a static asset from the web root', () async {
      File(p.join(webRoot.path, 'index.html')).writeAsStringSync('<html>');
      File(p.join(webRoot.path, 'main.dart.js')).writeAsStringSync('console;');
      final Handler handler = buildAppHandler(
        schemaVersion: 1,
        webRoot: webRoot.path,
        logger: silent(),
      );

      final Response response = await get(handler, '/main.dart.js');

      expect(response.statusCode, HttpStatus.ok);
      expect(await response.readAsString(), 'console;');
    });

    test('should fall back to index.html on a client-side route', () async {
      File(p.join(webRoot.path, 'index.html')).writeAsStringSync('<html>');
      final Handler handler = buildAppHandler(
        schemaVersion: 1,
        webRoot: webRoot.path,
        logger: silent(),
      );

      final Response response = await get(handler, '/collections/7');

      expect(response.statusCode, HttpStatus.ok);
      expect(await response.readAsString(), '<html>');
    });

    test('should keep /health working when a web client is present', () async {
      File(p.join(webRoot.path, 'index.html')).writeAsStringSync('<html>');
      final Handler handler = buildAppHandler(
        schemaVersion: 5,
        webRoot: webRoot.path,
        logger: silent(),
      );

      final Response response = await get(handler, '/health');

      final Map<String, Object?> body =
          jsonDecode(await response.readAsString()) as Map<String, Object?>;
      expect(body['schemaVersion'], 5);
    });
  });
}
