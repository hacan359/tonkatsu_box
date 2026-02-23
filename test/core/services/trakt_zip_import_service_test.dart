import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/core/api/tmdb_api.dart';
import 'package:xerabora/core/database/database_service.dart';
import 'package:xerabora/core/services/import_service.dart';
import 'package:xerabora/core/services/trakt_zip_import_service.dart';
import 'package:xerabora/data/repositories/collection_repository.dart';
import 'package:xerabora/data/repositories/wishlist_repository.dart';
import 'package:xerabora/shared/models/collection.dart';
import 'package:xerabora/shared/models/collection_item.dart';
import 'package:xerabora/shared/models/item_status.dart';
import 'package:xerabora/shared/models/media_type.dart';
import 'package:xerabora/shared/models/movie.dart';
import 'package:xerabora/shared/models/tv_show.dart';
import 'package:xerabora/shared/models/wishlist_item.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockTmdbApi extends Mock implements TmdbApi {}

class MockCollectionRepository extends Mock implements CollectionRepository {}

class MockDatabaseService extends Mock implements DatabaseService {}

class MockWishlistRepository extends Mock implements WishlistRepository {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Создаёт ZIP-архив в памяти со структурой Trakt export.
List<int> createTestZip({
  String username = 'testuser',
  String? watchedMoviesJson,
  String? watchedShowsJson,
  String? ratingsMoviesJson,
  String? ratingsShowsJson,
  String? watchlistJson,
}) {
  final Archive archive = Archive();
  if (watchedMoviesJson != null) {
    archive.addFile(ArchiveFile.string(
      '$username/watched/watched-movies.json',
      watchedMoviesJson,
    ));
  }
  if (watchedShowsJson != null) {
    archive.addFile(ArchiveFile.string(
      '$username/watched/watched-shows.json',
      watchedShowsJson,
    ));
  }
  if (ratingsMoviesJson != null) {
    archive.addFile(ArchiveFile.string(
      '$username/ratings/ratings-movies.json',
      ratingsMoviesJson,
    ));
  }
  if (ratingsShowsJson != null) {
    archive.addFile(ArchiveFile.string(
      '$username/ratings/ratings-shows.json',
      ratingsShowsJson,
    ));
  }
  if (watchlistJson != null) {
    archive.addFile(ArchiveFile.string(
      '$username/lists/watchlist.json',
      watchlistJson,
    ));
  }
  return ZipEncoder().encode(archive);
}

/// Создаёт JSON для одного watched movie.
String watchedMovieJson({
  String title = 'Test Movie',
  int? tmdbId = 100,
  int year = 2020,
  String? lastWatchedAt = '2023-06-15T10:30:00.000Z',
}) {
  final Map<String, dynamic> movie = <String, dynamic>{
    'title': title,
    'year': year,
    'ids': <String, dynamic>{'tmdb': tmdbId},
  };
  final Map<String, dynamic> entry = <String, dynamic>{
    'movie': movie,
    // ignore: use_null_aware_elements
    if (lastWatchedAt != null) 'last_watched_at': lastWatchedAt,
  };
  return jsonEncode(<Map<String, dynamic>>[entry]);
}

/// Создаёт JSON для одного watched show с опциональными эпизодами.
String watchedShowJson({
  String title = 'Test Show',
  int? tmdbId = 200,
  String? lastWatchedAt = '2023-08-20T15:00:00.000Z',
  List<Map<String, dynamic>>? seasons,
}) {
  final Map<String, dynamic> show = <String, dynamic>{
    'title': title,
    'ids': <String, dynamic>{'tmdb': tmdbId},
  };
  final Map<String, dynamic> entry = <String, dynamic>{
    'show': show,
    // ignore: use_null_aware_elements
    if (lastWatchedAt != null) 'last_watched_at': lastWatchedAt,
    // ignore: use_null_aware_elements
    if (seasons != null) 'seasons': seasons,
  };
  return jsonEncode(<Map<String, dynamic>>[entry]);
}

/// Создаёт JSON для ratings.
String ratingsJson({
  required String type,
  String title = 'Rated Item',
  int? tmdbId = 300,
  int rating = 8,
}) {
  final String mediaKey = type == 'movie' ? 'movie' : 'show';
  final Map<String, dynamic> media = <String, dynamic>{
    'title': title,
    'ids': <String, dynamic>{'tmdb': tmdbId},
  };
  final Map<String, dynamic> entry = <String, dynamic>{
    mediaKey: media,
    'rating': rating,
  };
  return jsonEncode(<Map<String, dynamic>>[entry]);
}

/// Создаёт JSON для watchlist.
String watchlistEntryJson({
  String type = 'movie',
  String title = 'Watchlist Item',
  int? tmdbId = 400,
}) {
  final String mediaKey = type == 'movie' ? 'movie' : 'show';
  final Map<String, dynamic> media = <String, dynamic>{
    'title': title,
    'ids': <String, dynamic>{'tmdb': tmdbId},
  };
  final Map<String, dynamic> entry = <String, dynamic>{
    'type': type,
    mediaKey: media,
  };
  return jsonEncode(<Map<String, dynamic>>[entry]);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockTmdbApi mockTmdb;
  late MockCollectionRepository mockRepo;
  late MockDatabaseService mockDb;
  late MockWishlistRepository mockWishlist;
  late TraktZipImportService sut;

  late Directory tempDir;
  late String zipPath;

  final DateTime testDate = DateTime(2024, 1, 15, 12, 0, 0);

  setUpAll(() {
    registerFallbackValue(const Movie(tmdbId: 0, title: 'fallback'));
    registerFallbackValue(const TvShow(tmdbId: 0, title: 'fallback'));
    registerFallbackValue(MediaType.game);
    registerFallbackValue(ItemStatus.notStarted);
    registerFallbackValue(CollectionType.own);
  });

  setUp(() {
    mockTmdb = MockTmdbApi();
    mockRepo = MockCollectionRepository();
    mockDb = MockDatabaseService();
    mockWishlist = MockWishlistRepository();
    sut = TraktZipImportService(
      tmdbApi: mockTmdb,
      repository: mockRepo,
      database: mockDb,
      wishlistRepository: mockWishlist,
    );

    tempDir = Directory.systemTemp.createTempSync('trakt_test');
    zipPath = '${tempDir.path}/test.zip';
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  /// Записывает байты ZIP в тестовый файл.
  void writeZip(List<int> bytes) {
    File(zipPath).writeAsBytesSync(bytes);
  }

  /// Хелпер для создания тестовой коллекции.
  Collection createTestCollection({
    int id = 1,
    String name = 'Test',
    String author = 'testuser',
  }) {
    return Collection(
      id: id,
      name: name,
      author: author,
      type: CollectionType.own,
      createdAt: testDate,
    );
  }

  /// Хелпер для создания CollectionItem.
  CollectionItem createTestItem({
    int id = 1,
    int collectionId = 1,
    MediaType mediaType = MediaType.movie,
    int externalId = 100,
    ItemStatus status = ItemStatus.notStarted,
    int? userRating,
    DateTime? completedAt,
  }) {
    return CollectionItem(
      id: id,
      collectionId: collectionId,
      mediaType: mediaType,
      externalId: externalId,
      status: status,
      userRating: userRating,
      completedAt: completedAt,
      addedAt: testDate,
    );
  }

  // =========================================================================
  // TraktZipInfo
  // =========================================================================

  group('TraktZipInfo', () {
    group('constructor', () {
      test('должен создать валидный экземпляр с параметрами', () {
        const TraktZipInfo info = TraktZipInfo(
          isValid: true,
          username: 'alice',
          watchedMovieCount: 5,
          watchedShowCount: 3,
          ratedMovieCount: 2,
          ratedShowCount: 1,
          watchlistCount: 4,
        );

        expect(info.isValid, isTrue);
        expect(info.username, equals('alice'));
        expect(info.watchedMovieCount, equals(5));
        expect(info.watchedShowCount, equals(3));
        expect(info.ratedMovieCount, equals(2));
        expect(info.ratedShowCount, equals(1));
        expect(info.watchlistCount, equals(4));
        expect(info.error, isNull);
      });

      test('должен использовать значения по умолчанию', () {
        const TraktZipInfo info = TraktZipInfo(isValid: false);

        expect(info.username, equals(''));
        expect(info.watchedMovieCount, equals(0));
        expect(info.watchedShowCount, equals(0));
        expect(info.ratedMovieCount, equals(0));
        expect(info.ratedShowCount, equals(0));
        expect(info.watchlistCount, equals(0));
        expect(info.error, isNull);
      });
    });

    group('invalid()', () {
      test('должен создать невалидный результат с ошибкой', () {
        const TraktZipInfo info = TraktZipInfo.invalid('Bad archive');

        expect(info.isValid, isFalse);
        expect(info.username, equals(''));
        expect(info.watchedMovieCount, equals(0));
        expect(info.watchedShowCount, equals(0));
        expect(info.ratedMovieCount, equals(0));
        expect(info.ratedShowCount, equals(0));
        expect(info.watchlistCount, equals(0));
        expect(info.error, equals('Bad archive'));
      });
    });

    group('totalItems', () {
      test('должен вычислить сумму всех категорий', () {
        const TraktZipInfo info = TraktZipInfo(
          isValid: true,
          watchedMovieCount: 10,
          watchedShowCount: 5,
          ratedMovieCount: 3,
          ratedShowCount: 2,
          watchlistCount: 7,
        );

        expect(info.totalItems, equals(27));
      });

      test('должен вернуть 0 для пустого архива', () {
        const TraktZipInfo info = TraktZipInfo(isValid: false);
        expect(info.totalItems, equals(0));
      });
    });
  });

  // =========================================================================
  // TraktImportOptions
  // =========================================================================

  group('TraktImportOptions', () {
    group('constructor', () {
      test('должен создать экземпляр с обязательными параметрами', () {
        const TraktImportOptions options = TraktImportOptions(
          zipPath: '/path/to/file.zip',
        );

        expect(options.zipPath, equals('/path/to/file.zip'));
        expect(options.collectionId, isNull);
        expect(options.importWatched, isTrue);
        expect(options.importRatings, isTrue);
        expect(options.importWatchlist, isTrue);
      });

      test('должен принимать все параметры', () {
        const TraktImportOptions options = TraktImportOptions(
          zipPath: '/path.zip',
          collectionId: 42,
          importWatched: false,
          importRatings: false,
          importWatchlist: false,
        );

        expect(options.zipPath, equals('/path.zip'));
        expect(options.collectionId, equals(42));
        expect(options.importWatched, isFalse);
        expect(options.importRatings, isFalse);
        expect(options.importWatchlist, isFalse);
      });
    });
  });

  // =========================================================================
  // TraktImportResult
  // =========================================================================

  group('TraktImportResult', () {
    group('constructor', () {
      test('должен создать экземпляр с параметрами', () {
        final Collection collection = createTestCollection();
        final TraktImportResult result = TraktImportResult(
          success: true,
          collection: collection,
          itemsImported: 10,
          itemsSkipped: 2,
          itemsUpdated: 3,
          wishlistItemsAdded: 1,
          errors: const <String>['error1'],
          error: null,
        );

        expect(result.success, isTrue);
        expect(result.collection, equals(collection));
        expect(result.itemsImported, equals(10));
        expect(result.itemsSkipped, equals(2));
        expect(result.itemsUpdated, equals(3));
        expect(result.wishlistItemsAdded, equals(1));
        expect(result.errors.length, equals(1));
        expect(result.error, isNull);
      });

      test('должен использовать значения по умолчанию', () {
        const TraktImportResult result = TraktImportResult(success: false);

        expect(result.collection, isNull);
        expect(result.itemsImported, equals(0));
        expect(result.itemsSkipped, equals(0));
        expect(result.itemsUpdated, equals(0));
        expect(result.wishlistItemsAdded, equals(0));
        expect(result.errors, isEmpty);
        expect(result.error, isNull);
      });
    });

    group('success()', () {
      test('должен создать успешный результат', () {
        final Collection collection = createTestCollection();
        final TraktImportResult result = TraktImportResult.success(
          collection: collection,
          itemsImported: 15,
          itemsSkipped: 3,
          itemsUpdated: 2,
          wishlistItemsAdded: 4,
          errors: const <String>['warn1'],
        );

        expect(result.success, isTrue);
        expect(result.collection, equals(collection));
        expect(result.itemsImported, equals(15));
        expect(result.itemsSkipped, equals(3));
        expect(result.itemsUpdated, equals(2));
        expect(result.wishlistItemsAdded, equals(4));
        expect(result.errors, equals(const <String>['warn1']));
        expect(result.error, isNull);
      });

      test('должен использовать значения по умолчанию для success()', () {
        final Collection collection = createTestCollection();
        final TraktImportResult result = TraktImportResult.success(
          collection: collection,
          itemsImported: 5,
        );

        expect(result.itemsSkipped, equals(0));
        expect(result.itemsUpdated, equals(0));
        expect(result.wishlistItemsAdded, equals(0));
        expect(result.errors, isEmpty);
      });
    });

    group('failure()', () {
      test('должен создать неудачный результат', () {
        const TraktImportResult result =
            TraktImportResult.failure('Something broke');

        expect(result.success, isFalse);
        expect(result.collection, isNull);
        expect(result.itemsImported, equals(0));
        expect(result.itemsSkipped, equals(0));
        expect(result.itemsUpdated, equals(0));
        expect(result.wishlistItemsAdded, equals(0));
        expect(result.errors, isEmpty);
        expect(result.error, equals('Something broke'));
      });
    });
  });

  // =========================================================================
  // validateZip
  // =========================================================================

  group('TraktZipImportService', () {
    group('validateZip', () {
      test('должен вернуть valid для правильного ZIP со всеми файлами',
          () async {
        writeZip(createTestZip(
          username: 'alice',
          watchedMoviesJson: watchedMovieJson(),
          watchedShowsJson: watchedShowJson(),
          ratingsMoviesJson: ratingsJson(type: 'movie'),
          ratingsShowsJson: ratingsJson(type: 'show'),
          watchlistJson: watchlistEntryJson(),
        ));

        final TraktZipInfo info = await sut.validateZip(zipPath);

        expect(info.isValid, isTrue);
        expect(info.username, equals('alice'));
        expect(info.watchedMovieCount, equals(1));
        expect(info.watchedShowCount, equals(1));
        expect(info.ratedMovieCount, equals(1));
        expect(info.ratedShowCount, equals(1));
        expect(info.watchlistCount, equals(1));
        expect(info.totalItems, equals(5));
        expect(info.error, isNull);
      });

      test('должен вернуть корректное количество для каждой категории',
          () async {
        // 2 movies, 0 shows, 1 rating movie, 0 rating shows, 3 watchlist
        final String twoMovies = jsonEncode(<Map<String, dynamic>>[
          <String, dynamic>{
            'movie': <String, dynamic>{
              'title': 'M1',
              'ids': <String, dynamic>{'tmdb': 1},
            },
          },
          <String, dynamic>{
            'movie': <String, dynamic>{
              'title': 'M2',
              'ids': <String, dynamic>{'tmdb': 2},
            },
          },
        ]);

        final String threeWatchlist = jsonEncode(<Map<String, dynamic>>[
          <String, dynamic>{
            'type': 'movie',
            'movie': <String, dynamic>{
              'title': 'W1',
              'ids': <String, dynamic>{'tmdb': 10},
            },
          },
          <String, dynamic>{
            'type': 'show',
            'show': <String, dynamic>{
              'title': 'W2',
              'ids': <String, dynamic>{'tmdb': 11},
            },
          },
          <String, dynamic>{
            'type': 'movie',
            'movie': <String, dynamic>{
              'title': 'W3',
              'ids': <String, dynamic>{'tmdb': 12},
            },
          },
        ]);

        writeZip(createTestZip(
          watchedMoviesJson: twoMovies,
          ratingsMoviesJson: ratingsJson(type: 'movie'),
          watchlistJson: threeWatchlist,
        ));

        final TraktZipInfo info = await sut.validateZip(zipPath);

        expect(info.isValid, isTrue);
        expect(info.watchedMovieCount, equals(2));
        expect(info.watchedShowCount, equals(0));
        expect(info.ratedMovieCount, equals(1));
        expect(info.ratedShowCount, equals(0));
        expect(info.watchlistCount, equals(3));
        expect(info.totalItems, equals(6));
      });

      test('должен извлечь username из корневой папки', () async {
        writeZip(createTestZip(
          username: 'my_trakt_user',
          watchedMoviesJson: watchedMovieJson(),
        ));

        final TraktZipInfo info = await sut.validateZip(zipPath);

        expect(info.username, equals('my_trakt_user'));
      });

      test('должен вернуть invalid для пустого ZIP (без JSON файлов)',
          () async {
        final Archive archive = Archive();
        // Добавляем не-JSON файл
        archive.addFile(ArchiveFile.string('testuser/readme.txt', 'hello'));
        final List<int> bytes = ZipEncoder().encode(archive);
        writeZip(bytes);

        final TraktZipInfo info = await sut.validateZip(zipPath);

        expect(info.isValid, isFalse);
        expect(info.error, equals('No JSON files found in archive'));
      });

      test('должен вернуть invalid для не-ZIP файла', () async {
        File(zipPath).writeAsBytesSync(<int>[0, 1, 2, 3, 4, 5]);

        final TraktZipInfo info = await sut.validateZip(zipPath);

        // archive package бросит ArchiveException
        expect(info.isValid, isFalse);
      });

      test('должен вернуть invalid для ZIP без JSON файлов', () async {
        final Archive archive = Archive();
        archive.addFile(ArchiveFile.string('user/data.csv', 'a,b,c'));
        final List<int> bytes = ZipEncoder().encode(archive);
        writeZip(bytes);

        final TraktZipInfo info = await sut.validateZip(zipPath);

        // CSV файл найден, но не на глубине >= 2 с .json расширением
        // Файл user/data.csv имеет parts.length >= 2 но не .json
        expect(info.isValid, isFalse);
      });

      test('должен вернуть invalid для ZIP с пустыми JSON массивами',
          () async {
        writeZip(createTestZip(
          watchedMoviesJson: '[]',
          watchedShowsJson: '[]',
          ratingsMoviesJson: '[]',
          ratingsShowsJson: '[]',
          watchlistJson: '[]',
        ));

        final TraktZipInfo info = await sut.validateZip(zipPath);

        expect(info.isValid, isFalse);
        expect(info.totalItems, equals(0));
      });

      test('должен вернуть invalid для несуществующего файла', () async {
        final TraktZipInfo info =
            await sut.validateZip('/nonexistent/path.zip');

        expect(info.isValid, isFalse);
      });
    });

    // =======================================================================
    // importFromZip
    // =======================================================================

    group('importFromZip', () {
      /// Настраивает стандартные моки для успешного импорта.
      void setupDefaultMocks({
        int collectionId = 1,
        String collectionName = 'Trakt: testuser',
        String author = 'testuser',
      }) {
        final Collection collection = createTestCollection(
          id: collectionId,
          name: collectionName,
          author: author,
        );

        when(() => mockRepo.create(
              name: any(named: 'name'),
              author: any(named: 'author'),
              type: any(named: 'type'),
            )).thenAnswer((_) async => collection);

        when(() => mockRepo.getById(collectionId))
            .thenAnswer((_) async => collection);

        when(() => mockRepo.findItem(
              collectionId: any(named: 'collectionId'),
              mediaType: any(named: 'mediaType'),
              externalId: any(named: 'externalId'),
            )).thenAnswer((_) async => null);

        when(() => mockRepo.addItem(
              collectionId: any(named: 'collectionId'),
              mediaType: any(named: 'mediaType'),
              externalId: any(named: 'externalId'),
              platformId: any(named: 'platformId'),
              status: any(named: 'status'),
            )).thenAnswer((_) async => 10);

        when(() => mockRepo.updateItemStatus(
              any(),
              any(),
              mediaType: any(named: 'mediaType'),
            )).thenAnswer((_) async {});

        when(() => mockDb.upsertMovie(any())).thenAnswer((_) async {});
        when(() => mockDb.upsertTvShow(any())).thenAnswer((_) async {});
        when(() => mockDb.updateItemActivityDates(
              any(),
              startedAt: any(named: 'startedAt'),
              completedAt: any(named: 'completedAt'),
              lastActivityAt: any(named: 'lastActivityAt'),
            )).thenAnswer((_) async {});
        when(() => mockDb.updateItemUserRating(any(), any()))
            .thenAnswer((_) async {});
        when(() => mockDb.markEpisodeWatched(any(), any(), any(), any()))
            .thenAnswer((_) async {});

        when(() => mockWishlist.add(
              text: any(named: 'text'),
              mediaTypeHint: any(named: 'mediaTypeHint'),
            )).thenAnswer((_) async => WishlistItem(
              id: 1,
              text: 'test',
              createdAt: testDate,
            ));
      }

      test('должен создать новую коллекцию когда collectionId == null',
          () async {
        setupDefaultMocks();
        when(() => mockTmdb.getMovie(any()))
            .thenAnswer((_) async => const Movie(tmdbId: 100, title: 'M'));
        writeZip(createTestZip(
          watchedMoviesJson: watchedMovieJson(),
        ));

        final TraktImportResult result = await sut.importFromZip(
          options: TraktImportOptions(zipPath: zipPath),
        );

        expect(result.success, isTrue);
        verify(() => mockRepo.create(
              name: 'Trakt: testuser',
              author: 'testuser',
              type: any(named: 'type'),
            )).called(1);
      });

      test('должен использовать существующую коллекцию', () async {
        setupDefaultMocks(collectionId: 42);
        when(() => mockTmdb.getMovie(any()))
            .thenAnswer((_) async => const Movie(tmdbId: 100, title: 'M'));
        writeZip(createTestZip(
          watchedMoviesJson: watchedMovieJson(),
        ));

        final TraktImportResult result = await sut.importFromZip(
          options: TraktImportOptions(
            zipPath: zipPath,
            collectionId: 42,
          ),
        );

        expect(result.success, isTrue);
        verify(() => mockRepo.getById(42)).called(1);
        verifyNever(() => mockRepo.create(
              name: any(named: 'name'),
              author: any(named: 'author'),
              type: any(named: 'type'),
            ));
      });

      test('должен вернуть failure для несуществующей коллекции', () async {
        when(() => mockRepo.getById(999)).thenAnswer((_) async => null);

        // Нужен валидный ZIP
        when(() => mockTmdb.getMovie(any()))
            .thenAnswer((_) async => const Movie(tmdbId: 100, title: 'M'));
        when(() => mockDb.upsertMovie(any())).thenAnswer((_) async {});
        writeZip(createTestZip(
          watchedMoviesJson: watchedMovieJson(),
        ));

        final TraktImportResult result = await sut.importFromZip(
          options: TraktImportOptions(
            zipPath: zipPath,
            collectionId: 999,
          ),
        );

        expect(result.success, isFalse);
        expect(result.error, equals('Collection not found'));
      });

      test('должен импортировать watched movies как completed', () async {
        setupDefaultMocks();
        const Movie testMovie = Movie(tmdbId: 100, title: 'Inception');
        when(() => mockTmdb.getMovie(100))
            .thenAnswer((_) async => testMovie);
        writeZip(createTestZip(
          watchedMoviesJson: watchedMovieJson(
            title: 'Inception',
            tmdbId: 100,
          ),
        ));

        final TraktImportResult result = await sut.importFromZip(
          options: TraktImportOptions(zipPath: zipPath),
        );

        expect(result.success, isTrue);
        expect(result.itemsImported, equals(1));
        verify(() => mockRepo.addItem(
              collectionId: 1,
              mediaType: MediaType.movie,
              externalId: 100,
              platformId: null,
              status: ItemStatus.completed,
            )).called(1);
      });

      test('должен установить completedAt из last_watched_at', () async {
        setupDefaultMocks();
        when(() => mockTmdb.getMovie(100))
            .thenAnswer((_) async => const Movie(tmdbId: 100, title: 'M'));

        writeZip(createTestZip(
          watchedMoviesJson: watchedMovieJson(
            lastWatchedAt: '2023-06-15T10:30:00.000Z',
          ),
        ));

        await sut.importFromZip(
          options: TraktImportOptions(zipPath: zipPath),
        );

        verify(() => mockDb.updateItemActivityDates(
              10,
              completedAt: any(named: 'completedAt'),
              lastActivityAt: any(named: 'lastActivityAt'),
            )).called(1);
      });

      test('должен импортировать watched shows как inProgress', () async {
        setupDefaultMocks();
        when(() => mockTmdb.getTvShow(200))
            .thenAnswer((_) async => const TvShow(tmdbId: 200, title: 'BB'));

        writeZip(createTestZip(
          watchedShowsJson: watchedShowJson(
            title: 'Breaking Bad',
            tmdbId: 200,
            seasons: <Map<String, dynamic>>[
              <String, dynamic>{
                'number': 1,
                'episodes': <Map<String, dynamic>>[
                  <String, dynamic>{'number': 1},
                  <String, dynamic>{'number': 2},
                ],
              },
            ],
          ),
        ));

        final TraktImportResult result = await sut.importFromZip(
          options: TraktImportOptions(zipPath: zipPath),
        );

        expect(result.success, isTrue);
        expect(result.itemsImported, equals(1));
        verify(() => mockRepo.addItem(
              collectionId: 1,
              mediaType: MediaType.tvShow,
              externalId: 200,
              platformId: null,
              status: ItemStatus.inProgress,
            )).called(1);
      });

      test('должен определить анимацию у фильмов (genres содержит Animation)',
          () async {
        setupDefaultMocks();
        const Movie animMovie = Movie(
          tmdbId: 100,
          title: 'Spirited Away',
          genres: <String>['Animation', 'Fantasy'],
        );
        when(() => mockTmdb.getMovie(100))
            .thenAnswer((_) async => animMovie);

        writeZip(createTestZip(
          watchedMoviesJson: watchedMovieJson(
            title: 'Spirited Away',
            tmdbId: 100,
          ),
        ));

        await sut.importFromZip(
          options: TraktImportOptions(zipPath: zipPath),
        );

        verify(() => mockRepo.addItem(
              collectionId: 1,
              mediaType: MediaType.animation,
              externalId: 100,
              platformId: AnimationSource.movie,
              status: ItemStatus.completed,
            )).called(1);
      });

      test('должен определить анимацию у сериалов (genres содержит 16)',
          () async {
        setupDefaultMocks();
        const TvShow animShow = TvShow(
          tmdbId: 200,
          title: 'Attack on Titan',
          genres: <String>['16', '10759'],
        );
        when(() => mockTmdb.getTvShow(200))
            .thenAnswer((_) async => animShow);

        writeZip(createTestZip(
          watchedShowsJson: watchedShowJson(
            title: 'Attack on Titan',
            tmdbId: 200,
            seasons: <Map<String, dynamic>>[
              <String, dynamic>{
                'number': 1,
                'episodes': <Map<String, dynamic>>[
                  <String, dynamic>{'number': 1},
                ],
              },
            ],
          ),
        ));

        await sut.importFromZip(
          options: TraktImportOptions(zipPath: zipPath),
        );

        verify(() => mockRepo.addItem(
              collectionId: 1,
              mediaType: MediaType.animation,
              externalId: 200,
              platformId: AnimationSource.tvShow,
              status: ItemStatus.inProgress,
            )).called(1);
      });

      test('должен пропустить элементы без TMDB ID и добавить ошибку',
          () async {
        setupDefaultMocks();

        writeZip(createTestZip(
          watchedMoviesJson: watchedMovieJson(
            title: 'No TMDB Movie',
            tmdbId: null,
          ),
        ));

        final TraktImportResult result = await sut.importFromZip(
          options: TraktImportOptions(zipPath: zipPath),
        );

        expect(result.success, isTrue);
        expect(result.itemsSkipped, equals(1));
        expect(result.errors.length, equals(1));
        expect(result.errors.first, contains('No TMDB Movie'));
        expect(result.errors.first, contains('no TMDB ID'));
      });

      test('должен пропустить элементы когда TMDB API вернул null', () async {
        setupDefaultMocks();
        when(() => mockTmdb.getMovie(100)).thenAnswer((_) async => null);

        writeZip(createTestZip(
          watchedMoviesJson: watchedMovieJson(
            title: 'Unavailable Movie',
            tmdbId: 100,
          ),
        ));

        final TraktImportResult result = await sut.importFromZip(
          options: TraktImportOptions(zipPath: zipPath),
        );

        expect(result.success, isTrue);
        expect(result.itemsSkipped, equals(1));
        expect(result.errors.length, equals(1));
        expect(result.errors.first, contains('TMDB data not available'));
      });

      test('должен применить рейтинг когда userRating == null', () async {
        setupDefaultMocks();
        const Movie testMovie = Movie(tmdbId: 300, title: 'Rated');
        when(() => mockTmdb.getMovie(300))
            .thenAnswer((_) async => testMovie);

        // Фильм уже в коллекции, но без рейтинга
        final CollectionItem existingItem = createTestItem(
          id: 50,
          externalId: 300,
          status: ItemStatus.completed,
          userRating: null,
        );
        when(() => mockRepo.findItem(
              collectionId: 1,
              mediaType: MediaType.movie,
              externalId: 300,
            )).thenAnswer((_) async => existingItem);

        writeZip(createTestZip(
          ratingsMoviesJson: ratingsJson(
            type: 'movie',
            tmdbId: 300,
            rating: 9,
          ),
        ));

        final TraktImportResult result = await sut.importFromZip(
          options: TraktImportOptions(
            zipPath: zipPath,
            importWatched: false,
          ),
        );

        expect(result.success, isTrue);
        verify(() => mockDb.updateItemUserRating(50, 9)).called(1);
      });

      test('должен НЕ перезаписывать существующий userRating', () async {
        setupDefaultMocks();
        const Movie testMovie = Movie(tmdbId: 300, title: 'Rated');
        when(() => mockTmdb.getMovie(300))
            .thenAnswer((_) async => testMovie);

        // Фильм уже в коллекции С рейтингом
        final CollectionItem existingItem = createTestItem(
          id: 50,
          externalId: 300,
          status: ItemStatus.completed,
          userRating: 7,
        );
        when(() => mockRepo.findItem(
              collectionId: 1,
              mediaType: MediaType.movie,
              externalId: 300,
            )).thenAnswer((_) async => existingItem);

        writeZip(createTestZip(
          ratingsMoviesJson: ratingsJson(
            type: 'movie',
            tmdbId: 300,
            rating: 9,
          ),
        ));

        await sut.importFromZip(
          options: TraktImportOptions(
            zipPath: zipPath,
            importWatched: false,
          ),
        );

        // updateItemUserRating НЕ должен вызываться
        verifyNever(() => mockDb.updateItemUserRating(50, any()));
      });

      test('должен создать элемент из ratings если нет в коллекции', () async {
        setupDefaultMocks();
        const Movie testMovie = Movie(tmdbId: 300, title: 'New Rated');
        when(() => mockTmdb.getMovie(300))
            .thenAnswer((_) async => testMovie);

        // findItem вернёт null для rating-элемента
        when(() => mockRepo.findItem(
              collectionId: 1,
              mediaType: MediaType.movie,
              externalId: 300,
            )).thenAnswer((_) async => null);

        when(() => mockRepo.addItem(
              collectionId: 1,
              mediaType: MediaType.movie,
              externalId: 300,
              platformId: null,
              status: any(named: 'status'),
            )).thenAnswer((_) async => 60);

        writeZip(createTestZip(
          ratingsMoviesJson: ratingsJson(
            type: 'movie',
            tmdbId: 300,
            rating: 8,
          ),
        ));

        final TraktImportResult result = await sut.importFromZip(
          options: TraktImportOptions(
            zipPath: zipPath,
            importWatched: false,
          ),
        );

        expect(result.success, isTrue);
        expect(result.itemsImported, greaterThanOrEqualTo(1));
        verify(() => mockDb.updateItemUserRating(60, 8)).called(1);
      });

      test('конфликт статусов: должен повысить planned -> completed',
          () async {
        setupDefaultMocks();
        const Movie testMovie = Movie(tmdbId: 100, title: 'Upgrade');
        when(() => mockTmdb.getMovie(100))
            .thenAnswer((_) async => testMovie);

        // Элемент уже planned
        final CollectionItem existingPlanned = createTestItem(
          id: 70,
          externalId: 100,
          status: ItemStatus.planned,
        );
        when(() => mockRepo.findItem(
              collectionId: 1,
              mediaType: MediaType.movie,
              externalId: 100,
            )).thenAnswer((_) async => existingPlanned);

        writeZip(createTestZip(
          watchedMoviesJson: watchedMovieJson(tmdbId: 100),
        ));

        final TraktImportResult result = await sut.importFromZip(
          options: TraktImportOptions(zipPath: zipPath),
        );

        expect(result.success, isTrue);
        expect(result.itemsUpdated, equals(1));
        verify(() => mockRepo.updateItemStatus(
              70,
              ItemStatus.completed,
              mediaType: MediaType.movie,
            )).called(1);
      });

      test('конфликт статусов: НЕ должен понизить completed -> planned',
          () async {
        setupDefaultMocks();
        const TvShow testShow = TvShow(tmdbId: 200, title: 'NoDowngrade');
        when(() => mockTmdb.getTvShow(200))
            .thenAnswer((_) async => testShow);

        // Элемент уже completed
        final CollectionItem existingCompleted = createTestItem(
          id: 80,
          externalId: 200,
          mediaType: MediaType.tvShow,
          status: ItemStatus.completed,
        );
        when(() => mockRepo.findItem(
              collectionId: 1,
              mediaType: MediaType.tvShow,
              externalId: 200,
            )).thenAnswer((_) async => existingCompleted);

        writeZip(createTestZip(
          watchedShowsJson: watchedShowJson(
            tmdbId: 200,
            seasons: <Map<String, dynamic>>[
              <String, dynamic>{
                'number': 1,
                'episodes': <Map<String, dynamic>>[
                  <String, dynamic>{'number': 1},
                ],
              },
            ],
          ),
        ));

        await sut.importFromZip(
          options: TraktImportOptions(zipPath: zipPath),
        );

        // Статус НЕ должен быть обновлён
        verifyNever(() => mockRepo.updateItemStatus(
              80,
              any(),
              mediaType: any(named: 'mediaType'),
            ));
      });

      test('конфликт статусов: НЕ должен перезаписать dropped', () async {
        setupDefaultMocks();
        const Movie testMovie = Movie(tmdbId: 100, title: 'Dropped');
        when(() => mockTmdb.getMovie(100))
            .thenAnswer((_) async => testMovie);

        // Элемент dropped
        final CollectionItem existingDropped = createTestItem(
          id: 90,
          externalId: 100,
          status: ItemStatus.dropped,
        );
        when(() => mockRepo.findItem(
              collectionId: 1,
              mediaType: MediaType.movie,
              externalId: 100,
            )).thenAnswer((_) async => existingDropped);

        writeZip(createTestZip(
          watchedMoviesJson: watchedMovieJson(tmdbId: 100),
        ));

        await sut.importFromZip(
          options: TraktImportOptions(zipPath: zipPath),
        );

        // dropped не должен быть обновлён
        verifyNever(() => mockRepo.updateItemStatus(
              90,
              any(),
              mediaType: any(named: 'mediaType'),
            ));
      });

      test('должен установить completedAt из Trakt если локальный null',
          () async {
        setupDefaultMocks();
        const Movie testMovie = Movie(tmdbId: 100, title: 'Dates');
        when(() => mockTmdb.getMovie(100))
            .thenAnswer((_) async => testMovie);

        // Элемент без completedAt
        final CollectionItem existingItem = createTestItem(
          id: 95,
          externalId: 100,
          status: ItemStatus.planned,
          completedAt: null,
        );
        when(() => mockRepo.findItem(
              collectionId: 1,
              mediaType: MediaType.movie,
              externalId: 100,
            )).thenAnswer((_) async => existingItem);

        writeZip(createTestZip(
          watchedMoviesJson: watchedMovieJson(
            tmdbId: 100,
            lastWatchedAt: '2023-06-15T10:30:00.000Z',
          ),
        ));

        await sut.importFromZip(
          options: TraktImportOptions(zipPath: zipPath),
        );

        verify(() => mockDb.updateItemActivityDates(
              95,
              completedAt: any(named: 'completedAt'),
              lastActivityAt: any(named: 'lastActivityAt'),
              startedAt: any(named: 'startedAt'),
            )).called(1);
      });

      test('должен отметить эпизоды как просмотренные', () async {
        setupDefaultMocks();
        when(() => mockTmdb.getTvShow(200))
            .thenAnswer((_) async => const TvShow(tmdbId: 200, title: 'S'));

        writeZip(createTestZip(
          watchedShowsJson: watchedShowJson(
            tmdbId: 200,
            seasons: <Map<String, dynamic>>[
              <String, dynamic>{
                'number': 1,
                'episodes': <Map<String, dynamic>>[
                  <String, dynamic>{'number': 1},
                  <String, dynamic>{'number': 2},
                  <String, dynamic>{'number': 3},
                ],
              },
              <String, dynamic>{
                'number': 2,
                'episodes': <Map<String, dynamic>>[
                  <String, dynamic>{'number': 1},
                ],
              },
            ],
          ),
        ));

        await sut.importFromZip(
          options: TraktImportOptions(zipPath: zipPath),
        );

        // 3 эпизода S1 + 1 эпизод S2 = 4 вызова
        verify(() =>
                mockDb.markEpisodeWatched(any(), 200, any(), any()))
            .called(4);
      });

      test('должен добавить watchlist элементы как planned', () async {
        setupDefaultMocks();
        const Movie watchlistMovie =
            Movie(tmdbId: 400, title: 'Watchlist Movie');
        when(() => mockTmdb.getMovie(400))
            .thenAnswer((_) async => watchlistMovie);

        writeZip(createTestZip(
          watchlistJson: watchlistEntryJson(
            type: 'movie',
            tmdbId: 400,
            title: 'Watchlist Movie',
          ),
        ));

        final TraktImportResult result = await sut.importFromZip(
          options: TraktImportOptions(
            zipPath: zipPath,
            importWatched: false,
            importRatings: false,
          ),
        );

        expect(result.success, isTrue);
        verify(() => mockRepo.addItem(
              collectionId: 1,
              mediaType: MediaType.movie,
              externalId: 400,
              platformId: null,
              status: ItemStatus.planned,
            )).called(1);
      });

      test('должен добавить в wishlist элементы без данных TMDB', () async {
        setupDefaultMocks();
        // TMDB не содержит данные о фильме 400
        when(() => mockTmdb.getMovie(400)).thenAnswer((_) async => null);

        writeZip(createTestZip(
          watchlistJson: watchlistEntryJson(
            type: 'movie',
            tmdbId: 400,
            title: 'Unknown Movie',
          ),
        ));

        final TraktImportResult result = await sut.importFromZip(
          options: TraktImportOptions(
            zipPath: zipPath,
            importWatched: false,
            importRatings: false,
          ),
        );

        expect(result.success, isTrue);
        expect(result.wishlistItemsAdded, equals(1));
        verify(() => mockWishlist.add(
              text: 'Unknown Movie',
              mediaTypeHint: MediaType.movie,
            )).called(1);
      });

      test('должен добавить в wishlist show элементы без TMDB ID', () async {
        setupDefaultMocks();

        writeZip(createTestZip(
          watchlistJson: watchlistEntryJson(
            type: 'show',
            tmdbId: null,
            title: 'No ID Show',
          ),
        ));

        final TraktImportResult result = await sut.importFromZip(
          options: TraktImportOptions(
            zipPath: zipPath,
            importWatched: false,
            importRatings: false,
          ),
        );

        expect(result.success, isTrue);
        expect(result.wishlistItemsAdded, equals(1));
        verify(() => mockWishlist.add(
              text: 'No ID Show',
              mediaTypeHint: MediaType.tvShow,
            )).called(1);
      });

      test('должен пропустить watchlist элементы уже в коллекции', () async {
        setupDefaultMocks();
        const Movie existingMovie = Movie(tmdbId: 400, title: 'Existing');
        when(() => mockTmdb.getMovie(400))
            .thenAnswer((_) async => existingMovie);

        // Элемент уже в коллекции
        final CollectionItem existing = createTestItem(
          id: 55,
          externalId: 400,
          status: ItemStatus.completed,
        );
        when(() => mockRepo.findItem(
              collectionId: 1,
              mediaType: MediaType.movie,
              externalId: 400,
            )).thenAnswer((_) async => existing);

        writeZip(createTestZip(
          watchlistJson: watchlistEntryJson(
            type: 'movie',
            tmdbId: 400,
          ),
        ));

        final TraktImportResult result = await sut.importFromZip(
          options: TraktImportOptions(
            zipPath: zipPath,
            importWatched: false,
            importRatings: false,
          ),
        );

        expect(result.success, isTrue);
        expect(result.wishlistItemsAdded, equals(0));
        // addItem не должен быть вызван для watchlist (только для watched)
        verifyNever(() => mockRepo.addItem(
              collectionId: 1,
              mediaType: MediaType.movie,
              externalId: 400,
              platformId: null,
              status: ItemStatus.planned,
            ));
      });

      test('должен вызывать progress callback', () async {
        setupDefaultMocks();
        when(() => mockTmdb.getMovie(100))
            .thenAnswer((_) async => const Movie(tmdbId: 100, title: 'M'));

        writeZip(createTestZip(
          watchedMoviesJson: watchedMovieJson(),
        ));

        final List<ImportStage> stages = <ImportStage>[];
        await sut.importFromZip(
          options: TraktImportOptions(zipPath: zipPath),
          onProgress: (ImportProgress progress) {
            if (!stages.contains(progress.stage)) {
              stages.add(progress.stage);
            }
          },
        );

        expect(stages, contains(ImportStage.reading));
        expect(stages, contains(ImportStage.fetchingMovies));
        expect(stages, contains(ImportStage.creatingCollection));
        expect(stages, contains(ImportStage.addingItems));
        expect(stages, contains(ImportStage.completed));
      });

      test('должен уважать importWatched=false', () async {
        setupDefaultMocks();
        when(() => mockTmdb.getMovie(any()))
            .thenAnswer((_) async => const Movie(tmdbId: 100, title: 'M'));

        writeZip(createTestZip(
          watchedMoviesJson: watchedMovieJson(),
          ratingsMoviesJson: ratingsJson(type: 'movie', tmdbId: 100),
        ));

        final TraktImportResult result = await sut.importFromZip(
          options: TraktImportOptions(
            zipPath: zipPath,
            importWatched: false,
          ),
        );

        expect(result.success, isTrue);
        // Watched movies не должны добавляться через addItem с completed
        // Но ratings — через addItem (элемент не в коллекции, есть TMDB)
        // Проверяем что addItem вызывается только для rating (не watched)
        verifyNever(() => mockRepo.addItem(
              collectionId: 1,
              mediaType: MediaType.movie,
              externalId: 100,
              platformId: null,
              status: ItemStatus.completed,
            ));
      });

      test('должен уважать importRatings=false', () async {
        setupDefaultMocks();
        when(() => mockTmdb.getMovie(any()))
            .thenAnswer((_) async => const Movie(tmdbId: 100, title: 'M'));

        writeZip(createTestZip(
          watchedMoviesJson: watchedMovieJson(tmdbId: 100),
          ratingsMoviesJson: ratingsJson(
            type: 'movie',
            tmdbId: 100,
            rating: 9,
          ),
        ));

        await sut.importFromZip(
          options: TraktImportOptions(
            zipPath: zipPath,
            importRatings: false,
          ),
        );

        // updateItemUserRating НЕ должен вызываться
        verifyNever(() => mockDb.updateItemUserRating(any(), any()));
      });

      test('должен уважать importWatchlist=false', () async {
        setupDefaultMocks();
        when(() => mockTmdb.getMovie(400))
            .thenAnswer((_) async => const Movie(tmdbId: 400, title: 'W'));

        writeZip(createTestZip(
          watchlistJson: watchlistEntryJson(tmdbId: 400),
        ));

        final TraktImportResult result = await sut.importFromZip(
          options: TraktImportOptions(
            zipPath: zipPath,
            importWatched: false,
            importRatings: false,
            importWatchlist: false,
          ),
        );

        expect(result.success, isTrue);
        expect(result.wishlistItemsAdded, equals(0));
        verifyNever(() => mockWishlist.add(
              text: any(named: 'text'),
              mediaTypeHint: any(named: 'mediaTypeHint'),
            ));
      });

      test('должен вернуть failure для ошибки чтения файла', () async {
        // Не записываем ZIP файл — путь не существует
        final TraktImportResult result = await sut.importFromZip(
          options: TraktImportOptions(
            zipPath: '${tempDir.path}/nonexistent.zip',
          ),
        );

        expect(result.success, isFalse);
        expect(result.error, contains('Import failed'));
      });

      test('должен вернуть failure для пустого архива', () async {
        final Archive archive = Archive();
        archive.addFile(ArchiveFile.string('user/readme.txt', 'hello'));
        writeZip(ZipEncoder().encode(archive));

        final TraktImportResult result = await sut.importFromZip(
          options: TraktImportOptions(zipPath: zipPath),
        );

        expect(result.success, isFalse);
        expect(result.error, equals('No data found in archive'));
      });

      test('должен корректно определить completed для show без сезонов',
          () async {
        setupDefaultMocks();
        when(() => mockTmdb.getTvShow(200))
            .thenAnswer((_) async => const TvShow(tmdbId: 200, title: 'S'));

        // Шоу без сезонов — resolveShowStatus возвращает completed
        writeZip(createTestZip(
          watchedShowsJson: watchedShowJson(
            tmdbId: 200,
            seasons: null,
          ),
        ));

        await sut.importFromZip(
          options: TraktImportOptions(zipPath: zipPath),
        );

        verify(() => mockRepo.addItem(
              collectionId: 1,
              mediaType: MediaType.tvShow,
              externalId: 200,
              platformId: null,
              status: ItemStatus.completed,
            )).called(1);
      });

      test('должен обработать show с пустыми сезонами как completed',
          () async {
        setupDefaultMocks();
        when(() => mockTmdb.getTvShow(200))
            .thenAnswer((_) async => const TvShow(tmdbId: 200, title: 'S'));

        // Шоу с сезонами без эпизодов — hasAnyEpisode = false → completed
        writeZip(createTestZip(
          watchedShowsJson: watchedShowJson(
            tmdbId: 200,
            seasons: <Map<String, dynamic>>[
              <String, dynamic>{
                'number': 1,
                'episodes': <Map<String, dynamic>>[],
              },
            ],
          ),
        ));

        await sut.importFromZip(
          options: TraktImportOptions(zipPath: zipPath),
        );

        verify(() => mockRepo.addItem(
              collectionId: 1,
              mediaType: MediaType.tvShow,
              externalId: 200,
              platformId: null,
              status: ItemStatus.completed,
            )).called(1);
      });

      test('должен корректно обработать TMDB API exception при fetch',
          () async {
        setupDefaultMocks();
        // TMDB бросает исключение — элемент пропускается
        when(() => mockTmdb.getMovie(100))
            .thenThrow(const TmdbApiException('Error', statusCode: 500));

        writeZip(createTestZip(
          watchedMoviesJson: watchedMovieJson(tmdbId: 100),
        ));

        final TraktImportResult result = await sut.importFromZip(
          options: TraktImportOptions(zipPath: zipPath),
        );

        expect(result.success, isTrue);
        expect(result.itemsSkipped, equals(1));
        expect(result.errors.first, contains('TMDB data not available'));
      });

      test('должен обработать rating для animation show', () async {
        setupDefaultMocks();
        const TvShow animShow = TvShow(
          tmdbId: 500,
          title: 'Anime Show',
          genres: <String>['16', 'Action'],
        );
        when(() => mockTmdb.getTvShow(500))
            .thenAnswer((_) async => animShow);

        // Элемент ещё не в коллекции
        when(() => mockRepo.findItem(
              collectionId: 1,
              mediaType: MediaType.animation,
              externalId: 500,
            )).thenAnswer((_) async => null);

        when(() => mockRepo.addItem(
              collectionId: 1,
              mediaType: MediaType.animation,
              externalId: 500,
              platformId: AnimationSource.tvShow,
              status: any(named: 'status'),
            )).thenAnswer((_) async => 75);

        writeZip(createTestZip(
          ratingsShowsJson: ratingsJson(
            type: 'show',
            tmdbId: 500,
            rating: 10,
          ),
        ));

        final TraktImportResult result = await sut.importFromZip(
          options: TraktImportOptions(
            zipPath: zipPath,
            importWatched: false,
          ),
        );

        expect(result.success, isTrue);
        verify(() => mockDb.updateItemUserRating(75, 10)).called(1);
      });

      test('должен обработать watchlist для animation movie', () async {
        setupDefaultMocks();
        const Movie animMovie = Movie(
          tmdbId: 600,
          title: 'Anime Movie',
          genres: <String>['Animation', 'Adventure'],
        );
        when(() => mockTmdb.getMovie(600))
            .thenAnswer((_) async => animMovie);

        // Элемент ещё не в коллекции
        when(() => mockRepo.findItem(
              collectionId: 1,
              mediaType: MediaType.animation,
              externalId: 600,
            )).thenAnswer((_) async => null);

        when(() => mockRepo.addItem(
              collectionId: 1,
              mediaType: MediaType.animation,
              externalId: 600,
              platformId: AnimationSource.movie,
              status: ItemStatus.planned,
            )).thenAnswer((_) async => 80);

        writeZip(createTestZip(
          watchlistJson: watchlistEntryJson(
            type: 'movie',
            tmdbId: 600,
            title: 'Anime Movie',
          ),
        ));

        final TraktImportResult result = await sut.importFromZip(
          options: TraktImportOptions(
            zipPath: zipPath,
            importWatched: false,
            importRatings: false,
          ),
        );

        expect(result.success, isTrue);
        expect(result.itemsImported, equals(1));
        verify(() => mockRepo.addItem(
              collectionId: 1,
              mediaType: MediaType.animation,
              externalId: 600,
              platformId: AnimationSource.movie,
              status: ItemStatus.planned,
            )).called(1);
      });

      test('должен корректно работать с полным набором данных', () async {
        setupDefaultMocks();

        const Movie movie = Movie(tmdbId: 100, title: 'Movie');
        const TvShow show = TvShow(tmdbId: 200, title: 'Show');
        const Movie ratedMovie = Movie(tmdbId: 300, title: 'Rated Movie');
        const TvShow ratedShow = TvShow(tmdbId: 500, title: 'Rated Show');
        const Movie wlMovie = Movie(tmdbId: 400, title: 'WL Movie');

        when(() => mockTmdb.getMovie(100)).thenAnswer((_) async => movie);
        when(() => mockTmdb.getTvShow(200)).thenAnswer((_) async => show);
        when(() => mockTmdb.getMovie(300))
            .thenAnswer((_) async => ratedMovie);
        when(() => mockTmdb.getTvShow(500))
            .thenAnswer((_) async => ratedShow);
        when(() => mockTmdb.getMovie(400)).thenAnswer((_) async => wlMovie);

        // addItem возвращает разные ID
        int nextItemId = 10;
        when(() => mockRepo.addItem(
              collectionId: any(named: 'collectionId'),
              mediaType: any(named: 'mediaType'),
              externalId: any(named: 'externalId'),
              platformId: any(named: 'platformId'),
              status: any(named: 'status'),
            )).thenAnswer((_) async => nextItemId++);

        writeZip(createTestZip(
          watchedMoviesJson: watchedMovieJson(tmdbId: 100),
          watchedShowsJson: watchedShowJson(
            tmdbId: 200,
            seasons: <Map<String, dynamic>>[
              <String, dynamic>{
                'number': 1,
                'episodes': <Map<String, dynamic>>[
                  <String, dynamic>{'number': 1},
                ],
              },
            ],
          ),
          ratingsMoviesJson: ratingsJson(
            type: 'movie',
            tmdbId: 300,
            rating: 8,
          ),
          ratingsShowsJson: ratingsJson(
            type: 'show',
            tmdbId: 500,
            rating: 7,
          ),
          watchlistJson: watchlistEntryJson(
            type: 'movie',
            tmdbId: 400,
          ),
        ));

        final TraktImportResult result = await sut.importFromZip(
          options: TraktImportOptions(zipPath: zipPath),
        );

        expect(result.success, isTrue);
        // 2 watched + 2 ratings (new) + 1 watchlist = 5 imported
        expect(result.itemsImported, greaterThanOrEqualTo(2));
        expect(result.collection, isNotNull);
      });

      test('должен корректно считать skipped для show без TMDB ID', () async {
        setupDefaultMocks();

        writeZip(createTestZip(
          watchedShowsJson: watchedShowJson(
            title: 'No TMDB Show',
            tmdbId: null,
          ),
        ));

        final TraktImportResult result = await sut.importFromZip(
          options: TraktImportOptions(zipPath: zipPath),
        );

        expect(result.success, isTrue);
        expect(result.itemsSkipped, equals(1));
        expect(result.errors.first, contains('No TMDB Show'));
        expect(result.errors.first, contains('no TMDB ID'));
      });

      test('должен обработать show с null TMDB data', () async {
        setupDefaultMocks();
        when(() => mockTmdb.getTvShow(200)).thenAnswer((_) async => null);

        writeZip(createTestZip(
          watchedShowsJson: watchedShowJson(tmdbId: 200),
        ));

        final TraktImportResult result = await sut.importFromZip(
          options: TraktImportOptions(zipPath: zipPath),
        );

        expect(result.success, isTrue);
        expect(result.itemsSkipped, equals(1));
        expect(result.errors.first, contains('TMDB data not available'));
      });

      test('должен пропустить эпизоды для show без TMDB ID', () async {
        setupDefaultMocks();

        writeZip(createTestZip(
          watchedShowsJson: watchedShowJson(
            tmdbId: null,
            seasons: <Map<String, dynamic>>[
              <String, dynamic>{
                'number': 1,
                'episodes': <Map<String, dynamic>>[
                  <String, dynamic>{'number': 1},
                ],
              },
            ],
          ),
        ));

        await sut.importFromZip(
          options: TraktImportOptions(zipPath: zipPath),
        );

        // markEpisodeWatched не вызывается для show без tmdbId
        verifyNever(
            () => mockDb.markEpisodeWatched(any(), any(), any(), any()));
      });

      test('должен пропустить rating без TMDB ID', () async {
        setupDefaultMocks();

        writeZip(createTestZip(
          ratingsMoviesJson: ratingsJson(
            type: 'movie',
            tmdbId: null,
            rating: 8,
          ),
        ));

        final TraktImportResult result = await sut.importFromZip(
          options: TraktImportOptions(
            zipPath: zipPath,
            importWatched: false,
          ),
        );

        expect(result.success, isTrue);
        verifyNever(() => mockDb.updateItemUserRating(any(), any()));
      });

      test('должен clamp рейтинг в диапазон 1-10', () async {
        setupDefaultMocks();
        const Movie testMovie = Movie(tmdbId: 300, title: 'Clamped');
        when(() => mockTmdb.getMovie(300))
            .thenAnswer((_) async => testMovie);

        // Элемент существует без рейтинга
        final CollectionItem existingItem = createTestItem(
          id: 50,
          externalId: 300,
          userRating: null,
        );
        when(() => mockRepo.findItem(
              collectionId: 1,
              mediaType: MediaType.movie,
              externalId: 300,
            )).thenAnswer((_) async => existingItem);

        // Рейтинг 0 — должен быть clamp(1, 10) = 1
        final String zeroRating = jsonEncode(<Map<String, dynamic>>[
          <String, dynamic>{
            'movie': <String, dynamic>{
              'title': 'Clamped',
              'ids': <String, dynamic>{'tmdb': 300},
            },
            'rating': 0,
          },
        ]);

        writeZip(createTestZip(
          ratingsMoviesJson: zeroRating,
        ));

        await sut.importFromZip(
          options: TraktImportOptions(
            zipPath: zipPath,
            importWatched: false,
          ),
        );

        verify(() => mockDb.updateItemUserRating(50, 1)).called(1);
      });

      test('должен не перезаписывать completedAt когда локальный != null',
          () async {
        setupDefaultMocks();
        const Movie testMovie = Movie(tmdbId: 100, title: 'DatesExist');
        when(() => mockTmdb.getMovie(100))
            .thenAnswer((_) async => testMovie);

        // Элемент уже имеет completedAt
        final DateTime existingCompletedAt = DateTime(2022, 1, 1);
        final CollectionItem existingItem = createTestItem(
          id: 96,
          externalId: 100,
          status: ItemStatus.planned,
          completedAt: existingCompletedAt,
        );
        when(() => mockRepo.findItem(
              collectionId: 1,
              mediaType: MediaType.movie,
              externalId: 100,
            )).thenAnswer((_) async => existingItem);

        writeZip(createTestZip(
          watchedMoviesJson: watchedMovieJson(
            tmdbId: 100,
            lastWatchedAt: '2023-12-25T00:00:00.000Z',
          ),
        ));

        await sut.importFromZip(
          options: TraktImportOptions(zipPath: zipPath),
        );

        // Статус обновлён (planned -> completed), но completedAt НЕ обновлён
        verify(() => mockRepo.updateItemStatus(
              96,
              ItemStatus.completed,
              mediaType: MediaType.movie,
            )).called(1);
        // updateItemActivityDates не вызывается — completedAt уже есть
        verifyNever(() => mockDb.updateItemActivityDates(
              96,
              completedAt: any(named: 'completedAt'),
              lastActivityAt: any(named: 'lastActivityAt'),
              startedAt: any(named: 'startedAt'),
            ));
      });

      test('должен обработать watchlist show элементы', () async {
        setupDefaultMocks();
        const TvShow watchlistShow =
            TvShow(tmdbId: 700, title: 'WL Show');
        when(() => mockTmdb.getTvShow(700))
            .thenAnswer((_) async => watchlistShow);

        when(() => mockRepo.findItem(
              collectionId: 1,
              mediaType: MediaType.tvShow,
              externalId: 700,
            )).thenAnswer((_) async => null);

        when(() => mockRepo.addItem(
              collectionId: 1,
              mediaType: MediaType.tvShow,
              externalId: 700,
              platformId: null,
              status: ItemStatus.planned,
            )).thenAnswer((_) async => 85);

        writeZip(createTestZip(
          watchlistJson: watchlistEntryJson(
            type: 'show',
            tmdbId: 700,
            title: 'WL Show',
          ),
        ));

        final TraktImportResult result = await sut.importFromZip(
          options: TraktImportOptions(
            zipPath: zipPath,
            importWatched: false,
            importRatings: false,
          ),
        );

        expect(result.success, isTrue);
        expect(result.itemsImported, equals(1));
      });

      test('addItem возвращает null — элемент не создан (skipped)', () async {
        setupDefaultMocks();
        const Movie testMovie = Movie(tmdbId: 100, title: 'M');
        when(() => mockTmdb.getMovie(100))
            .thenAnswer((_) async => testMovie);

        // addItem возвращает null (дубликат, например)
        when(() => mockRepo.addItem(
              collectionId: any(named: 'collectionId'),
              mediaType: any(named: 'mediaType'),
              externalId: any(named: 'externalId'),
              platformId: any(named: 'platformId'),
              status: any(named: 'status'),
            )).thenAnswer((_) async => null);

        writeZip(createTestZip(
          watchedMoviesJson: watchedMovieJson(tmdbId: 100),
        ));

        final TraktImportResult result = await sut.importFromZip(
          options: TraktImportOptions(zipPath: zipPath),
        );

        expect(result.success, isTrue);
        expect(result.itemsSkipped, equals(1));
      });

      test('должен обработать watched movie без last_watched_at', () async {
        setupDefaultMocks();
        when(() => mockTmdb.getMovie(100))
            .thenAnswer((_) async => const Movie(tmdbId: 100, title: 'M'));

        writeZip(createTestZip(
          watchedMoviesJson: watchedMovieJson(
            tmdbId: 100,
            lastWatchedAt: null,
          ),
        ));

        final TraktImportResult result = await sut.importFromZip(
          options: TraktImportOptions(zipPath: zipPath),
        );

        expect(result.success, isTrue);
        expect(result.itemsImported, equals(1));
        // updateItemActivityDates не вызывается (completedAt = null)
        verifyNever(() => mockDb.updateItemActivityDates(
              any(),
              completedAt: any(named: 'completedAt'),
              lastActivityAt: any(named: 'lastActivityAt'),
              startedAt: any(named: 'startedAt'),
            ));
      });

      test('ratings: addItem возвращает null — рейтинг не применяется',
          () async {
        setupDefaultMocks();
        const Movie testMovie = Movie(tmdbId: 300, title: 'NullItem');
        when(() => mockTmdb.getMovie(300))
            .thenAnswer((_) async => testMovie);

        // findItem возвращает null (не в коллекции)
        when(() => mockRepo.findItem(
              collectionId: 1,
              mediaType: MediaType.movie,
              externalId: 300,
            )).thenAnswer((_) async => null);

        // addItem возвращает null (не удалось создать)
        when(() => mockRepo.addItem(
              collectionId: 1,
              mediaType: MediaType.movie,
              externalId: 300,
              platformId: null,
              status: any(named: 'status'),
            )).thenAnswer((_) async => null);

        writeZip(createTestZip(
          ratingsMoviesJson: ratingsJson(
            type: 'movie',
            tmdbId: 300,
            rating: 8,
          ),
        ));

        await sut.importFromZip(
          options: TraktImportOptions(
            zipPath: zipPath,
            importWatched: false,
          ),
        );

        // Рейтинг не применяется, т.к. addItem вернул null
        verifyNever(() => mockDb.updateItemUserRating(any(), any()));
      });

      test('ratings: нет данных TMDB — рейтинг не создаётся', () async {
        setupDefaultMocks();
        // TMDB не имеет данных для фильма 300
        when(() => mockTmdb.getMovie(300)).thenAnswer((_) async => null);

        when(() => mockRepo.findItem(
              collectionId: 1,
              mediaType: MediaType.movie,
              externalId: 300,
            )).thenAnswer((_) async => null);

        writeZip(createTestZip(
          ratingsMoviesJson: ratingsJson(
            type: 'movie',
            tmdbId: 300,
            rating: 8,
          ),
        ));

        await sut.importFromZip(
          options: TraktImportOptions(
            zipPath: zipPath,
            importWatched: false,
          ),
        );

        // addItem не вызывается для ratings (нет данных TMDB)
        verifyNever(() => mockRepo.addItem(
              collectionId: 1,
              mediaType: MediaType.movie,
              externalId: 300,
              platformId: null,
              status: any(named: 'status'),
            ));
      });

      test('watchlist: addItem возвращает null — фоллбэк в wishlist',
          () async {
        setupDefaultMocks();
        const Movie testMovie = Movie(tmdbId: 400, title: 'Fallback WL');
        when(() => mockTmdb.getMovie(400))
            .thenAnswer((_) async => testMovie);

        when(() => mockRepo.findItem(
              collectionId: 1,
              mediaType: MediaType.movie,
              externalId: 400,
            )).thenAnswer((_) async => null);

        // addItem возвращает null — не удалось добавить
        when(() => mockRepo.addItem(
              collectionId: 1,
              mediaType: MediaType.movie,
              externalId: 400,
              platformId: null,
              status: ItemStatus.planned,
            )).thenAnswer((_) async => null);

        writeZip(createTestZip(
          watchlistJson: watchlistEntryJson(
            type: 'movie',
            tmdbId: 400,
            title: 'Fallback WL',
          ),
        ));

        final TraktImportResult result = await sut.importFromZip(
          options: TraktImportOptions(
            zipPath: zipPath,
            importWatched: false,
            importRatings: false,
          ),
        );

        expect(result.success, isTrue);
        // Фоллбэк в wishlist
        expect(result.wishlistItemsAdded, equals(1));
        verify(() => mockWishlist.add(
              text: 'Fallback WL',
              mediaTypeHint: MediaType.movie,
            )).called(1);
      });

      test('должен обработать show episodes с last_watched_at', () async {
        setupDefaultMocks();
        when(() => mockTmdb.getTvShow(200))
            .thenAnswer((_) async => const TvShow(tmdbId: 200, title: 'S'));

        writeZip(createTestZip(
          watchedShowsJson: watchedShowJson(
            tmdbId: 200,
            seasons: <Map<String, dynamic>>[
              <String, dynamic>{
                'number': 1,
                'episodes': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'number': 1,
                    'last_watched_at': '2023-01-01T00:00:00.000Z',
                  },
                ],
              },
            ],
          ),
        ));

        final TraktImportResult result = await sut.importFromZip(
          options: TraktImportOptions(zipPath: zipPath),
        );

        expect(result.success, isTrue);
        verify(() => mockDb.markEpisodeWatched(1, 200, 1, 1)).called(1);
      });

      test('должен считать completedAt для show status == completed',
          () async {
        setupDefaultMocks();
        when(() => mockTmdb.getTvShow(200))
            .thenAnswer((_) async => const TvShow(tmdbId: 200, title: 'S'));

        // show без сезонов = completed, так что completedAt будет установлен
        writeZip(createTestZip(
          watchedShowsJson: watchedShowJson(
            tmdbId: 200,
            lastWatchedAt: '2023-08-20T15:00:00.000Z',
            seasons: null,
          ),
        ));

        await sut.importFromZip(
          options: TraktImportOptions(zipPath: zipPath),
        );

        verify(() => mockRepo.addItem(
              collectionId: 1,
              mediaType: MediaType.tvShow,
              externalId: 200,
              platformId: null,
              status: ItemStatus.completed,
            )).called(1);

        // completedAt должен быть установлен для completed show
        verify(() => mockDb.updateItemActivityDates(
              10,
              completedAt: any(named: 'completedAt'),
              lastActivityAt: any(named: 'lastActivityAt'),
              startedAt: any(named: 'startedAt'),
            )).called(1);
      });

      test('show status inProgress — completedAt не устанавливается',
          () async {
        setupDefaultMocks();
        when(() => mockTmdb.getTvShow(200))
            .thenAnswer((_) async => const TvShow(tmdbId: 200, title: 'S'));

        // show с эпизодами = inProgress, completedAt = null
        writeZip(createTestZip(
          watchedShowsJson: watchedShowJson(
            tmdbId: 200,
            seasons: <Map<String, dynamic>>[
              <String, dynamic>{
                'number': 1,
                'episodes': <Map<String, dynamic>>[
                  <String, dynamic>{'number': 1},
                ],
              },
            ],
          ),
        ));

        await sut.importFromZip(
          options: TraktImportOptions(zipPath: zipPath),
        );

        verify(() => mockRepo.addItem(
              collectionId: 1,
              mediaType: MediaType.tvShow,
              externalId: 200,
              platformId: null,
              status: ItemStatus.inProgress,
            )).called(1);

        // completedAt НЕ устанавливается для inProgress
        verifyNever(() => mockDb.updateItemActivityDates(
              10,
              completedAt: any(named: 'completedAt'),
              lastActivityAt: any(named: 'lastActivityAt'),
              startedAt: any(named: 'startedAt'),
            ));
      });
    });
  });
}
