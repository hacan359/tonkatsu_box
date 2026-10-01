import 'dart:io';

import 'package:test/test.dart';
import 'package:tonkatsu_server/src/app_handler.dart';
import 'package:tonkatsu_server/src/auth_token.dart';
import 'package:tonkatsu_server/src/upstream_client.dart';

/// A no-op logger so the request line does not pollute test output.
Middleware silent() =>
    (Handler inner) => inner;

void main() {
  group('AuthToken', () {
    test('matches only the exact bearer value', () {
      final AuthToken token = AuthToken.load(generate: true);

      expect(token.raw, isNotEmpty);
      expect(token.matches(token.raw), isTrue);
      expect(token.matches(''), isFalse);
      expect(token.matches('wrong'), isFalse);
      expect(token.matches(null), isFalse);
      // A prefix must not match — the token is not a suffix match.
      expect(token.matches('${token.raw}x'), isFalse);
    });

    test('persists to the data dir and reloads', () {
      final Directory dir = Directory.systemTemp.createTempSync('auth_token');
      addTearDown(() => dir.deleteSync(recursive: true));

      final AuthToken first = AuthToken.load(dataDir: dir.path, generate: true);
      final AuthToken second = AuthToken.load(dataDir: dir.path);

      expect(second.raw, first.raw);
      expect(
        File('${dir.path}/auth_token').readAsStringSync().trim(),
        first.raw,
      );
    });

    test('empty when no file and not asked to generate', () {
      final Directory dir = Directory.systemTemp.createTempSync('auth_token');
      addTearDown(() => dir.deleteSync(recursive: true));

      final AuthToken token = AuthToken.load(dataDir: dir.path);
      expect(token.raw, isEmpty);
    });

    test('generates a long unpredictable value', () {
      final AuthToken a = AuthToken.load(generate: true);
      final AuthToken b = AuthToken.load(generate: true);
      expect(a.raw.length, greaterThanOrEqualTo(40));
      expect(a.raw, isNot(b.raw));
    });
  });

  group('buildAppHandler with auth', () {
    late AuthToken token;

    setUp(() {
      token = AuthToken.load(generate: true);
    });

    Handler build() =>
        buildAppHandler(schemaVersion: 42, logger: silent(), authToken: token);

    Future<Response> get(Handler handler, String path, {String? bearer}) async {
      final Request request = Request(
        'GET',
        Uri.parse('http://localhost$path'),
        headers: bearer == null
            ? <String, String>{}
            : <String, String>{
                HttpHeaders.authorizationHeader: 'Bearer $bearer',
              },
      );
      return handler(request);
    }

    test('/health stays public', () async {
      final Response response = await get(build(), '/health');
      expect(response.statusCode, HttpStatus.ok);
    });

    test('/rpc without a token answers 401', () async {
      final Response response = await get(build(), '/rpc');
      expect(response.statusCode, HttpStatus.unauthorized);
    });

    test('/rpc with the right token passes through', () async {
      final Response response = await get(build(), '/rpc', bearer: token.raw);
      // No daos wired → the route does not exist past auth; 401 preview what
      // the gate would do without the token, 404 means auth passed.
      expect(response.statusCode, isNot(HttpStatus.unauthorized));
    });

    test('/proxy/keys without a token answers 401', () async {
      final Response response = await get(build(), '/proxy/keys');
      expect(response.statusCode, HttpStatus.unauthorized);
    });

    test('/proxy/keys with the token passes the gate', () async {
      final Response response = await get(
        build(),
        '/proxy/keys',
        bearer: token.raw,
      );
      expect(response.statusCode, isNot(HttpStatus.unauthorized));
    });

    test('a wrong token still answers 401', () async {
      final Response response = await get(
        build(),
        '/proxy/keys',
        bearer: 'wrong-token',
      );
      expect(response.statusCode, HttpStatus.unauthorized);
    });

    test('/img stays public (covers via Image.network)', () async {
      final Response response = await get(build(), '/img/portal/abc');
      expect(response.statusCode, isNot(HttpStatus.unauthorized));
    });

    test('static assets stay public', () async {
      final Response response = await get(build(), '/assets/some.js');
      expect(response.statusCode, isNot(HttpStatus.unauthorized));
    });
  });
}
