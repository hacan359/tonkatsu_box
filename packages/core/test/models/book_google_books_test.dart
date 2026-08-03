import 'package:core/models/book.dart';
import 'package:core/models/book_kind.dart';
import 'package:core/models/data_source.dart';
import 'package:test/test.dart';

void main() {
  group('fnv1a64', () {
    test('is deterministic for the same input', () {
      expect(fnv1a64('OL123'), fnv1a64('OL123'));
      expect(fnv1a64('_aMwEAAAQBAJ'), fnv1a64('_aMwEAAAQBAJ'));
    });

    test('differs for different inputs', () {
      expect(fnv1a64('vol1'), isNot(fnv1a64('vol2')));
    });

    test('is always non-negative so it fits a positive external_id', () {
      for (final String s in <String>['', 'a', 'zzzzzzzzzzzz', '汉字']) {
        expect(fnv1a64(s) >= 0, isTrue);
      }
    });
  });

  group('Book.fromGoogleBooksVolume', () {
    Map<String, dynamic> volume(
      Map<String, dynamic> info, {
      String id = 'vol1',
    }) =>
        <String, dynamic>{'id': id, 'volumeInfo': info};

    test('maps the core fields and hashes the volumeId into a numeric id', () {
      final Book b = Book.fromGoogleBooksVolume(volume(<String, dynamic>{
        'title': 'Dune',
        'authors': <String>['Frank Herbert'],
        'description': '<p>Spice.</p>',
        'pageCount': 412,
        'publishedDate': '1965',
        'publisher': 'Ace',
        'language': 'en',
        'categories': <String>['Fiction', 'Fiction'],
        'averageRating': 4,
        'ratingsCount': 50,
        'infoLink': 'https://books.google.com/info',
        'industryIdentifiers': <Map<String, dynamic>>[
          <String, dynamic>{'type': 'ISBN_13', 'identifier': '9780441013593'},
        ],
      }));

      expect(b.id, fnv1a64('vol1').toString());
      // The numeric-string contract still parses for collection_items.
      expect(b.externalIdInt, int.parse(fnv1a64('vol1').toString()));
      expect(b.source, DataSource.googleBooks);
      expect(b.kind, BookKind.book);
      expect(b.nativeId, 'vol1');
      expect(b.title, 'Dune');
      expect(b.authors, <String>['Frank Herbert']);
      expect(b.description, 'Spice.');
      expect(b.pageCount, 412);
      expect(b.publishYear, 1965);
      expect(b.publishers, <String>['Ace']);
      expect(b.languages, <String>['en']);
      expect(b.subjects, <String>['Fiction']); // deduped
      expect(b.rating, 8.0); // 4 * 2
      expect(b.ratingCount, 50);
      expect(b.isbn13, '9780441013593');
      expect(b.isbn10, isNull);
      expect(b.externalUrl, 'https://books.google.com/info');
    });

    test('appends a subtitle to the title', () {
      final Book b = Book.fromGoogleBooksVolume(volume(<String, dynamic>{
        'title': 'Dune',
        'subtitle': 'Book One',
      }));
      expect(b.title, 'Dune: Book One');
    });

    test('handles a volume with no ISBN, rating or cover', () {
      final Book b = Book.fromGoogleBooksVolume(volume(<String, dynamic>{
        'title': 'Free Scan',
      }));
      expect(b.isbn10, isNull);
      expect(b.isbn13, isNull);
      expect(b.rating, isNull);
      expect(b.coverUrl, isNull);
      expect(b.title, 'Free Scan');
    });

    test('drops a zero averageRating', () {
      final Book b = Book.fromGoogleBooksVolume(volume(<String, dynamic>{
        'title': 'Unrated',
        'averageRating': 0,
      }));
      expect(b.rating, isNull);
    });

    test('treats a zero pageCount as unknown (catalog-only search rows)', () {
      // volumes.list returns pageCount 0 for no-preview volumes; the real
      // count lives only in the detail payload.
      final Book b = Book.fromGoogleBooksVolume(volume(<String, dynamic>{
        'title': 'White Nights',
        'pageCount': 0,
      }));
      expect(b.pageCount, isNull);
    });

    test(
        'builds the cover from the thumbnail (never the page-scan sizes), '
        'strips edge=curl, upgrades to https and upscales via fife', () {
      final Book b = Book.fromGoogleBooksVolume(volume(<String, dynamic>{
        'title': 'Dune',
        'imageLinks': <String, dynamic>{
          'smallThumbnail': 'http://x/small',
          'thumbnail': 'http://x/thumb?zoom=1&edge=curl',
          // Interior page scan on scanned volumes — must be ignored.
          'large': 'http://books.google.com/large?zoom=4&edge=curl',
          'extraLarge': 'http://books.google.com/xl?zoom=6&edge=curl',
        },
      }));
      expect(b.coverUrl, 'https://x/thumb?zoom=1&fife=w800');
    });

    test('falls back to smallThumbnail when thumbnail is absent', () {
      final Book b = Book.fromGoogleBooksVolume(volume(<String, dynamic>{
        'title': 'Dune',
        'imageLinks': <String, dynamic>{
          'smallThumbnail': 'http://x/small?zoom=5',
        },
      }));
      expect(b.coverUrl, 'https://x/small?zoom=5&fife=w800');
    });

    test('falls back to canonicalVolumeLink for the external url', () {
      final Book b = Book.fromGoogleBooksVolume(volume(<String, dynamic>{
        'title': 'Dune',
        'canonicalVolumeLink': 'https://books.google.com/canonical',
      }));
      expect(b.externalUrl, 'https://books.google.com/canonical');
    });

    test('defaults the title when volumeInfo is missing', () {
      final Book b = Book.fromGoogleBooksVolume(<String, dynamic>{'id': 'x'});
      expect(b.title, 'Unknown');
      expect(b.nativeId, 'x');
    });
  });
}
