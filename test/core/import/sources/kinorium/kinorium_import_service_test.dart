import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/import/sources/kinorium/kinorium_import_service.dart';
import 'package:tonkatsu_box/shared/models/collection_item.dart';
import 'package:tonkatsu_box/shared/models/item_status.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';
import 'package:tonkatsu_box/shared/models/movie.dart';
import 'package:tonkatsu_box/shared/models/tv_show.dart';
import 'package:tonkatsu_box/shared/models/universal_import_result.dart';
import 'package:tonkatsu_box/shared/models/wishlist_item.dart';

import '../../../../helpers/test_helpers.dart';

String _row(List<String> cells) =>
    cells.map((String c) => '"$c"').join('\t');

const List<String> _header = <String>[
  'My rating', 'Date', 'Title', 'Original Title', 'Type', 'Year',
];

/// A minimal Kinorium CSV with the columns the importer reads.
String _csv(List<List<String>> rows) =>
    <String>[_row(_header), ...rows.map(_row)].join('\n');

Uint8List _utf16le(String text) {
  final List<int> bytes = <int>[0xFF, 0xFE];
  for (final int unit in text.codeUnits) {
    bytes.add(unit & 0xFF);
    bytes.add((unit >> 8) & 0xFF);
  }
  return Uint8List.fromList(bytes);
}

void main() {
  late MockTmdbApi mockTmdb;
  late MockCollectionRepository mockRepo;
  late MockWishlistRepository mockWishlist;
  late MockDatabaseService mockDb;
  late MockMovieDao mockMovieDao;
  late MockTvShowDao mockTvShowDao;
  late KinoriumImportService sut;

  late Directory tempDir;
  late String csvPath;

  setUpAll(() {
    registerAllFallbacks();
    registerFallbackValue(<Map<String, dynamic>>[]);
    registerFallbackValue(<(int, Map<String, dynamic>)>[]);
  });

  setUp(() {
    mockTmdb = MockTmdbApi();
    mockRepo = MockCollectionRepository();
    mockWishlist = MockWishlistRepository();
    mockDb = MockDatabaseService();
    mockMovieDao = MockMovieDao();
    mockTvShowDao = MockTvShowDao();
    when(() => mockDb.movieDao).thenReturn(mockMovieDao);
    when(() => mockDb.tvShowDao).thenReturn(mockTvShowDao);

    sut = KinoriumImportService(
      repository: mockRepo,
      wishlistRepository: mockWishlist,
      tmdbApi: mockTmdb,
      database: mockDb,
    );

    tempDir = Directory.systemTemp.createTempSync('kinorium_test');
    csvPath = '${tempDir.path}/list.csv';

    when(() => mockRepo.create(
          name: any(named: 'name'),
          author: any(named: 'author'),
        )).thenAnswer((_) async => createTestCollection());
    when(() => mockRepo.getItems(any()))
        .thenAnswer((_) async => <CollectionItem>[]);
    when(() => mockMovieDao.upsertMovies(any())).thenAnswer((_) async {});
    when(() => mockTvShowDao.upsertTvShows(any())).thenAnswer((_) async {});
    when(() => mockRepo.addItemsBatch(any(), any()))
        .thenAnswer((Invocation inv) async =>
            (inv.positionalArguments[1] as List<dynamic>).length);
    when(() => mockRepo.updateItemFieldsBatch(any()))
        .thenAnswer((_) async {});
    when(() => mockWishlist.getAll(
          includeResolved: any(named: 'includeResolved'),
        )).thenAnswer((_) async => <WishlistItem>[]);
    when(() => mockWishlist.addWishlistItemsBatch(any()))
        .thenAnswer((Invocation inv) async =>
            (inv.positionalArguments[0] as List<dynamic>).length);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  void writeCsv(String content) {
    File(csvPath).writeAsBytesSync(_utf16le(content));
  }

  List<Map<String, dynamic>> capturedItemRows() =>
      verify(() => mockRepo.addItemsBatch(any(), captureAny()))
          .captured
          .single as List<Map<String, dynamic>>;

  group('KinoriumImportService', () {
    test('watched movie → batch row with completed status, rating, date',
        () async {
      writeCsv(_csv(<List<String>>[
        <String>['8', '2023-06-15 21:30:00', 'Матрица', 'The Matrix',
            'Фильм', '1999'],
      ]));
      when(() => mockTmdb.searchMovies(any(), year: any(named: 'year')))
          .thenAnswer(
              (_) async => <Movie>[createTestMovie(tmdbId: 603, releaseYear: 1999)]);

      final UniversalImportResult result =
          await sut.import(KinoriumImportOptions(filePath: csvPath));

      expect(result.success, isTrue);
      expect(result.totalImported, 1);
      verify(() => mockMovieDao.upsertMovies(any())).called(1);
      final Map<String, dynamic> row = capturedItemRows().single;
      expect(row['status'], ItemStatus.completed.value);
      expect(row['external_id'], 603);
      expect(row['user_rating'], 8.0);
      expect(row['completed_at'], isNotNull);
      expect(row['last_activity_at'], isNotNull);
      expect(row['user_comment'],
          contains('[Link](https://en.kinorium.com/search/?q=The%20Matrix)'));
    });

    test('watchlist toggle → planned row, no watch date', () async {
      writeCsv(_csv(<List<String>>[
        <String>['', '2026-04-26 20:56:45', 'Почтальон', 'The Postman',
            'Фильм', '1997'],
      ]));
      when(() => mockTmdb.searchMovies(any(), year: any(named: 'year')))
          .thenAnswer(
              (_) async => <Movie>[createTestMovie(tmdbId: 7, releaseYear: 1997)]);

      final UniversalImportResult result = await sut.import(
        KinoriumImportOptions(filePath: csvPath, isWishlist: true),
      );

      expect(result.success, isTrue);
      final Map<String, dynamic> row = capturedItemRows().single;
      expect(row['status'], ItemStatus.planned.value);
      expect(row['completed_at'], isNull);
    });

    test('retries without the year filter before giving up', () async {
      writeCsv(_csv(<List<String>>[
        <String>['', '', 'Обнажённая убийца', 'Naked Killer', 'Фильм', '1992'],
      ]));
      when(() => mockTmdb.searchMovies(any(), year: 1992))
          .thenAnswer((_) async => <Movie>[]);
      when(() => mockTmdb.searchMovies(any(), year: null))
          .thenAnswer(
              (_) async => <Movie>[createTestMovie(tmdbId: 88, releaseYear: 1992)]);

      final UniversalImportResult result =
          await sut.import(KinoriumImportOptions(filePath: csvPath));

      expect(result.success, isTrue);
      expect(result.totalImported, 1);
      expect(result.totalWishlisted, 0);
    });

    test('re-sync refreshes rating of an already-present item', () async {
      writeCsv(_csv(<List<String>>[
        <String>['9', '', 'Матрица', 'The Matrix', 'Фильм', '1999'],
      ]));
      when(() => mockTmdb.searchMovies(any(), year: any(named: 'year')))
          .thenAnswer(
              (_) async => <Movie>[createTestMovie(tmdbId: 603, releaseYear: 1999)]);
      when(() => mockRepo.getById(1))
          .thenAnswer((_) async => createTestCollection(id: 1));
      when(() => mockRepo.getItems(any())).thenAnswer((_) async =>
          <CollectionItem>[
            createTestCollectionItem(
              id: 42,
              mediaType: MediaType.movie,
              externalId: 603,
              userRating: 5,
            ),
          ]);

      final UniversalImportResult result = await sut.import(
        KinoriumImportOptions(filePath: csvPath, collectionId: 1),
      );

      expect(result.success, isTrue);
      expect(result.totalImported, 0, reason: 'already present → not re-added');
      expect(result.totalUpdated, 1);
      expect(capturedItemRows(), isEmpty);
      final List<(int, Map<String, dynamic>)> updates =
          verify(() => mockRepo.updateItemFieldsBatch(captureAny()))
              .captured
              .single as List<(int, Map<String, dynamic>)>;
      expect(updates, hasLength(1));
      expect(updates.single.$1, 42);
      expect(updates.single.$2['user_rating'], 9.0);
    });

    test('re-sync leaves an unchanged item untouched', () async {
      writeCsv(_csv(<List<String>>[
        <String>['5', '', 'Матрица', 'The Matrix', 'Фильм', '1999'],
      ]));
      when(() => mockTmdb.searchMovies(any(), year: any(named: 'year')))
          .thenAnswer(
              (_) async => <Movie>[createTestMovie(tmdbId: 603, releaseYear: 1999)]);
      when(() => mockRepo.getById(1))
          .thenAnswer((_) async => createTestCollection(id: 1));
      when(() => mockRepo.getItems(any())).thenAnswer((_) async =>
          <CollectionItem>[
            createTestCollectionItem(
              id: 42,
              mediaType: MediaType.movie,
              externalId: 603,
              userRating: 5,
              userComment:
                  '[Link](https://en.kinorium.com/search/?q=The%20Matrix)',
            ),
          ]);

      final UniversalImportResult result = await sut.import(
        KinoriumImportOptions(filePath: csvPath, collectionId: 1),
      );

      expect(result.success, isTrue);
      expect(result.totalImported, 0);
      expect(result.totalUpdated, 0,
          reason: 'same rating and same note (link) → no update');
      expect(capturedItemRows(), isEmpty);
    });

    test('no TMDB match → batched into the wishlist under one tag', () async {
      writeCsv(_csv(<List<String>>[
        <String>['', '', 'Неизвестный фильм', '', 'Фильм', '2099'],
      ]));
      when(() => mockTmdb.searchMovies(any(), year: any(named: 'year')))
          .thenAnswer((_) async => <Movie>[]);

      final UniversalImportResult result =
          await sut.import(KinoriumImportOptions(filePath: csvPath));

      expect(result.success, isTrue);
      expect(result.totalImported, 0);
      expect(result.totalWishlisted, 1);
      final List<Map<String, dynamic>> wlRows =
          verify(() => mockWishlist.addWishlistItemsBatch(captureAny()))
              .captured
              .single as List<Map<String, dynamic>>;
      expect(wlRows, hasLength(1));
      expect(wlRows.single['text'], 'Неизвестный фильм');
      expect(wlRows.single['tag'], isNotNull,
          reason: 'wishlist items get a single import tag');
      expect(wlRows.single['note'],
          contains('https://en.kinorium.com/search/?q='));
    });

    test('missing file → failure result', () async {
      final UniversalImportResult result = await sut.import(
        const KinoriumImportOptions(filePath: '/no/such/file.csv'),
      );
      expect(result.success, isFalse);
      expect(result.fatalError, isNotNull);
    });

    test('series → tv show row resolved on the TV endpoint', () async {
      // Real watchlist row (back.csv); Year 2026.
      writeCsv(_csv(<List<String>>[
        <String>['', '', 'Рыцарь Семи Королевств',
            'A Knight of the Seven Kingdoms', 'Сериал', '2026'],
      ]));
      when(() => mockTmdb.searchTvShows(any(),
              firstAirDateYear: any(named: 'firstAirDateYear')))
          .thenAnswer((_) async =>
              <TvShow>[createTestTvShow(tmdbId: 1396, firstAirYear: 2026)]);

      final UniversalImportResult result =
          await sut.import(KinoriumImportOptions(filePath: csvPath));

      expect(result.success, isTrue);
      expect(result.totalImported, 1);
      verify(() => mockTvShowDao.upsertTvShows(any())).called(1);
      verifyNever(() => mockTmdb.searchMovies(any(), year: any(named: 'year')));
      final Map<String, dynamic> row = capturedItemRows().single;
      expect(row['media_type'], MediaType.tvShow.value);
      expect(row['external_id'], 1396);
    });

    test('animated film → animation type with the movie platform id',
        () async {
      // Real watchlist row (back.csv).
      writeCsv(_csv(<List<String>>[
        <String>['', '', 'Миньоны и монстры', 'Minions & Monsters',
            'Мультфильм', '2026'],
      ]));
      when(() => mockTmdb.searchMovies(any(), year: any(named: 'year')))
          .thenAnswer(
              (_) async => <Movie>[createTestMovie(tmdbId: 129, releaseYear: 2026)]);

      final UniversalImportResult result =
          await sut.import(KinoriumImportOptions(filePath: csvPath));

      expect(result.success, isTrue);
      final Map<String, dynamic> row = capturedItemRows().single;
      expect(row['media_type'], MediaType.animation.value);
      expect(row['platform_id'], AnimationSource.movie);
      verify(() => mockMovieDao.upsertMovies(any())).called(1);
    });

    test('animated series → animation type with the tv platform id', () async {
      // Real watchlist row (back.csv): a "Мультсериал".
      writeCsv(_csv(<List<String>>[
        <String>['', '', "Люди Икс '97", "X-Men '97", 'Мультсериал', '2024'],
      ]));
      when(() => mockTmdb.searchTvShows(any(),
              firstAirDateYear: any(named: 'firstAirDateYear')))
          .thenAnswer((_) async =>
              <TvShow>[createTestTvShow(tmdbId: 219, firstAirYear: 2024)]);

      final UniversalImportResult result =
          await sut.import(KinoriumImportOptions(filePath: csvPath));

      expect(result.success, isTrue);
      final Map<String, dynamic> row = capturedItemRows().single;
      expect(row['media_type'], MediaType.animation.value);
      expect(row['platform_id'], AnimationSource.tvShow);
      verify(() => mockTvShowDao.upsertTvShows(any())).called(1);
    });

    test('import notes option adds directors and actors to the comment',
        () async {
      // Real watched row (backup_1381523_votes.csv) with cast & crew.
      writeCsv(<String>[
        _row(<String>['My rating', 'Date', 'Title', 'Original Title', 'Type',
            'Year', 'Actors', 'Directors']),
        _row(<String>['6', '2026-05-17 01:49:42', 'Я иду искать 2',
            'Ready or Not: Here I Come', 'Фильм', '2025',
            'Самара Уивинг, Кэтрин Ньютон',
            'Мэтт Беттинелли-Олпин, Тайлер Джиллетт']),
      ].join('\n'));
      when(() => mockTmdb.searchMovies(any(), year: any(named: 'year')))
          .thenAnswer(
              (_) async => <Movie>[createTestMovie(tmdbId: 603, releaseYear: 2025)]);

      final UniversalImportResult result = await sut.import(
        KinoriumImportOptions(filePath: csvPath, importNotes: true),
      );

      expect(result.success, isTrue);
      final Map<String, dynamic> row = capturedItemRows().single;
      expect(row['user_comment'],
          contains('Directors: Мэтт Беттинелли-Олпин, Тайлер Джиллетт'));
      expect(row['user_comment'], contains('Actors: Самара Уивинг, Кэтрин Ньютон'));
    });

    test('same title twice in the file → one row, the duplicate skipped',
        () async {
      // Real watched row (backup_1381523_votes.csv), listed twice.
      writeCsv(_csv(<List<String>>[
        <String>['5', '2026-05-14 20:58:46', 'Токсичный мститель 2',
            'The Toxic Avenger, Part II', 'Фильм', '1989'],
        <String>['5', '2026-05-14 20:58:46', 'Токсичный мститель 2',
            'The Toxic Avenger, Part II', 'Фильм', '1989'],
      ]));
      when(() => mockTmdb.searchMovies(any(), year: any(named: 'year')))
          .thenAnswer(
              (_) async => <Movie>[createTestMovie(tmdbId: 603, releaseYear: 1989)]);

      final UniversalImportResult result =
          await sut.import(KinoriumImportOptions(filePath: csvPath));

      expect(result.success, isTrue);
      expect(result.totalImported, 1);
      expect(capturedItemRows(), hasLength(1));
      // The duplicate row resolves to the same TMDB id; rather than being
      // silently dropped it is routed to the wishlist so nothing is lost.
      expect(result.totalWishlisted, 1);
    });

    test('unsupported type (episode) → wishlisted without a TMDB search',
        () async {
      writeCsv(_csv(<List<String>>[
        <String>['', '', 'Пилот', 'Pilot', 'Эпизод', '2010'],
      ]));

      final UniversalImportResult result =
          await sut.import(KinoriumImportOptions(filePath: csvPath));

      expect(result.success, isTrue);
      expect(result.totalImported, 0);
      // Episodes aren't collection items, but the row is preserved in the
      // wishlist rather than dropped — and no TMDB search is spent on it.
      expect(result.totalWishlisted, 1);
      verifyNever(() => mockTmdb.searchMovies(any(), year: any(named: 'year')));
    });
  });
}
