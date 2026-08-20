import 'dart:convert';
import 'dart:io';

import 'package:core/api/image_proxy.dart';
import 'package:core/api/proxy_targets.dart';
import 'package:core/rpc/protocol.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';

import 'image_handler.dart';
import 'proxy_handler.dart';
import 'request_log.dart';
import 'rpc_handler.dart';

const String _kHealthPath = '/health';
const String _kRpcPath = '/rpc';

/// Builds the request pipeline: `/health`, then the web client if one is built.
/// A missing or unbuilt [webRoot] is not fatal — the API answers regardless.
Handler buildAppHandler({
  required int schemaVersion,
  DaoRegistry? daos,
  ApiProxy? proxy,
  ImageCache? images,
  String? webRoot,
  Middleware? logger,
}) {
  final Router api = Router()
    ..get(_kHealthPath, (Request request) {
      return Response.ok(
        jsonEncode(<String, Object>{
          'status': 'ok',
          'schemaVersion': schemaVersion,
          'protocolVersion': kProtocolVersion,
        }),
        headers: <String, String>{
          HttpHeaders.contentTypeHeader: 'application/json',
        },
      );
    });
  if (daos != null) api.post(_kRpcPath, buildRpcHandler(daos));
  if (proxy != null) {
    api.get('$kProxyPathPrefix/keys', (Request request) {
      return Response.ok(
        jsonEncode(proxy.credentials.values),
        headers: <String, String>{
          HttpHeaders.contentTypeHeader: 'application/json',
        },
      );
    });
    // The browser has no keys file to edit, so it sets them here instead.
    api.post('$kProxyPathPrefix/keys', (Request request) async {
      final Object? body = jsonDecode(await request.readAsString());
      if (body is! Map<String, Object?>) {
        return Response(HttpStatus.badRequest,
            body: jsonEncode(<String, Object?>{'ok': false}));
      }
      final Map<String, String> stored =
          proxy.applyCredentials(<String, String>{
        for (final MapEntry<String, Object?> e in body.entries)
          if (e.value is String) e.key: e.value! as String,
      });
      return Response.ok(
        jsonEncode(stored),
        headers: <String, String>{
          HttpHeaders.contentTypeHeader: 'application/json',
        },
      );
    });
    // Both shapes: AniList and friends are posted to the bare host, so the
    // rewritten path can end at the slug.
    api.all('$kProxyPathPrefix/<slug>', proxy.handler);
    api.all('$kProxyPathPrefix/<slug>/<rest|.*>', proxy.handler);
  }
  if (images != null) {
    api.get('$kImagePathPrefix/<folder>/<id|.*>', images.handler);
    api.post('$kImagePathPrefix/<folder>/<id|.*>', images.uploadHandler);
    api.delete('$kImagePathPrefix/<folder>/<id|.*>', images.deleteHandler);
  }

  final Handler? web = _webHandler(webRoot);
  final Handler handler = web == null ? api.call : _withWebFallback(api, web);

  return const Pipeline()
      .addMiddleware(logger ?? sanitizedLogRequests())
      .addHandler(handler);
}

/// A plain `Cascade` would answer "unknown upstream" with index.html and a 200,
/// which reads as success to the caller and buries the mistake.
Handler _withWebFallback(Router api, Handler web) {
  return (Request request) async {
    final String path = '/${request.url.path}';
    final bool isApi = path == _kHealthPath ||
        path == _kRpcPath ||
        path.startsWith('$kProxyPathPrefix/') ||
        path.startsWith('$kImagePathPrefix/');
    if (isApi) return api.call(request);

    final Response response = await api.call(request);
    if (response.statusCode != HttpStatus.notFound) return response;
    return web(request);
  };
}

/// Static files with an index.html fallback, so client-side routes survive a
/// browser reload instead of 404-ing on a path the server knows nothing about.
Handler? _webHandler(String? webRoot) {
  if (webRoot == null || webRoot.isEmpty) return null;
  final Directory dir = Directory(webRoot);
  if (!dir.existsSync()) return null;

  final File index = File(p.join(dir.path, 'index.html'));
  if (!index.existsSync()) return null;

  final Handler files = createStaticHandler(
    dir.path,
    defaultDocument: 'index.html',
  );

  // Revalidate every time. Without it the browser heuristically caches
  // main.dart.js and keeps serving the old app after an update.
  const String cacheControl = 'no-cache';

  return (Request request) async {
    final Response response = await files(request);
    if (response.statusCode != HttpStatus.notFound) {
      // Only the app shell revalidates; fonts, wasm and assets would cost a
      // conditional round trip each on every page load for nothing.
      if (!_isAppShell(request.url.path)) return response;
      return response.change(headers: <String, String>{
        HttpHeaders.cacheControlHeader: cacheControl,
      });
    }
    return Response.ok(
      await index.readAsBytes(),
      headers: <String, String>{
        HttpHeaders.contentTypeHeader: 'text/html; charset=utf-8',
        HttpHeaders.cacheControlHeader: cacheControl,
      },
    );
  };
}

/// The files that decide which app version the browser runs.
bool _isAppShell(String path) {
  if (path.isEmpty || path.endsWith('/')) return true;
  return path.endsWith('.html') || path.endsWith('.js') || path.endsWith('.json');
}
