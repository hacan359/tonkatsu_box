import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/fantlab_api.dart';
import 'package:tonkatsu_box/shared/models/book.dart';
import 'package:tonkatsu_box/shared/models/data_source.dart';

import '../../helpers/test_helpers.dart';

Response<dynamic> _ok(Object? data) => Response<dynamic>(
      data: data,
      statusCode: 200,
      requestOptions: RequestOptions(),
    );

DioException _dioError(int statusCode) => DioException(
      requestOptions: RequestOptions(),
      response: Response<dynamic>(
        statusCode: statusCode,
        requestOptions: RequestOptions(),
      ),
      type: DioExceptionType.badResponse,
    );

void main() {
  late FantlabApi sut;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    sut = FantlabApi(dio: mockDio);
  });

  tearDown(() => sut.dispose());

  void stubGet(String path, Object? data) {
    when(() => mockDio.get<dynamic>(
          path,
          queryParameters: any(named: 'queryParameters'),
        )).thenAnswer((_) async => _ok(data));
  }

  Map<String, dynamic> solarisMatch() => <String, dynamic>{
        'work_id': 3104,
        'rusname': 'Солярис',
        'name': 'Solaris',
        'name_eng': 'novel',
        'name_show_im': 'роман',
        'year': 1961,
        'pic_edition_id': 24724,
        'midmark_by_weight': <double>[8.62],
        'markcount': 9026,
        'autor1_rusname': 'Станислав Лем',
      };

  group('FantlabApiException', () {
    test('toString includes message and status', () {
      const FantlabApiException e =
          FantlabApiException('Boom', statusCode: 429);
      expect(e.toString(), 'FantlabApiException: Boom (status: 429)');
    });
  });

  group('searchWorks', () {
    test('parses matches into Fantlab books', () async {
      stubGet('/search-works', <String, dynamic>{
        'matches': <Map<String, dynamic>>[solarisMatch()],
        'total_found': 1,
      });

      final (List<Book> books, bool hasMore, int totalPages) =
          await sut.searchWorks(query: 'солярис');

      expect(books, hasLength(1));
      expect(books.single.id, '3104');
      expect(books.single.source, DataSource.fantlab);
      expect(books.single.title, 'Солярис');
      expect(hasMore, isFalse);
      expect(totalPages, 1);
    });

    test('accepts the bare matches array (onlymatches=1 shape)', () async {
      stubGet('/search-works', <Map<String, dynamic>>[solarisMatch()]);
      final (List<Book> books, _, _) = await sut.searchWorks(query: 'x');
      expect(books, hasLength(1));
    });

    test('decodes a raw JSON string body (ResponseType.plain transport)',
        () async {
      // Fantlab's malformed content-type makes Dio return the body as a String;
      // the client must still parse it.
      stubGet(
        '/search-works',
        jsonEncode(<String, dynamic>{
          'matches': <Map<String, dynamic>>[solarisMatch()],
          'total_found': 1,
        }),
      );
      final (List<Book> books, _, _) = await sut.searchWorks(query: 'солярис');
      expect(books, hasLength(1));
      expect(books.single.id, '3104');
    });

    test('drops non-book types (reviews / interviews)', () async {
      stubGet('/search-works', <String, dynamic>{
        'matches': <Map<String, dynamic>>[
          solarisMatch(),
          <String, dynamic>{
            'work_id': 922274,
            'rusname': 'Контакт',
            'name_eng': 'review',
          },
        ],
        'total_found': 2,
      });
      final (List<Book> books, _, _) = await sut.searchWorks(query: 'x');
      expect(books, hasLength(1));
      expect(books.single.id, '3104');
    });

    test('workType keeps only matches of that name_eng', () async {
      stubGet('/search-works', <String, dynamic>{
        'matches': <Map<String, dynamic>>[
          solarisMatch(),
          <String, dynamic>{
            'work_id': 3119,
            'rusname': 'Маска',
            'name_eng': 'shortstory',
            'name_show_im': 'рассказ',
          },
        ],
        'total_found': 2,
      });
      final (List<Book> books, _, _) =
          await sut.searchWorks(query: 'лем', workType: 'novel');
      expect(books, hasLength(1));
      expect(books.single.id, '3104');
    });

    test('reports more pages from total_found and the 25/page size', () async {
      stubGet('/search-works', <String, dynamic>{
        'matches': <Map<String, dynamic>>[solarisMatch()],
        'total_found': 100,
      });
      final (_, bool hasMore, int totalPages) =
          await sut.searchWorks(query: 'lem', page: 1);
      expect(hasMore, isTrue);
      expect(totalPages, 4);
    });

    test('caps the reachable result set at 1000', () async {
      stubGet('/search-works', <String, dynamic>{
        'matches': <Map<String, dynamic>>[solarisMatch()],
        'total_found': 999999,
      });
      final (_, _, int totalPages) = await sut.searchWorks(query: 'x');
      expect(totalPages, 40);
    });

    test('maps a Dio error to FantlabApiException', () async {
      when(() => mockDio.get<dynamic>(
            '/search-works',
            queryParameters: any(named: 'queryParameters'),
          )).thenThrow(_dioError(429));

      await expectLater(
        sut.searchWorks(query: 'x'),
        throwsA(isA<FantlabApiException>().having(
          (FantlabApiException e) => e.statusCode,
          'statusCode',
          429,
        )),
      );
    });
  });

  group('getWork', () {
    test('builds a full book from the extended response', () async {
      stubGet('/work/3104/extended', <String, dynamic>{
        'work_id': 3104,
        'work_name': 'Солярис',
        'work_name_orig': 'Solaris',
        'work_description': '[b]Plot[/b]',
        'work_type': 'Роман',
        'work_year': 1961,
        'rating': <String, dynamic>{'rating': '8.62', 'voters': 9026},
      });

      final Book? book = await sut.getWork('3104');
      expect(book, isNotNull);
      expect(book!.title, 'Солярис');
      expect(book.description, 'Plot');
      expect(book.rating, closeTo(8.62, 0.0001));
    });

    test('returns null on 404', () async {
      when(() => mockDio.get<dynamic>(
            '/work/999/extended',
            queryParameters: any(named: 'queryParameters'),
          )).thenThrow(_dioError(404));
      expect(await sut.getWork('999'), isNull);
    });

    test('returns null when the payload carries no work id', () async {
      stubGet('/work/0/extended', <String, dynamic>{'error': 'not found'});
      expect(await sut.getWork('0'), isNull);
    });

    test('decodes a raw JSON string body', () async {
      stubGet(
        '/work/3104/extended',
        jsonEncode(<String, dynamic>{
          'work_id': 3104,
          'work_name': 'Солярис',
        }),
      );
      final Book? book = await sut.getWork('3104');
      expect(book?.title, 'Солярис');
    });

    test('tolerates work_id arriving as an array', () async {
      stubGet('/work/3104/extended', <String, dynamic>{
        'work_id': <int>[3104],
        'work_name': 'Солярис',
      });
      final Book? book = await sut.getWork('3104');
      expect(book, isNotNull);
      expect(book!.id, '3104');
    });
  });

  group('getSimilars', () {
    test('parses the similars array', () async {
      stubGet('/work/3104/similars', <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 134421,
          'name': 'Ложная слепота',
          'name_type': 'роман',
          'year': 2006,
          'stat': <String, dynamic>{'rating': '7.87', 'voters': 5573},
        },
      ]);

      final List<Book> similars = await sut.getSimilars('3104');
      expect(similars, hasLength(1));
      expect(similars.single.id, '134421');
      expect(similars.single.title, 'Ложная слепота');
      expect(similars.single.source, DataSource.fantlab);
    });

    test('returns empty on 404', () async {
      when(() => mockDio.get<dynamic>(
            '/work/999/similars',
            queryParameters: any(named: 'queryParameters'),
          )).thenThrow(_dioError(404));
      expect(await sut.getSimilars('999'), isEmpty);
    });

    test('returns empty when the payload is not a list', () async {
      stubGet('/work/3104/similars', <String, dynamic>{'unexpected': true});
      expect(await sut.getSimilars('3104'), isEmpty);
    });
  });

  group('getEditions', () {
    test('parses editions_blocks into grouped editions', () async {
      stubGet('/work/3104/extended', <String, dynamic>{
        'work_id': 3104,
        'editions_blocks': <String, dynamic>{
          '10': <String, dynamic>{
            'title': 'Издания',
            'list': <dynamic>[
              <String, dynamic>{
                'edition_id': 24724,
                'name': 'Солярис',
                'year': 1992,
                'lang_code': 'ru',
                'pic_num': 1,
              },
            ],
          },
        },
      });

      final List<FantlabEditionBlock> blocks = await sut.getEditions('3104');

      expect(blocks, hasLength(1));
      expect(blocks.first.title, 'Издания');
      expect(blocks.first.editions.single.editionId, 24724);
    });

    test('returns empty on 404', () async {
      when(() => mockDio.get<dynamic>(
            '/work/999/extended',
            queryParameters: any(named: 'queryParameters'),
          )).thenThrow(_dioError(404));
      expect(await sut.getEditions('999'), isEmpty);
    });

    test('returns empty when editions_blocks is absent', () async {
      stubGet('/work/3104/extended', <String, dynamic>{'work_id': 3104});
      expect(await sut.getEditions('3104'), isEmpty);
    });
  });
}
