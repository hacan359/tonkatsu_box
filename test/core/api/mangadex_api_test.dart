import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/mangadex_api.dart';
import 'package:tonkatsu_box/shared/models/manga.dart';

import '../../helpers/test_helpers.dart';

void main() {
  late MockDio mockDio;
  late MangaDexApi api;

  const String uuid = 'a1c7c817-4e59-43b7-9365-09675a149a6f';

  setUpAll(registerAllFallbacks);

  setUp(() {
    mockDio = MockDio();
    api = MangaDexApi(dio: mockDio);
  });

  Response<dynamic> makeResponse(dynamic data) => Response<dynamic>(
        data: data,
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      );

  Map<String, dynamic> mangaRow(String id) => <String, dynamic>{
        'id': id,
        'type': 'manga',
        'attributes': <String, dynamic>{
          'title': <String, dynamic>{'en': 'Title'},
          'status': 'ongoing',
        },
        'relationships': <Map<String, dynamic>>[
          <String, dynamic>{
            'type': 'cover_art',
            'attributes': <String, dynamic>{'fileName': 'c.jpg'},
          },
        ],
      };

  DioException dioError({int? statusCode, DioExceptionType? type}) {
    return DioException(
      requestOptions: RequestOptions(path: ''),
      type: type ?? DioExceptionType.badResponse,
      response: statusCode == null
          ? null
          : Response<dynamic>(
              statusCode: statusCode,
              requestOptions: RequestOptions(path: ''),
            ),
    );
  }

  group('browseManga', () {
    test('computes hasMore and totalPages from total / limit', () async {
      when(() => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => makeResponse(<String, dynamic>{
            'data': <Map<String, dynamic>>[
              mangaRow(uuid),
              mangaRow('b2c7c817-4e59-43b7-9365-09675a149a70'),
            ],
            'limit': 20,
            'offset': 0,
            'total': 40,
          }));

      final (List<Manga> mangas, bool hasMore, int totalPages) =
          await api.browseManga(query: 'chainsaw');

      expect(mangas, hasLength(2));
      expect(hasMore, isTrue);
      expect(totalPages, 2);
    });

    test('hasMore false on the last page', () async {
      when(() => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => makeResponse(<String, dynamic>{
            'data': <Map<String, dynamic>>[mangaRow(uuid)],
            'limit': 20,
            'offset': 20,
            'total': 21,
          }));

      final (List<Manga> _, bool hasMore, int _) =
          await api.browseManga(page: 2);
      expect(hasMore, isFalse);
    });

    test('maps 429 to a rate-limit MangaDexApiException', () async {
      when(() => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenThrow(dioError(statusCode: 429));

      await expectLater(
        api.browseManga(query: 'x'),
        throwsA(isA<MangaDexApiException>().having(
            (MangaDexApiException e) => e.statusCode, 'statusCode', 429)),
      );
    });
  });

  group('getByUuid', () {
    test('returns the series total from lastChapter / lastVolume, not the '
        'translated-chapter aggregate', () async {
      final Map<String, dynamic> detail = mangaRow(uuid);
      (detail['attributes'] as Map<String, dynamic>)['lastChapter'] = '700';
      (detail['attributes'] as Map<String, dynamic>)['lastVolume'] = '72';
      when(() => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer(
          (_) async => makeResponse(<String, dynamic>{'data': detail}));

      final Manga? m = await api.getByUuid(uuid);
      expect(m, isNotNull);
      expect(m!.chapters, 700);
      expect(m.volumes, 72);
    });

    test('returns null on 404', () async {
      when(() => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenThrow(dioError(statusCode: 404));

      expect(await api.getByUuid(uuid), isNull);
    });
  });

  group('fetchTags', () {
    test('parses the tag catalog and skips malformed rows', () async {
      when(() => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => makeResponse(<String, dynamic>{
            'data': <dynamic>[
              <String, dynamic>{
                'id': 't1',
                'attributes': <String, dynamic>{
                  'name': <String, dynamic>{'en': 'Action'},
                  'group': 'genre',
                },
              },
              'not a map',
            ],
          }));

      final List<dynamic> tags = await api.fetchTags();
      expect(tags, hasLength(1));
    });
  });

  group('getRecommendations', () {
    const String seed = 'seed-uuid';
    const String a = 'aaaa';
    const String b = 'bbbb';

    Map<String, dynamic> recRow(String rec, double score) => <String, dynamic>{
          'id': '${seed}_$rec',
          'type': 'manga_recommendation',
          'attributes': <String, dynamic>{'score': score},
          'relationships': <Map<String, dynamic>>[
            <String, dynamic>{'id': seed, 'type': 'manga'},
            <String, dynamic>{'id': rec, 'type': 'manga'},
          ],
        };

    Map<String, dynamic> mangaDoc(String id, String title) => <String, dynamic>{
          'id': id,
          'type': 'manga',
          'attributes': <String, dynamic>{
            'title': <String, dynamic>{'en': title},
          },
        };

    // Routes the recommendation call and the batch-hydration call by path.
    void stubFlow(
      List<Map<String, dynamic>> rows,
      List<Map<String, dynamic>> hydrated,
    ) {
      when(() => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((Invocation inv) async {
        final String path = inv.positionalArguments.first as String;
        final List<Map<String, dynamic>> data =
            path.contains('recommendation') ? rows : hydrated;
        return makeResponse(<String, dynamic>{'data': data});
      });
    }

    test('returns recommendations in score order, hydrated with details',
        () async {
      stubFlow(
        <Map<String, dynamic>>[recRow(a, 0.9), recRow(b, 0.8)],
        // Hydration returns them reversed to prove the score order is restored.
        <Map<String, dynamic>>[
          mangaDoc(b, 'Vinland Saga'),
          mangaDoc(a, 'Berserk'),
        ],
      );

      final List<Manga> recs = await api.getRecommendations(seed);

      expect(recs.map((Manga m) => m.title),
          <String>['Berserk', 'Vinland Saga']);
    });

    test('returns empty when the endpoint yields no rows', () async {
      stubFlow(<Map<String, dynamic>>[], <Map<String, dynamic>>[]);
      expect(await api.getRecommendations(seed), isEmpty);
    });

    test('drops a recommendation that hydration does not return', () async {
      stubFlow(
        <Map<String, dynamic>>[recRow(a, 0.9), recRow(b, 0.8)],
        <Map<String, dynamic>>[mangaDoc(a, 'Berserk')],
      );

      final List<Manga> recs = await api.getRecommendations(seed);
      expect(recs.map((Manga m) => m.title), <String>['Berserk']);
    });

    test('throws MangaDexApiException on a Dio error', () async {
      when(() => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenThrow(dioError(type: DioExceptionType.connectionError));

      await expectLater(
        api.getRecommendations(seed),
        throwsA(isA<MangaDexApiException>()),
      );
    });
  });
}
