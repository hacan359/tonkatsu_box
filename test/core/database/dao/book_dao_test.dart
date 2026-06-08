import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tonkatsu_box/core/database/dao/book_dao.dart';
import 'package:tonkatsu_box/core/database/schema.dart';
import 'package:tonkatsu_box/shared/models/book.dart';
import 'package:tonkatsu_box/shared/models/data_source.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late BookDao dao;

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (Database d, int _) async {
          await DatabaseSchema.createBooksCacheTable(d);
        },
      ),
    );
    dao = BookDao(() async => db);
  });

  tearDown(() async {
    await db.close();
  });

  group('BookDao', () {
    group('upsertBook / getBook', () {
      test('round-trips a book by (id, source)', () async {
        final Book book = createTestBook(id: '27448', title: 'LOTR');
        await dao.upsertBook(book);

        final Book? loaded =
            await dao.getBook('27448', source: DataSource.openLibrary);
        expect(loaded, isNotNull);
        expect(loaded!.title, 'LOTR');
      });

      test('returns null for a missing row', () async {
        final Book? loaded =
            await dao.getBook('999', source: DataSource.openLibrary);
        expect(loaded, isNull);
      });

      test('replaces an existing row on conflict', () async {
        await dao.upsertBook(createTestBook(id: '27448', title: 'Old'));
        await dao.upsertBook(createTestBook(id: '27448', title: 'New'));
        final Book? loaded =
            await dao.getBook('27448', source: DataSource.openLibrary);
        expect(loaded!.title, 'New');
      });
    });

    group('(id, source) primary key', () {
      test('the same numeric id from two sources coexists', () async {
        await dao.upsertBook(createTestBook(
          id: '100',
          source: DataSource.openLibrary,
          nativeId: 'OL100W',
          title: 'OL Book',
        ));
        await dao.upsertBook(createTestBook(
          id: '100',
          source: DataSource.fantlab,
          nativeId: '100',
          title: 'FL Book',
        ));

        final Book? ol =
            await dao.getBook('100', source: DataSource.openLibrary);
        final Book? fl = await dao.getBook('100', source: DataSource.fantlab);
        expect(ol!.title, 'OL Book');
        expect(fl!.title, 'FL Book');
      });
    });

    group('getBooksByIds', () {
      test('matches CAST(id AS INTEGER) against external ids', () async {
        await dao.upsertBook(createTestBook(id: '27448', title: 'LOTR'));
        await dao.upsertBook(createTestBook(id: '893415', title: 'Dune'));

        final List<Book> books = await dao.getBooksByIds(<int>[27448]);
        expect(books, hasLength(1));
        expect(books.single.title, 'LOTR');
      });

      test('returns rows from every source sharing a numeric id', () async {
        await dao.upsertBook(createTestBook(
          id: '100', source: DataSource.openLibrary, title: 'OL'));
        await dao.upsertBook(createTestBook(
          id: '100', source: DataSource.fantlab, nativeId: '100', title: 'FL'));

        final List<Book> books = await dao.getBooksByIds(<int>[100]);
        expect(books, hasLength(2));
        expect(
          books.map((Book b) => b.source).toSet(),
          <DataSource>{DataSource.openLibrary, DataSource.fantlab},
        );
      });

      test('returns empty for an empty id list', () async {
        expect(await dao.getBooksByIds(<int>[]), isEmpty);
      });
    });

    group('clearBooks', () {
      test('removes every cached book', () async {
        await dao.upsertBooks(<Book>[
          createTestBook(id: '1'),
          createTestBook(id: '2'),
        ]);
        await dao.clearBooks();
        expect(await dao.getBooksByIds(<int>[1, 2]), isEmpty);
      });
    });
  });
}
