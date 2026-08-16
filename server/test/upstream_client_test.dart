import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:tonkatsu_server/src/upstream_client.dart';

void main() {
  group('HttpUpstreamClient', () {
    late HttpServer server;
    late List<HttpRequest> received;
    late List<String> bodies;

    setUp(() async {
      received = <HttpRequest>[];
      bodies = <String>[];
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((HttpRequest request) async {
        received.add(request);
        bodies.add(await utf8.decoder.bind(request).join());
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write('{"ok":true}');
        await request.response.close();
      });
    });

    tearDown(() async => server.close(force: true));

    Uri url(String path) =>
        Uri.parse('http://${server.address.host}:${server.port}$path');

    test('sends a POST body with an explicit length, not chunked', () async {
      final HttpUpstreamClient client = HttpUpstreamClient();
      final List<int> body = utf8.encode('{"mbids":["a"]}');

      final UpstreamResponse response = await client.send(
        method: 'POST',
        url: url('/popularity'),
        headers: <String, String>{HttpHeaders.contentTypeHeader: 'application/json'},
        body: body,
      );

      expect(response.status, 200);
      expect(received.single.headers.contentLength, body.length);
      expect(
        received.single.headers.value(HttpHeaders.transferEncodingHeader),
        isNot('chunked'),
      );
      expect(bodies.single, '{"mbids":["a"]}');
    });

    test('a bodyless GET sends no payload', () async {
      final HttpUpstreamClient client = HttpUpstreamClient();

      final UpstreamResponse response = await client.send(
        method: 'GET',
        url: url('/search'),
        headers: <String, String>{},
      );

      expect(response.status, 200);
      expect(bodies.single, isEmpty);
    });
  });
}
