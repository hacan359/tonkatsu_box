import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:core/api/image_proxy.dart';
import 'package:core/models/image_type.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';

import 'proxy_handler.dart' show kProxyUserAgent;
import 'upstream_client.dart';
import 'upstream_throttle.dart';

/// A cover is immutable for a given id, so the browser can hold it as long as
/// it likes and the server stops being asked at all.
const String _kImmutable = 'public, max-age=31536000, immutable';

/// Cover Art Archive rate-limits per IP; the gap mirrors the desktop client's
/// host_rate_limiter so a burst of cold covers does not collect 429s.
const Map<String, Duration> _hostMinGap = <String, Duration>{
  'coverartarchive.org': Duration(milliseconds: 300),
};

final Map<String, UpstreamThrottle> _hostThrottles =
    <String, UpstreamThrottle>{};

Future<void> _throttleHost(String host) {
  final Duration? gap = _hostMinGap[host];
  if (gap == null) return Future<void>.value();
  return _hostThrottles
      .putIfAbsent(host, () => UpstreamThrottle(gap))
      .acquire();
}

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
        final (ImageType, String)? target = _target(request);
        if (target == null) {
          return _error(HttpStatus.notFound, 'No image in the path');
        }
        final (ImageType type, String imageId) = target;
        if (!_isSafeImageId(imageId)) {
          return _error(HttpStatus.badRequest, 'Bad image id');
        }

        final File file = _fileFor(type, imageId);
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
          await _throttleHost(sourceUri.host);
          response = await _upstream.send(
            method: 'GET',
            url: sourceUri,
            // Cover hosts (Cover Art Archive among them) rate-limit or refuse
            // agent-less clients; identify like the API proxy does.
            headers: <String, String>{
              HttpHeaders.userAgentHeader: kProxyUserAgent,
            },
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

        // ScreenScraper answers an outage with a 200 HTML page; caching that
        // would serve a broken "image" for the year the entry is immutable.
        final String? contentType = response.contentType;
        if (contentType != null && !contentType.startsWith('image/')) {
          return _error(
            HttpStatus.badGateway,
            'Source answered $contentType, not an image',
          );
        }

        await _writeAtomically(file, response.body);

        return _image(
          response.body,
          response.contentType ?? _contentTypeOf(imageId),
        );
      };

  /// The web build's stand-in for the desktop local-cache write: a user-picked
  /// cover has no upstream URL the GET route could fetch.
  Handler get uploadHandler => (Request request) async {
        final (ImageType, String)? target = _target(request);
        if (target == null) {
          return _error(HttpStatus.notFound, 'No image in the path');
        }
        final (ImageType type, String imageId) = target;
        if (!_isSafeImageId(imageId)) {
          return _error(HttpStatus.badRequest, 'Bad image id');
        }

        final BytesBuilder body = BytesBuilder(copy: false);
        await for (final List<int> chunk in request.read()) {
          body.add(chunk);
          if (body.length > _kMaxUploadBytes) {
            return _error(HttpStatus.requestEntityTooLarge, 'Image too large');
          }
        }
        if (body.isEmpty) {
          return _error(HttpStatus.badRequest, 'Empty body');
        }

        await _writeAtomically(_fileFor(type, imageId), body.takeBytes());
        return Response.ok(
          jsonEncode(<String, Object?>{'ok': true}),
          headers: <String, String>{
            HttpHeaders.contentTypeHeader: 'application/json',
          },
        );
      };

  /// The web build's stand-in for deleting a local cache file: a cover the
  /// user replaced would otherwise be served from the copy taken before.
  Handler get deleteHandler => (Request request) async {
        final (ImageType, String)? target = _target(request);
        if (target == null) {
          return _error(HttpStatus.notFound, 'No image in the path');
        }
        final (ImageType type, String imageId) = target;
        if (!_isSafeImageId(imageId)) {
          return _error(HttpStatus.badRequest, 'Bad image id');
        }

        final File file = _fileFor(type, imageId);
        try {
          if (file.existsSync()) await file.delete();
        } on FileSystemException catch (e) {
          return _error(HttpStatus.internalServerError, '$e');
        }
        return Response.ok(
          jsonEncode(<String, Object?>{'ok': true}),
          headers: <String, String>{
            HttpHeaders.contentTypeHeader: 'application/json',
          },
        );
      };

  /// Folder + id from `/img/<folder>/<id>`, or null when the path is not an
  /// image.
  (ImageType, String)? _target(Request request) {
    final List<String> segments = request.url.pathSegments;
    if (segments.length < 3) return null;
    final ImageType? type = imageTypeForFolder(segments[1]);
    if (type == null) return null;
    return (type, segments.skip(2).join('/'));
  }

  /// A traversal, absolute or drive-qualified id would land the read, write
  /// or delete outside the cache directory (p.join drops dataDir on absolute).
  static bool _isSafeImageId(String imageId) =>
      imageId.isNotEmpty &&
      !imageId.contains('..') &&
      !imageId.contains(':') &&
      !p.isAbsolute(imageId);

  File _fileFor(ImageType type, String imageId) =>
      File(p.join(dataDir, 'images', type.folder, imageId));

  /// Write through a temporary name: a half-written file would be served as a
  /// valid cache hit forever after.
  Future<void> _writeAtomically(File file, List<int> bytes) async {
    final File temp = File('${file.path}.part');
    await temp.parent.create(recursive: true);
    await temp.writeAsBytes(bytes, flush: true);
    await temp.rename(file.path);
  }
}

/// Covers are hundreds of KB; anything bigger than this is not a cover.
const int _kMaxUploadBytes = 20 * 1024 * 1024;

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
