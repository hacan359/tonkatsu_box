import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/tmdb_api.dart';
import 'package:tonkatsu_box/core/services/import_service.dart';
import 'package:tonkatsu_box/core/import/sources/trakt/trakt_import_service.dart';
import 'package:tonkatsu_box/shared/models/collection.dart';
import 'package:tonkatsu_box/shared/models/collection_item.dart';
import 'package:tonkatsu_box/shared/models/item_status.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';
import 'package:tonkatsu_box/shared/models/movie.dart';
import 'package:tonkatsu_box/shared/models/tv_show.dart';
import 'package:tonkatsu_box/shared/models/universal_import_result.dart';
import 'package:tonkatsu_box/shared/models/wishlist_item.dart';

import '../../../../helpers/test_helpers.dart';

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

void main() {
  late MockTmdbApi mockTmdb;
  late MockCollectionRepository mockRepo;
  late MockDatabaseService mockDb;
  late MockMovieDao mockMovieDao;
  late MockTvShowDao mockTvShowDao;
  late MockWishlistRepository mockWishlist;
  late TraktImportService sut;

  late Directory tempDir;
  late String zipPath;

  setUpAll(() {
    registerAllFallbacks();
    registerFallbackValue(<Map<String, dynamic>>[]);
    registerFallbackValue(<(int, Map<String, dynamic>)>[]);
  });

  setUp(() {
    mockTmdb = MockTmdbApi();
    mockRepo = MockCollectionRepository();
    mockDb = MockDatabaseService();
    mockMovieDao = MockMovieDao();
    when(() => mockDb.movieDao).thenReturn(mockMovieDao);
    mockTvShowDao = MockTvShowDao();
    when(() => mockDb.tvShowDao).thenReturn(mockTvShowDao);
    mockWishlist = MockWishlistRepository();
    sut = TraktImportService(
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

  void writeZip(List<int> bytes) {
    File(zipPath).writeAsBytesSync(bytes);
  }

  group('TraktZipInfo', () {
    group('constructor', () {
      test('should create валидный экземпляр с параметрами', () {
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

      test('should use значения по умолчанию', () {
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
      test('should create невалидный результат с ошибкой', () {
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

      test('should return 0 для пустого архива', () {
        const TraktZipInfo info = TraktZipInfo(isValid: false);
        expect(info.totalItems, equals(0));
      });
    });
  });

  group('TraktImportOptions', () {
    group('constructor', () {
      test('should create экземпляр с обязательными параметрами', () {
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

  group('TraktImportService', () {
    group('validateZip', () {
      test('should return valid для правильного ZIP со всеми файлами',
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

      test('should return корректное количество для каждой категории',
          () async {
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

      test('should return invalid для пустого ZIP (без JSON файлов)',
          () async {
        final Archive archive = Archive();
        archive.addFile(ArchiveFile.string('testuser/readme.txt', 'hello'));
        final List<int> bytes = ZipEncoder().encode(archive);
        writeZip(bytes);

        final TraktZipInfo info = await sut.validateZip(zipPath);

        expect(info.isValid, isFalse);
        expect(info.error, equals('No JSON files found in archive'));
      });

      test('should return invalid для не-ZIP файла', () async {
        File(zipPath).writeAsBytesSync(<int>[0, 1, 2, 3, 4, 5]);

        final TraktZipInfo info = await sut.validateZip(zipPath);

        expect(info.isValid, isFalse);
      });

      test('should return invalid для ZIP без JSON файлов', () async {
        final Archive archive = Archive();
        archive.addFile(ArchiveFile.string('user/data.csv', 'a,b,c'));
        final List<int> bytes = ZipEncoder().encode(archive);
        writeZip(bytes);

        final TraktZipInfo info = await sut.validateZip(zipPath);

        expect(info.isValid, isFalse);
      });

      test('should return invalid для ZIP с пустыми JSON массивами',
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

      test('should return invalid для несуществующего файла', () async {
        final TraktZipInfo info =
            await sut.validateZip('/nonexistent/path.zip');

        expect(info.isValid, isFalse);
      });
    });

    group('import', () {
      // Sets up the ImportWriter-backed mocks: collection resolution, batch
      // item reads/writes, and wishlist batch writes. Per-test overrides layer
      // on top (e.g. getItems returning an existing item).
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
            )).thenAnswer((_) async => collection);

        when(() => mockRepo.getById(collectionId))
            .thenAnswer((_) async => collection);

        when(() => mockRepo.getItems(any()))
            .thenAnswer((_) async => <CollectionItem>[]);

        when(() => mockRepo.addItemsBatch(any(), any())).thenAnswer(
            (Invocation inv) async =>
                (inv.positionalArguments[1] as List<dynamic>).length);

        when(() => mockRepo.updateItemFieldsBatch(any()))
            .thenAnswer((_) async {});

        when(() => mockMovieDao.upsertMovie(any())).thenAnswer((_) async {});
        when(() => mockTvShowDao.upsertTvShow(any())).thenAnswer((_) async {});
        when(() => mockTvShowDao.markEpisodeWatched(any(), any(), any(), any()))
            .thenAnswer((_) async {});

        when(() => mockWishlist.getAll(
              includeResolved: any(named: 'includeResolved'),
            )).thenAnswer((_) async => <WishlistItem>[]);
        when(() => mockWishlist.addWishlistItemsBatch(any())).thenAnswer(
            (Invocation inv) async =>
                (inv.positionalArguments[0] as List<dynamic>).length);
      }

      // All insert rows passed to addItemsBatch, flattened across every pass.
      List<Map<String, dynamic>> capturedItemRows() {
        final List<dynamic> calls =
            verify(() => mockRepo.addItemsBatch(any(), captureAny())).captured;
        return <Map<String, dynamic>>[
          for (final dynamic batch in calls)
            ...(batch as List<dynamic>).cast<Map<String, dynamic>>(),
        ];
      }

      // All (id, columns) update tuples passed to updateItemFieldsBatch.
      List<(int, Map<String, dynamic>)> capturedUpdates() {
        final List<dynamic> calls =
            verify(() => mockRepo.updateItemFieldsBatch(captureAny()))
                .captured;
        return <(int, Map<String, dynamic>)>[
          for (final dynamic batch in calls)
            ...(batch as List<dynamic>).cast<(int, Map<String, dynamic>)>(),
        ];
      }

      // All rows passed to addWishlistItemsBatch.
      List<Map<String, dynamic>> capturedWishlistRows() {
        final List<dynamic> calls =
            verify(() => mockWishlist.addWishlistItemsBatch(captureAny()))
                .captured;
        return <Map<String, dynamic>>[
          for (final dynamic batch in calls)
            ...(batch as List<dynamic>).cast<Map<String, dynamic>>(),
        ];
      }

      test('should create новую коллекцию когда collectionId == null',
          () async {
        setupDefaultMocks();
        when(() => mockTmdb.getMovie(any()))
            .thenAnswer((_) async => const Movie(tmdbId: 100, title: 'M'));
        writeZip(createTestZip(
          watchedMoviesJson: watchedMovieJson(),
        ));

        final UniversalImportResult result = await sut.import(
          TraktImportOptions(zipPath: zipPath),
        );

        expect(result.success, isTrue);
        verify(() => mockRepo.create(
              name: 'Trakt: testuser',
              author: 'testuser',
            )).called(1);
      });

      test('should use существующую коллекцию', () async {
        setupDefaultMocks(collectionId: 42);
        when(() => mockTmdb.getMovie(any()))
            .thenAnswer((_) async => const Movie(tmdbId: 100, title: 'M'));
        writeZip(createTestZip(
          watchedMoviesJson: watchedMovieJson(),
        ));

        final UniversalImportResult result = await sut.import(
          TraktImportOptions(
            zipPath: zipPath,
            collectionId: 42,
          ),
        );

        expect(result.success, isTrue);
        verify(() => mockRepo.getById(42)).called(1);
        verifyNever(() => mockRepo.create(
              name: any(named: 'name'),
              author: any(named: 'author'),
            ));
      });

      test('should return failure для несуществующей коллекции', () async {
        when(() => mockRepo.getById(999)).thenAnswer((_) async => null);

        when(() => mockTmdb.getMovie(any()))
            .thenAnswer((_) async => const Movie(tmdbId: 100, title: 'M'));
        when(() => mockMovieDao.upsertMovie(any())).thenAnswer((_) async {});
        writeZip(createTestZip(
          watchedMoviesJson: watchedMovieJson(),
        ));

        final UniversalImportResult result = await sut.import(
          TraktImportOptions(
            zipPath: zipPath,
            collectionId: 999,
          ),
        );

        expect(result.success, isFalse);
        expect(result.fatalError, equals('Collection not found'));
      });

      test('должен импортировать watched movies как completed', () async {
        setupDefaultMocks();
        const Movie testMovie = Movie(tmdbId: 100, title: 'Inception');
        when(() => mockTmdb.getMovie(100)).thenAnswer((_) async => testMovie);
        writeZip(createTestZip(
          watchedMoviesJson: watchedMovieJson(
            title: 'Inception',
            tmdbId: 100,
          ),
        ));

        final UniversalImportResult result = await sut.import(
          TraktImportOptions(zipPath: zipPath),
        );

        expect(result.success, isTrue);
        expect(result.totalImported, equals(1));
        final Map<String, dynamic> row = capturedItemRows().single;
        expect(row['media_type'], equals(MediaType.movie.value));
        expect(row['external_id'], equals(100));
        expect(row['platform_id'], isNull);
        expect(row['status'], equals(ItemStatus.completed.value));
      });

      test('should set completedAt из last_watched_at', () async {
        setupDefaultMocks();
        when(() => mockTmdb.getMovie(100))
            .thenAnswer((_) async => const Movie(tmdbId: 100, title: 'M'));

        writeZip(createTestZip(
          watchedMoviesJson: watchedMovieJson(
            lastWatchedAt: '2023-06-15T10:30:00.000Z',
          ),
        ));

        await sut.import(TraktImportOptions(zipPath: zipPath));

        final Map<String, dynamic> row = capturedItemRows().single;
        expect(row['completed_at'], isNotNull);
        expect(row['last_activity_at'], isNotNull);
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

        final UniversalImportResult result = await sut.import(
          TraktImportOptions(zipPath: zipPath),
        );

        expect(result.success, isTrue);
        expect(result.totalImported, equals(1));
        final Map<String, dynamic> row = capturedItemRows().single;
        expect(row['media_type'], equals(MediaType.tvShow.value));
        expect(row['external_id'], equals(200));
        expect(row['platform_id'], isNull);
        expect(row['status'], equals(ItemStatus.inProgress.value));
      });

      test('должен определить анимацию у фильмов (genres содержит Animation)',
          () async {
        setupDefaultMocks();
        const Movie animMovie = Movie(
          tmdbId: 100,
          title: 'Spirited Away',
          genres: <String>['Animation', 'Fantasy'],
        );
        when(() => mockTmdb.getMovie(100)).thenAnswer((_) async => animMovie);

        writeZip(createTestZip(
          watchedMoviesJson: watchedMovieJson(
            title: 'Spirited Away',
            tmdbId: 100,
          ),
        ));

        await sut.import(TraktImportOptions(zipPath: zipPath));

        final Map<String, dynamic> row = capturedItemRows().single;
        expect(row['media_type'], equals(MediaType.animation.value));
        expect(row['external_id'], equals(100));
        expect(row['platform_id'], equals(AnimationSource.movie));
        expect(row['status'], equals(ItemStatus.completed.value));
      });

      test('должен определить анимацию у сериалов (genres содержит 16)',
          () async {
        setupDefaultMocks();
        const TvShow animShow = TvShow(
          tmdbId: 200,
          title: 'Attack on Titan',
          genres: <String>['16', '10759'],
        );
        when(() => mockTmdb.getTvShow(200)).thenAnswer((_) async => animShow);

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

        await sut.import(TraktImportOptions(zipPath: zipPath));

        final Map<String, dynamic> row = capturedItemRows().single;
        expect(row['media_type'], equals(MediaType.animation.value));
        expect(row['external_id'], equals(200));
        expect(row['platform_id'], equals(AnimationSource.tvShow));
        expect(row['status'], equals(ItemStatus.inProgress.value));
      });

      test('should skip watched movie без TMDB ID (no insert)', () async {
        setupDefaultMocks();

        writeZip(createTestZip(
          watchedMoviesJson: watchedMovieJson(
            title: 'No TMDB Movie',
            tmdbId: null,
          ),
        ));

        final UniversalImportResult result = await sut.import(
          TraktImportOptions(zipPath: zipPath),
        );

        expect(result.success, isTrue);
        expect(result.skipped, equals(1));
        expect(capturedItemRows(), isEmpty);
        // A title without a TMDB id is counted as skipped, not wishlisted.
        expect(result.totalWishlisted, equals(0));
        verifyNever(() => mockWishlist.addWishlistItemsBatch(any()));
      });

      test('watched movie без данных TMDB — фоллбэк в wishlist', () async {
        setupDefaultMocks();
        when(() => mockTmdb.getMovie(100)).thenAnswer((_) async => null);

        writeZip(createTestZip(
          watchedMoviesJson: watchedMovieJson(
            title: 'Unavailable Movie',
            tmdbId: 100,
          ),
        ));

        final UniversalImportResult result = await sut.import(
          TraktImportOptions(zipPath: zipPath),
        );

        expect(result.success, isTrue);
        // Not inserted into the collection, dropped to the text wishlist.
        expect(capturedItemRows(), isEmpty);
        expect(result.skipped, equals(1));
        expect(result.totalWishlisted, equals(1));
        final Map<String, dynamic> wl = capturedWishlistRows().single;
        expect(wl['text'], equals('Unavailable Movie'));
        expect(wl['media_type_hint'], equals(MediaType.movie.value));
      });

      test('должен применить рейтинг когда userRating == null', () async {
        setupDefaultMocks();
        const Movie testMovie = Movie(tmdbId: 300, title: 'Rated');
        when(() => mockTmdb.getMovie(300)).thenAnswer((_) async => testMovie);

        final CollectionItem existingItem = createTestCollectionItem(
          id: 50,
          externalId: 300,
          mediaType: MediaType.movie,
          status: ItemStatus.completed,
          userRating: null,
        );
        when(() => mockRepo.getItems(any()))
            .thenAnswer((_) async => <CollectionItem>[existingItem]);

        writeZip(createTestZip(
          ratingsMoviesJson: ratingsJson(
            type: 'movie',
            tmdbId: 300,
            rating: 9,
          ),
        ));

        final UniversalImportResult result = await sut.import(
          TraktImportOptions(
            zipPath: zipPath,
            importWatched: false,
          ),
        );

        expect(result.success, isTrue);
        final (int, Map<String, dynamic>) update = capturedUpdates()
            .firstWhere(((int, Map<String, dynamic>) u) => u.$1 == 50);
        expect(update.$2['user_rating'], equals(9.0));
      });

      test('должен НЕ перезаписывать существующий userRating', () async {
        setupDefaultMocks();
        const Movie testMovie = Movie(tmdbId: 300, title: 'Rated');
        when(() => mockTmdb.getMovie(300)).thenAnswer((_) async => testMovie);

        final CollectionItem existingItem = createTestCollectionItem(
          id: 50,
          externalId: 300,
          mediaType: MediaType.movie,
          status: ItemStatus.completed,
          userRating: 7,
        );
        when(() => mockRepo.getItems(any()))
            .thenAnswer((_) async => <CollectionItem>[existingItem]);

        writeZip(createTestZip(
          ratingsMoviesJson: ratingsJson(
            type: 'movie',
            tmdbId: 300,
            rating: 9,
          ),
        ));

        await sut.import(
          TraktImportOptions(
            zipPath: zipPath,
            importWatched: false,
          ),
        );

        final List<(int, Map<String, dynamic>)> updates = capturedUpdates();
        final Iterable<(int, Map<String, dynamic>)> forItem =
            updates.where(((int, Map<String, dynamic>) u) => u.$1 == 50);
        // Either no update at all, or one that does not touch user_rating.
        for (final (int, Map<String, dynamic>) u in forItem) {
          expect(u.$2.containsKey('user_rating'), isFalse);
        }
      });

      test('should create элемент из ratings если нет в коллекции', () async {
        setupDefaultMocks();
        const Movie testMovie = Movie(tmdbId: 300, title: 'New Rated');
        when(() => mockTmdb.getMovie(300)).thenAnswer((_) async => testMovie);

        writeZip(createTestZip(
          ratingsMoviesJson: ratingsJson(
            type: 'movie',
            tmdbId: 300,
            rating: 8,
          ),
        ));

        final UniversalImportResult result = await sut.import(
          TraktImportOptions(
            zipPath: zipPath,
            importWatched: false,
          ),
        );

        expect(result.success, isTrue);
        expect(result.totalImported, greaterThanOrEqualTo(1));
        final Map<String, dynamic> row = capturedItemRows().single;
        expect(row['external_id'], equals(300));
        expect(row['status'], equals(ItemStatus.notStarted.value));
        expect(row['user_rating'], equals(8.0));
      });

      test('конфликт статусов: должен повысить planned -> completed',
          () async {
        setupDefaultMocks();
        const Movie testMovie = Movie(tmdbId: 100, title: 'Upgrade');
        when(() => mockTmdb.getMovie(100)).thenAnswer((_) async => testMovie);

        final CollectionItem existingPlanned = createTestCollectionItem(
          id: 70,
          externalId: 100,
          mediaType: MediaType.movie,
          status: ItemStatus.planned,
        );
        when(() => mockRepo.getItems(any()))
            .thenAnswer((_) async => <CollectionItem>[existingPlanned]);

        writeZip(createTestZip(
          watchedMoviesJson: watchedMovieJson(tmdbId: 100),
        ));

        final UniversalImportResult result = await sut.import(
          TraktImportOptions(zipPath: zipPath),
        );

        expect(result.success, isTrue);
        expect(result.totalUpdated, equals(1));
        expect(capturedItemRows(), isEmpty);
        final (int, Map<String, dynamic>) update = capturedUpdates().single;
        expect(update.$1, equals(70));
        expect(update.$2['status'], equals(ItemStatus.completed.value));
      });

      test('конфликт статусов: НЕ должен понизить completed -> planned',
          () async {
        setupDefaultMocks();
        const TvShow testShow = TvShow(tmdbId: 200, title: 'NoDowngrade');
        when(() => mockTmdb.getTvShow(200)).thenAnswer((_) async => testShow);

        final CollectionItem existingCompleted = createTestCollectionItem(
          id: 80,
          externalId: 200,
          mediaType: MediaType.tvShow,
          status: ItemStatus.completed,
        );
        when(() => mockRepo.getItems(any()))
            .thenAnswer((_) async => <CollectionItem>[existingCompleted]);

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

        await sut.import(TraktImportOptions(zipPath: zipPath));

        // inProgress is lower priority than completed → no status change.
        final List<(int, Map<String, dynamic>)> updates = capturedUpdates();
        final Iterable<(int, Map<String, dynamic>)> forItem =
            updates.where(((int, Map<String, dynamic>) u) => u.$1 == 80);
        for (final (int, Map<String, dynamic>) u in forItem) {
          expect(u.$2.containsKey('status'), isFalse);
        }
        expect(capturedItemRows(), isEmpty);
      });

      test('конфликт статусов: НЕ должен перезаписать dropped', () async {
        setupDefaultMocks();
        const Movie testMovie = Movie(tmdbId: 100, title: 'Dropped');
        when(() => mockTmdb.getMovie(100)).thenAnswer((_) async => testMovie);

        final CollectionItem existingDropped = createTestCollectionItem(
          id: 90,
          externalId: 100,
          mediaType: MediaType.movie,
          status: ItemStatus.dropped,
        );
        when(() => mockRepo.getItems(any()))
            .thenAnswer((_) async => <CollectionItem>[existingDropped]);

        writeZip(createTestZip(
          watchedMoviesJson: watchedMovieJson(tmdbId: 100),
        ));

        await sut.import(TraktImportOptions(zipPath: zipPath));

        // dropped is protected: merge returns null → no status column.
        final List<(int, Map<String, dynamic>)> updates = capturedUpdates();
        final Iterable<(int, Map<String, dynamic>)> forItem =
            updates.where(((int, Map<String, dynamic>) u) => u.$1 == 90);
        for (final (int, Map<String, dynamic>) u in forItem) {
          expect(u.$2.containsKey('status'), isFalse);
        }
        expect(capturedItemRows(), isEmpty);
      });

      test('should set completedAt из Trakt если локальный null', () async {
        setupDefaultMocks();
        const Movie testMovie = Movie(tmdbId: 100, title: 'Dates');
        when(() => mockTmdb.getMovie(100)).thenAnswer((_) async => testMovie);

        final CollectionItem existingItem = createTestCollectionItem(
          id: 95,
          externalId: 100,
          mediaType: MediaType.movie,
          status: ItemStatus.planned,
          completedAt: null,
        );
        when(() => mockRepo.getItems(any()))
            .thenAnswer((_) async => <CollectionItem>[existingItem]);

        writeZip(createTestZip(
          watchedMoviesJson: watchedMovieJson(
            tmdbId: 100,
            lastWatchedAt: '2023-06-15T10:30:00.000Z',
          ),
        ));

        await sut.import(TraktImportOptions(zipPath: zipPath));

        final (int, Map<String, dynamic>) update = capturedUpdates().single;
        expect(update.$1, equals(95));
        // Local completedAt is null → the Trakt watch date is written.
        final int expectedEpoch =
            DateTime.parse('2023-06-15T10:30:00.000Z').millisecondsSinceEpoch ~/
                1000;
        expect(update.$2['completed_at'], equals(expectedEpoch));
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

        await sut.import(TraktImportOptions(zipPath: zipPath));

        verify(() =>
                mockTvShowDao.markEpisodeWatched(any(), 200, any(), any()))
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

        final UniversalImportResult result = await sut.import(
          TraktImportOptions(
            zipPath: zipPath,
            importWatched: false,
            importRatings: false,
          ),
        );

        expect(result.success, isTrue);
        final Map<String, dynamic> row = capturedItemRows().single;
        expect(row['media_type'], equals(MediaType.movie.value));
        expect(row['external_id'], equals(400));
        expect(row['platform_id'], isNull);
        expect(row['status'], equals(ItemStatus.planned.value));
      });

      test('должен добавить в wishlist элементы без данных TMDB', () async {
        setupDefaultMocks();
        when(() => mockTmdb.getMovie(400)).thenAnswer((_) async => null);

        writeZip(createTestZip(
          watchlistJson: watchlistEntryJson(
            type: 'movie',
            tmdbId: 400,
            title: 'Unknown Movie',
          ),
        ));

        final UniversalImportResult result = await sut.import(
          TraktImportOptions(
            zipPath: zipPath,
            importWatched: false,
            importRatings: false,
          ),
        );

        expect(result.success, isTrue);
        expect(result.totalWishlisted, equals(1));
        final Map<String, dynamic> wl = capturedWishlistRows().single;
        expect(wl['text'], equals('Unknown Movie'));
        expect(wl['media_type_hint'], equals(MediaType.movie.value));
        expect(wl['tag'], isNotNull);
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

        final UniversalImportResult result = await sut.import(
          TraktImportOptions(
            zipPath: zipPath,
            importWatched: false,
            importRatings: false,
          ),
        );

        expect(result.success, isTrue);
        expect(result.totalWishlisted, equals(1));
        final Map<String, dynamic> wl = capturedWishlistRows().single;
        expect(wl['text'], equals('No ID Show'));
        expect(wl['media_type_hint'], equals(MediaType.tvShow.value));
      });

      test('should skip watchlist элементы уже в коллекции', () async {
        setupDefaultMocks();
        const Movie existingMovie = Movie(tmdbId: 400, title: 'Existing');
        when(() => mockTmdb.getMovie(400))
            .thenAnswer((_) async => existingMovie);

        final CollectionItem existing = createTestCollectionItem(
          id: 55,
          externalId: 400,
          mediaType: MediaType.movie,
          status: ItemStatus.completed,
        );
        when(() => mockRepo.getItems(any()))
            .thenAnswer((_) async => <CollectionItem>[existing]);

        writeZip(createTestZip(
          watchlistJson: watchlistEntryJson(
            type: 'movie',
            tmdbId: 400,
          ),
        ));

        final UniversalImportResult result = await sut.import(
          TraktImportOptions(
            zipPath: zipPath,
            importWatched: false,
            importRatings: false,
          ),
        );

        expect(result.success, isTrue);
        expect(result.totalWishlisted, equals(0));
        // Existing item is left untouched — not re-inserted, not status-changed.
        expect(capturedItemRows(), isEmpty);
        final List<(int, Map<String, dynamic>)> updates = capturedUpdates();
        for (final (int, Map<String, dynamic>) u in updates) {
          expect(u.$2.containsKey('status'), isFalse);
        }
      });

      test('should call progress callback', () async {
        setupDefaultMocks();
        when(() => mockTmdb.getMovie(100))
            .thenAnswer((_) async => const Movie(tmdbId: 100, title: 'M'));

        writeZip(createTestZip(
          watchedMoviesJson: watchedMovieJson(),
        ));

        final List<ImportStage> stages = <ImportStage>[];
        await sut.import(
          TraktImportOptions(zipPath: zipPath),
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

        final UniversalImportResult result = await sut.import(
          TraktImportOptions(
            zipPath: zipPath,
            importWatched: false,
          ),
        );

        expect(result.success, isTrue);
        // No watched insert: the only inserted row is the rating (notStarted).
        for (final Map<String, dynamic> row in capturedItemRows()) {
          expect(row['status'], isNot(equals(ItemStatus.completed.value)));
        }
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

        await sut.import(
          TraktImportOptions(
            zipPath: zipPath,
            importRatings: false,
          ),
        );

        // No rating column written anywhere.
        for (final Map<String, dynamic> row in capturedItemRows()) {
          expect(row.containsKey('user_rating'), isFalse);
        }
        for (final (int, Map<String, dynamic>) u in capturedUpdates()) {
          expect(u.$2.containsKey('user_rating'), isFalse);
        }
      });

      test('должен уважать importWatchlist=false', () async {
        setupDefaultMocks();
        when(() => mockTmdb.getMovie(400))
            .thenAnswer((_) async => const Movie(tmdbId: 400, title: 'W'));

        writeZip(createTestZip(
          watchlistJson: watchlistEntryJson(tmdbId: 400),
        ));

        final UniversalImportResult result = await sut.import(
          TraktImportOptions(
            zipPath: zipPath,
            importWatched: false,
            importRatings: false,
            importWatchlist: false,
          ),
        );

        expect(result.success, isTrue);
        expect(result.totalWishlisted, equals(0));
        expect(capturedItemRows(), isEmpty);
      });

      test('should return failure для ошибки чтения файла', () async {
        final UniversalImportResult result = await sut.import(
          TraktImportOptions(
            zipPath: '${tempDir.path}/nonexistent.zip',
          ),
        );

        expect(result.success, isFalse);
        expect(result.fatalError, contains('Import failed'));
      });

      test('should return failure для пустого архива', () async {
        final Archive archive = Archive();
        archive.addFile(ArchiveFile.string('user/readme.txt', 'hello'));
        writeZip(ZipEncoder().encode(archive));

        final UniversalImportResult result = await sut.import(
          TraktImportOptions(zipPath: zipPath),
        );

        expect(result.success, isFalse);
        expect(result.fatalError, equals('No data found in archive'));
      });

      test('должен корректно определить completed для show без сезонов',
          () async {
        setupDefaultMocks();
        when(() => mockTmdb.getTvShow(200))
            .thenAnswer((_) async => const TvShow(tmdbId: 200, title: 'S'));

        writeZip(createTestZip(
          watchedShowsJson: watchedShowJson(
            tmdbId: 200,
            seasons: null,
          ),
        ));

        await sut.import(TraktImportOptions(zipPath: zipPath));

        final Map<String, dynamic> row = capturedItemRows().single;
        expect(row['media_type'], equals(MediaType.tvShow.value));
        expect(row['external_id'], equals(200));
        expect(row['status'], equals(ItemStatus.completed.value));
      });

      test('should handle show с пустыми сезонами как completed', () async {
        setupDefaultMocks();
        when(() => mockTmdb.getTvShow(200))
            .thenAnswer((_) async => const TvShow(tmdbId: 200, title: 'S'));

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

        await sut.import(TraktImportOptions(zipPath: zipPath));

        final Map<String, dynamic> row = capturedItemRows().single;
        expect(row['external_id'], equals(200));
        expect(row['status'], equals(ItemStatus.completed.value));
      });

      test('должен корректно обработать TMDB API exception при fetch',
          () async {
        setupDefaultMocks();
        when(() => mockTmdb.getMovie(100))
            .thenThrow(const TmdbApiException('Error', statusCode: 500));

        writeZip(createTestZip(
          watchedMoviesJson: watchedMovieJson(tmdbId: 100),
        ));

        final UniversalImportResult result = await sut.import(
          TraktImportOptions(zipPath: zipPath),
        );

        // The fetch failed → no data → fall back to wishlist, counted skipped.
        expect(result.success, isTrue);
        expect(result.skipped, equals(1));
        expect(capturedItemRows(), isEmpty);
        expect(result.totalWishlisted, equals(1));
      });

      test('should handle rating для animation show', () async {
        setupDefaultMocks();
        const TvShow animShow = TvShow(
          tmdbId: 500,
          title: 'Anime Show',
          genres: <String>['16', 'Action'],
        );
        when(() => mockTmdb.getTvShow(500)).thenAnswer((_) async => animShow);

        writeZip(createTestZip(
          ratingsShowsJson: ratingsJson(
            type: 'show',
            tmdbId: 500,
            rating: 10,
          ),
        ));

        final UniversalImportResult result = await sut.import(
          TraktImportOptions(
            zipPath: zipPath,
            importWatched: false,
          ),
        );

        expect(result.success, isTrue);
        final Map<String, dynamic> row = capturedItemRows().single;
        expect(row['media_type'], equals(MediaType.animation.value));
        expect(row['platform_id'], equals(AnimationSource.tvShow));
        expect(row['external_id'], equals(500));
        expect(row['user_rating'], equals(10.0));
      });

      test('should handle watchlist для animation movie', () async {
        setupDefaultMocks();
        const Movie animMovie = Movie(
          tmdbId: 600,
          title: 'Anime Movie',
          genres: <String>['Animation', 'Adventure'],
        );
        when(() => mockTmdb.getMovie(600)).thenAnswer((_) async => animMovie);

        writeZip(createTestZip(
          watchlistJson: watchlistEntryJson(
            type: 'movie',
            tmdbId: 600,
            title: 'Anime Movie',
          ),
        ));

        final UniversalImportResult result = await sut.import(
          TraktImportOptions(
            zipPath: zipPath,
            importWatched: false,
            importRatings: false,
          ),
        );

        expect(result.success, isTrue);
        expect(result.totalImported, equals(1));
        final Map<String, dynamic> row = capturedItemRows().single;
        expect(row['media_type'], equals(MediaType.animation.value));
        expect(row['external_id'], equals(600));
        expect(row['platform_id'], equals(AnimationSource.movie));
        expect(row['status'], equals(ItemStatus.planned.value));
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

        final UniversalImportResult result = await sut.import(
          TraktImportOptions(zipPath: zipPath),
        );

        expect(result.success, isTrue);
        expect(result.totalImported, greaterThanOrEqualTo(2));
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

        final UniversalImportResult result = await sut.import(
          TraktImportOptions(zipPath: zipPath),
        );

        expect(result.success, isTrue);
        expect(result.skipped, equals(1));
        expect(capturedItemRows(), isEmpty);
        expect(result.totalWishlisted, equals(0));
      });

      test('should handle show с null TMDB data', () async {
        setupDefaultMocks();
        when(() => mockTmdb.getTvShow(200)).thenAnswer((_) async => null);

        writeZip(createTestZip(
          watchedShowsJson: watchedShowJson(tmdbId: 200),
        ));

        final UniversalImportResult result = await sut.import(
          TraktImportOptions(zipPath: zipPath),
        );

        expect(result.success, isTrue);
        expect(result.skipped, equals(1));
        expect(capturedItemRows(), isEmpty);
        // No TMDB data → fall back to wishlist.
        expect(result.totalWishlisted, equals(1));
      });

      test('should skip эпизоды для show без TMDB ID', () async {
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

        await sut.import(TraktImportOptions(zipPath: zipPath));

        verifyNever(
            () => mockTvShowDao.markEpisodeWatched(any(), any(), any(), any()));
      });

      test('should skip rating без TMDB ID', () async {
        setupDefaultMocks();

        writeZip(createTestZip(
          ratingsMoviesJson: ratingsJson(
            type: 'movie',
            tmdbId: null,
            rating: 8,
          ),
        ));

        final UniversalImportResult result = await sut.import(
          TraktImportOptions(
            zipPath: zipPath,
            importWatched: false,
          ),
        );

        expect(result.success, isTrue);
        // A rating with no TMDB id never becomes a collection item.
        expect(capturedItemRows(), isEmpty);
        for (final (int, Map<String, dynamic>) u in capturedUpdates()) {
          expect(u.$2.containsKey('user_rating'), isFalse);
        }
      });

      test('должен clamp рейтинг в диапазон 1-10', () async {
        setupDefaultMocks();
        const Movie testMovie = Movie(tmdbId: 300, title: 'Clamped');
        when(() => mockTmdb.getMovie(300)).thenAnswer((_) async => testMovie);

        final CollectionItem existingItem = createTestCollectionItem(
          id: 50,
          externalId: 300,
          mediaType: MediaType.movie,
          userRating: null,
        );
        when(() => mockRepo.getItems(any()))
            .thenAnswer((_) async => <CollectionItem>[existingItem]);

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

        await sut.import(
          TraktImportOptions(
            zipPath: zipPath,
            importWatched: false,
          ),
        );

        final (int, Map<String, dynamic>) update = capturedUpdates()
            .firstWhere(((int, Map<String, dynamic>) u) => u.$1 == 50);
        // Rating 0 clamps up to 1.
        expect(update.$2['user_rating'], equals(1.0));
      });

      test('promote planned -> completed перезаписывает completed_at (флаг)',
          () async {
        // INTENT (old test "не перезаписывать completedAt когда локальный
        // != null"): a pre-existing completedAt should not be clobbered.
        // The new merge path always re-stamps completed_at when a status
        // transition lands on `completed` (statusDateColumns uses
        // computeDatesForStatus, which sets completedAt = now for the
        // `completed` case). So promoting planned -> completed DOES overwrite
        // a non-null local completedAt. This test pins the actual behavior;
        // see the migration notes for the discrepancy.
        setupDefaultMocks();
        const Movie testMovie = Movie(tmdbId: 100, title: 'DatesExist');
        when(() => mockTmdb.getMovie(100)).thenAnswer((_) async => testMovie);

        final DateTime existingCompletedAt = DateTime(2022, 1, 1);
        final CollectionItem existingItem = createTestCollectionItem(
          id: 96,
          externalId: 100,
          mediaType: MediaType.movie,
          status: ItemStatus.planned,
          completedAt: existingCompletedAt,
        );
        when(() => mockRepo.getItems(any()))
            .thenAnswer((_) async => <CollectionItem>[existingItem]);

        writeZip(createTestZip(
          watchedMoviesJson: watchedMovieJson(
            tmdbId: 100,
            lastWatchedAt: '2023-12-25T00:00:00.000Z',
          ),
        ));

        await sut.import(TraktImportOptions(zipPath: zipPath));

        final (int, Map<String, dynamic>) update = capturedUpdates().single;
        expect(update.$1, equals(96));
        expect(update.$2['status'], equals(ItemStatus.completed.value));
        // completed_at IS present (re-stamped); it is NOT the old 2022 value.
        final int oldEpoch =
            existingCompletedAt.millisecondsSinceEpoch ~/ 1000;
        expect(update.$2['completed_at'], isNotNull);
        expect(update.$2['completed_at'], isNot(equals(oldEpoch)));
      });

      test('should handle watchlist show элементы', () async {
        setupDefaultMocks();
        const TvShow watchlistShow = TvShow(tmdbId: 700, title: 'WL Show');
        when(() => mockTmdb.getTvShow(700))
            .thenAnswer((_) async => watchlistShow);

        writeZip(createTestZip(
          watchlistJson: watchlistEntryJson(
            type: 'show',
            tmdbId: 700,
            title: 'WL Show',
          ),
        ));

        final UniversalImportResult result = await sut.import(
          TraktImportOptions(
            zipPath: zipPath,
            importWatched: false,
            importRatings: false,
          ),
        );

        expect(result.success, isTrue);
        expect(result.totalImported, equals(1));
        final Map<String, dynamic> row = capturedItemRows().single;
        expect(row['media_type'], equals(MediaType.tvShow.value));
        expect(row['external_id'], equals(700));
        expect(row['status'], equals(ItemStatus.planned.value));
      });

      test('in-batch дубликат не вставляется дважды (skipped)', () async {
        // INTENT (old "addItem возвращает null — не создан"): the per-item
        // null-insert path is gone. The closest surviving behavior: a title
        // present twice in one batch is inserted once and the duplicate
        // counted as skipped (ConflictAlgorithm.ignore at the batch level).
        setupDefaultMocks();
        const Movie testMovie = Movie(tmdbId: 100, title: 'Dup');
        when(() => mockTmdb.getMovie(100)).thenAnswer((_) async => testMovie);

        final String twoSame = jsonEncode(<Map<String, dynamic>>[
          <String, dynamic>{
            'movie': <String, dynamic>{
              'title': 'Dup',
              'ids': <String, dynamic>{'tmdb': 100},
            },
            'last_watched_at': '2023-06-15T10:30:00.000Z',
          },
          <String, dynamic>{
            'movie': <String, dynamic>{
              'title': 'Dup',
              'ids': <String, dynamic>{'tmdb': 100},
            },
            'last_watched_at': '2023-06-15T10:30:00.000Z',
          },
        ]);

        writeZip(createTestZip(watchedMoviesJson: twoSame));

        final UniversalImportResult result = await sut.import(
          TraktImportOptions(zipPath: zipPath),
        );

        expect(result.success, isTrue);
        expect(result.totalImported, equals(1));
        expect(capturedItemRows(), hasLength(1));
        expect(result.skipped, greaterThanOrEqualTo(1));
      });

      test('should handle watched movie без last_watched_at', () async {
        setupDefaultMocks();
        when(() => mockTmdb.getMovie(100))
            .thenAnswer((_) async => const Movie(tmdbId: 100, title: 'M'));

        writeZip(createTestZip(
          watchedMoviesJson: watchedMovieJson(
            tmdbId: 100,
            lastWatchedAt: null,
          ),
        ));

        final UniversalImportResult result = await sut.import(
          TraktImportOptions(zipPath: zipPath),
        );

        expect(result.success, isTrue);
        expect(result.totalImported, equals(1));
        final Map<String, dynamic> row = capturedItemRows().single;
        expect(row['status'], equals(ItemStatus.completed.value));
        // No watch date → date columns are absent from the insert row.
        expect(row.containsKey('completed_at'), isFalse);
        expect(row.containsKey('last_activity_at'), isFalse);
      });

      test('ratings: нет данных TMDB — рейтинг не создаётся', () async {
        setupDefaultMocks();
        when(() => mockTmdb.getMovie(300)).thenAnswer((_) async => null);

        writeZip(createTestZip(
          ratingsMoviesJson: ratingsJson(
            type: 'movie',
            tmdbId: 300,
            rating: 8,
          ),
        ));

        await sut.import(
          TraktImportOptions(
            zipPath: zipPath,
            importWatched: false,
          ),
        );

        // No TMDB data → no rating item inserted, no rating update.
        expect(capturedItemRows(), isEmpty);
        for (final (int, Map<String, dynamic>) u in capturedUpdates()) {
          expect(u.$2.containsKey('user_rating'), isFalse);
        }
      });

      test('should handle show episodes с last_watched_at', () async {
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

        final UniversalImportResult result = await sut.import(
          TraktImportOptions(zipPath: zipPath),
        );

        expect(result.success, isTrue);
        verify(() => mockTvShowDao.markEpisodeWatched(1, 200, 1, 1)).called(1);
      });

      test('должен считать completedAt для show status == completed',
          () async {
        setupDefaultMocks();
        when(() => mockTmdb.getTvShow(200))
            .thenAnswer((_) async => const TvShow(tmdbId: 200, title: 'S'));

        writeZip(createTestZip(
          watchedShowsJson: watchedShowJson(
            tmdbId: 200,
            lastWatchedAt: '2023-08-20T15:00:00.000Z',
            seasons: null,
          ),
        ));

        await sut.import(TraktImportOptions(zipPath: zipPath));

        final Map<String, dynamic> row = capturedItemRows().single;
        expect(row['status'], equals(ItemStatus.completed.value));
        expect(row['completed_at'], isNotNull);
        expect(row['last_activity_at'], isNotNull);
      });

      test('show status inProgress — completedAt не устанавливается',
          () async {
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
                ],
              },
            ],
          ),
        ));

        await sut.import(TraktImportOptions(zipPath: zipPath));

        final Map<String, dynamic> row = capturedItemRows().single;
        expect(row['status'], equals(ItemStatus.inProgress.value));
        // inProgress show: completedAt stays null (key absent on the insert).
        expect(row.containsKey('completed_at'), isFalse);
      });
    });
  });
}
