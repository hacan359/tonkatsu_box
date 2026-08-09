import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';

import 'protocol.dart';
import 'rpc_handler.dart';

/// Builds the request pipeline: `/health`, then the web client if one is built.
/// A missing or unbuilt [webRoot] is not fatal — the API answers regardless.
Handler buildAppHandler({
  required int schemaVersion,
  DaoRegistry? daos,
  String? webRoot,
  Middleware? logger,
}) {
  final Router api = Router()
    ..get('/health', (Request request) {
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
  if (daos != null) api.post('/rpc', buildRpcHandler(daos));

  final Handler? web = _webHandler(webRoot);
  final Handler handler = web == null
      ? api.call
      : Cascade().add(api.call).add(web).handler;

  return const Pipeline()
      .addMiddleware(logger ?? logRequests())
      .addHandler(handler);
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

  return (Request request) async {
    final Response response = await files(request);
    if (response.statusCode != HttpStatus.notFound) return response;
    return Response.ok(
      await index.readAsBytes(),
      headers: <String, String>{
        HttpHeaders.contentTypeHeader: 'text/html; charset=utf-8',
      },
    );
  };
}
