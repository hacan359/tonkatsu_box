import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/mangabaka_api.dart';
import 'package:tonkatsu_box/shared/models/manga.dart';
import 'package:tonkatsu_box/shared/models/mangabaka_tag.dart';

import '../../helpers/test_helpers.dart';

void main() {
  late MockDio mockDio;
  late MangaBakaApi api;

  setUpAll(registerAllFallbacks);

  setUp(() {
    mockDio = MockDio();
    api = MangaBakaApi(dio: mockDio);
  });

  Response<dynamic> makeResponse(dynamic data, {int statusCode = 200}) {
    return Response<dynamic>(
      data: data,
      statusCode: statusCode,
      requestOptions: RequestOptions(path: ''),
    );
  }

  void stubGet(Response<dynamic> response) {
    when(() => mockDio.get<dynamic>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        )).thenAnswer((_) async => response);
  }

  void stubGetThrows(DioException error) {
    when(() => mockDio.get<dynamic>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        )).thenThrow(error);
  }

  Map<String, dynamic> seriesJson({int id = 123, String title = 'Berserk'}) {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'rating': 9,
    };
  }

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

  group('MangaBakaApiException', () {
    test('toString formats message and status', () {
      const MangaBakaApiException exception =
          MangaBakaApiException('boom', statusCode: 429);
      expect(
        exception.toString(),
        'MangaBakaApiException: boom (status: 429)',
      );
    });
  });

  group('browseManga', () {
    test('returns parsed manga with hasMore and totalPages from pagination',
        () async {
      stubGet(makeResponse(<String, dynamic>{
        'data': <Map<String, dynamic>>[
          seriesJson(id: 1),
          seriesJson(id: 2),
        ],
        'pagination': <String, dynamic>{
          'next': 'https://api.mangabaka.org/v1/series/search?page=2',
          'count': 40,
          'limit': 20,
        },
      }));

      final (List<Manga> mangas, bool hasMore, int totalPages) =
          await api.browseManga(query: 'berserk');

      expect(mangas, hasLength(2));
      expect(mangas.first.id, 1);
      expect(hasMore, isTrue);
      expect(totalPages, 2);
    });

    test('skips malformed series rows rather than failing the page', () async {
      stubGet(makeResponse(<String, dynamic>{
        'data': <dynamic>[
          seriesJson(id: 1),
          <String, dynamic>{'title': 'missing id'},
          'not a map',
        ],
      }));

      final (List<Manga> mangas, bool _, int _) = await api.browseManga();

      expect(mangas, hasLength(1));
      expect(mangas.first.id, 1);
    });

    test('hasMore is false and totalPages floored to 1 without pagination',
        () async {
      stubGet(makeResponse(<String, dynamic>{
        'data': <Map<String, dynamic>>[seriesJson()],
      }));

      final (List<Manga> _, bool hasMore, int totalPages) =
          await api.browseManga();

      expect(hasMore, isFalse);
      expect(totalPages, 1);
    });

    test('maps 429 to a rate-limit MangaBakaApiException', () async {
      stubGetThrows(dioError(statusCode: 429));

      await expectLater(
        api.browseManga(query: 'x'),
        throwsA(isA<MangaBakaApiException>()
            .having((MangaBakaApiException e) => e.statusCode, 'statusCode', 429)
            .having((MangaBakaApiException e) => e.message, 'message',
                contains('Rate limit'))),
      );
    });
  });

  group('getById', () {
    test('returns the parsed series', () async {
      stubGet(makeResponse(<String, dynamic>{
        'data': seriesJson(id: 7, title: 'Vinland Saga'),
      }));

      final Manga? manga = await api.getById(7);

      expect(manga, isNotNull);
      expect(manga!.id, 7);
    });

    test('returns null when the payload has no series map', () async {
      stubGet(makeResponse(<String, dynamic>{'data': null}));

      expect(await api.getById(7), isNull);
    });

    test('returns null on 404', () async {
      stubGetThrows(dioError(statusCode: 404));

      expect(await api.getById(7), isNull);
    });

    test('throws MangaBakaApiException on a non-404 error', () async {
      stubGetThrows(dioError(type: DioExceptionType.connectionError));

      await expectLater(
        api.getById(7),
        throwsA(isA<MangaBakaApiException>()),
      );
    });
  });

  group('getRecommendations', () {
    test('unwraps the series object from each mix row', () async {
      stubGet(makeResponse(<String, dynamic>{
        'data': <Map<String, dynamic>>[
          <String, dynamic>{'series': seriesJson(id: 10)},
          <String, dynamic>{'series': seriesJson(id: 11)},
        ],
      }));

      final List<Manga> recs = await api.getRecommendations(1);

      expect(recs, hasLength(2));
      expect(recs.map((Manga m) => m.id), <int>[10, 11]);
    });

    test('excludes the seed series if it comes back in the results', () async {
      stubGet(makeResponse(<String, dynamic>{
        'data': <Map<String, dynamic>>[
          <String, dynamic>{'series': seriesJson(id: 5)},
          <String, dynamic>{'series': seriesJson(id: 6)},
        ],
      }));

      final List<Manga> recs = await api.getRecommendations(5);

      expect(recs.map((Manga m) => m.id), <int>[6]);
    });

    test('skips rows without a series map and malformed series', () async {
      stubGet(makeResponse(<String, dynamic>{
        'data': <dynamic>[
          <String, dynamic>{'series': seriesJson(id: 10)},
          <String, dynamic>{'series': 'not a map'},
          <String, dynamic>{'score': 0.5},
          <String, dynamic>{
            'series': <String, dynamic>{'title': 'missing id'}
          },
          'not a map',
        ],
      }));

      final List<Manga> recs = await api.getRecommendations(1);

      expect(recs, hasLength(1));
      expect(recs.first.id, 10);
    });

    test('returns an empty list when there is no data', () async {
      stubGet(makeResponse(<String, dynamic>{}));

      expect(await api.getRecommendations(1), isEmpty);
    });

    test('maps a 429 to a rate-limit MangaBakaApiException', () async {
      stubGetThrows(dioError(statusCode: 429));

      await expectLater(
        api.getRecommendations(1),
        throwsA(isA<MangaBakaApiException>()
            .having((MangaBakaApiException e) => e.statusCode, 'statusCode', 429)),
      );
    });
  });

  group('fetchTagCatalog', () {
    test('returns parsed tags', () async {
      stubGet(makeResponse(<String, dynamic>{
        'data': <Map<String, dynamic>>[
          <String, dynamic>{'id': 1, 'name': 'Action', 'is_genre': true},
          <String, dynamic>{'id': 2, 'name': 'Romance'},
        ],
      }));

      final List<MangaBakaTag> tags = await api.fetchTagCatalog();

      expect(tags, hasLength(2));
      expect(tags.first.name, 'Action');
      expect(tags.first.isGenre, isTrue);
    });

    test('skips malformed tag rows', () async {
      stubGet(makeResponse(<String, dynamic>{
        'data': <dynamic>[
          <String, dynamic>{'id': 1, 'name': 'Action'},
          <String, dynamic>{'name': 'missing id'},
          'not a map',
        ],
      }));

      final List<MangaBakaTag> tags = await api.fetchTagCatalog();

      expect(tags, hasLength(1));
      expect(tags.first.id, 1);
    });

    test('maps a timeout to MangaBakaApiException', () async {
      stubGetThrows(dioError(type: DioExceptionType.receiveTimeout));

      await expectLater(
        api.fetchTagCatalog(),
        throwsA(isA<MangaBakaApiException>().having(
            (MangaBakaApiException e) => e.message, 'message',
            contains('timeout'))),
      );
    });
  });
}
