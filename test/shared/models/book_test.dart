import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/models/book.dart';
import 'package:tonkatsu_box/shared/models/data_source.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('Book', () {
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
    });
  });
}
