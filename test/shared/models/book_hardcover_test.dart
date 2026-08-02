import 'package:core/models/book.dart';
import 'package:core/models/book_kind.dart';
import 'package:core/models/data_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Book.fromHardcoverDocument', () {
    Map<String, dynamic> doc({
      Object? id = '312460',
      String? subtitle,
      int? categoryId = 1,
      double? rating = 4.5,
      List<String>? isbns,
    }) =>
        <String, dynamic>{
          'id': id,
          'title': 'Dune',
          'subtitle': subtitle,
          'description': 'A desert planet.',
          'release_year': 1965,
          'pages': 704,
          'author_names': <String>['Frank Herbert', 'Brian Herbert'],
          'isbns': isbns ?? <String>['0441013597', '9780441013593'],
          'genres': <String>['Science Fiction'],
          'moods': <String>['adventurous'],
          'rating': rating,
          'ratings_count': 5837,
          'slug': 'dune',
          'book_category_id': categoryId,
          'image': <String, dynamic>{
            'url': 'https://assets.hardcover.app/x.jpg',
          },
          'featured_series': <String, dynamic>{
            'position': 1.0,
            'series': <String, dynamic>{'name': 'Dune'},
          },
          'series_names': <String>['Dune', 'Dune Universe'],
        };

    test('maps the full card from one document', () {
      final Book b = Book.fromHardcoverDocument(doc());

      expect(b.id, '312460');
      expect(b.nativeId, '312460');
      expect(b.source, DataSource.hardcover);
      expect(b.kind, BookKind.book);
      expect(b.title, 'Dune');
      expect(b.authors, <String>['Frank Herbert', 'Brian Herbert']);
      expect(b.description, 'A desert planet.');
      expect(b.pageCount, 704);
      expect(b.publishYear, 1965);
      expect(b.isbn10, '0441013597');
      expect(b.isbn13, '9780441013593');
      expect(b.subjects, <String>['Science Fiction', 'adventurous']);
      expect(b.series, 'Dune');
      expect(b.rating, 9.0);
      expect(b.ratingCount, 5837);
      expect(b.coverUrl, 'https://assets.hardcover.app/x.jpg');
      expect(b.externalUrl, 'https://hardcover.app/id/book/312460');
      expect(b.externalIdInt, 312460);
    });

    test('joins the subtitle into the title', () {
      final Book b = Book.fromHardcoverDocument(doc(subtitle: 'Deluxe'));
      expect(b.title, 'Dune: Deluxe');
    });

    test('graphic novels map to BookKind.comic', () {
      expect(Book.fromHardcoverDocument(doc(categoryId: 4)).kind,
          BookKind.comic);
      expect(Book.fromHardcoverDocument(doc(categoryId: 10)).kind,
          BookKind.book, reason: 'light novels stay prose');
    });

    test('zero rating stays null', () {
      expect(Book.fromHardcoverDocument(doc(rating: 0)).rating, isNull);
    });

    test('splits a mixed isbns array, dashes stripped', () {
      final Book b = Book.fromHardcoverDocument(
        doc(isbns: <String>['978-0-441-01359-3', '0-441-01359-7']),
      );
      expect(b.isbn13, '9780441013593');
      expect(b.isbn10, '0441013597');
    });

    test('falls back to series_names without a featured series', () {
      final Map<String, dynamic> d = doc();
      d['featured_series'] = null;
      expect(Book.fromHardcoverDocument(d).series, 'Dune');
    });

    test('an int id and a non-numeric id both stay valid external ids', () {
      expect(Book.fromHardcoverDocument(doc(id: 312460)).id, '312460');
      final Book hashed = Book.fromHardcoverDocument(doc(id: 'abc'));
      expect(hashed.id, fnv1a64('abc').toString());
      expect(hashed.externalIdInt, isPositive);
    });
  });

  group('Book.fromHardcoverBook', () {
    Map<String, dynamic> graphBook({bool withEdition = true}) =>
        <String, dynamic>{
          'id': 312460,
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
              <String, dynamic>{'tag': 'Fiction'},
            ],
            'Mood': <Map<String, dynamic>>[
              <String, dynamic>{'tag': 'adventurous'},
            ],
            'Content Warning': <Map<String, dynamic>>[
              <String, dynamic>{'tag': 'Violence'},
            ],
          },
          'image': <String, dynamic>{
            'url': 'https://assets.hardcover.app/x.jpg',
          },
          'contributions': <Map<String, dynamic>>[
            <String, dynamic>{
              'author': <String, dynamic>{'name': 'Frank Herbert'},
            },
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
          if (withEdition)
            'default_physical_edition': <String, dynamic>{
              'isbn_10': '0441013597',
              'isbn_13': '9780441013593',
              'publisher': <String, dynamic>{'name': 'Penguin'},
              'language': <String, dynamic>{'code2': 'en'},
            },
        };

    test('maps the graph object with the edition block', () {
      final Book b = Book.fromHardcoverBook(graphBook());

      expect(b.id, '312460');
      expect(b.source, DataSource.hardcover);
      expect(b.authors, <String>['Frank Herbert'],
          reason: 'duplicate contributions collapse');
      expect(b.publishers, <String>['Penguin']);
      expect(b.languages, <String>['en']);
      expect(b.isbn10, '0441013597');
      expect(b.isbn13, '9780441013593');
      expect(b.series, 'Dune', reason: 'lowest position wins');
      expect(b.subjects,
          <String>['Science Fiction', 'Fiction', 'adventurous'],
          reason: 'genres then moods; content warnings excluded');
      expect(b.rating, closeTo(8.636, 0.001));
    });

    test('tolerates the import shape without an edition', () {
      final Book b = Book.fromHardcoverBook(graphBook(withEdition: false));

      expect(b.isbn10, isNull);
      expect(b.isbn13, isNull);
      expect(b.publishers, isEmpty);
      expect(b.languages, isEmpty);
      expect(b.title, 'Dune');
    });
  });
}
