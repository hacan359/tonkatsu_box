import 'dart:convert';
import 'dart:io';

import 'package:core/api/image_proxy.dart';
import 'package:core/models/image_type.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';

import 'upstream_client.dart';

/// A cover is immutable for a given id, so the browser can hold it as long as
/// it likes and the server stops being asked at all.
const String _kImmutable = 'public, max-age=31536000, immutable';

/// `/img/<folder>/<id>` — one cache in the volume for every client, instead of
/// each browser re-downloading the same poster from the provider.
class ImageCache {
  ImageCache({
    required this.dataDir,
    UpstreamClient? upstream,
  }) : _upstream = upstream ?? HttpUpstreamClient();

  final String dataDir;
  final UpstreamClient _upstream;

  Handler get handler => (Request request) async {
        final List<String> segments = request.url.pathSegments;
        if (segments.length < 3) {
          return _error(HttpStatus.notFound, 'No image in the path');
        }

        final ImageType? type = imageTypeForFolder(segments[1]);
        if (type == null) {
          return _error(HttpStatus.notFound, 'Unknown image type');
        }

        final String imageId = segments.skip(2).join('/');
        // A traversal would land the write outside the cache directory.
        if (imageId.isEmpty || imageId.contains('..')) {
          return _error(HttpStatus.badRequest, 'Bad image id');
        }

        final File file = File(p.join(dataDir, 'images', type.folder, imageId));
        if (file.existsSync() && file.lengthSync() > 0) {
          return _image(await file.readAsBytes(), _contentTypeOf(imageId));
        }

        final String? source =
            request.requestedUri.queryParameters[kImageSourceParam];
        if (source == null || source.isEmpty) {
          return _error(HttpStatus.notFound, 'Not cached and no source given');
        }

        final Uri? sourceUri = Uri.tryParse(source);
        if (sourceUri == null || !sourceUri.isScheme('https')) {
          return _error(HttpStatus.badRequest, 'Source must be an https URL');
        }

        final UpstreamResponse response;
        try {
          response = await _upstream.send(
            method: 'GET',
            url: sourceUri,
            headers: <String, String>{},
          );
        } on Object catch (e) {
          return _error(HttpStatus.badGateway, '$e');
        }

        if (response.status != HttpStatus.ok || response.body.isEmpty) {
          return _error(
            HttpStatus.badGateway,
            'Source answered ${response.status}',
          );
        }

        // Write through a temporary name: a half-written file would be served
        // as a valid cache hit forever after.
        final File temp = File('${file.path}.part');
        await temp.parent.create(recursive: true);
        await temp.writeAsBytes(response.body, flush: true);
        await temp.rename(file.path);

        return _image(
          response.body,
          response.contentType ?? _contentTypeOf(imageId),
        );
      };
}

String _contentTypeOf(String name) {
  switch (p.extension(name).toLowerCase()) {
    case '.png':
      return 'image/png';
    case '.webp':
      return 'image/webp';
    case '.gif':
      return 'image/gif';
    default:
      return 'image/jpeg';
  }
}

Response _image(List<int> bytes, String contentType) => Response.ok(
      bytes,
      headers: <String, String>{
        HttpHeaders.contentTypeHeader: contentType,
        HttpHeaders.cacheControlHeader: _kImmutable,
      },
    );

Response _error(int status, String message) => Response(
      status,
      body: jsonEncode(<String, Object?>{
        'ok': false,
        'error': <String, String>{'kind': 'image', 'message': message},
      }),
      headers: <String, String>{
        HttpHeaders.contentTypeHeader: 'application/json',
      },
    );
