import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tonkatsu_box/core/selfhost/server_auth_token.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SharedPreferences> prefsWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  group('ServerAuthToken', () {
    setUp(() async {
      await ServerAuthToken.init(await prefsWith(<String, Object>{}));
    });

    group('init', () {
      test('should expose a stored token', () async {
        await ServerAuthToken.init(
          await prefsWith(<String, Object>{'server_auth_token': 'abc'}),
        );

        expect(ServerAuthToken.current, 'abc');
      });

      test('should read a blank stored value as no token', () async {
        await ServerAuthToken.init(
          await prefsWith(<String, Object>{'server_auth_token': '  '}),
        );

        expect(ServerAuthToken.current, isNull);
      });
    });

    group('write', () {
      test('should persist and expose the token', () async {
        await ServerAuthToken.write('xyz');

        expect(ServerAuthToken.current, 'xyz');
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('server_auth_token'), 'xyz');
      });

      test('should clear the token when given an empty value', () async {
        await ServerAuthToken.write('xyz');
        await ServerAuthToken.write('');

        expect(ServerAuthToken.current, isNull);
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('server_auth_token'), isNull);
      });
    });

    group('consumeFromUrl', () {
      test('should store the token from the sign-in link', () async {
        final bool consumed = await ServerAuthToken.consumeFromUrl(
          Uri.parse('http://box.local:8080/?token=from-link'),
        );

        expect(consumed, isTrue);
        expect(ServerAuthToken.current, 'from-link');
      });

      test(
        'should leave the stored token alone without the parameter',
        () async {
          await ServerAuthToken.write('kept');

          final bool consumed = await ServerAuthToken.consumeFromUrl(
            Uri.parse('http://box.local:8080/?other=1'),
          );

          expect(consumed, isFalse);
          expect(ServerAuthToken.current, 'kept');
        },
      );

      test('should ignore an empty token parameter', () async {
        final bool consumed = await ServerAuthToken.consumeFromUrl(
          Uri.parse('http://box.local:8080/?token='),
        );

        expect(consumed, isFalse);
        expect(ServerAuthToken.current, isNull);
      });
    });
  });

  group('ServerAuthInterceptor', () {
    const String origin = 'http://box.local:8080';

    Future<RequestOptions> run(String url) async {
      final ServerAuthInterceptor interceptor = ServerAuthInterceptor(
        serverOrigin: origin,
      );
      final RequestOptions options = RequestOptions(path: url);
      final RequestInterceptorHandler handler = RequestInterceptorHandler();
      interceptor.onRequest(options, handler);
      return options;
    }

    setUp(() async {
      await ServerAuthToken.init(await prefsWith(<String, Object>{}));
    });

    test('should add the bearer header to a request to the server', () async {
      await ServerAuthToken.write('tok');

      final RequestOptions options = await run('$origin/rpc');

      expect(options.headers['authorization'], 'Bearer tok');
    });

    test('should leave a request to another host untouched', () async {
      await ServerAuthToken.write('tok');

      final RequestOptions options = await run('https://api.example/search');

      expect(options.headers.containsKey('authorization'), isFalse);
    });

    test('should send nothing when no token is stored', () async {
      final RequestOptions options = await run('$origin/rpc');

      expect(options.headers.containsKey('authorization'), isFalse);
    });
  });
}
