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

      test('should reject a non-numeric port', () {
        expect(
          () => ServerConfig.parse(const <String>['--port', 'abc']),
          throwsFormatException,
        );
      });
    });
  });
}
