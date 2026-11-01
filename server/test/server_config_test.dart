import 'package:test/test.dart';
import 'package:tonkatsu_server/src/server_config.dart';

void main() {
  group('ServerConfig', () {
    group('parse', () {
      test('should fall back to defaults when nothing is provided', () {
        final ServerConfig config = ServerConfig.parse(const <String>[]);

        expect(config.address, '0.0.0.0');
        expect(config.port, 8080);
        expect(config.dataDir, 'data');
        expect(config.webRoot, 'web');
        expect(config.authMode, AuthMode.off);
        expect(config.requiresAuth, isFalse);
        expect(config.authToken, isNull);
      });

      test('should require a token when --auth token is passed', () {
        final ServerConfig config = ServerConfig.parse(
          const <String>['--auth', 'token', '--auth-token', 'abc'],
        );

        expect(config.authMode, AuthMode.token);
        expect(config.requiresAuth, isTrue);
        expect(config.authToken, 'abc');
      });

      test('should read the auth mode and token from the environment', () {
        final ServerConfig config = ServerConfig.parse(
          const <String>[],
          env: const <String, String>{
            'TONKATSU_AUTH': 'token',
            'TONKATSU_AUTH_TOKEN': 'from-env',
          },
        );

        expect(config.requiresAuth, isTrue);
        expect(config.authToken, 'from-env');
      });

      test('should treat an empty TONKATSU_AUTH_TOKEN as absent', () {
        final ServerConfig config = ServerConfig.parse(
          const <String>[],
          env: const <String, String>{'TONKATSU_AUTH_TOKEN': ''},
        );

        expect(config.authToken, isNull);
      });

      test('should reject an unknown auth mode', () {
        expect(
          () => ServerConfig.parse(const <String>['--auth', 'maybe']),
          throwsFormatException,
        );
        expect(
          () => ServerConfig.parse(
            const <String>[],
            env: const <String, String>{'TONKATSU_AUTH': 'maybe'},
          ),
          throwsFormatException,
        );
      });

      test('should read the environment when no arguments are given', () {
        final ServerConfig config = ServerConfig.parse(
          const <String>[],
          env: const <String, String>{
            'TONKATSU_ADDRESS': '127.0.0.1',
            'TONKATSU_PORT': '9090',
            'TONKATSU_DATA_DIR': '/data',
            'TONKATSU_WEB_ROOT': '/srv/web',
          },
        );

        expect(config.address, '127.0.0.1');
        expect(config.port, 9090);
        expect(config.dataDir, '/data');
        expect(config.webRoot, '/srv/web');
      });

      test('should let arguments win over the environment', () {
        final ServerConfig config = ServerConfig.parse(
          const <String>['--port', '7000', '--data-dir', '/from-args'],
          env: const <String, String>{
            'TONKATSU_PORT': '9090',
            'TONKATSU_DATA_DIR': '/from-env',
          },
        );

        expect(config.port, 7000);
        expect(config.dataDir, '/from-args');
      });

      test('should ignore an empty environment value', () {
        final ServerConfig config = ServerConfig.parse(
          const <String>[],
          env: const <String, String>{'TONKATSU_DATA_DIR': ''},
        );

        expect(config.dataDir, 'data');
      });

      test('should split image hosts on commas and normalise them', () {
        final ServerConfig config = ServerConfig.parse(
          const <String>['--image-hosts', ' Image.TMDB.org, bgm.tv ,,'],
        );

        expect(config.imageHosts, <String>['image.tmdb.org', 'bgm.tv']);
      });

      test('should default image hosts to none and read the environment',
          () {
        expect(ServerConfig.parse(const <String>[]).imageHosts, isEmpty);

        final ServerConfig config = ServerConfig.parse(
          const <String>[],
          env: const <String, String>{'TONKATSU_IMAGE_HOSTS': 'a.test'},
        );

        expect(config.imageHosts, <String>['a.test']);
      });

      test('should reject a non-numeric port', () {
        expect(
          () => ServerConfig.parse(const <String>['--port', 'abc']),
          throwsFormatException,
        );
      });
    });
  });
}
