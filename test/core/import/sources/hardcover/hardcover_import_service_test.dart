import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/hardcover_api.dart';
import 'package:tonkatsu_box/core/import/sources/anilist/anilist_import_service.dart'
    show ImportMode;
import 'package:tonkatsu_box/core/import/sources/hardcover/hardcover_import_service.dart';
import 'package:tonkatsu_box/core/services/import_service.dart';
import 'package:tonkatsu_box/shared/models/book.dart';
import 'package:tonkatsu_box/shared/models/collection_item.dart';
import 'package:tonkatsu_box/shared/models/data_source.dart';
import 'package:tonkatsu_box/shared/models/item_status.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';
import 'package:tonkatsu_box/shared/models/universal_import_result.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  late HardcoverImportService sut;
  late MockHardcoverApi mockHardcover;
  late MockDatabaseService mockDb;
  late MockBookDao mockBookDao;
  late MockGlobalTagDao mockTagDao;
  late MockCollectionRepository mockRepo;
  late MockWishlistRepository mockWishlist;

  setUpAll(() {
    registerAllFallbacks();
    registerFallbackValue(<Map<String, dynamic>>[]);
    registerFallbackValue(<(int, Map<String, dynamic>)>[]);
    registerFallbackValue(const <Book>[]);
  });

  setUp(() {
    mockHardcover = MockHardcoverApi();
    mockDb = MockDatabaseService();
    mockBookDao = MockBookDao();
    mockTagDao = MockGlobalTagDao();
    when(() => mockDb.bookDao).thenReturn(mockBookDao);
    when(() => mockDb.globalTagDao).thenReturn(mockTagDao);
    mockRepo = MockCollectionRepository();
    mockWishlist = MockWishlistRepository();

    sut = HardcoverImportService(
      hardcoverApi: mockHardcover,
      database: mockDb,
      repository: mockRepo,
      wishlistRepository: mockWishlist,
    );

    when(() => mockBookDao.upsertBooks(any())).thenAnswer((_) async {});
    when(() => mockTagDao.resolveOrCreate(any()))
        .thenAnswer((_) async => 99);
    when(() => mockTagDao.addTagToItems(any(), any()))
        .thenAnswer((_) async {});
    when(() => mockRepo.create(
          name: any(named: 'name'),
          author: any(named: 'author'),
        )).thenAnswer((_) async => createTestCollection(id: 42));
    when(() => mockRepo.getById(any()))
        .thenAnswer((_) async => createTestCollection(id: 1));
    when(() => mockRepo.getItems(any()))
        .thenAnswer((_) async => <CollectionItem>[]);
    when(() => mockRepo.addItemsBatch(any(), any())).thenAnswer(
        (Invocation inv) async =>
            (inv.positionalArguments[1] as List<dynamic>).length);
    when(() => mockRepo.updateItemFieldsBatch(any())).thenAnswer((_) async {});
  });

  Book book({int id = 312460, String title = 'Dune'}) => Book(
        id: '$id',
        source: DataSource.hardcover,
        nativeId: '$id',
        title: title,
        externalUrl: 'https://hardcover.app/id/book/$id',
      );

  HardcoverUserBookEntry entry({
    int statusId = 3,
    int bookId = 312460,
    double? rating,
    int readCount = 1,
    DateTime? firstStartedReadingDate,
    DateTime? firstReadDate,
    DateTime? lastReadDate,
    DateTime? dateAdded,
    String? review,
    String? privateNotes,
    bool owned = false,
  }) =>
      HardcoverUserBookEntry(
        statusId: statusId,
        book: book(id: bookId),
        rating: rating,
        readCount: readCount,
        firstStartedReadingDate: firstStartedReadingDate,
        firstReadDate: firstReadDate,
        lastReadDate: lastReadDate,
        dateAdded: dateAdded,
        review: review,
        privateNotes: privateNotes,
        owned: owned,
      );

  void stubLibrary(List<HardcoverUserBookEntry> entries) {
    when(() => mockHardcover.fetchUserBooks(
          username: any(named: 'username'),
          onProgress: any(named: 'onProgress'),
        )).thenAnswer((_) async => entries);
  }

  HardcoverImportOptions opts({
    ImportMode mode = ImportMode.newOnly,
    int? collectionId = 1,
  }) =>
      HardcoverImportOptions(
        userName: 'adam',
        mode: mode,
        author: 'me',
        newCollectionName: 'Hardcover',
        collectionId: collectionId,
      );

  List<Map<String, dynamic>> capturedItemRows() =>
      verify(() => mockRepo.addItemsBatch(any(), captureAny())).captured.single
          as List<Map<String, dynamic>>;

  List<(int, Map<String, dynamic>)> capturedUpdates() =>
      verify(() => mockRepo.updateItemFieldsBatch(captureAny())).captured.single
          as List<(int, Map<String, dynamic>)>;

  group('HardcoverImportService.import', () {
    test('throws FormatException when the library is empty', () async {
      stubLibrary(<HardcoverUserBookEntry>[]);

      expect(() => sut.import(opts()), throwsA(isA<FormatException>()));
    });

    test('ignored entries (status 6) do not count as content', () async {
      stubLibrary(<HardcoverUserBookEntry>[entry(statusId: 6)]);

      expect(() => sut.import(opts()), throwsA(isA<FormatException>()));
    });

    test('caches books and writes rows stamped with the hardcover source',
        () async {
      stubLibrary(<HardcoverUserBookEntry>[entry()]);

      final UniversalImportResult result =
          await sut.import(opts(collectionId: null));

      verify(() => mockBookDao.upsertBooks(any())).called(1);
      expect(result.success, isTrue);
      expect(result.effectiveCollectionId, 42);
      expect(result.importedByType[MediaType.book], 1);
      final Map<String, dynamic> row = capturedItemRows().single;
      expect(row['media_type'], MediaType.book.value);
      expect(row['external_id'], 312460);
      expect(row['source'], 'hardcover');
    });

    test('maps Hardcover status ids to ItemStatus', () async {
      const Map<int, ItemStatus> mapping = <int, ItemStatus>{
        1: ItemStatus.planned,
        2: ItemStatus.inProgress,
        3: ItemStatus.completed,
        4: ItemStatus.dropped,
        5: ItemStatus.dropped,
      };

      for (final MapEntry<int, ItemStatus> e in mapping.entries) {
        clearInteractions(mockRepo);
        stubLibrary(<HardcoverUserBookEntry>[entry(statusId: e.key)]);

        await sut.import(opts());

        expect(capturedItemRows().single['status'], e.value.value,
            reason: 'status_id ${e.key}');
      }
    });

    test('doubles the 0–5 rating and drops a zero', () async {
      stubLibrary(<HardcoverUserBookEntry>[
        entry(bookId: 1, rating: 4.5),
        entry(bookId: 2, rating: 0),
        entry(bookId: 3),
      ]);

      await sut.import(opts());

      final List<Map<String, dynamic>> rows = capturedItemRows();
      Map<String, dynamic> rowFor(int id) =>
          rows.firstWhere((Map<String, dynamic> r) => r['external_id'] == id);
      expect(rowFor(1)['user_rating'], 9.0);
      expect(rowFor(2).containsKey('user_rating'), isFalse);
      expect(rowFor(3).containsKey('user_rating'), isFalse);
    });

    test('read_count maps to re-reads (0 = read once)', () async {
      stubLibrary(<HardcoverUserBookEntry>[
        entry(bookId: 1, readCount: 1),
        entry(bookId: 2, readCount: 3),
        entry(bookId: 3, statusId: 2, readCount: 0),
      ]);

      await sut.import(opts());

      final List<Map<String, dynamic>> rows = capturedItemRows();
      Map<String, dynamic> rowFor(int id) =>
          rows.firstWhere((Map<String, dynamic> r) => r['external_id'] == id);
      expect(rowFor(1)['rewatch_count'], 0);
      expect(rowFor(2)['rewatch_count'], 2);
      expect(rowFor(3).containsKey('rewatch_count'), isFalse);
    });

    test('carries reading dates and the Hardcover add date', () async {
      stubLibrary(<HardcoverUserBookEntry>[
        entry(
          firstStartedReadingDate: DateTime.utc(2023, 1, 5),
          lastReadDate: DateTime.utc(2023, 2, 10),
          dateAdded: DateTime.utc(2022, 12, 31),
        ),
      ]);

      await sut.import(opts());

      final Map<String, dynamic> row = capturedItemRows().single;
      expect(row['started_at'],
          DateTime.utc(2023, 1, 5).millisecondsSinceEpoch ~/ 1000);
      expect(row['completed_at'],
          DateTime.utc(2023, 2, 10).millisecondsSinceEpoch ~/ 1000);
      expect(row['added_at'],
          DateTime.utc(2022, 12, 31).millisecondsSinceEpoch ~/ 1000);
    });

    test('completed without dates still gets a completion date', () async {
      stubLibrary(<HardcoverUserBookEntry>[entry()]);

      await sut.import(opts());

      final Map<String, dynamic> row = capturedItemRows().single;
      expect(row['completed_at'], isNotNull);
      expect(row['started_at'], isNotNull);
      expect(row.containsKey('added_at'), isFalse,
          reason: 'no date_added → the DAO stamps now');
    });

    test('builds the comment from link, re-reads, review and notes', () async {
      stubLibrary(<HardcoverUserBookEntry>[
        entry(
          readCount: 3,
          review:
              '<p>Loved it, <span data-mention-id="1">@frank</span></p>',
          privateNotes: 'do not lend out',
        ),
      ]);

      await sut.import(opts());

      final String comment =
          capturedItemRows().single['user_comment'] as String;
      expect(comment, contains('https://hardcover.app/id/book/312460'));
      expect(comment, contains('Reread times: 2'));
      expect(comment, contains('Loved it'));
      expect(comment, isNot(contains('<span')));
      expect(comment, contains('do not lend out'));
    });

    test('links the Owned tag to owned books only', () async {
      stubLibrary(<HardcoverUserBookEntry>[
        entry(bookId: 1, owned: true),
        entry(bookId: 2),
      ]);
      when(() => mockRepo.getItems(any())).thenAnswer((_) async =>
          <CollectionItem>[
            createTestCollectionItem(
              id: 11,
              mediaType: MediaType.book,
              externalId: 1,
            ),
            createTestCollectionItem(
              id: 12,
              mediaType: MediaType.book,
              externalId: 2,
            ),
          ]);

      await sut.import(opts());

      verify(() => mockTagDao.resolveOrCreate('Owned')).called(1);
      verify(() => mockTagDao.addTagToItems(<int>[11], 99)).called(1);
    });

    test('does not touch tags when nothing is owned', () async {
      stubLibrary(<HardcoverUserBookEntry>[entry()]);

      await sut.import(opts());

      verifyNever(() => mockTagDao.resolveOrCreate(any()));
    });

    test('skips existing items in newOnly mode', () async {
      stubLibrary(<HardcoverUserBookEntry>[entry()]);
      when(() => mockRepo.getItems(any())).thenAnswer((_) async =>
          <CollectionItem>[
            createTestCollectionItem(
              id: 7,
              mediaType: MediaType.book,
              externalId: 312460,
            ),
          ]);

      final UniversalImportResult result =
          await sut.import(opts(mode: ImportMode.newOnly));

      expect(result.importedByType[MediaType.book] ?? 0, 0);
      expect(result.totalUpdated, 0);
    });

    test('updates rating and added_at in overwrite mode', () async {
      stubLibrary(<HardcoverUserBookEntry>[
        entry(rating: 4.5, dateAdded: DateTime.utc(2022, 12, 31)),
      ]);
      when(() => mockRepo.getItems(any())).thenAnswer((_) async =>
          <CollectionItem>[
            createTestCollectionItem(
              id: 7,
              mediaType: MediaType.book,
              externalId: 312460,
              status: ItemStatus.completed,
              userRating: 7,
            ),
          ]);

      final UniversalImportResult result =
          await sut.import(opts(mode: ImportMode.overwrite));

      expect(result.updatedByType[MediaType.book], 1);
      final (int, Map<String, dynamic>) update = capturedUpdates().single;
      expect(update.$1, 7);
      expect(update.$2['user_rating'], 9.0);
      expect(update.$2['added_at'],
          DateTime.utc(2022, 12, 31).millisecondsSinceEpoch ~/ 1000);
    });

    test('reports progress ending in the completed stage', () async {
      stubLibrary(<HardcoverUserBookEntry>[entry()]);
      final List<ImportProgress> updates = <ImportProgress>[];

      await sut.import(opts(), onProgress: updates.add);

      expect(updates.first.stage, ImportStage.fetchingBooks);
      expect(updates.last.stage, ImportStage.completed);
    });
  });
}
