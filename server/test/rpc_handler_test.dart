import 'dart:convert';
import 'dart:io';

import 'package:core/rpc/rpc_codec.dart';
import 'package:shelf/shelf.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';
import 'package:tonkatsu_server/src/app_handler.dart';
import 'package:tonkatsu_server/src/database_bootstrap.dart';
import 'package:tonkatsu_server/src/protocol.dart';
import 'package:tonkatsu_server/src/rpc_handler.dart';

void main() {
  late Directory dataDir;
  late DatabaseBootstrap bootstrap;
  late Handler handler;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    dataDir = Directory.systemTemp.createTempSync('tonkatsu_rpc_test');
    bootstrap = await bootstrapDatabase(
      factory: databaseFactoryFfi,
      dataDir: dataDir.path,
    );
    handler = buildAppHandler(
      schemaVersion: bootstrap.schemaVersion,
      daos: DaoRegistry(bootstrap.db),
      logger: (Handler inner) => inner,
    );
  });

  tearDown(() async {
    await bootstrap.db.close();
    if (dataDir.existsSync()) dataDir.deleteSync(recursive: true);
  });

  Future<Map<String, Object?>> post(Map<String, Object?> body) async {
    final Response response = await handler(Request(
      'POST',
      Uri.parse('http://localhost/rpc'),
      body: jsonEncode(body),
    ));
    return asObject(jsonDecode(await response.readAsString()));
  }

  Map<String, Object?> envelope(String method, Map<String, Object?> args) =>
      <String, Object?>{
        'protocol': kProtocolVersion,
        'dao': 'CollectionDao',
        'method': method,
        'args': args,
      };

  group('POST /rpc', () {
    test('should run a DAO method against the server database', () async {
      final Map<String, Object?> created = await post(envelope(
        'createCollection',
        <String, Object?>{'name': 'Shelf', 'author': 'ann'},
      ));

      expect(created['ok'], isTrue);
      expect(asObject(created['result'])['name'], 'Shelf');

      final Map<String, Object?> listed =
          await post(envelope('getAllCollections', <String, Object?>{}));
      expect(asList(listed['result']), hasLength(1));
    });

    test('should reject a protocol version it does not speak', () async {
      final Map<String, Object?> body = await post(<String, Object?>{
        'protocol': kProtocolVersion + 1,
        'dao': 'CollectionDao',
        'method': 'getAllCollections',
        'args': <String, Object?>{},
      });

      expect(body['ok'], isFalse);
      expect(asObject(body['error'])['kind'], 'protocol');
    });

    test('should route a DAO other than the first one', () async {
      final Map<String, Object?> body = await post(<String, Object?>{
        'protocol': kProtocolVersion,
        'dao': 'WishlistDao',
        'method': 'addWishlistItem',
        'args': <String, Object?>{'text': 'later'},
      });

      expect(body['ok'], isTrue);
      expect(asObject(body['result'])['text'], 'later');
    });

    test('should report an unknown dao as a bad request', () async {
      final Map<String, Object?> body = await post(<String, Object?>{
        'protocol': kProtocolVersion,
        'dao': 'NoSuchDao',
        'method': 'whatever',
        'args': <String, Object?>{},
      });

      expect(body['ok'], isFalse);
      expect(asObject(body['error'])['kind'], 'badRequest');
    });

    test('should surface a database failure as a typed error', () async {
      // collection_id 999 does not exist, so the FK rejects the insert.
      final Map<String, Object?> body = await post(envelope(
        'addItemToCollection',
        <String, Object?>{
          'collectionId': '999',
          'mediaType': 'movie',
          'externalId': '1',
          'platformId': null,
          'source': null,
          'authorComment': null,
          'status': 'planned',
          'addedAt': null,
        },
      ));

      expect(body['ok'], isFalse);
      expect(asObject(body['error'])['kind'], 'database');
    });

    test('should answer 400 on a malformed body', () async {
      final Response response = await handler(Request(
        'POST',
        Uri.parse('http://localhost/rpc'),
        body: 'not json',
      ));

      expect(response.statusCode, HttpStatus.badRequest);
    });

    test('should not expose /rpc when no registry is wired', () async {
      final Handler bare = buildAppHandler(
        schemaVersion: 1,
        logger: (Handler inner) => inner,
      );

      final Response response = await bare(Request(
        'POST',
        Uri.parse('http://localhost/rpc'),
        body: '{}',
      ));

      expect(response.statusCode, HttpStatus.notFound);
    });
  });
}
