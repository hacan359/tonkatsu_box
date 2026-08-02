import 'package:core/models/book.dart';
import 'package:core/models/book_kind.dart';
import 'package:core/models/data_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/hardcover_api.dart';

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

/// Typesense search document as the live API returns it (`id` is a string).
Map<String, dynamic> _document({String id = '312460'}) => <String, dynamic>{
      'id': id,
      'title': 'Dune',
      'description': 'A desert planet.',
      'release_year': 1965,
      'pages': 704,
      'author_names': <String>['Frank Herbert'],
      'isbns': <String>['0441013597', '9780441013593'],
      'genres': <String>['Science Fiction', 'Fiction'],
      'moods': <String>['adventurous'],
      'rating': 4.5,
      'ratings_count': 5837,
      'users_count': 13307,
      'slug': 'dune',
      'book_category_id': 1,
      'image': <String, dynamic>{
        'url': 'https://assets.hardcover.app/editions/1/dune.jpg',
      },
      'featured_series': <String, dynamic>{
        'position': 1.0,
        'series': <String, dynamic>{'name': 'Dune'},
      },
      'series_names': <String>['Dune', 'Dune Universe'],
    };

Map<String, dynamic> _searchBody(List<Map<String, dynamic>> docs,
        {int? found}) =>
    <String, dynamic>{
      'data': <String, dynamic>{
        'search': <String, dynamic>{
          'results': <String, dynamic>{
            'found': found ?? docs.length,
            'hits': <Map<String, dynamic>>[
              for (final Map<String, dynamic> doc in docs)
                <String, dynamic>{'document': doc},
            ],
          },
        },
      },
    };

/// Graph `book` object (`books_by_pk` / nested in `user_books`) — `id` is int.
Map<String, dynamic> _graphBook({int id = 312460}) => <String, dynamic>{
      'id': id,
      'title': 'Dune',
      'subtitle': null,
      'description': 'A desert planet.',
      'release_year': 1965,
      'pages': 704,
      'rating': 4.318,
      'ratings_count': 5837,
      'slug': 'dune',
      'book_category_id': 1,
      'cached_tags': <String, dynamic>{
        'Genre': <Map<String, dynamic>>[
          <String, dynamic>{'tag': 'Science Fiction'},
        ],
        'Mood': <Map<String, dynamic>>[
          <String, dynamic>{'tag': 'adventurous'},
        ],
      },
      'image': <String, dynamic>{
        'url': 'https://assets.hardcover.app/editions/1/dune.jpg',
      },
      'contributions': <Map<String, dynamic>>[
        <String, dynamic>{
          'author': <String, dynamic>{'name': 'Frank Herbert'},
        },
      ],
      'book_series': <Map<String, dynamic>>[
        <String, dynamic>{
          'position': 21,
          'series': <String, dynamic>{'name': 'Dune Universe'},
        },
        <String, dynamic>{
          'position': 1,
          'series': <String, dynamic>{'name': 'Dune'},
        },
      ],
      'default_physical_edition': <String, dynamic>{
        'isbn_10': '0441013597',
        'isbn_13': '9780441013593',
        'publisher': <String, dynamic>{'name': 'Penguin'},
        'language': <String, dynamic>{'code2': 'en'},
      },
    };

Map<String, dynamic> _userBookRow({
  int statusId = 3,
  double? rating = 4.5,
  int readCount = 1,
  bool owned = false,
  String? review,
  String? privateNotes,
  Map<String, dynamic>? book,
}) =>
    <String, dynamic>{
      'status_id': statusId,
      'rating': rating,
      'read_count': readCount,
      'first_started_reading_date': '2023-01-05',
      'first_read_date': '2023-02-01',
      'last_read_date': '2023-02-10',
      'date_added': '2022-12-31',
      'review': review,
      'private_notes': privateNotes,
      'owned': owned,
      'book': book ?? _graphBook(),
    };

void main() {
  late HardcoverApi sut;
  late MockDio mockDio;

  setUpAll(registerAllFallbacks);

  setUp(() {
    mockDio = MockDio();
    sut = HardcoverApi(dio: mockDio);
    sut.setApiKey('token');
  });

  tearDown(() => sut.dispose());

  /// All GraphQL calls hit one endpoint — dispatch stubs on a query substring.
  void stubGraph(Map<String, Map<String, dynamic>> bodyByNeedle) {
    when(() => mockDio.post<dynamic>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        )).thenAnswer((Invocation inv) async {
      final Map<String, dynamic> data =
          inv.namedArguments[#data] as Map<String, dynamic>;
      final String query = data['query'] as String;
      for (final MapEntry<String, Map<String, dynamic>> entry
          in bodyByNeedle.entries) {
        if (query.contains(entry.key)) return _resp(entry.value);
      }
      fail('Unexpected GraphQL query: $query');
    });
  }

  void stubThrows(DioException error) {
    when(() => mockDio.post<dynamic>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        )).thenThrow(error);
  }

  Map<String, dynamic> capturedVariables() {
    final Map<String, dynamic> data = verify(() => mockDio.post<dynamic>(
          any(),
          data: captureAny(named: 'data'),
          options: any(named: 'options'),
        )).captured.single as Map<String, dynamic>;
    return data['variables'] as Map<String, dynamic>;
  }

  group('searchBooks', () {
    test('maps a search document to a Book on the 0–10 scale', () async {
      stubGraph(<String, Map<String, dynamic>>{
        'search(': _searchBody(<Map<String, dynamic>>[_document()]),
      });

      final (List<Book> books, bool hasMore) = await sut.searchBooks('dune');

      expect(books, hasLength(1));
      final Book b = books.single;
      expect(b.id, '312460');
      expect(b.nativeId, '312460');
      expect(b.source, DataSource.hardcover);
      expect(b.kind, BookKind.book);
      expect(b.title, 'Dune');
      expect(b.authors, <String>['Frank Herbert']);
      expect(b.pageCount, 704);
      expect(b.publishYear, 1965);
      expect(b.rating, 9.0); // 4.5 * 2
      expect(b.ratingCount, 5837);
      expect(b.isbn10, '0441013597');
      expect(b.isbn13, '9780441013593');
      expect(b.subjects, containsAll(<String>['Science Fiction', 'adventurous']));
      expect(b.series, 'Dune');
      expect(b.coverUrl, 'https://assets.hardcover.app/editions/1/dune.jpg');
      expect(b.externalUrl, 'https://hardcover.app/id/book/312460');
      expect(hasMore, isFalse);
    });

    test('sends pagination and the sort pair, null sort for relevance',
        () async {
      stubGraph(<String, Map<String, dynamic>>{
        'search(': _searchBody(const <Map<String, dynamic>>[]),
      });

      await sut.searchBooks('dune', page: 3, sort: 'users_count:desc');

      final Map<String, dynamic> vars = capturedVariables();
      expect(vars['query'], 'dune');
      expect(vars['page'], 3);
      expect(vars['perPage'], HardcoverApi.searchPageSize);
      expect(vars['sort'], 'users_count:desc');
    });

    test('reports hasMore from a full page below the total', () async {
      final List<Map<String, dynamic>> docs = List<Map<String, dynamic>>
          .generate(25, (int i) => _document(id: '$i'));
      stubGraph(<String, Map<String, dynamic>>{
        'search(': _searchBody(docs, found: 789),
      });

      final (List<Book> books, bool hasMore) = await sut.searchBooks('dune');

      expect(books, hasLength(25));
      expect(hasMore, isTrue);
    });

    test('throws HardcoverAuthException when no token is set', () async {
      sut.clearApiKey();

      await expectLater(
        sut.searchBooks('dune'),
        throwsA(isA<HardcoverAuthException>()),
      );
      verifyNever(() => mockDio.post<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          ));
    });

    test('maps a 401 to HardcoverAuthException', () async {
      stubThrows(_dioError(401));
      await expectLater(
        sut.searchBooks('dune'),
        throwsA(isA<HardcoverAuthException>()),
      );
    });

    test('maps a 429 to HardcoverRateLimitException', () async {
      stubThrows(_dioError(429));
      await expectLater(
        sut.searchBooks('dune'),
        throwsA(isA<HardcoverRateLimitException>()),
      );
    });

    test('surfaces a GraphQL error message from a 200 body', () async {
      stubGraph(<String, Map<String, dynamic>>{
        'search(': <String, dynamic>{
          'errors': <Map<String, dynamic>>[
            <String, dynamic>{'message': 'query depth exceeded'},
          ],
        },
      });

      await expectLater(
        sut.searchBooks('dune'),
        throwsA(isA<HardcoverApiException>().having(
          (HardcoverApiException e) => e.message,
          'message',
          'query depth exceeded',
        )),
      );
    });
  });

  group('getBook', () {
    test('parses the graph book with edition, language and primary series',
        () async {
      stubGraph(<String, Map<String, dynamic>>{
        'books_by_pk': <String, dynamic>{
          'data': <String, dynamic>{'books_by_pk': _graphBook()},
        },
      });

      final Book? b = await sut.getBook('312460');

      expect(b, isNotNull);
      expect(b!.id, '312460');
      expect(b.source, DataSource.hardcover);
      expect(b.title, 'Dune');
      expect(b.publishers, <String>['Penguin']);
      expect(b.languages, <String>['en']);
      expect(b.isbn10, '0441013597');
      expect(b.isbn13, '9780441013593');
      expect(b.series, 'Dune', reason: 'lowest position wins');
      expect(b.subjects, containsAll(<String>['Science Fiction', 'adventurous']));
    });

    test('returns null when the book is missing', () async {
      stubGraph(<String, Map<String, dynamic>>{
        'books_by_pk': <String, dynamic>{
          'data': <String, dynamic>{'books_by_pk': null},
        },
      });

      expect(await sut.getBook('999'), isNull);
    });

    test('returns null for a non-numeric id without a request', () async {
      expect(await sut.getBook('abc'), isNull);
      verifyNever(() => mockDio.post<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          ));
    });
  });

  group('getEditions', () {
    test('parses editions with both image shapes and passes the book id',
        () async {
      stubGraph(<String, Map<String, dynamic>>{
        'EditionsByBook': <String, dynamic>{
          'data': <String, dynamic>{
            'editions': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 32753857,
                'book_id': 465829,
                'title': 'World of Warcraft: Перед бурей',
                'users_count': 1,
                'pages': 416,
                'isbn_10': '5171122857',
                'isbn_13': '9785171122850',
                'release_date': '2018-06-12',
                'language': <String, dynamic>{'code2': 'ru'},
                'publisher': <String, dynamic>{'name': 'АСТ'},
                'image': <String, dynamic>{
                  'url':
                      'https://assets.hardcover.app/editions/32753857/x.jpg',
                },
                'cached_image': null,
              },
              <String, dynamic>{
                'id': 30383507,
                'book_id': 465829,
                'title': 'World of Warcraft: Before the Storm',
                'users_count': 10,
                'pages': 304,
                'isbn_10': null,
                'isbn_13': null,
                'release_date': null,
                'language': null,
                'publisher': null,
                'image': null,
                'cached_image': <String, dynamic>{
                  'url':
                      'https://assets.hardcover.app/external_data/1/y.jpeg',
                },
              },
            ],
          },
        },
      });

      final List<HardcoverEdition> editions = await sut.getEditions('465829');

      expect(editions, hasLength(2));
      final HardcoverEdition ru = editions.first;
      expect(ru.id, 32753857);
      expect(ru.bookId, 465829);
      expect(ru.title, 'World of Warcraft: Перед бурей');
      expect(ru.languageCode, 'ru');
      expect(ru.publisher, 'АСТ');
      expect(ru.pages, 416);
      expect(ru.isbn13, '9785171122850');
      expect(ru.releaseYear, 2018);
      expect(ru.coverUrl,
          'https://assets.hardcover.app/editions/32753857/x.jpg');

      final HardcoverEdition en = editions.last;
      expect(en.languageCode, isNull);
      expect(en.releaseYear, isNull);
      expect(en.coverUrl,
          'https://assets.hardcover.app/external_data/1/y.jpeg',
          reason: 'cached_image backs a missing image relation');

      expect(capturedVariables()['bookId'], 465829);
    });

    test('returns empty for a non-numeric id without a request', () async {
      expect(await sut.getEditions('abc'), isEmpty);
      verifyNever(() => mockDio.post<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          ));
    });
  });

  group('getEdition', () {
    test('parses a single edition', () async {
      stubGraph(<String, Map<String, dynamic>>{
        'EditionById': <String, dynamic>{
          'data': <String, dynamic>{
            'editions_by_pk': <String, dynamic>{
              'id': 30426415,
              'book_id': 312460,
              'title': 'Dune',
              'users_count': 3965,
              'pages': 704,
              'isbn_10': null,
              'isbn_13': '9783423026185',
              'release_date': '1965-06-01',
              'language': <String, dynamic>{'code2': 'en'},
              'publisher': <String, dynamic>{'name': 'Penguin'},
              'image': <String, dynamic>{
                'url': 'https://assets.hardcover.app/editions/30426415/z.jpg',
              },
              'cached_image': null,
            },
          },
        },
      });

      final HardcoverEdition? edition = await sut.getEdition(30426415);

      expect(edition, isNotNull);
      expect(edition!.id, 30426415);
      expect(edition.bookId, 312460);
      expect(edition.languageCode, 'en');
      expect(edition.releaseYear, 1965);
      expect(edition.usersCount, 3965);
    });

    test('returns null when the edition is missing', () async {
      stubGraph(<String, Map<String, dynamic>>{
        'EditionById': <String, dynamic>{
          'data': <String, dynamic>{'editions_by_pk': null},
        },
      });

      expect(await sut.getEdition(1), isNull);
    });
  });

  group('validateApiKey', () {
    test('true when me returns the owner', () async {
      stubGraph(<String, Map<String, dynamic>>{
        'me {': <String, dynamic>{
          'data': <String, dynamic>{
            'me': <Map<String, dynamic>>[
              <String, dynamic>{'id': 128405, 'username': 'hacan'},
            ],
          },
        },
      });

      expect(await sut.validateApiKey('token'), isTrue);
    });

    test('false when me is empty', () async {
      stubGraph(<String, Map<String, dynamic>>{
        'me {': <String, dynamic>{
          'data': <String, dynamic>{'me': <Map<String, dynamic>>[]},
        },
      });

      expect(await sut.validateApiKey('token'), isFalse);
    });

    test('false on a 401', () async {
      stubThrows(_dioError(401));
      expect(await sut.validateApiKey('bad'), isFalse);
    });
  });

  group('fetchUserBooks', () {
    Map<String, dynamic> usersBody({bool found = true}) => <String, dynamic>{
          'data': <String, dynamic>{
            'users': found
                ? <Map<String, dynamic>>[
                    <String, dynamic>{'id': 1, 'username': 'adam'},
                  ]
                : <Map<String, dynamic>>[],
          },
        };

    Map<String, dynamic> countBody(int count) => <String, dynamic>{
          'data': <String, dynamic>{
            'user_books_aggregate': <String, dynamic>{
              'aggregate': <String, dynamic>{'count': count},
            },
          },
        };

    Map<String, dynamic> pageBody(List<Map<String, dynamic>> rows) =>
        <String, dynamic>{
          'data': <String, dynamic>{'user_books': rows},
        };

    test('parses entries with dates, rating and the nested book', () async {
      stubGraph(<String, Map<String, dynamic>>{
        'users(': usersBody(),
        'user_books_aggregate': countBody(1),
        'user_books(': pageBody(<Map<String, dynamic>>[
          _userBookRow(review: 'Great', privateNotes: 'mine', owned: true),
        ]),
      });

      final List<HardcoverUserBookEntry> entries =
          await sut.fetchUserBooks(username: 'adam');

      expect(entries, hasLength(1));
      final HardcoverUserBookEntry e = entries.single;
      expect(e.statusId, 3);
      expect(e.rating, 4.5);
      expect(e.readCount, 1);
      expect(e.firstStartedReadingDate, DateTime.parse('2023-01-05'));
      expect(e.lastReadDate, DateTime.parse('2023-02-10'));
      expect(e.dateAdded, DateTime.parse('2022-12-31'));
      expect(e.review, 'Great');
      expect(e.privateNotes, 'mine');
      expect(e.owned, isTrue);
      expect(e.book.id, '312460');
      expect(e.book.source, DataSource.hardcover);
    });

    test('skips rows without a nested book', () async {
      stubGraph(<String, Map<String, dynamic>>{
        'users(': usersBody(),
        'user_books_aggregate': countBody(2),
        'user_books(': pageBody(<Map<String, dynamic>>[
          <String, dynamic>{'status_id': 3, 'book': null},
          _userBookRow(),
        ]),
      });

      final List<HardcoverUserBookEntry> entries =
          await sut.fetchUserBooks(username: 'adam');

      expect(entries, hasLength(1));
    });

    test('throws HardcoverUserNotFoundException for an unknown username',
        () async {
      stubGraph(<String, Map<String, dynamic>>{
        'users(': usersBody(found: false),
      });

      await expectLater(
        sut.fetchUserBooks(username: 'nobody'),
        throwsA(isA<HardcoverUserNotFoundException>()),
      );
    });

    test('reports progress against the aggregate total', () async {
      stubGraph(<String, Map<String, dynamic>>{
        'users(': usersBody(),
        'user_books_aggregate': countBody(2),
        'user_books(': pageBody(<Map<String, dynamic>>[
          _userBookRow(),
          _userBookRow(book: _graphBook(id: 2)),
        ]),
      });

      final List<(int, int)> progress = <(int, int)>[];
      await sut.fetchUserBooks(
        username: 'adam',
        onProgress: (int fetched, int total) => progress.add((fetched, total)),
      );

      expect(progress, isNotEmpty);
      expect(progress.last, (2, 2));
    });
  });
}
