// Тесты для клиента VNDB API

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/core/api/vndb_api.dart';
import 'package:xerabora/shared/models/visual_novel.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late VndbApi api;

  setUp(() {
    mockDio = MockDio();
    api = VndbApi(dio: mockDio);
  });

  group('VndbApiException', () {
    test('должен содержать message и statusCode', () {
      const VndbApiException exception =
          VndbApiException('test', statusCode: 429);
      expect(exception.message, 'test');
      expect(exception.statusCode, 429);
    });

    test('toString должен форматировать сообщение', () {
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
      test('должен вернуть пустой список для пустого запроса', () async {
        final (List<VisualNovel> results, bool hasMore) =
            await api.searchVn(query: '');
        expect(results, isEmpty);
        expect(hasMore, isFalse);
      });

      test('должен вернуть пустой список для запроса из пробелов', () async {
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

      test('должен обработать rate limit (429)', () async {
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
      test('должен вернуть результаты с totalPages', () async {
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

      test('должен использовать tagId в фильтрах', () async {
        Map<String, dynamic>? capturedData;
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((Invocation inv) async {
          capturedData =
              inv.namedArguments[const Symbol('data')] as Map<String, dynamic>?;
          return makeResponse(<String, dynamic>{
            'results': <dynamic>[],
            'more': false,
            'count': 0,
          });
        });

        await api.browseVn(tagId: 'g7');

        expect(capturedData, isNotNull);
        final dynamic filters = capturedData!['filters'];
        expect(filters, isA<List<dynamic>>());
        // Should be ['and', ['tag', '=', 'g7'], ['votecount', '>=', 10]]
        final List<dynamic> filterList = filters as List<dynamic>;
        expect(filterList.first, 'and');
      });

      test('должен обработать ошибку ответа', () async {
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
      test('должен вернуть VN по ID', () async {
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

      test('должен вернуть null для пустых результатов', () async {
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

      test('должен обработать ошибку ответа', () async {
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
      test('должен вернуть пустой список для пустого массива', () async {
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

      test('должен обработать DioException', () async {
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

      test('должен обработать ошибку ответа', () async {
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
