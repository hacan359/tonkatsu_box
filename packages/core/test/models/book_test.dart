import 'package:core/models/book.dart';
import 'package:core/models/book_kind.dart';
import 'package:core/models/data_source.dart';
import 'package:test/test.dart';

import 'package:core/testing/builders.dart';

void main() {
  group('Book', () {
    group('fromComicVineVolume', () {
      Map<String, dynamic> volume() => <String, dynamic>{
            'id': 796,
            'name': 'Batman',
            'start_year': '1940',
            'count_of_issues': 716,
            'publisher': <String, dynamic>{'id': 10, 'name': 'DC Comics'},
            'image': <String, dynamic>{
              'medium_url': 'https://cv/medium.jpg',
              'super_url': 'https://cv/super.jpg',
            },
            'site_detail_url':
                'https://comicvine.gamespot.com/batman/4050-796/',
            'description': '<p>The <b>Dark Knight</b>.</p>',
          };

      test('maps a volume to a comic-kind book', () {
        final Book book = Book.fromComicVineVolume(volume());
        expect(book.id, '796');
        expect(book.source, DataSource.comicVine);
        expect(book.kind, BookKind.comic);
        expect(book.nativeId, '4050-796');
        expect(book.title, 'Batman');
        expect(book.publishYear, 1940);
        expect(book.pageCount, 716); // count_of_issues
        expect(book.publishers, <String>['DC Comics']);
        expect(book.coverUrl, 'https://cv/medium.jpg');
        expect(book.externalUrl,
            'https://comicvine.gamespot.com/batman/4050-796/');
      });

      test('strips HTML from the description', () {
        final Book book = Book.fromComicVineVolume(volume());
        expect(book.description, 'The Dark Knight.');
      });

      test('isComic is true; prose books are false', () {
        expect(Book.fromComicVineVolume(volume()).isComic, isTrue);
        expect(createTestBook().isComic, isFalse);
      });

      test('rows without people carry no authors', () {
        expect(Book.fromComicVineVolume(volume()).authors, isEmpty);
      });

      test('maps people to authors, deduped, skipping nameless entries', () {
        final Map<String, dynamic> v = volume()
          ..['people'] = <dynamic>[
            <String, dynamic>{'name': 'Bob Kane'},
            <String, dynamic>{'name': 'Bill Finger'},
            <String, dynamic>{'name': 'Bob Kane'}, // duplicate dropped
            <String, dynamic>{'id': 5}, // nameless dropped
            'garbage', // non-map dropped
          ];
        expect(
          Book.fromComicVineVolume(v).authors,
          <String>['Bob Kane', 'Bill Finger'],
        );
      });

      test('caps people at 12', () {
        final Map<String, dynamic> v = volume()
          ..['people'] = <Map<String, dynamic>>[
            for (int i = 0; i < 20; i++) <String, dynamic>{'name': 'Person $i'},
          ];
        expect(Book.fromComicVineVolume(v).authors, hasLength(12));
      });

      test('rows without characters carry no subjects', () {
        expect(Book.fromComicVineVolume(volume()).subjects, isEmpty);
      });

      test('maps characters to subjects (the tag slot), capped at 15', () {
        final Map<String, dynamic> v = volume()
          ..['characters'] = <Map<String, dynamic>>[
            for (int i = 0; i < 20; i++) <String, dynamic>{'name': 'Char $i'},
          ];
        final Book book = Book.fromComicVineVolume(v);
        expect(book.subjects, hasLength(15));
        expect(book.subjects.first, 'Char 0');
      });

      test('falls back to deck when description is absent', () {
        final Map<String, dynamic> v = volume()
          ..remove('description')
          ..['deck'] = 'Volume 1.';
        expect(Book.fromComicVineVolume(v).description, 'Volume 1.');
      });

      test('tolerates a missing publisher and image', () {
        final Map<String, dynamic> v = volume()
          ..remove('publisher')
          ..remove('image');
        final Book book = Book.fromComicVineVolume(v);
        expect(book.publishers, isEmpty);
        expect(book.coverUrl, isNull);
      });

      test('kind survives a db round-trip', () {
        final Book comic = Book.fromComicVineVolume(volume());
        final Book back = Book.fromDb(comic.toDb());
        expect(back.kind, BookKind.comic);
        expect(back.source, DataSource.comicVine);
      });

      test('default Book kind is book and round-trips', () {
        final Book book = createTestBook();
        expect(book.kind, BookKind.book);
        expect(Book.fromDb(book.toDb()).kind, BookKind.book);
      });

      test('legacy rows without a kind column default to book', () {
        final Map<String, dynamic> row = createTestBook().toDb()
          ..remove('kind');
        expect(Book.fromDb(row).kind, BookKind.book);
      });
    });

    group('fromOpenLibrarySearchDoc', () {
      Map<String, dynamic> doc() => <String, dynamic>{
            'key': '/works/OL27448W',
            'title': 'The Lord of the Rings',
            'author_name': <String>['J.R.R. Tolkien'],
            'first_publish_year': 1954,
            'cover_i': 14625765,
            'language': <String>['eng', 'rus'],
            'edition_count': 251,
            'ratings_average': 4.3,
            'ratings_count': 100,
            'subject': <String>[
              'Fiction',
              'Fantasy fiction',
              'Fiction',
              'award:hugo_award=1966',
              'nyt:bestseller=2021',
            ],
            'number_of_pages_median': 500,
          };

      test('extracts numeric id and native OLID from the work key', () {
        final Book book = Book.fromOpenLibrarySearchDoc(doc());
        expect(book.id, '27448');
        expect(book.nativeId, 'OL27448W');
        expect(book.externalIdInt, 27448);
        expect(book.source, DataSource.openLibrary);
      });

      test('maps core fields', () {
        final Book book = Book.fromOpenLibrarySearchDoc(doc());
        expect(book.title, 'The Lord of the Rings');
        expect(book.authors, <String>['J.R.R. Tolkien']);
        expect(book.publishYear, 1954);
        expect(book.languages, <String>['eng', 'rus']);
        expect(book.pageCount, 500);
        expect(book.coverUrl,
            'https://covers.openlibrary.org/b/id/14625765-L.jpg');
        expect(book.externalUrl, 'https://openlibrary.org/works/OL27448W');
      });

      test('doubles the 1-5 rating to the app 1-10 scale', () {
        final Book book = Book.fromOpenLibrarySearchDoc(doc());
        expect(book.rating, closeTo(8.6, 0.0001));
        expect(book.ratingCount, 100);
      });

      test('cleans subjects — drops machine markers and dedupes', () {
        final Book book = Book.fromOpenLibrarySearchDoc(doc());
        expect(book.subjects, <String>['Fiction', 'Fantasy fiction']);
      });

      test('handles a missing cover', () {
        final Map<String, dynamic> d = doc()..remove('cover_i');
        expect(Book.fromOpenLibrarySearchDoc(d).coverUrl, isNull);
      });
    });

    group('fromOpenLibraryWork', () {
      test('reads a typed-text description object', () {
        final Book book = Book.fromOpenLibraryWork(
          <String, dynamic>{
            'key': '/works/OL27448W',
            'title': 'LOTR',
            'description': <String, dynamic>{
              'type': '/type/text',
              'value': 'An epic tale.',
            },
          },
        );
        expect(book.description, 'An epic tale.');
      });

      test('reads a plain-string description', () {
        final Book book = Book.fromOpenLibraryWork(<String, dynamic>{
          'key': '/works/OL27448W',
          'title': 'LOTR',
          'description': 'Plain string.',
        });
        expect(book.description, 'Plain string.');
      });

      test('doubles the ratings summary average and keeps the count', () {
        final Book book = Book.fromOpenLibraryWork(
          <String, dynamic>{'key': '/works/OL27448W', 'title': 'LOTR'},
          ratings: <String, dynamic>{
            'summary': <String, dynamic>{'average': 4.5, 'count': 50},
          },
          authorNames: <String>['J.R.R. Tolkien'],
        );
        expect(book.rating, closeTo(9.0, 0.0001));
        expect(book.ratingCount, 50);
        expect(book.authors, <String>['J.R.R. Tolkien']);
      });

      test('skips null / negative cover ids', () {
        final Book book = Book.fromOpenLibraryWork(<String, dynamic>{
          'key': '/works/OL27448W',
          'title': 'LOTR',
          'covers': <dynamic>[null, -1, 14625765],
        });
        expect(book.coverUrl,
            'https://covers.openlibrary.org/b/id/14625765-L.jpg');
      });

      test('pulls page count / publishers / isbn / year from an edition', () {
        final Book book = Book.fromOpenLibraryWork(
          <String, dynamic>{'key': '/works/OL27448W', 'title': 'LOTR'},
          edition: <String, dynamic>{
            'title': 'The Fellowship of the Ring',
            'number_of_pages': 1178,
            'publishers': <String>['Houghton Mifflin'],
            'isbn_10': <String>['0395193958'],
            'isbn_13': <String>['9780395193952'],
            'publish_date': 'cop. 1954',
          },
        );
        expect(book.pageCount, 1178);
        expect(book.publishers, <String>['Houghton Mifflin']);
        expect(book.isbn10, '0395193958');
        expect(book.isbn13, '9780395193952');
        expect(book.publishYear, 1954);
        expect(book.originalTitle, 'The Fellowship of the Ring');
      });
    });

    group('fromFantlabSearchMatch', () {
      Map<String, dynamic> match() => <String, dynamic>{
            'work_id': 3104,
            'rusname': 'Солярис',
            'name': 'Solaris',
            'year': 1961,
            'pic_edition_id': 24724,
            'name_show_im': 'роман',
            'midmark_by_weight': <double>[8.62],
            'midmark': <double>[8.65],
            'markcount': 9026,
            'autor1_rusname': 'Станислав Лем',
            'all_autor_rusname': 'Станислав Лем',
          };

      test('maps a match to a Fantlab book', () {
        final Book book = Book.fromFantlabSearchMatch(match());
        expect(book.id, '3104');
        expect(book.source, DataSource.fantlab);
        expect(book.nativeId, '3104');
        expect(book.title, 'Солярис');
        expect(book.originalTitle, 'Solaris');
        expect(book.authors, <String>['Станислав Лем']);
        expect(book.publishYear, 1961);
        expect(book.workType, 'роман');
        expect(book.coverUrl,
            'https://fantlab.ru/images/editions/big/24724');
        expect(book.externalUrl, 'https://fantlab.ru/work3104');
        expect(book.externalIdInt, 3104);
      });

      test('prefers midmark_by_weight for the rating; markcount as count', () {
        final Book book = Book.fromFantlabSearchMatch(match());
        expect(book.rating, closeTo(8.62, 0.0001));
        expect(book.ratingCount, 9026);
      });

      test('tolerates work_id arriving as a string', () {
        final Map<String, dynamic> m = match()..['work_id'] = '3104';
        expect(Book.fromFantlabSearchMatch(m).id, '3104');
      });

      test('tolerates work_id arriving as a single-element array', () {
        final Map<String, dynamic> m = match()..['work_id'] = <int>[3104];
        final Book book = Book.fromFantlabSearchMatch(m);
        expect(book.id, '3104');
        expect(book.externalIdInt, 3104);
      });

      test('falls back to all_autor_rusname when no numbered authors', () {
        final Map<String, dynamic> m = match()..remove('autor1_rusname');
        expect(
          Book.fromFantlabSearchMatch(m).authors,
          <String>['Станислав Лем'],
        );
      });

      test('drops a zero cover edition id', () {
        final Map<String, dynamic> m = match()..['pic_edition_id'] = 0;
        expect(Book.fromFantlabSearchMatch(m).coverUrl, isNull);
      });

      test('falls back to pic_edition_id_auto when pic_edition_id is 0', () {
        final Map<String, dynamic> m = match()
          ..['pic_edition_id'] = 0
          ..['pic_edition_id_auto'] = 555;
        expect(
          Book.fromFantlabSearchMatch(m).coverUrl,
          'https://fantlab.ru/images/editions/big/555',
        );
      });
    });

    group('fromFantlabWork', () {
      Map<String, dynamic> work() => <String, dynamic>{
            'work_id': 3104,
            'work_name': 'Солярис',
            'work_name_orig': 'Solaris',
            'work_description': '[b]An epic[/b] tale [USER=1]nog[/USER]',
            'image': '/images/editions/big/24724?r=1',
            'work_type': 'Роман',
            'work_year': 1961,
            'lang_code': 'pl',
            'val_voters': 9026,
            'rating': <String, dynamic>{'rating': '8.62', 'voters': 9026},
            'authors': <Map<String, dynamic>>[
              <String, dynamic>{'name': 'Станислав Лем', 'type': 'autor'},
              <String, dynamic>{'name': 'Переводчик', 'type': 'translator'},
            ],
            'classificatory': <String, dynamic>{
              'genre_group': <Map<String, dynamic>>[
                <String, dynamic>{
                  'genre': <Map<String, dynamic>>[
                    <String, dynamic>{'label': 'Планетарная фантастика'},
                  ],
                },
              ],
            },
            'awards': <String, dynamic>{
              'win': <Map<String, dynamic>>[
                <String, dynamic>{'award_rusname': 'Премия имени Лема'},
              ],
            },
            'parents': <String, dynamic>{
              'digest': <List<Map<String, dynamic>>>[
                <Map<String, dynamic>>[
                  <String, dynamic>{'work_name': 'Цикл о контакте'},
                ],
              ],
            },
            'editions_blocks': <String, dynamic>{
              '10': <String, dynamic>{
                'list': <Map<String, dynamic>>[
                  <String, dynamic>{'pages': 200, 'isbn': '978-5-17-012345-6'},
                ],
              },
            },
          };

      test('maps base fields and strips BB-codes from the description', () {
        final Book book = Book.fromFantlabWork(work());
        expect(book.id, '3104');
        expect(book.source, DataSource.fantlab);
        expect(book.title, 'Солярис');
        expect(book.originalTitle, 'Solaris');
        expect(book.description, 'An epic tale nog');
        expect(book.workType, 'Роман');
        expect(book.publishYear, 1961);
        expect(book.languages, <String>['pl']);
        expect(book.coverUrl,
            'https://fantlab.ru/images/editions/big/24724?r=1');
      });

      test('keeps only real authors (type == autor)', () {
        expect(Book.fromFantlabWork(work()).authors, <String>['Станислав Лем']);
      });

      test('parses the string rating object and voter count', () {
        final Book book = Book.fromFantlabWork(work());
        expect(book.rating, closeTo(8.62, 0.0001));
        expect(book.ratingCount, 9026);
      });

      test('pulls subjects / awards / series from the extended blocks', () {
        final Book book = Book.fromFantlabWork(work());
        expect(book.subjects, <String>['Планетарная фантастика']);
        expect(book.awards, <String>['Премия имени Лема']);
        expect(book.series, 'Цикл о контакте');
      });

      test('reads page count and a normalised 13-digit ISBN from editions', () {
        final Book book = Book.fromFantlabWork(work());
        expect(book.pageCount, 200);
        expect(book.isbn13, '9785170123456');
        expect(book.isbn10, isNull);
      });

      test('falls back to the first edition cover when image is null', () {
        final Map<String, dynamic> w = work()
          ..remove('image')
          ..['editions_blocks'] = <String, dynamic>{
            '32': <String, dynamic>{
              'list': <Map<String, dynamic>>[
                <String, dynamic>{'edition_id': 491880},
              ],
            },
          };
        expect(
          Book.fromFantlabWork(w).coverUrl,
          'https://fantlab.ru/images/editions/big/491880',
        );
      });
    });

    group('fromFantlabSimilar', () {
      Map<String, dynamic> entry() => <String, dynamic>{
            'id': 134421,
            'name': 'Ложная слепота',
            'name_orig': 'Blindsight',
            'name_type': 'роман',
            'year': 2006,
            'image': '/images/editions/big/160373',
            'description': 'desc',
            'creators': <String, dynamic>{
              'authors': <Map<String, dynamic>>[
                <String, dynamic>{'name': 'Питер Уоттс', 'type': 'autor'},
              ],
            },
            'stat': <String, dynamic>{'rating': '7.87', 'voters': 5573},
            'saga': <String, dynamic>{'name': 'Огнепад'},
          };

      test('maps a similar entry to a Fantlab book', () {
        final Book book = Book.fromFantlabSimilar(entry());
        expect(book.id, '134421');
        expect(book.source, DataSource.fantlab);
        expect(book.title, 'Ложная слепота');
        expect(book.originalTitle, 'Blindsight');
        expect(book.authors, <String>['Питер Уоттс']);
        expect(book.publishYear, 2006);
        expect(book.workType, 'роман');
        expect(book.series, 'Огнепад');
        expect(book.rating, closeTo(7.87, 0.0001));
        expect(book.ratingCount, 5573);
        expect(book.coverUrl,
            'https://fantlab.ru/images/editions/big/160373');
        expect(book.externalUrl, 'https://fantlab.ru/work134421');
      });
    });

    group('db round-trip', () {
      test('toDb / fromDb preserves every field', () {
        final Book book = createTestBook(
          id: '3104',
          source: DataSource.fantlab,
          nativeId: '3104',
          title: 'Солярис',
          originalTitle: 'Solaris',
          authors: const <String>['Станислав Лем'],
          description: 'desc',
          coverUrl: 'https://fantlab.ru/cover.jpg',
          pageCount: 200,
          publishYear: 1961,
          subjects: const <String>['sci-fi'],
          rating: 9.1,
          ratingCount: 1234,
          externalUrl: 'https://fantlab.ru/work3104',
          cachedAt: 1700000000,
        );
        final Book back = Book.fromDb(book.toDb());
        expect(back.id, '3104');
        expect(back.source, DataSource.fantlab);
        expect(back.nativeId, '3104');
        expect(back.title, 'Солярис');
        expect(back.originalTitle, 'Solaris');
        expect(back.authors, <String>['Станислав Лем']);
        expect(back.description, 'desc');
        expect(back.pageCount, 200);
        expect(back.publishYear, 1961);
        expect(back.subjects, <String>['sci-fi']);
        expect(back.rating, 9.1);
        expect(back.ratingCount, 1234);
        expect(back.externalUrl, 'https://fantlab.ru/work3104');
        expect(back.cachedAt, 1700000000);
      });

      test('toExport drops cached_at; fromExport round-trips', () {
        final Book book = createTestBook(cachedAt: 1700000000);
        final Map<String, dynamic> export = book.toExport();
        expect(export.containsKey('cached_at'), isFalse);
        final Book back = Book.fromExport(export);
        expect(back.id, book.id);
        expect(back.source, book.source);
        expect(back.cachedAt, isNull);
      });
    });

    group('withWorkDetails', () {
      test('overlays detail fields, keeps the search row year / pages', () {
        final Book light = createTestBook(
          description: null,
          publishYear: 1965,
          pageCount: 412,
          subjects: const <String>[],
          rating: 8.0,
        );
        final Book full = createTestBook(
          description: 'Full description',
          originalTitle: 'Orig',
          publishYear: null,
          pageCount: null,
          subjects: const <String>['Sci-Fi'],
        );
        final Book merged = light.withWorkDetails(full);
        expect(merged.description, 'Full description');
        expect(merged.originalTitle, 'Orig');
        expect(merged.subjects, <String>['Sci-Fi']);
        expect(merged.publishYear, 1965);
        expect(merged.pageCount, 412);
        expect(merged.rating, 8.0);
      });
    });

    group('identity', () {
      test('equality is the (id, source) pair', () {
        final Book ol = createTestBook(id: '100', source: DataSource.openLibrary);
        final Book fl = createTestBook(id: '100', source: DataSource.fantlab);
        final Book ol2 =
            createTestBook(id: '100', source: DataSource.openLibrary);
        expect(ol == fl, isFalse);
        expect(ol == ol2, isTrue);
        expect(ol.hashCode == ol2.hashCode, isTrue);
      });

      test('toString names the id, source and title', () {
        final Book book = createTestBook(id: '100', title: 'Dune');

        final String text = book.toString();
        expect(text, contains('100'));
        expect(text, contains('Dune'));
        expect(text, contains(DataSource.openLibrary.name));
      });
    });

    group('formatted getters', () {
      test('formattedRating keeps one decimal', () {
        expect(createTestBook(rating: 4.25).formattedRating, '4.3');
      });

      test('formattedRating is null without a rating', () {
        expect(createTestBook().formattedRating, isNull);
      });

      test('authorsString joins the authors', () {
        final Book book = createTestBook(
          authors: const <String>['Frank Herbert', 'Brian Herbert'],
        );

        expect(book.authorsString, 'Frank Herbert, Brian Herbert');
      });

      test('authorsString is null when there are no authors', () {
        expect(
          createTestBook(authors: const <String>[]).authorsString,
          isNull,
        );
      });
    });

    group('cover URL helpers', () {
      test('coverUrlFromId builds the large OpenLibrary id URL', () {
        expect(
          Book.coverUrlFromId(12345),
          'https://covers.openlibrary.org/b/id/12345-L.jpg',
        );
      });

      test('coverUrlFromIsbn builds the large OpenLibrary isbn URL', () {
        expect(
          Book.coverUrlFromIsbn('9780441013593'),
          'https://covers.openlibrary.org/b/isbn/9780441013593-L.jpg',
        );
      });
    });

    group('list columns', () {
      Map<String, dynamic> rowWith(Object? subjects) => <String, dynamic>{
            'id': '100',
            'source': DataSource.openLibrary.name,
            'native_id': 'OL100W',
            'title': 'Dune',
            'authors': '["Frank Herbert"]',
            'subjects': subjects,
            'cached_at': 1700000000,
          };

      test('decodes a JSON array column', () {
        expect(
          Book.fromDb(rowWith('["Sci-Fi","Desert"]')).subjects,
          <String>['Sci-Fi', 'Desert'],
        );
      });

      test('tolerates a malformed JSON column', () {
        expect(Book.fromDb(rowWith('not json')).subjects, isEmpty);
      });

      test('tolerates a JSON value that is not a list', () {
        expect(Book.fromDb(rowWith('{"a":1}')).subjects, isEmpty);
      });

      test('tolerates a NULL column', () {
        expect(Book.fromDb(rowWith(null)).subjects, isEmpty);
      });
    });
  });
}
