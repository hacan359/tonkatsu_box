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
}
