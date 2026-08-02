import 'package:core/models/book.dart';
import 'package:core/models/book_kind.dart';
import 'package:core/models/data_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/google_books_api.dart';

import '../../helpers/test_helpers.dart';

Response<dynamic> _resp(Map<String, dynamic> data, {int status = 200}) =>
    Response<dynamic>(
      data: data,
      statusCode: status,
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

Map<String, dynamic> _volume({String id = 'vol1'}) => <String, dynamic>{
      'id': id,
      'volumeInfo': <String, dynamic>{
        'title': 'Dune',
        'authors': <String>['Frank Herbert'],
        'publisher': 'Ace',
        'publishedDate': '1965-08-01',
        'description': '<p>A desert planet.</p>',
        'industryIdentifiers': <Map<String, dynamic>>[
          <String, dynamic>{'type': 'ISBN_13', 'identifier': '9780441013593'},
          <String, dynamic>{'type': 'ISBN_10', 'identifier': '0441013597'},
        ],
        'pageCount': 412,
        'categories': <String>['Fiction'],
        'averageRating': 4.5,
        'ratingsCount': 100,
        'imageLinks': <String, dynamic>{
          'thumbnail': 'http://books.google.com/thumb?zoom=1&edge=curl',
          'large': 'http://books.google.com/large?zoom=1&edge=curl',
        },
        'language': 'en',
        'infoLink': 'https://books.google.com/info',
      },
    };

void main() {
  late GoogleBooksApi sut;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    sut = GoogleBooksApi(dio: mockDio);
  });

  tearDown(() => sut.dispose());

  void stub(String path, Map<String, dynamic> body, {int status = 200}) {
    when(() => mockDio.get<dynamic>(
          path,
          queryParameters: any(named: 'queryParameters'),
        )).thenAnswer((_) async => _resp(body, status: status));
  }

  void stubThrows(String path, DioException error) {
    when(() => mockDio.get<dynamic>(
          path,
          queryParameters: any(named: 'queryParameters'),
        )).thenThrow(error);
  }

  group('GoogleBooksApiException', () {
    test('toString includes the message', () {
      const GoogleBooksApiException e =
          GoogleBooksApiException('Boom', statusCode: 400);
      expect(e.toString(), 'GoogleBooksApiException: Boom');
    });
  });

  group('searchVolumes', () {
    test('maps a volume to a book on the 0–10 scale with the largest cover',
        () async {
      stub('/volumes', <String, dynamic>{
        'totalItems': 1,
        'items': <Map<String, dynamic>>[_volume()],
      });

      final (List<Book> books, bool hasMore) = await sut.searchVolumes('dune');

      expect(books, hasLength(1));
      final Book b = books.single;
      expect(b.id, fnv1a64('vol1').toString());
      expect(b.source, DataSource.googleBooks);
      expect(b.kind, BookKind.book);
      expect(b.nativeId, 'vol1');
      expect(b.pageCount, 412);
      expect(b.publishYear, 1965);
      expect(b.rating, 9.0); // 4.5 * 2
      expect(b.isbn13, '9780441013593');
      expect(b.isbn10, '0441013597');
      expect(b.description, 'A desert planet.');
      // Thumbnail variant (larger sizes can be page scans), curled-corner
      // overlay removed, scheme upgraded, fife upscale appended.
      expect(b.coverUrl, 'https://books.google.com/thumb?zoom=1&fife=w800');
      expect(hasMore, isFalse);
    });

    test('reports hasMore from a full page below the total', () async {
      stub('/volumes', <String, dynamic>{
        'totalItems': 100,
        'items': <Map<String, dynamic>>[_volume(id: 'a'), _volume(id: 'b')],
      });

      final (List<Book> _, bool hasMore) =
          await sut.searchVolumes('dune', maxResults: 2);

      expect(hasMore, isTrue);
    });

    test('hasMore is false on the last page', () async {
      stub('/volumes', <String, dynamic>{
        'totalItems': 2,
        'items': <Map<String, dynamic>>[_volume(id: 'a'), _volume(id: 'b')],
      });

      final (List<Book> _, bool hasMore) =
          await sut.searchVolumes('dune', maxResults: 2);

      expect(hasMore, isFalse);
    });

    test('empty when the catalog returns no items', () async {
      stub('/volumes', <String, dynamic>{'totalItems': 0});

      final (List<Book> books, bool hasMore) = await sut.searchVolumes('zzz');

      expect(books, isEmpty);
      expect(hasMore, isFalse);
    });

    test('sends params, clamps maxResults to 40, omits the key when unset',
        () async {
      stub('/volumes', <String, dynamic>{'totalItems': 0});

      await sut.searchVolumes(
        'dune',
        startIndex: 40,
        maxResults: 100,
        orderBy: 'newest',
        langRestrict: 'ru',
        printType: 'books',
      );

      final Map<String, dynamic> q = verify(() => mockDio.get<dynamic>(
            '/volumes',
            queryParameters: captureAny(named: 'queryParameters'),
          )).captured.single as Map<String, dynamic>;
      expect(q['q'], 'dune');
      expect(q['startIndex'], 40);
      expect(q['maxResults'], 40); // clamped to maxPageSize
      expect(q['orderBy'], 'newest');
      expect(q['langRestrict'], 'ru');
      expect(q['printType'], 'books');
      expect(q.containsKey('key'), isFalse);
    });

    test('sends the key when one is set', () async {
      sut.setApiKey('test-key');
      stub('/volumes', <String, dynamic>{'totalItems': 0});

      await sut.searchVolumes('dune');

      final Map<String, dynamic> q = verify(() => mockDio.get<dynamic>(
            '/volumes',
            queryParameters: captureAny(named: 'queryParameters'),
          )).captured.single as Map<String, dynamic>;
      expect(q['key'], 'test-key');
    });

    test('maps a Dio 400 to an invalid-request message', () async {
      stubThrows('/volumes', _dioError(400));
      await expectLater(
        sut.searchVolumes('dune'),
        throwsA(isA<GoogleBooksApiException>().having(
          (GoogleBooksApiException e) => e.message,
          'message',
          contains('Invalid'),
        )),
      );
    });

    test('maps a Dio 429 to a quota message', () async {
      stubThrows('/volumes', _dioError(429));
      await expectLater(
        sut.searchVolumes('dune'),
        throwsA(isA<GoogleBooksApiException>().having(
          (GoogleBooksApiException e) => e.message,
          'message',
          contains('quota'),
        )),
      );
    });
  });

  group('getVolume', () {
    test('parses the volume object', () async {
      stub('/volumes/vol1', _volume());

      final Book? b = await sut.getVolume('vol1');

      expect(b, isNotNull);
      expect(b!.title, 'Dune');
      expect(b.nativeId, 'vol1');
      expect(b.kind, BookKind.book);
    });

    test('returns null when the id is missing', () async {
      stub('/volumes/vol1', <String, dynamic>{
        'volumeInfo': <String, dynamic>{'title': 'Dune'},
      });

      expect(await sut.getVolume('vol1'), isNull);
    });
  });

  group('validateApiKey', () {
    test('true on a 200 response', () async {
      stub('/volumes', <String, dynamic>{'totalItems': 1});
      expect(await sut.validateApiKey('k'), isTrue);
    });

    test('false on a Dio error', () async {
      stubThrows('/volumes', _dioError(400));
      expect(await sut.validateApiKey('k'), isFalse);
    });
  });
}
