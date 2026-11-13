import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/core/services/app_http_overrides.dart';
import 'package:tonkatsu_box/core/services/app_proxy_config.dart';

void main() {
  group('AppHttpOverrides', () {
    test('createHttpClient sets the descriptive User-Agent', () {
      final HttpClient client =
          AppHttpOverrides().createHttpClient(null);
      addTearDown(() => client.close(force: true));

      expect(client.userAgent, AppHttpOverrides.userAgent);
    });

    test('should send a remote request to the configured proxy', () async {
      final HttpServer proxy = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      final List<Uri> seen = <Uri>[];
      proxy.listen((HttpRequest request) {
        seen.add(request.requestedUri);
        request.response.close();
      });
      AppProxyConfig.current = AppProxyConfig(
        enabled: true,
        host: InternetAddress.loopbackIPv4.address,
        port: proxy.port,
      );
      final HttpClient client = AppHttpOverrides().createHttpClient(null);
      addTearDown(() async {
        AppProxyConfig.current = const AppProxyConfig.disabled();
        client.close(force: true);
        await proxy.close(force: true);
      });

      final HttpClientRequest request = await client.getUrl(
        Uri.parse('http://remote.example.invalid/ping'),
      );
      await (await request.close()).drain<void>();

      expect(seen.single.host, 'remote.example.invalid');
    });

    test('userAgent identifies the app and a contact URL', () {
      expect(AppHttpOverrides.userAgent, contains('TonkatsuBox'));
      expect(AppHttpOverrides.userAgent, contains('github.com'));
      expect(AppHttpOverrides.userAgent, isNot(contains('Dart/')));
    });
  });
}
