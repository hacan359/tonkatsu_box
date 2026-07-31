import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/kitsu_api.dart';
import 'package:tonkatsu_box/shared/models/anime.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late MockDio mockDio;
  late KitsuApi api;

  setUpAll(registerAllFallbacks);

  setUp(() {
    mockDio = MockDio();
    api = KitsuApi(dio: mockDio);
  });

  Response<dynamic> makeResponse(dynamic data) => Response<dynamic>(
        data: data,
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      );

  Map<String, dynamic> animeResource(String id) => <String, dynamic>{
        'id': id,
        'type': 'anime',
        'attributes': <String, dynamic>{
          'canonicalTitle': 'Hunter x Hunter',
          'titles': <String, dynamic>{'en': 'Hunter x Hunter'},
        },
      };

  Map<String, dynamic> mapping(String externalId, String? itemId) =>
      <String, dynamic>{
        'id': 'm-$externalId',
        'type': 'mappings',
        'attributes': <String, dynamic>{'externalId': externalId},
        'relationships': <String, dynamic>{
          'item': <String, dynamic>{
            'data': itemId == null
                ? null
                : <String, dynamic>{'id': itemId, 'type': 'anime'},
          },
        },
      };

  void stubGet(List<Response<dynamic>> responses) {
    int call = 0;
    when(() => mockDio.get<dynamic>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        )).thenAnswer((_) async => responses[call++]);
  }

  List<Map<String, dynamic>> capturedQueries() =>
      verify(() => mockDio.get<dynamic>(
            any(),
            queryParameters: captureAny(named: 'queryParameters'),
            options: any(named: 'options'),
          )).captured.cast<Map<String, dynamic>>();

  group('getAnimeByMalIds', () {
    test('maps external ids to the included anime records', () async {
      stubGet(<Response<dynamic>>[
        makeResponse(<String, dynamic>{
          'data': <Map<String, dynamic>>[mapping('11061', '6448')],
          'included': <Map<String, dynamic>>[animeResource('6448')],
        }),
      ]);

      final Map<int, Anime> result = await api.getAnimeByMalIds(<int>[11061]);

      expect(result.keys, <int>[11061]);
      expect(result[11061]?.id, 6448);
      final Map<String, dynamic> query = capturedQueries().single;
      expect(query['filter[externalSite]'], 'myanimelist/anime');
      expect(query['filter[externalId]'], '11061');
      expect(query['include'], 'item');
    });

    test('drops mappings whose item is missing from the response', () async {
      stubGet(<Response<dynamic>>[
        makeResponse(<String, dynamic>{
          'data': <Map<String, dynamic>>[
            mapping('11061', '6448'),
            mapping('999', '404'),
            mapping('888', null),
          ],
          'included': <Map<String, dynamic>>[animeResource('6448')],
        }),
      ]);

      final Map<int, Anime> result =
          await api.getAnimeByMalIds(<int>[11061, 999, 888]);

      expect(result.keys, <int>[11061]);
    });

    test('splits requests into batches of 20 ids', () async {
      stubGet(<Response<dynamic>>[
        makeResponse(<String, dynamic>{}),
        makeResponse(<String, dynamic>{}),
      ]);

      await api.getAnimeByMalIds(
        List<int>.generate(25, (int index) => index + 1),
      );

      final List<Map<String, dynamic>> queries = capturedQueries();
      expect(queries, hasLength(2));
      expect(
        (queries[0]['filter[externalId]'] as String).split(','),
        hasLength(20),
      );
      expect(
        (queries[1]['filter[externalId]'] as String).split(','),
        hasLength(5),
      );
    });

    test('an empty id list makes no request', () async {
      expect(await api.getAnimeByMalIds(<int>[]), isEmpty);
      verifyNever(() => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ));
    });

    test('surfaces transport failures as KitsuApiException', () async {
      when(() => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          statusCode: 500,
          requestOptions: RequestOptions(path: ''),
        ),
      ));

      expect(
        () => api.getAnimeByMalIds(<int>[1]),
        throwsA(isA<KitsuApiException>()),
      );
    });
  });

  group('getAnimeByAnidbIds', () {
    test('queries the anidb external site', () async {
      stubGet(<Response<dynamic>>[
        makeResponse(<String, dynamic>{
          'data': <Map<String, dynamic>>[mapping('4087', '6448')],
          'included': <Map<String, dynamic>>[animeResource('6448')],
        }),
      ]);

      final Map<int, Anime> result = await api.getAnimeByAnidbIds(<int>[4087]);

      expect(result[4087]?.id, 6448);
      expect(capturedQueries().single['filter[externalSite]'], 'anidb');
    });
  });

  group('getAnimeByIds', () {
    test('fetches cards by a comma list of Kitsu ids', () async {
      stubGet(<Response<dynamic>>[
        makeResponse(<String, dynamic>{
          'data': <Map<String, dynamic>>[animeResource('6448')],
        }),
      ]);

      final List<Anime> result = await api.getAnimeByIds(<int>[6448]);

      expect(result.single.id, 6448);
      expect(capturedQueries().single['filter[id]'], '6448');
    });

    test('batches ids by the Kitsu page cap', () async {
      stubGet(<Response<dynamic>>[
        makeResponse(<String, dynamic>{}),
        makeResponse(<String, dynamic>{}),
      ]);

      await api.getAnimeByIds(List<int>.generate(21, (int i) => i + 1));

      final List<Map<String, dynamic>> queries = capturedQueries();
      expect(queries, hasLength(2));
      expect((queries[1]['filter[id]'] as String).split(','), hasLength(1));
    });

    test('an empty id list makes no request', () async {
      expect(await api.getAnimeByIds(<int>[]), isEmpty);
      verifyNever(() => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ));
    });
  });
}
