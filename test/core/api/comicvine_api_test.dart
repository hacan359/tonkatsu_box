import 'package:core/models/book.dart';
import 'package:core/models/book_kind.dart';
import 'package:core/models/data_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/comicvine_api.dart';

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

Map<String, dynamic> _volume({int id = 796}) => <String, dynamic>{
      'id': id,
      'name': 'Batman',
      'start_year': '1940',
      'count_of_issues': 716,
      'publisher': <String, dynamic>{'id': 10, 'name': 'DC Comics'},
      'image': <String, dynamic>{
        'medium_url': 'https://cv/medium.jpg',
        'super_url': 'https://cv/super.jpg',
      },
      'site_detail_url': 'https://comicvine.gamespot.com/batman/4050-$id/',
      'description': '<p>The Dark Knight.</p>',
    };

void main() {
  late ComicVineApi sut;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    sut = ComicVineApi(dio: mockDio)..setApiKey('test-key');
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

  group('ComicVineApiException', () {
    test('toString includes the message', () {
      const ComicVineApiException e =
          ComicVineApiException('Boom', statusCode: 420);
      expect(e.toString(), 'ComicVineApiException: Boom');
    });
  });

  group('searchVolumes', () {
    test('maps results to comic-kind books', () async {
      stub('/search/', <String, dynamic>{
        'status_code': 1,
        'results': <Map<String, dynamic>>[_volume()],
      });

      final List<Book> books = await sut.searchVolumes('batman');

      expect(books, hasLength(1));
      final Book b = books.single;
      expect(b.id, '796');
      expect(b.source, DataSource.comicVine);
      expect(b.kind, BookKind.comic);
      expect(b.nativeId, '4050-796');
      expect(b.pageCount, 716);
      expect(b.publishYear, 1940);
      expect(b.coverUrl, 'https://cv/medium.jpg');
      expect(b.description, 'The Dark Knight.');
    });

    test('throws when the API key is not set', () async {
      final ComicVineApi noKey = ComicVineApi(dio: mockDio);
      await expectLater(
        noKey.searchVolumes('batman'),
        throwsA(isA<ComicVineApiException>()),
      );
    });

    test('throws on a non-OK status_code envelope', () async {
      stub('/search/', <String, dynamic>{
        'status_code': 100,
        'error': 'Invalid API Key',
      });
      await expectLater(
        sut.searchVolumes('batman'),
        throwsA(isA<ComicVineApiException>().having(
          (ComicVineApiException e) => e.message,
          'message',
          'Invalid API Key',
        )),
      );
    });

    test('maps a Dio 420 to an invalid-key message', () async {
      stubThrows('/search/', _dioError(420));
      await expectLater(
        sut.searchVolumes('batman'),
        throwsA(isA<ComicVineApiException>().having(
          (ComicVineApiException e) => e.message,
          'message',
          contains('Invalid'),
        )),
      );
    });
  });

  group('browseVolumes', () {
    test('reports hasMore from the total count', () async {
      stub('/volumes/', <String, dynamic>{
        'status_code': 1,
        'number_of_total_results': 100,
        'results': <Map<String, dynamic>>[_volume(id: 1), _volume(id: 2)],
      });

      final (List<Book> books, bool hasMore) =
          await sut.browseVolumes(page: 1, perPage: 2);

      expect(books, hasLength(2));
      expect(hasMore, isTrue);
    });

    test('hasMore is false on the last page', () async {
      stub('/volumes/', <String, dynamic>{
        'status_code': 1,
        'number_of_total_results': 2,
        'results': <Map<String, dynamic>>[_volume(id: 1), _volume(id: 2)],
      });

      final (List<Book> _, bool hasMore) =
          await sut.browseVolumes(page: 1, perPage: 24);

      expect(hasMore, isFalse);
    });

    test('sends name filter, sort and offset for the sorted path', () async {
      stub('/volumes/', <String, dynamic>{
        'status_code': 1,
        'number_of_total_results': 1,
        'results': <Map<String, dynamic>>[_volume()],
      });

      await sut.browseVolumes(
        nameFilter: '  batman  ',
        sort: 'name:asc',
        page: 3,
        perPage: 24,
      );

      final Map<String, dynamic> q = verify(() => mockDio.get<dynamic>(
            '/volumes/',
            queryParameters: captureAny(named: 'queryParameters'),
          )).captured.single as Map<String, dynamic>;
      expect(q['filter'], 'name:batman'); // trimmed
      expect(q['sort'], 'name:asc');
      expect(q['offset'], 48); // (3 - 1) * 24
    });

    test('omits filter and sort when blank', () async {
      stub('/volumes/', <String, dynamic>{
        'status_code': 1,
        'number_of_total_results': 0,
        'results': <Map<String, dynamic>>[],
      });

      await sut.browseVolumes(sort: '');

      final Map<String, dynamic> q = verify(() => mockDio.get<dynamic>(
            '/volumes/',
            queryParameters: captureAny(named: 'queryParameters'),
          )).captured.single as Map<String, dynamic>;
      expect(q.containsKey('filter'), isFalse);
      expect(q.containsKey('sort'), isFalse);
    });
  });

  group('getVolume', () {
    test('parses the single results object', () async {
      stub('/volume/4050-796/', <String, dynamic>{
        'status_code': 1,
        'results': _volume(),
      });

      final Book? b = await sut.getVolume('4050-796');

      expect(b, isNotNull);
      expect(b!.title, 'Batman');
      expect(b.kind, BookKind.comic);
    });

    test('maps the volume people to authors', () async {
      final Map<String, dynamic> v = _volume()
        ..['people'] = <Map<String, dynamic>>[
          <String, dynamic>{'name': 'Bob Kane'},
          <String, dynamic>{'name': 'Bill Finger'},
        ];
      stub('/volume/4050-796/', <String, dynamic>{
        'status_code': 1,
        'results': v,
      });

      final Book? b = await sut.getVolume('4050-796');

      expect(b!.authors, <String>['Bob Kane', 'Bill Finger']);
    });

    test('returns null when results is not an object', () async {
      stub('/volume/4050-1/', <String, dynamic>{
        'status_code': 1,
        'results': <dynamic>[],
      });

      expect(await sut.getVolume('4050-1'), isNull);
    });

    test('falls back to the first issue synopsis on an empty description',
        () async {
      final Map<String, dynamic> v = _volume()
        ..remove('description')
        ..['first_issue'] = <String, dynamic>{'id': 99};
      stub('/volume/4050-796/',
          <String, dynamic>{'status_code': 1, 'results': v});
      stub('/issue/4000-99/', <String, dynamic>{
        'status_code': 1,
        'results': <String, dynamic>{
          'description': '<p>Issue one synopsis.</p>',
        },
      });

      final Book? b = await sut.getVolume('4050-796');

      expect(b!.description, 'Issue one synopsis.');
    });

    test('leaves description null when volume and first issue are both empty',
        () async {
      final Map<String, dynamic> v = _volume()..remove('description');
      stub('/volume/4050-796/',
          <String, dynamic>{'status_code': 1, 'results': v});

      final Book? b = await sut.getVolume('4050-796');

      expect(b!.description, isNull);
    });
  });

  group('validateApiKey', () {
    test('true when the envelope is OK', () async {
      stub('/search/', <String, dynamic>{
        'status_code': 1,
        'results': <dynamic>[],
      });
      expect(await sut.validateApiKey('k'), isTrue);
    });

    test('false on a Dio error', () async {
      stubThrows('/search/', _dioError(401));
      expect(await sut.validateApiKey('k'), isFalse);
    });
  });
}
