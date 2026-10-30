import 'dart:convert';
import 'dart:io';

import 'package:core/rpc/protocol.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:tonkatsu_server/src/app_handler.dart';
import 'package:tonkatsu_server/src/auth_token.dart';

void main() {
  late Directory dataDir;

  setUp(() {
    dataDir = Directory.systemTemp.createTempSync('tonkatsu_auth');
  });

  tearDown(() {
    if (dataDir.existsSync()) dataDir.deleteSync(recursive: true);
  });

  group('AuthToken', () {
    group('load', () {
      test('should generate and persist a token when nothing exists', () {
        final AuthToken token = AuthToken.load(dataDir: dataDir.path);

        expect(token.raw.length, greaterThanOrEqualTo(40));
        expect(
          File(
            p.join(dataDir.path, kAuthTokenFileName),
          ).readAsStringSync().trim(),
          token.raw,
        );
      });

      test('should reuse the stored token on the next boot', () {
        final AuthToken first = AuthToken.load(dataDir: dataDir.path);
        final AuthToken second = AuthToken.load(dataDir: dataDir.path);

        expect(second.raw, first.raw);
      });

      test('should prefer an explicit token over the stored one', () {
        AuthToken.load(dataDir: dataDir.path);

        final AuthToken token = AuthToken.load(
          dataDir: dataDir.path,
          explicit: ' from-env ',
        );

        expect(token.raw, 'from-env');
      });

      test('should treat a blank explicit token as absent', () {
        final AuthToken token = AuthToken.load(
          dataDir: dataDir.path,
          explicit: '   ',
        );

        expect(token.raw, isNot(isEmpty));
        expect(token.raw.trim(), token.raw);
      });

      test('should regenerate when the stored file is empty', () {
        File(p.join(dataDir.path, kAuthTokenFileName)).writeAsStringSync('\n');

        final AuthToken token = AuthToken.load(dataDir: dataDir.path);

        expect(token.raw, isNotEmpty);
      });
    });

    group('generate', () {
      test('should produce distinct values', () {
        expect(AuthToken.generate().raw, isNot(AuthToken.generate().raw));
      });
    });

    group('matches', () {
      const AuthToken token = AuthToken('secret-value');

      test('should accept only the exact value', () {
        expect(token.matches('secret-value'), isTrue);
        expect(token.matches('secret-valu'), isFalse);
        expect(token.matches('secret-valueX'), isFalse);
        expect(token.matches('Secret-value'), isFalse);
      });

      test('should reject null and empty', () {
        expect(token.matches(null), isFalse);
        expect(token.matches(''), isFalse);
      });
    });

    group('bearerOf', () {
      Request withHeader(String? value) => Request(
        'GET',
        Uri.parse('http://localhost/rpc'),
        headers: value == null
            ? const <String, String>{}
            : <String, String>{HttpHeaders.authorizationHeader: value},
      );

      test('should extract the token after the Bearer scheme', () {
        expect(AuthToken.bearerOf(withHeader('Bearer abc')), 'abc');
        expect(AuthToken.bearerOf(withHeader('bearer abc ')), 'abc');
      });

      test('should return null when the header is absent or malformed', () {
        expect(AuthToken.bearerOf(withHeader(null)), isNull);
        expect(AuthToken.bearerOf(withHeader('Basic abc')), isNull);
        expect(AuthToken.bearerOf(withHeader('Bearer')), isNull);
        expect(AuthToken.bearerOf(withHeader('Bearer   ')), isNull);
      });
    });
  });

  group('buildAppHandler token gate', () {
    const AuthToken token = AuthToken('the-token');

    Middleware silent() =>
        (Handler inner) => inner;

    Handler build({AuthToken? auth = token}) =>
        buildAppHandler(schemaVersion: 42, logger: silent(), authToken: auth);

    Future<Response> send(
      Handler handler,
      String method,
      String path, {
      String? bearer,
    }) async => handler(
      Request(
        method,
        Uri.parse('http://localhost$path'),
        headers: bearer == null
            ? const <String, String>{}
            : <String, String>{
                HttpHeaders.authorizationHeader: 'Bearer $bearer',
              },
      ),
    );

    test('should report auth on /health and keep it public', () async {
      final Response response = await send(build(), 'GET', '/health');

      expect(response.statusCode, HttpStatus.ok);
      final Map<String, Object?> body =
          jsonDecode(await response.readAsString()) as Map<String, Object?>;
      expect(body['auth'], isTrue);
    });

    test('should report auth off when no token is configured', () async {
      final Response response = await send(build(auth: null), 'GET', '/health');

      final Map<String, Object?> body =
          jsonDecode(await response.readAsString()) as Map<String, Object?>;
      expect(body['auth'], isFalse);
    });

    test(
      'should answer 401 with the auth kind on /rpc without a token',
      () async {
        final Response response = await send(build(), 'POST', '/rpc');

        expect(response.statusCode, HttpStatus.unauthorized);
        final Map<String, Object?> body =
            jsonDecode(await response.readAsString()) as Map<String, Object?>;
        expect(body['ok'], isFalse);
        expect(
          (body['error'] as Map<String, Object?>)['kind'],
          kRpcErrorKindAuth,
        );
      },
    );

    test('should answer 401 on /rpc with a wrong token', () async {
      final Response response = await send(
        build(),
        'POST',
        '/rpc',
        bearer: 'nope',
      );

      expect(response.statusCode, HttpStatus.unauthorized);
    });

    test('should pass /rpc through with the right token', () async {
      // No DAOs are wired, so passing the gate means a 404 from the router.
      final Response response = await send(
        build(),
        'POST',
        '/rpc',
        bearer: token.raw,
      );

      expect(response.statusCode, isNot(HttpStatus.unauthorized));
    });

    test('should gate /proxy paths', () async {
      expect(
        (await send(build(), 'GET', '/proxy/keys')).statusCode,
        HttpStatus.unauthorized,
      );
      expect(
        (await send(
          build(),
          'GET',
          '/proxy/tmdb/search',
          bearer: token.raw,
        )).statusCode,
        isNot(HttpStatus.unauthorized),
      );
    });

    test('should keep GET /img public but gate its writes', () async {
      expect(
        (await send(build(), 'GET', '/img/anime_covers/x')).statusCode,
        isNot(HttpStatus.unauthorized),
      );
      expect(
        (await send(build(), 'POST', '/img/custom_covers/x')).statusCode,
        HttpStatus.unauthorized,
      );
      expect(
        (await send(build(), 'DELETE', '/img/custom_covers/x')).statusCode,
        HttpStatus.unauthorized,
      );
      expect(
        (await send(
          build(),
          'POST',
          '/img/custom_covers/x',
          bearer: token.raw,
        )).statusCode,
        isNot(HttpStatus.unauthorized),
      );
    });

    test('should keep static paths public', () async {
      final Response response = await send(build(), 'GET', '/assets/app.js');

      expect(response.statusCode, isNot(HttpStatus.unauthorized));
    });

    test('should not gate anything when no token is configured', () async {
      final Response response = await send(build(auth: null), 'POST', '/rpc');

      expect(response.statusCode, isNot(HttpStatus.unauthorized));
    });
  });
}
