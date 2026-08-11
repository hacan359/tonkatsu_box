import 'package:core/api/proxy_targets.dart';
import 'package:dio/dio.dart';

import '../selfhost/server_origin.dart';

/// Routes an allowlisted upstream through the selfhost server, which a browser
/// cannot reach itself: no CORS header, no `User-Agent`, no keys.
class ProxyRewriteInterceptor extends Interceptor {
  ProxyRewriteInterceptor({String? baseUrl}) : _baseUrl = baseUrl;

  final String? _baseUrl;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final Uri uri = options.uri;
    final ProxyTarget? target = proxyTargetForHost(uri.host);
    if (target == null) {
      handler.next(options);
      return;
    }

    // `uri` has queryParameters merged in already, so baking the whole thing
    // into an absolute path and clearing them avoids a doubled query.
    final Uri server = Uri.parse(_baseUrl ?? serverBaseUrl());
    options.path = server
        .replace(
          path: '$kProxyPathPrefix/${target.slug}${uri.path}',
          query: uri.query.isEmpty ? null : uri.query,
        )
        .toString();
    options.baseUrl = '';
    options.queryParameters = <String, dynamic>{};

    handler.next(options);
  }
}
