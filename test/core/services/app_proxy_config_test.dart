import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/core/services/app_proxy_config.dart';

void main() {
  const AppProxyConfig enabled = AppProxyConfig(
    enabled: true,
    host: '127.0.0.1',
    port: 7890,
  );
  final Uri remote = Uri.parse('https://api.example.com/v1');

  group('AppProxyConfig', () {
    group('findProxyForUri', () {
      test('should go direct when the proxy is disabled', () {
        expect(
          const AppProxyConfig.disabled().findProxyForUri(remote),
          'DIRECT',
        );
      });

      test('should route a remote host through the proxy with a fallback', () {
        expect(enabled.findProxyForUri(remote), 'PROXY 127.0.0.1:7890; DIRECT');
      });

      test('should only ever emit directives HttpClient can parse', () {
        for (final String directive
            in enabled.findProxyForUri(remote).split(';')) {
          final String d = directive.trim();
          expect(d == 'DIRECT' || d.startsWith('PROXY '), isTrue);
        }
      });

      for (final String local in <String>[
        'http://localhost:8080/rpc',
        'http://127.0.0.1:8080/',
        'http://[::1]:8080/',
        'http://192.168.1.50:8080/jsonrpc',
        'http://10.0.0.7/',
        'http://172.20.3.4/',
        'http://169.254.10.1/',
        'http://nas:8080/',
        'http://kodi.local/',
      ]) {
        test('should go direct for the local address $local', () {
          expect(enabled.findProxyForUri(Uri.parse(local)), 'DIRECT');
        });
      }

      for (final String host in <String>['', 'http://127.0.0.1', 'a b', ':1']) {
        test('should go direct when the stored host is "$host"', () {
          final AppProxyConfig config = AppProxyConfig(
            enabled: true,
            host: host,
            port: 7890,
          );

          expect(config.findProxyForUri(remote), 'DIRECT');
        });
      }

      for (final int port in <int>[0, -1, 65536]) {
        test('should go direct when the stored port is $port', () {
          final AppProxyConfig config = AppProxyConfig(
            enabled: true,
            host: '127.0.0.1',
            port: port,
          );

          expect(config.findProxyForUri(remote), 'DIRECT');
        });
      }
    });

    group('isLocalHost', () {
      for (final String host in <String>[
        '172.15.0.1',
        '172.32.0.1',
        '192.169.0.1',
        '8.8.8.8',
        'example.com',
        '2001:db8::1',
      ]) {
        test('should treat $host as remote', () {
          expect(AppProxyConfig.isLocalHost(host), isFalse);
        });
      }
    });

    group('isValidHost', () {
      test('should accept a host name and an IPv4 address', () {
        expect(AppProxyConfig.isValidHost('proxy.example.com'), isTrue);
        expect(AppProxyConfig.isValidHost('192.168.1.2'), isTrue);
      });

      test('should reject a scheme, a port, a space and an empty value', () {
        expect(AppProxyConfig.isValidHost('http://host'), isFalse);
        expect(AppProxyConfig.isValidHost('host:7890'), isFalse);
        expect(AppProxyConfig.isValidHost('ho st'), isFalse);
        expect(AppProxyConfig.isValidHost(''), isFalse);
      });
    });

    group('isValidPort', () {
      test('should accept the boundaries and reject what lies past them', () {
        expect(AppProxyConfig.isValidPort(1), isTrue);
        expect(AppProxyConfig.isValidPort(65535), isTrue);
        expect(AppProxyConfig.isValidPort(0), isFalse);
        expect(AppProxyConfig.isValidPort(65536), isFalse);
      });
    });
  });
}
