import 'dart:convert';
import 'dart:io';

import 'package:core/models/image_type.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:tonkatsu_server/src/app_handler.dart';
import 'package:tonkatsu_server/src/image_handler.dart';
import 'package:tonkatsu_server/src/upstream_client.dart';

class _FakeUpstream implements UpstreamClient {
  _FakeUpstream({this.payload = const <int>[1, 2, 3], this.status = 200});

  final List<int> payload;
  final int status;
  final List<Uri> sent = <Uri>[];

  @override
  Future<UpstreamResponse> send({
    required String method,
    required Uri url,
    required Map<String, String> headers,
    List<int>? body,
  }) async {
    sent.add(url);
    return UpstreamResponse(
      status: status,
      contentType: 'image/jpeg',
      body: payload,
    );
  }
}

void main() {
  late Directory dataDir;
  late _FakeUpstream upstream;

  setUp(() {
    dataDir = Directory.systemTemp.createTempSync('tonkatsu_img');
    upstream = _FakeUpstream();
  });

  tearDown(() {
    if (dataDir.existsSync()) dataDir.deleteSync(recursive: true);
  });

  Handler build() => buildAppHandler(
        schemaVersion: 1,
        images: ImageCache(dataDir: dataDir.path, upstream: upstream),
        logger: (Handler inner) => inner,
      );

  Future<Response> get(String path) async =>
      build()(Request('GET', Uri.parse('http://localhost$path')));

  File cached(String name) =>
      File(p.join(dataDir.path, 'images', ImageType.animeCover.folder, name));

  const String src = '?src=https%3A%2F%2Fcdn.example%2Fa.jpg';

  group('GET /img/<folder>/<id>', () {
    test('should fetch and store an image the cache does not have', () async {
      final Response response = await get('/img/anime_covers/anilist_1$src');

      expect(response.statusCode, HttpStatus.ok);
      expect(await response.read().expand((List<int> c) => c).toList(),
          <int>[1, 2, 3]);
      expect(upstream.sent.single.host, 'cdn.example');
      expect(cached('anilist_1').readAsBytesSync(), <int>[1, 2, 3]);
    });

    test('should serve a second request without going upstream again',
        () async {
      await get('/img/anime_covers/anilist_1$src');
      await get('/img/anime_covers/anilist_1$src');

      expect(upstream.sent, hasLength(1));
    });

    test('should let the browser hold a cover indefinitely', () async {
      final Response response = await get('/img/anime_covers/anilist_1$src');

      expect(
        response.headers[HttpHeaders.cacheControlHeader],
        contains('immutable'),
      );
    });

    test('should refuse an unknown image type', () async {
      final Response response = await get('/img/not_a_folder/x$src');

      expect(response.statusCode, HttpStatus.notFound);
      expect(upstream.sent, isEmpty);
    });

    test('should refuse an id that climbs out of the cache directory',
        () async {
      final Response response =
          await get('/img/anime_covers/..%2F..%2Fescape$src');

      expect(response.statusCode, HttpStatus.badRequest);
      expect(upstream.sent, isEmpty);
    });

    test('should refuse a source that is not https', () async {
      final Response response = await get(
        '/img/anime_covers/anilist_1?src=http%3A%2F%2Fcdn.example%2Fa.jpg',
      );

      expect(response.statusCode, HttpStatus.badRequest);
      expect(upstream.sent, isEmpty);
    });

    test('should 404 a miss with no source to fetch from', () async {
      final Response response = await get('/img/anime_covers/anilist_1');

      expect(response.statusCode, HttpStatus.notFound);
    });

    test('should not cache what the source refused', () async {
      upstream = _FakeUpstream(status: 404, payload: <int>[]);

      final Response response = await get('/img/anime_covers/anilist_1$src');

      expect(response.statusCode, HttpStatus.badGateway);
      expect(cached('anilist_1').existsSync(), isFalse);
    });

    test('should report the failure as JSON, not as the web client', () async {
      final Response response = await get('/img/not_a_folder/x$src');

      final Object? body = jsonDecode(await response.readAsString());
      expect((body! as Map<String, Object?>)['ok'], isFalse);
    });
  });
}
