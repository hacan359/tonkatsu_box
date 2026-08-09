import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/core/api/proxy_rewrite_interceptor.dart';

/// Runs the interceptor the way Dio would and reports the URI that would go
/// out, without opening a socket.
Future<Uri> rewritten(RequestOptions options) {
  final ProxyRewriteInterceptor interceptor =
      ProxyRewriteInterceptor(baseUrl: 'http://box.lan:8080');
  final Completer<Uri> done = Completer<Uri>();
  interceptor.onRequest(
    options,
    _CapturingHandler((RequestOptions o) => done.complete(o.uri)),
  );
  return done.future;
}

class _CapturingHandler extends RequestInterceptorHandler {
  _CapturingHandler(this.onNext);

  final void Function(RequestOptions) onNext;

  @override
  void next(RequestOptions options) => onNext(options);
}

void main() {
  group('ProxyRewriteInterceptor', () {
    test('should route an allowlisted host through the server', () async {
      final Uri uri = await rewritten(RequestOptions(
        baseUrl: 'https://api.themoviedb.org/3',
        path: '/search/movie',
      ));

      expect(uri.origin, 'http://box.lan:8080');
      expect(uri.path, '/proxy/tmdb/3/search/movie');
    });

    test('should keep the query, wherever Dio was carrying it', () async {
      final Uri fromParameters = await rewritten(RequestOptions(
        baseUrl: 'https://api.themoviedb.org/3',
        path: '/search/movie',
        queryParameters: <String, dynamic>{'query': 'alien', 'page': 2},
      ));
      final Uri fromPath = await rewritten(RequestOptions(
        path: 'https://api.themoviedb.org/3/search/movie?query=alien&page=2',
      ));

      const Map<String, String> expected = <String, String>{
        'query': 'alien',
        'page': '2',
      };
      expect(fromParameters.queryParameters, expected);
      expect(fromPath.queryParameters, expected);
    });

    test('should rewrite a client that builds the whole URL per request',
        () async {
      final Uri uri = await rewritten(RequestOptions(
        path: 'https://graphql.anilist.co',
      ));

      expect(uri.path, '/proxy/anilist');
      expect(uri.host, 'box.lan');
    });

    test('should leave a host outside the allowlist alone', () async {
      // A Kodi box on the user's LAN — ours to reach directly or not at all.
      final Uri uri = await rewritten(RequestOptions(
        path: 'http://192.168.1.50:8080/jsonrpc',
      ));

      expect(uri.toString(), 'http://192.168.1.50:8080/jsonrpc');
    });

    test('should leave the server\'s own routes alone', () async {
      final Uri uri = await rewritten(RequestOptions(
        baseUrl: 'http://box.lan:8080',
        path: '/rpc',
      ));

      expect(uri.path, '/rpc');
    });
  });
}
