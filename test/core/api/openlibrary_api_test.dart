import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/openlibrary_api.dart';
import 'package:tonkatsu_box/shared/models/book.dart';

import '../../helpers/test_helpers.dart';

Response<dynamic> _ok(Map<String, dynamic> data) => Response<dynamic>(
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
  late OpenLibraryApi sut;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    sut = OpenLibraryApi(dio: mockDio);
  });

  tearDown(() => sut.dispose());

  void stubSearch(Map<String, dynamic> body) {
    when(() => mockDio.get<dynamic>(
          '/search.json',
          queryParameters: any(named: 'queryParameters'),
        )).thenAnswer((_) async => _ok(body));
  }

  group('OpenLibraryApiException', () {
    test('toString includes message and status', () {
      const OpenLibraryApiException e =
          OpenLibraryApiException('Boom', statusCode: 429);
      expect(e.toString(),
          'OpenLibraryApiException: Boom (status: 429)');
    });
  });

  group('search', () {
    test('parses docs into books with rich fields', () async {
      stubSearch(<String, dynamic>{
        'numFound': 1,
        'docs': <Map<String, dynamic>>[
          <String, dynamic>{
            'key': '/works/OL27448W',
            'title': 'The Lord of the Rings',
            'author_name': <String>['J.R.R. Tolkien'],
            'first_publish_year': 1954,
            'cover_i': 14625765,
            'ratings_average': 4.5,
            'ratings_count': 10,
            'subject': <String>['Fantasy fiction'],
            'number_of_pages_median': 500,
          },
        ],
      });

      final (List<Book> books, bool hasMore, int totalPages) =
          await sut.search(query: 'lord of the rings');

      expect(books, hasLength(1));
      expect(books.single.id, '27448');
      expect(books.single.rating, closeTo(9.0, 0.0001));
      expect(books.single.pageCount, 500);
      expect(hasMore, isFalse);
      expect(totalPages, 1);
    });

    test('reports more pages when numFound exceeds the page size', () async {
      stubSearch(<String, dynamic>{'numFound': 100, 'docs': <dynamic>[]});
      final (_, bool hasMore, int totalPages) =
          await sut.search(query: 'dune', perPage: 20);
      expect(hasMore, isTrue);
      expect(totalPages, 5);
    });

    test('routes the query to the chosen scope field', () async {
      stubSearch(<String, dynamic>{'numFound': 0, 'docs': <dynamic>[]});

      await sut.search(query: 'tolkien', scope: 'author');

      final Map<String, dynamic> qp = verify(() => mockDio.get<dynamic>(
            '/search.json',
            queryParameters: captureAny(named: 'queryParameters'),
          )).captured.single as Map<String, dynamic>;
      expect(qp.containsKey('author'), isTrue);
      expect(qp.containsKey('q'), isFalse);
    });

    test('falls back to q for an unknown scope', () async {
      stubSearch(<String, dynamic>{'numFound': 0, 'docs': <dynamic>[]});
      await sut.search(query: 'x', scope: 'bogus');
      final Map<String, dynamic> qp = verify(() => mockDio.get<dynamic>(
            '/search.json',
            queryParameters: captureAny(named: 'queryParameters'),
          )).captured.single as Map<String, dynamic>;
      expect(qp.containsKey('q'), isTrue);
    });

    test('includes language and sort only when set', () async {
      stubSearch(<String, dynamic>{'numFound': 0, 'docs': <dynamic>[]});
      await sut.search(query: 'x', language: 'rus', sort: 'rating');
      final Map<String, dynamic> qp = verify(() => mockDio.get<dynamic>(
            '/search.json',
            queryParameters: captureAny(named: 'queryParameters'),
          )).captured.single as Map<String, dynamic>;
      expect(qp['language'], 'rus');
      expect(qp['sort'], 'rating');
    });

    test('maps a Dio error to OpenLibraryApiException', () async {
      when(() => mockDio.get<dynamic>(
            '/search.json',
            queryParameters: any(named: 'queryParameters'),
          )).thenThrow(_dioError(429));

      await expectLater(
        sut.search(query: 'x'),
        throwsA(isA<OpenLibraryApiException>().having(
          (OpenLibraryApiException e) => e.statusCode,
          'statusCode',
          429,
        )),
      );
    });
  });

  group('getWork', () {
    test('combines work, ratings and resolved author names', () async {
      when(() => mockDio.get<dynamic>(
            '/works/OL27448W.json',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => _ok(<String, dynamic>{
            'key': '/works/OL27448W',
            'title': 'The Lord of the Rings',
            'description': 'An epic.',
            'authors': <Map<String, dynamic>>[
              <String, dynamic>{
                'author': <String, dynamic>{'key': '/authors/OL26320A'},
              },
            ],
          }));
      when(() => mockDio.get<dynamic>(
            '/works/OL27448W/ratings.json',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => _ok(<String, dynamic>{
            'summary': <String, dynamic>{'average': 4.0, 'count': 7},
          }));
      when(() => mockDio.get<dynamic>(
            '/authors/OL26320A.json',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async =>
              _ok(<String, dynamic>{'name': 'J.R.R. Tolkien'}));

      final Book? book = await sut.getWork('OL27448W');
      expect(book, isNotNull);
      expect(book!.description, 'An epic.');
      expect(book.rating, closeTo(8.0, 0.0001));
      expect(book.authors, <String>['J.R.R. Tolkien']);
    });

    test('returns null on 404', () async {
      when(() => mockDio.get<dynamic>(
            '/works/OL999W.json',
            queryParameters: any(named: 'queryParameters'),
          )).thenThrow(_dioError(404));
      expect(await sut.getWork('OL999W'), isNull);
    });
  });
}
