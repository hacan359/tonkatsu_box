import 'package:core/models/visual_novel.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/vndb_api.dart';

import '../../helpers/test_helpers.dart';

void main() {
  late MockDio mockDio;
  late VndbApi api;

  setUp(() {
    mockDio = MockDio();
    api = VndbApi(dio: mockDio);
  });

  group('VndbApiException', () {
    test('should contain message и statusCode', () {
      const VndbApiException exception =
          VndbApiException('test', statusCode: 429);
      expect(exception.message, 'test');
      expect(exception.statusCode, 429);
    });

    test('toString should format сообщение', () {
      const VndbApiException exception =
          VndbApiException('error', statusCode: 500);
      expect(exception.toString(),
          'VndbApiException: error (status: 500)');
    });
  });

  group('VndbApi', () {
    Response<dynamic> makeResponse(
      Map<String, dynamic> data, {
      int statusCode = 200,
    }) {
      return Response<dynamic>(
        data: data,
        statusCode: statusCode,
        requestOptions: RequestOptions(path: ''),
      );
    }

    Map<String, dynamic> vnJson({
      String id = 'v17',
      String title = 'Ever17',
    }) {
      return <String, dynamic>{
        'id': id,
        'title': title,
        'rating': 85.0,
        'votecount': 100,
      };
    }

    group('searchVn', () {
      test('should return пустой список для пустого запроса', () async {
        final (List<VisualNovel> results, bool hasMore) =
            await api.searchVn(query: '');
        expect(results, isEmpty);
        expect(hasMore, isFalse);
      });

      test('should return пустой список для запроса из пробелов', () async {
        final (List<VisualNovel> results, bool hasMore) =
            await api.searchVn(query: '   ');
        expect(results, isEmpty);
        expect(hasMore, isFalse);
      });

      test('должен отправить POST и вернуть результаты', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => makeResponse(<String, dynamic>{
            'results': <dynamic>[vnJson()],
            'more': true,
          }),
        );

        final (List<VisualNovel> results, bool hasMore) =
            await api.searchVn(query: 'ever');

        expect(results, hasLength(1));
        expect(results.first.id, 'v17');
        expect(hasMore, isTrue);

        verify(() => mockDio.post<dynamic>(
              'https://api.vndb.org/kana/vn',
              data: any(named: 'data'),
            )).called(1);
      });

      test('должен выбросить VndbApiException при DioException', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(path: ''),
        ));

        expect(
          () => api.searchVn(query: 'test'),
          throwsA(isA<VndbApiException>()),
        );
      });

      test('should handle rate limit (429)', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            statusCode: 429,
            requestOptions: RequestOptions(path: ''),
          ),
          requestOptions: RequestOptions(path: ''),
        ));

        try {
          await api.searchVn(query: 'test');
          fail('Should throw');
        } on VndbApiException catch (e) {
          expect(e.message, contains('Rate limit'));
          expect(e.statusCode, 429);
        }
      });
    });

    group('browseVn', () {
      test('should return результаты с totalPages', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => makeResponse(<String, dynamic>{
            'results': <dynamic>[vnJson()],
            'more': false,
            'count': 15,
          }),
        );

        final (
          List<VisualNovel> results,
          bool hasMore,
          int totalPages,
        ) = await api.browseVn();

        expect(results, hasLength(1));
        expect(hasMore, isFalse);
        expect(totalPages, 1);
      });

      // Captures the `filters` payload of a browseVn call and returns the
      // individual filter nodes (unwrapping the leading 'and').
      Future<List<dynamic>> captureFilters(
        Future<void> Function() run,
      ) async {
        Map<String, dynamic>? capturedData;
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((Invocation inv) async {
          capturedData = inv.namedArguments[const Symbol('data')]
              as Map<String, dynamic>?;
          return makeResponse(<String, dynamic>{
            'results': <dynamic>[],
            'more': false,
            'count': 0,
          });
        });

        await run();

        final dynamic filters = capturedData!['filters'];
        if (filters is List<dynamic> &&
            filters.isNotEmpty &&
            filters.first == 'and') {
          return filters.sublist(1);
        }
        return <dynamic>[filters];
      }

      test('ANDs each selected tag as a tag filter', () async {
        final List<dynamic> nodes = await captureFilters(
          () => api.browseVn(tagIds: <String>['g7', 'g13']),
        );
        expect(nodes, anyElement(equals(<dynamic>['tag', '=', 'g7'])));
        expect(nodes, anyElement(equals(<dynamic>['tag', '=', 'g13'])));
      });

      test('maps length to a length filter', () async {
        final List<dynamic> nodes =
            await captureFilters(() => api.browseVn(length: 3));
        expect(nodes, anyElement(equals(<dynamic>['length', '=', 3])));
      });

      test('ORs the selected languages', () async {
        final List<dynamic> nodes = await captureFilters(
          () => api.browseVn(langs: <String>['en', 'ru']),
        );
        expect(
          nodes,
          anyElement(equals(<dynamic>[
            'or',
            <dynamic>['lang', '=', 'en'],
            <dynamic>['lang', '=', 'ru'],
          ])),
        );
      });

      test('emits a bare lang predicate for a single language', () async {
        final List<dynamic> nodes =
            await captureFilters(() => api.browseVn(langs: <String>['en']));
        expect(nodes, anyElement(equals(<dynamic>['lang', '=', 'en'])));
        expect(
          nodes,
          isNot(anyElement(equals(<dynamic>['or', <dynamic>['lang', '=', 'en']]))),
        );
      });

      test('maps a year range to released bounds', () async {
        final List<dynamic> nodes = await captureFilters(
          () => api.browseVn(startYear: 2010, endYear: 2015),
        );
        expect(nodes, anyElement(equals(<dynamic>['released', '>=', '2010-01-01'])));
        expect(nodes, anyElement(equals(<dynamic>['released', '<=', '2015-12-31'])));
      });

      test('maps minRating to a rating threshold', () async {
        final List<dynamic> nodes =
            await captureFilters(() => api.browseVn(minRating: 80));
        expect(nodes, anyElement(equals(<dynamic>['rating', '>=', 80])));
      });

      test('maps hasAnime to has_anime = 1', () async {
        final List<dynamic> nodes =
            await captureFilters(() => api.browseVn(hasAnime: true));
        expect(nodes, anyElement(equals(<dynamic>['has_anime', '=', 1])));
      });

      test('omits has_anime when not requested', () async {
        final List<dynamic> nodes =
            await captureFilters(() => api.browseVn(hasAnime: false));
        expect(nodes, isNot(anyElement(equals(<dynamic>['has_anime', '=', 1]))));
      });

      test('should handle ошибку ответа', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => makeResponse(
            <String, dynamic>{},
            statusCode: 500,
          ),
        );

        expect(
          () => api.browseVn(),
          throwsA(isA<VndbApiException>()),
        );
      });
    });

    group('getVnById', () {
      test('should return VN по ID', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => makeResponse(<String, dynamic>{
            'results': <dynamic>[vnJson(id: 'v2')],
          }),
        );

        final VisualNovel? vn = await api.getVnById('v2');

        expect(vn, isNotNull);
        expect(vn!.id, 'v2');
      });

      test('should return null для пустых результатов', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => makeResponse(<String, dynamic>{
            'results': <dynamic>[],
          }),
        );

        final VisualNovel? vn = await api.getVnById('v999999');

        expect(vn, isNull);
      });

      test('should handle ошибку ответа', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => makeResponse(
            <String, dynamic>{},
            statusCode: 404,
          ),
        );

        expect(
          () => api.getVnById('v1'),
          throwsA(isA<VndbApiException>()),
        );
      });
    });

    group('getVnByIds', () {
      test('should return пустой список для пустого массива', () async {
        final List<VisualNovel> results =
            await api.getVnByIds(<String>[]);
        expect(results, isEmpty);
      });

      test('должен загрузить несколько VN', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => makeResponse(<String, dynamic>{
            'results': <dynamic>[
              vnJson(id: 'v2', title: 'Kanon'),
              vnJson(id: 'v17', title: 'Ever17'),
            ],
          }),
        );

        final List<VisualNovel> results =
            await api.getVnByIds(<String>['v2', 'v17']);

        expect(results, hasLength(2));
      });

      test('should handle DioException', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          type: DioExceptionType.connectionError,
          requestOptions: RequestOptions(path: ''),
        ));

        try {
          await api.getVnByIds(<String>['v1']);
          fail('Should throw');
        } on VndbApiException catch (e) {
          expect(e.message, contains('internet'));
        }
      });
    });

    group('fetchTags', () {
      test('должен загрузить теги', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => makeResponse(<String, dynamic>{
            'results': <dynamic>[
              <String, dynamic>{'id': 'g7', 'name': 'Sci-fi'},
              <String, dynamic>{'id': 'g4', 'name': 'Romance'},
            ],
          }),
        );

        final List<VndbTag> tags = await api.fetchTags();

        expect(tags, hasLength(2));
        expect(tags.first.id, 'g7');
        expect(tags.first.name, 'Sci-fi');
      });

      test('должен отправить POST на /tag', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => makeResponse(<String, dynamic>{
            'results': <dynamic>[],
          }),
        );

        await api.fetchTags();

        verify(() => mockDio.post<dynamic>(
              'https://api.vndb.org/kana/tag',
              data: any(named: 'data'),
            )).called(1);
      });

      test('should handle ошибку ответа', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => makeResponse(
            <String, dynamic>{},
            statusCode: 500,
          ),
        );

        expect(
          () => api.fetchTags(),
          throwsA(isA<VndbApiException>()),
        );
      });
    });

    group('dispose', () {
      test('должен закрыть Dio клиент', () {
        when(() => mockDio.close()).thenReturn(null);
        api.dispose();
        verify(() => mockDio.close()).called(1);
      });
    });
  });
}
