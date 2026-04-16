// Тесты для KodiApi — JSON-RPC клиент.

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/core/api/kodi_api.dart';
import 'package:xerabora/shared/models/kodi_application_info.dart';
import 'package:xerabora/shared/models/kodi_episode.dart';
import 'package:xerabora/shared/models/kodi_movie.dart';
import 'package:xerabora/shared/models/kodi_tv_show.dart';

import '../../helpers/test_helpers.dart';

void main() {
  late KodiApi sut;
  late MockDio mockDio;

  setUpAll(registerAllFallbacks);

  setUp(() {
    mockDio = MockDio();
    sut = KodiApi(dio: mockDio);
    sut.setConnection(
      host: '192.168.1.10',
      port: 8080,
      username: 'kodi',
      password: 'secret',
    );
  });

  tearDown(() {
    sut.dispose();
  });

  Response<dynamic> makeJsonRpcResponse(Object? result) {
    return Response<dynamic>(
      data: <String, dynamic>{
        'jsonrpc': '2.0',
        'id': 1,
        'result': result,
      },
      statusCode: 200,
      requestOptions: RequestOptions(),
    );
  }

  group('configuration', () {
    test('isConfigured = true после setConnection', () {
      expect(sut.isConfigured, isTrue);
      expect(sut.baseUrl, 'http://192.168.1.10:8080/jsonrpc');
    });

    test('clearConnection сбрасывает isConfigured', () {
      sut.clearConnection();
      expect(sut.isConfigured, isFalse);
      expect(sut.baseUrl, isNull);
    });

    test('host с пробелами триммится', () {
      sut.setConnection(host: '  10.0.0.5  ', port: 8080);
      expect(sut.baseUrl, 'http://10.0.0.5:8080/jsonrpc');
    });

    test('пустой host → isConfigured = false', () {
      sut.setConnection(host: '', port: 8080);
      expect(sut.isConfigured, isFalse);
    });

    test('невалидный port (0) → isConfigured = false', () {
      sut.setConnection(host: '1.1.1.1', port: 0);
      expect(sut.isConfigured, isFalse);
    });

    test('port > 65535 → isConfigured = false', () {
      sut.setConnection(host: '1.1.1.1', port: 99999);
      expect(sut.isConfigured, isFalse);
    });
  });

  group('rawCall', () {
    test('без конфигурации → KodiApiException', () async {
      final KodiApi unconfigured = KodiApi(dio: mockDio);
      expect(
        () => unconfigured.rawCall('JSONRPC.Ping', null),
        throwsA(isA<KodiApiException>()),
      );
      unconfigured.dispose();
    });

    test('передаёт JSON-RPC body с method + id', () async {
      final List<Object?> capturedBodies = <Object?>[];

      when(() => mockDio.post<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((Invocation inv) async {
        capturedBodies.add(inv.namedArguments[#data]);
        return makeJsonRpcResponse('pong');
      });

      await sut.rawCall('JSONRPC.Ping', null);

      expect(capturedBodies, hasLength(1));
      final Map<String, dynamic> body =
          capturedBodies.first! as Map<String, dynamic>;
      expect(body['jsonrpc'], '2.0');
      expect(body['method'], 'JSONRPC.Ping');
      expect(body['id'], isA<int>());
      expect(body.containsKey('params'), isFalse);
    });

    test('включает params в body если переданы', () async {
      final List<Object?> capturedBodies = <Object?>[];

      when(() => mockDio.post<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((Invocation inv) async {
        capturedBodies.add(inv.namedArguments[#data]);
        return makeJsonRpcResponse(<String, dynamic>{});
      });

      await sut.rawCall(
        'VideoLibrary.GetMovies',
        <String, dynamic>{'limits': <String, int>{'start': 0, 'end': 10}},
      );

      final Map<String, dynamic> body =
          capturedBodies.first! as Map<String, dynamic>;
      expect(body['params'], isA<Map<String, dynamic>>());
    });

    test('инкрементирует request id между вызовами', () async {
      final List<int> ids = <int>[];

      when(() => mockDio.post<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((Invocation inv) async {
        final Map<String, dynamic> body =
            inv.namedArguments[#data] as Map<String, dynamic>;
        ids.add(body['id'] as int);
        return makeJsonRpcResponse('pong');
      });

      await sut.rawCall('JSONRPC.Ping', null);
      await sut.rawCall('JSONRPC.Ping', null);

      expect(ids[1], greaterThan(ids[0]));
    });

    test('добавляет Authorization Basic заголовок', () async {
      final List<Options?> capturedOptions = <Options?>[];

      when(() => mockDio.post<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((Invocation inv) async {
        capturedOptions.add(inv.namedArguments[#options] as Options?);
        return makeJsonRpcResponse('pong');
      });

      await sut.rawCall('JSONRPC.Ping', null);

      final Options opts = capturedOptions.first!;
      final String? auth = opts.headers?['Authorization'] as String?;
      expect(auth, isNotNull);
      expect(auth!.startsWith('Basic '), isTrue);
      final String encoded = auth.substring(6);
      expect(utf8.decode(base64Decode(encoded)), 'kodi:secret');
    });

    test('не добавляет Authorization если credentials пустые', () async {
      sut.setConnection(host: '1.1.1.1', port: 8080);
      final List<Options?> capturedOptions = <Options?>[];

      when(() => mockDio.post<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((Invocation inv) async {
        capturedOptions.add(inv.namedArguments[#options] as Options?);
        return makeJsonRpcResponse('pong');
      });

      await sut.rawCall('JSONRPC.Ping', null);

      expect(capturedOptions.first!.headers?['Authorization'], isNull);
    });

    test('POST идёт на /jsonrpc', () async {
      final List<String?> urls = <String?>[];

      when(() => mockDio.post<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((Invocation inv) async {
        urls.add(inv.positionalArguments.first as String?);
        return makeJsonRpcResponse('pong');
      });

      await sut.rawCall('JSONRPC.Ping', null);
      expect(urls.first, 'http://192.168.1.10:8080/jsonrpc');
    });

    test('401 → KodiApiException про authentication', () async {
      when(() => mockDio.post<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenThrow(DioException(
        response: Response<dynamic>(
          statusCode: 401,
          requestOptions: RequestOptions(),
        ),
        requestOptions: RequestOptions(),
      ));

      await expectLater(
        sut.rawCall('JSONRPC.Ping', null),
        throwsA(isA<KodiApiException>()
            .having(
                (KodiApiException e) => e.statusCode, 'statusCode', 401)
            .having((KodiApiException e) => e.message.toLowerCase(),
                'message', contains('auth'))),
      );
    });

    test('404 → KodiApiException про HTTP API', () async {
      when(() => mockDio.post<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenThrow(DioException(
        response: Response<dynamic>(
          statusCode: 404,
          requestOptions: RequestOptions(),
        ),
        requestOptions: RequestOptions(),
      ));

      await expectLater(
        sut.rawCall('JSONRPC.Ping', null),
        throwsA(isA<KodiApiException>().having(
            (KodiApiException e) => e.message.toLowerCase(),
            'message',
            contains('http api'))),
      );
    });

    test('connection timeout → KodiApiException', () async {
      when(() => mockDio.post<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenThrow(DioException(
        type: DioExceptionType.connectionTimeout,
        requestOptions: RequestOptions(),
      ));

      await expectLater(
        sut.rawCall('JSONRPC.Ping', null),
        throwsA(isA<KodiApiException>()),
      );
    });

    test('connection refused → KodiApiException с host:port', () async {
      when(() => mockDio.post<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenThrow(DioException(
        type: DioExceptionType.connectionError,
        requestOptions: RequestOptions(),
      ));

      await expectLater(
        sut.rawCall('JSONRPC.Ping', null),
        throwsA(isA<KodiApiException>().having(
            (KodiApiException e) => e.message,
            'message',
            contains('192.168.1.10:8080'))),
      );
    });

    test('JSON-RPC error в ответе → KodiApiException', () async {
      when(() => mockDio.post<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response<dynamic>(
            data: <String, dynamic>{
              'jsonrpc': '2.0',
              'id': 1,
              'error': <String, dynamic>{
                'code': -32601,
                'message': 'Method not found',
              },
            },
            statusCode: 200,
            requestOptions: RequestOptions(),
          ));

      await expectLater(
        sut.rawCall('Unknown.Method', null),
        throwsA(isA<KodiApiException>().having(
            (KodiApiException e) => e.message,
            'message',
            'Method not found')),
      );
    });

    test('не-JSON ответ → KodiApiException', () async {
      when(() => mockDio.post<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response<dynamic>(
            data: '<html>401 Unauthorized</html>',
            statusCode: 200,
            requestOptions: RequestOptions(),
          ));

      await expectLater(
        sut.rawCall('JSONRPC.Ping', null),
        throwsA(isA<KodiApiException>()),
      );
    });
  });

  group('ping', () {
    test('"pong" → true', () async {
      when(() => mockDio.post<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => makeJsonRpcResponse('pong'));

      expect(await sut.ping(), isTrue);
    });

    test('другой result → false', () async {
      when(() => mockDio.post<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => makeJsonRpcResponse('something'));

      expect(await sut.ping(), isFalse);
    });
  });

  group('getApplicationProperties', () {
    test('парсит version/name', () async {
      when(() => mockDio.post<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => makeJsonRpcResponse(<String, dynamic>{
            'version': <String, dynamic>{
              'major': 21,
              'minor': 0,
              'tag': 'stable',
            },
            'name': 'Kodi',
          }));

      final KodiApplicationInfo info = await sut.getApplicationProperties();
      expect(info.versionMajor, 21);
      expect(info.name, 'Kodi');
    });

    test('передаёт запрос на version/name в params', () async {
      final List<Object?> capturedBodies = <Object?>[];
      when(() => mockDio.post<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((Invocation inv) async {
        capturedBodies.add(inv.namedArguments[#data]);
        return makeJsonRpcResponse(<String, dynamic>{});
      });

      await sut.getApplicationProperties();

      final Map<String, dynamic> body =
          capturedBodies.first! as Map<String, dynamic>;
      final Map<String, dynamic> params =
          body['params'] as Map<String, dynamic>;
      expect(params['properties'], containsAll(<String>['version', 'name']));
    });
  });

  group('getMovies', () {
    test('парсит список фильмов', () async {
      when(() => mockDio.post<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => makeJsonRpcResponse(<String, dynamic>{
            'movies': <Map<String, dynamic>>[
              <String, dynamic>{
                'movieid': 1,
                'title': 'Inception',
                'year': 2010,
                'playcount': 1,
                'lastplayed': '2026-04-12 22:30:11',
                'uniqueid': <String, dynamic>{'tmdb': '27205'},
              },
              <String, dynamic>{
                'movieid': 2,
                'title': 'The Matrix',
              },
            ],
          }));

      final List<KodiMovie> movies = await sut.getMovies();
      expect(movies, hasLength(2));
      expect(movies.first.title, 'Inception');
      expect(movies.first.uniqueIds.tmdbId, 27205);
      expect(movies.last.title, 'The Matrix');
    });

    test('пустой result → пустой список', () async {
      when(() => mockDio.post<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => makeJsonRpcResponse(<String, dynamic>{}));

      expect(await sut.getMovies(), isEmpty);
    });

    test('передаёт limits с start/end', () async {
      final List<Object?> capturedBodies = <Object?>[];
      when(() => mockDio.post<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((Invocation inv) async {
        capturedBodies.add(inv.namedArguments[#data]);
        return makeJsonRpcResponse(<String, dynamic>{});
      });

      await sut.getMovies(start: 200, end: 400);

      final Map<String, dynamic> body =
          capturedBodies.first! as Map<String, dynamic>;
      final Map<String, dynamic> params =
          body['params'] as Map<String, dynamic>;
      expect(params['limits'], <String, int>{'start': 200, 'end': 400});
    });

    test('запрашивает обязательные properties', () async {
      final List<Object?> capturedBodies = <Object?>[];
      when(() => mockDio.post<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((Invocation inv) async {
        capturedBodies.add(inv.namedArguments[#data]);
        return makeJsonRpcResponse(<String, dynamic>{});
      });

      await sut.getMovies();

      final Map<String, dynamic> body =
          capturedBodies.first! as Map<String, dynamic>;
      final Map<String, dynamic> params =
          body['params'] as Map<String, dynamic>;
      expect(
        params['properties'] as List<dynamic>,
        containsAll(<String>[
          'title',
          'year',
          'playcount',
          'lastplayed',
          'uniqueid',
          'userrating',
        ]),
      );
    });
  });

  group('getTvShows', () {
    test('парсит список сериалов', () async {
      when(() => mockDio.post<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => makeJsonRpcResponse(<String, dynamic>{
            'tvshows': <Map<String, dynamic>>[
              <String, dynamic>{
                'tvshowid': 7,
                'title': 'Breaking Bad',
                'year': 2008,
              },
            ],
          }));

      final List<KodiTvShow> shows = await sut.getTvShows();
      expect(shows, hasLength(1));
      expect(shows.first.tvShowId, 7);
    });
  });

  group('getEpisodes', () {
    test('парсит список эпизодов', () async {
      when(() => mockDio.post<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => makeJsonRpcResponse(<String, dynamic>{
            'episodes': <Map<String, dynamic>>[
              <String, dynamic>{
                'episodeid': 1,
                'showtitle': 'Show',
                'season': 1,
                'episode': 1,
                'playcount': 1,
              },
            ],
          }));

      final List<KodiEpisode> episodes = await sut.getEpisodes();
      expect(episodes, hasLength(1));
      expect(episodes.first.isWatched, isTrue);
    });

    test('передаёт tvshowid фильтр если задан', () async {
      final List<Object?> capturedBodies = <Object?>[];
      when(() => mockDio.post<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((Invocation inv) async {
        capturedBodies.add(inv.namedArguments[#data]);
        return makeJsonRpcResponse(<String, dynamic>{});
      });

      await sut.getEpisodes(tvShowId: 7);

      final Map<String, dynamic> body =
          capturedBodies.first! as Map<String, dynamic>;
      final Map<String, dynamic> params =
          body['params'] as Map<String, dynamic>;
      expect(params['tvshowid'], 7);
    });

    test('не передаёт tvshowid если не задан', () async {
      final List<Object?> capturedBodies = <Object?>[];
      when(() => mockDio.post<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((Invocation inv) async {
        capturedBodies.add(inv.namedArguments[#data]);
        return makeJsonRpcResponse(<String, dynamic>{});
      });

      await sut.getEpisodes();

      final Map<String, dynamic> body =
          capturedBodies.first! as Map<String, dynamic>;
      final Map<String, dynamic> params =
          body['params'] as Map<String, dynamic>;
      expect(params.containsKey('tvshowid'), isFalse);
    });
  });

  group('KodiApiException', () {
    test('toString содержит статус и сообщение', () {
      const KodiApiException e =
          KodiApiException('Auth failed', statusCode: 401);
      expect(e.toString(), 'KodiApiException(401): Auth failed');
    });
  });
}
