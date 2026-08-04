import 'package:core/models/anime.dart';
import 'package:core/models/collection_item.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/item_status.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/tv_episode.dart';
import 'package:core/models/tv_season.dart';
import 'package:core/models/universal_import_result.dart';
import 'package:core/models/wishlist_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/kitsu_api.dart';
import 'package:tonkatsu_box/core/api/simkl_api.dart';
import 'package:tonkatsu_box/core/import/import_progress.dart';
import 'package:tonkatsu_box/core/import/sources/anilist/anilist_import_service.dart'
    show ImportMode;
import 'package:tonkatsu_box/core/import/sources/simkl/simkl_import_service.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  late SimklImportService sut;
  late MockSimklApi mockSimkl;
  late MockTmdbApi mockTmdb;
  late MockKitsuApi mockKitsu;
  late MockDatabaseService mockDb;
  late MockMovieDao mockMovieDao;
  late MockTvShowDao mockTvShowDao;
  late MockAnimeDao mockAnimeDao;
  late MockGlobalTagDao mockTagDao;
  late MockCollectionRepository mockRepo;
  late MockWishlistRepository mockWishlist;

  setUpAll(() {
    registerAllFallbacks();
    registerFallbackValue(<Map<String, dynamic>>[]);
    registerFallbackValue(<(int, Map<String, dynamic>)>[]);
    registerFallbackValue(const <(int, int, int?)>[]);
  });

  setUp(() {
    mockSimkl = MockSimklApi();
    mockTmdb = MockTmdbApi();
    mockKitsu = MockKitsuApi();
    mockDb = MockDatabaseService();
    mockMovieDao = MockMovieDao();
    mockTvShowDao = MockTvShowDao();
    mockAnimeDao = MockAnimeDao();
    mockTagDao = MockGlobalTagDao();
    mockRepo = MockCollectionRepository();
    mockWishlist = MockWishlistRepository();

    when(() => mockDb.movieDao).thenReturn(mockMovieDao);
    when(() => mockDb.tvShowDao).thenReturn(mockTvShowDao);
    when(() => mockDb.animeDao).thenReturn(mockAnimeDao);
    when(() => mockDb.globalTagDao).thenReturn(mockTagDao);

    sut = SimklImportService(
      simklApi: mockSimkl,
      tmdbApi: mockTmdb,
      kitsuApi: mockKitsu,
      database: mockDb,
      repository: mockRepo,
      wishlistRepository: mockWishlist,
    );

    when(() => mockMovieDao.upsertMovie(any())).thenAnswer((_) async {});
    when(() => mockTvShowDao.upsertTvShow(any())).thenAnswer((_) async {});
    when(() => mockAnimeDao.upsertAnimes(any())).thenAnswer((_) async {});
    when(() => mockTvShowDao.markEpisodesWatchedAt(
          any(),
          any(),
          any(),
          any(),
        )).thenAnswer((_) async {});
    when(() => mockTagDao.resolveOrCreate(any())).thenAnswer((_) async => 99);
    when(() => mockTagDao.addTagToItems(any(), any())).thenAnswer((_) async {});

    when(() => mockRepo.create(
          name: any(named: 'name'),
          author: any(named: 'author'),
        )).thenAnswer((_) async => createTestCollection(id: 42));
    when(() => mockRepo.getById(any()))
        .thenAnswer((_) async => createTestCollection(id: 1));
    when(() => mockRepo.getItems(any()))
        .thenAnswer((_) async => <CollectionItem>[]);
    when(() => mockRepo.addItemsBatchReturningIds(any(), any())).thenAnswer(
        (Invocation inv) async => List<int?>.generate(
            (inv.positionalArguments[1] as List<dynamic>).length,
            (int index) => index + 1));
    when(() => mockRepo.updateItemFieldsBatch(any())).thenAnswer((_) async {});
    when(() => mockWishlist.getAll(
          includeResolved: any(named: 'includeResolved'),
        )).thenAnswer((_) async => <WishlistItem>[]);
    when(() => mockWishlist.addWishlistItemsBatch(any()))
        .thenAnswer((_) async => 0);

    when(() => mockTmdb.getMovie(any()))
        .thenAnswer((_) async => createTestMovie(tmdbId: 550));
    when(() => mockTmdb.getTvShow(any()))
        .thenAnswer((_) async => createTestTvShow(tmdbId: 200));
    when(() => mockTmdb.getTvSeasons(any()))
        .thenAnswer((_) async => <TvSeason>[]);
    when(() => mockTmdb.getSeasonEpisodes(any(), any()))
        .thenAnswer((_) async => <TvEpisode>[]);
    when(() => mockKitsu.getAnimeByIds(any())).thenAnswer((_) async => <Anime>[]);
    when(() => mockKitsu.getAnimeByMalIds(any()))
        .thenAnswer((_) async => <int, Anime>{});
    when(() => mockKitsu.getAnimeByAnidbIds(any()))
        .thenAnswer((_) async => <int, Anime>{});
    when(() => mockKitsu.getAnimeEpisodes(any()))
        .thenAnswer((_) async => <TvEpisode>[]);
  });

  Map<String, dynamic> movieJson({
    int? tmdbId = 550,
    int? simklId = 1001,
    String? slug = 'fight-club',
    String status = 'completed',
    String title = 'Fight Club',
    int? year = 1999,
    int? rating,
    String? lastWatchedAt,
    String? addedToWatchlistAt,
    String? memo,
  }) =>
      <String, dynamic>{
        'status': status,
        'user_rating': rating,
        'last_watched_at': lastWatchedAt,
        'added_to_watchlist_at': addedToWatchlistAt,
        if (memo != null) 'memo': <String, dynamic>{'text': memo},
        'movie': <String, dynamic>{
          'title': title,
          'year': year,
          'ids': <String, dynamic>{
            'simkl': ?simklId,
            'slug': ?slug,
            'tmdb': ?tmdbId?.toString(),
          },
        },
      };

  Map<String, dynamic> showJson({
    int? tmdbId = 200,
    int? simklId = 2002,
    String status = 'watching',
    String title = 'The Chi',
    List<Map<String, dynamic>>? seasons,
    String? lastWatchedAt,
  }) =>
      <String, dynamic>{
        'status': status,
        'last_watched_at': lastWatchedAt,
        'seasons': ?seasons,
        'show': <String, dynamic>{
          'title': title,
          'year': 2018,
          'ids': <String, dynamic>{
            'simkl': ?simklId,
            'tmdb': ?tmdbId?.toString(),
          },
        },
      };

  Map<String, dynamic> animeJson({
    int? kitsuId = 6448,
    int? malId,
    int? anidbId,
    String status = 'watching',
    String title = 'Hunter x Hunter',
    List<Map<String, dynamic>>? seasons,
    String? lastWatchedAt,
  }) =>
      <String, dynamic>{
        'status': status,
        'anime_type': 'tv',
        'last_watched_at': lastWatchedAt,
        'seasons': ?seasons,
        'show': <String, dynamic>{
          'title': title,
          'year': 2011,
          'ids': <String, dynamic>{
            'simkl': 3003,
            'kitsu': ?kitsuId,
            'mal': ?malId,
            'anidb': ?anidbId,
          },
        },
      };

  void stubLibrary({
    List<Map<String, dynamic>> movies = const <Map<String, dynamic>>[],
    List<Map<String, dynamic>> shows = const <Map<String, dynamic>>[],
    List<Map<String, dynamic>> anime = const <Map<String, dynamic>>[],
  }) {
    when(() => mockSimkl.getAllItems()).thenAnswer(
      (_) async => SimklAllItems.fromJson(<String, dynamic>{
        'movies': movies,
        'shows': shows,
        'anime': anime,
      }),
    );
  }

  SimklImportOptions opts({
    ImportMode mode = ImportMode.newOnly,
    int? collectionId = 1,
  }) =>
      SimklImportOptions(
        mode: mode,
        author: 'me',
        newCollectionName: 'Simkl',
        collectionId: collectionId,
      );

  List<Map<String, dynamic>> capturedItemRows() =>
      verify(() => mockRepo.addItemsBatchReturningIds(any(), captureAny()))
          .captured
          .single as List<Map<String, dynamic>>;

  List<Map<String, dynamic>> capturedWishlistRows() =>
      verify(() => mockWishlist.addWishlistItemsBatch(captureAny()))
          .captured
          .single as List<Map<String, dynamic>>;

  group('SimklImportService.import', () {
    test('fails without throwing when the account is empty', () async {
      stubLibrary();

      final UniversalImportResult result = await sut.import(opts());

      expect(result.success, isFalse);
      expect(result.fatalError, isNotNull);
      verifyNever(() => mockRepo.addItemsBatchReturningIds(any(), any()));
    });

    test('reports a failure result when Simkl rejects the request', () async {
      when(() => mockSimkl.getAllItems())
          .thenThrow(const SimklApiException('nope', statusCode: 401));

      final UniversalImportResult result = await sut.import(opts());

      expect(result.success, isFalse);
      expect(result.fatalError, contains('nope'));
    });

    test('writes a movie row enriched from TMDB by id', () async {
      stubLibrary(movies: <Map<String, dynamic>>[movieJson(rating: 8)]);

      final UniversalImportResult result = await sut.import(opts());

      verify(() => mockTmdb.getMovie(550)).called(1);
      verify(() => mockMovieDao.upsertMovie(any())).called(1);
      expect(result.success, isTrue);
      expect(result.importedByType[MediaType.movie], 1);
      final Map<String, dynamic> row = capturedItemRows().single;
      expect(row['media_type'], MediaType.movie.value);
      expect(row['external_id'], 550);
      expect(row['status'], ItemStatus.completed.value);
      expect(row['user_rating'], 8.0);
      expect(row['platform_id'], isNull);
    });

    test('routes movies whose TMDB fetch failed to the wishlist', () async {
      when(() => mockTmdb.getMovie(any())).thenAnswer((_) async => null);
      stubLibrary(movies: <Map<String, dynamic>>[movieJson()]);

      final UniversalImportResult result = await sut.import(opts());

      expect(result.wishlistedByType[MediaType.movie], 1);
      final Map<String, dynamic> row = capturedWishlistRows().single;
      expect(row['text'], 'Fight Club (1999)');
      expect(row['media_type_hint'], MediaType.movie.value);
      expect(capturedItemRows(), isEmpty);
    });

    test('routes entries without a tmdb id to the wishlist', () async {
      stubLibrary(shows: <Map<String, dynamic>>[showJson(tmdbId: null)]);

      final UniversalImportResult result = await sut.import(opts());

      expect(result.wishlistedByType[MediaType.tvShow], 1);
      verifyNever(() => mockTmdb.getTvShow(any()));
    });

    test('classifies animation by TMDB genres', () async {
      when(() => mockTmdb.getMovie(any())).thenAnswer((_) async =>
          createTestMovie(tmdbId: 550, genres: <String>['Animation']));
      stubLibrary(movies: <Map<String, dynamic>>[movieJson()]);

      final UniversalImportResult result = await sut.import(opts());

      expect(result.importedByType[MediaType.animation], 1);
      final Map<String, dynamic> row = capturedItemRows().single;
      expect(row['media_type'], MediaType.animation.value);
      expect(row['platform_id'], AnimationSource.movie);
    });

    test('maps Simkl statuses to ItemStatus', () async {
      const Map<String, ItemStatus> mapping = <String, ItemStatus>{
        'watching': ItemStatus.inProgress,
        'plantowatch': ItemStatus.planned,
        'completed': ItemStatus.completed,
        'dropped': ItemStatus.dropped,
        'hold': ItemStatus.planned,
        'something-new': ItemStatus.notStarted,
      };

      for (final MapEntry<String, ItemStatus> e in mapping.entries) {
        clearInteractions(mockRepo);
        stubLibrary(movies: <Map<String, dynamic>>[movieJson(status: e.key)]);

        await sut.import(opts());

        expect(capturedItemRows().single['status'], e.value.value,
            reason: 'status ${e.key}');
      }
    });

    test('tags held entries with the on-hold tag', () async {
      stubLibrary(movies: <Map<String, dynamic>>[movieJson(status: 'hold')]);

      await sut.import(opts());

      verify(() => mockTagDao.resolveOrCreate(kSimklOnHoldTag)).called(1);
      verify(() => mockTagDao.addTagToItems(<int>[1], 99)).called(1);
    });

    test('does not touch tags when nothing is on hold', () async {
      stubLibrary(movies: <Map<String, dynamic>>[movieJson()]);

      await sut.import(opts());

      verifyNever(() => mockTagDao.resolveOrCreate(any()));
      verifyNever(() => mockTagDao.addTagToItems(any(), any()));
    });

    test('builds the note from the Simkl link and the memo', () async {
      stubLibrary(
        movies: <Map<String, dynamic>>[movieJson(memo: '  rewatch later  ')],
      );

      await sut.import(opts());

      expect(
        capturedItemRows().single['user_comment'],
        '[Simkl](https://simkl.com/movies/1001/fight-club)\n\nrewatch later',
      );
    });

    test('omits the slug from the link when Simkl sends none', () async {
      stubLibrary(movies: <Map<String, dynamic>>[movieJson(slug: null)]);

      await sut.import(opts());

      expect(
        capturedItemRows().single['user_comment'],
        '[Simkl](https://simkl.com/movies/1001)',
      );
    });

    test('stamps completion and activity dates from last_watched_at',
        () async {
      stubLibrary(movies: <Map<String, dynamic>>[
        movieJson(lastWatchedAt: '2026-01-02T03:04:05Z'),
      ]);

      await sut.import(opts());

      final int epoch =
          DateTime.parse('2026-01-02T03:04:05Z').millisecondsSinceEpoch ~/ 1000;
      final Map<String, dynamic> row = capturedItemRows().single;
      expect(row['added_at'], epoch);
      expect(row['completed_at'], epoch);
      expect(row['last_activity_at'], epoch);
    });

    test('falls back to added_to_watchlist_at for the added date', () async {
      stubLibrary(movies: <Map<String, dynamic>>[
        movieJson(status: 'plantowatch', addedToWatchlistAt: '2025-05-05'),
      ]);

      await sut.import(opts());

      final Map<String, dynamic> row = capturedItemRows().single;
      expect(row['added_at'],
          DateTime.parse('2025-05-05').millisecondsSinceEpoch ~/ 1000);
      expect(row['completed_at'], isNull);
    });

    test('leaves existing items untouched in newOnly mode', () async {
      when(() => mockRepo.getItems(any())).thenAnswer((_) async =>
          <CollectionItem>[
            createTestCollectionItem(
              id: 7,
              mediaType: MediaType.movie,
              externalId: 550,
            ),
          ]);
      stubLibrary(movies: <Map<String, dynamic>>[movieJson(rating: 9)]);

      final UniversalImportResult result = await sut.import(opts());

      expect(result.skipped, 1);
      expect(capturedItemRows(), isEmpty);
      final List<(int, Map<String, dynamic>)> updates =
          verify(() => mockRepo.updateItemFieldsBatch(captureAny()))
              .captured
              .single as List<(int, Map<String, dynamic>)>;
      expect(updates, isEmpty);
    });

    test('refreshes rating and note on existing items in overwrite mode',
        () async {
      when(() => mockRepo.getItems(any())).thenAnswer((_) async =>
          <CollectionItem>[
            createTestCollectionItem(
              id: 7,
              mediaType: MediaType.movie,
              externalId: 550,
              status: ItemStatus.inProgress,
            ),
          ]);
      stubLibrary(movies: <Map<String, dynamic>>[movieJson(rating: 9)]);

      await sut.import(opts(mode: ImportMode.overwrite));

      final List<(int, Map<String, dynamic>)> updates =
          verify(() => mockRepo.updateItemFieldsBatch(captureAny()))
              .captured
              .single as List<(int, Map<String, dynamic>)>;
      expect(updates, hasLength(1));
      expect(updates.single.$1, 7);
      expect(updates.single.$2['user_rating'], 9.0);
      expect(updates.single.$2['status'], ItemStatus.completed.value);
      expect(updates.single.$2['user_comment'], contains('[Simkl]'));
    });
  });

  group('SimklImportService anime resolution', () {
    test('resolves anime by the kitsu id from the list', () async {
      when(() => mockKitsu.getAnimeByIds(<int>[6448])).thenAnswer((_) async =>
          <Anime>[createTestAnime(id: 6448, source: DataSource.kitsu)]);
      stubLibrary(anime: <Map<String, dynamic>>[animeJson()]);

      final UniversalImportResult result = await sut.import(opts());

      expect(result.importedByType[MediaType.anime], 1);
      final Map<String, dynamic> row = capturedItemRows().single;
      expect(row['media_type'], MediaType.anime.value);
      expect(row['external_id'], 6448);
      expect(row['source'], DataSource.kitsu.name);
      verify(() => mockAnimeDao.upsertAnimes(any())).called(1);
      verifyNever(() => mockKitsu.getAnimeByMalIds(any()));
    });

    test('falls back to the MAL mapping when no kitsu id is present', () async {
      when(() => mockKitsu.getAnimeByMalIds(<int>[11061])).thenAnswer(
          (_) async => <int, Anime>{
                11061: createTestAnime(id: 6448, source: DataSource.kitsu),
              });
      stubLibrary(
        anime: <Map<String, dynamic>>[animeJson(kitsuId: null, malId: 11061)],
      );

      final UniversalImportResult result = await sut.import(opts());

      expect(result.importedByType[MediaType.anime], 1);
      expect(capturedItemRows().single['external_id'], 6448);
      verifyNever(() => mockKitsu.getAnimeByIds(any()));
      verifyNever(() => mockKitsu.getAnimeByAnidbIds(any()));
    });

    test('falls back to the AniDB mapping when MAL resolves nothing', () async {
      when(() => mockKitsu.getAnimeByAnidbIds(<int>[4087])).thenAnswer(
          (_) async => <int, Anime>{
                4087: createTestAnime(id: 6448, source: DataSource.kitsu),
              });
      stubLibrary(anime: <Map<String, dynamic>>[
        animeJson(kitsuId: null, malId: 11061, anidbId: 4087),
      ]);

      final UniversalImportResult result = await sut.import(opts());

      expect(result.importedByType[MediaType.anime], 1);
      verify(() => mockKitsu.getAnimeByMalIds(<int>[11061])).called(1);
      verify(() => mockKitsu.getAnimeByAnidbIds(<int>[4087])).called(1);
    });

    test('wishlists anime that no lane could resolve', () async {
      stubLibrary(anime: <Map<String, dynamic>>[animeJson()]);

      final UniversalImportResult result = await sut.import(opts());

      expect(result.wishlistedByType[MediaType.anime], 1);
      expect(capturedWishlistRows().single['text'], 'Hunter x Hunter (2011)');
    });

    test('a failing Kitsu lane only sends its entries to the wishlist',
        () async {
      when(() => mockKitsu.getAnimeByIds(any()))
          .thenThrow(const KitsuApiException('boom'));
      stubLibrary(anime: <Map<String, dynamic>>[animeJson()]);

      final UniversalImportResult result = await sut.import(opts());

      expect(result.success, isTrue);
      expect(result.wishlistedByType[MediaType.anime], 1);
    });
  });

  group('SimklImportService episode marks', () {
    List<Map<String, dynamic>> seasonBlock({
      int number = 1,
      List<(int, String?)> episodes = const <(int, String?)>[(1, null)],
    }) =>
        <Map<String, dynamic>>[
          <String, dynamic>{
            'number': number,
            'episodes': <Map<String, dynamic>>[
              for (final (int ep, String? watchedAt) in episodes)
                <String, dynamic>{'number': ep, 'watched_at': watchedAt},
            ],
          },
        ];

    List<(int, int, int?)> capturedMarks(DataSource source, int showId) =>
        verify(() => mockTvShowDao.markEpisodesWatchedAt(
              any(),
              source,
              showId,
              captureAny(),
            )).captured.single as List<(int, int, int?)>;

    test('writes show marks with the Simkl watch date per episode', () async {
      stubLibrary(shows: <Map<String, dynamic>>[
        showJson(
          seasons: seasonBlock(
            number: 2,
            episodes: <(int, String?)>[
              (3, '2026-02-03T00:00:00Z'),
              (4, null),
            ],
          ),
          lastWatchedAt: '2026-03-03T00:00:00Z',
        ),
      ]);

      await sut.import(opts());

      final int watched =
          DateTime.parse('2026-02-03T00:00:00Z').millisecondsSinceEpoch;
      final int fallback =
          DateTime.parse('2026-03-03T00:00:00Z').millisecondsSinceEpoch;
      expect(capturedMarks(DataSource.tmdb, 200), <(int, int, int?)>[
        (2, 3, watched),
        (2, 4, fallback),
      ]);
    });

    test('expands a completed show over the TMDB episode metadata', () async {
      when(() => mockTmdb.getTvSeasons(200)).thenAnswer((_) async => <TvSeason>[
            const TvSeason(tmdbShowId: 200, seasonNumber: 0),
            const TvSeason(tmdbShowId: 200, seasonNumber: 1),
          ]);
      when(() => mockTmdb.getSeasonEpisodes(200, 1))
          .thenAnswer((_) async => <TvEpisode>[
                const TvEpisode(
                  tmdbShowId: 200,
                  seasonNumber: 1,
                  episodeNumber: 1,
                  name: 'One',
                ),
                const TvEpisode(
                  tmdbShowId: 200,
                  seasonNumber: 1,
                  episodeNumber: 2,
                  name: 'Two',
                ),
              ]);
      stubLibrary(shows: <Map<String, dynamic>>[
        showJson(status: 'completed', lastWatchedAt: '2026-03-03T00:00:00Z'),
      ]);

      await sut.import(opts());

      final int fallback =
          DateTime.parse('2026-03-03T00:00:00Z').millisecondsSinceEpoch;
      // Season 0 is TMDB specials and stays out of the tracker.
      verifyNever(() => mockTmdb.getSeasonEpisodes(200, 0));
      expect(capturedMarks(DataSource.tmdb, 200), <(int, int, int?)>[
        (1, 1, fallback),
        (1, 2, fallback),
      ]);
    });

    test('does not fetch metadata for a show without marks', () async {
      stubLibrary(shows: <Map<String, dynamic>>[showJson()]);

      await sut.import(opts());

      verifyNever(() => mockTmdb.getTvSeasons(any()));
      verifyNever(() => mockTvShowDao.markEpisodesWatchedAt(
            any(),
            any(),
            any(),
            any(),
          ));
    });

    test('maps absolute anime episode numbers onto Kitsu seasons', () async {
      when(() => mockKitsu.getAnimeByIds(<int>[6448])).thenAnswer((_) async =>
          <Anime>[createTestAnime(id: 6448, source: DataSource.kitsu)]);
      when(() => mockKitsu.getAnimeEpisodes(6448))
          .thenAnswer((_) async => <TvEpisode>[
                const TvEpisode(
                  tmdbShowId: 6448,
                  seasonNumber: 1,
                  episodeNumber: 1,
                  name: 'One',
                  source: DataSource.kitsu,
                ),
                const TvEpisode(
                  tmdbShowId: 6448,
                  seasonNumber: 3,
                  episodeNumber: 42,
                  name: 'Forty-two',
                  source: DataSource.kitsu,
                ),
              ]);
      stubLibrary(anime: <Map<String, dynamic>>[
        animeJson(
          seasons: seasonBlock(
            episodes: <(int, String?)>[
              (42, '2026-02-03T00:00:00Z'),
              (999, '2026-02-03T00:00:00Z'),
            ],
          ),
          lastWatchedAt: '2026-03-03T00:00:00Z',
        ),
      ]);

      await sut.import(opts());

      final int watched =
          DateTime.parse('2026-02-03T00:00:00Z').millisecondsSinceEpoch;
      // Episode 999 is not in the Kitsu list, so it has no season to land in.
      expect(capturedMarks(DataSource.kitsu, 6448), <(int, int, int?)>[
        (3, 42, watched),
      ]);
    });

    test('expands a completed anime over the whole Kitsu episode list',
        () async {
      when(() => mockKitsu.getAnimeByIds(<int>[6448])).thenAnswer((_) async =>
          <Anime>[createTestAnime(id: 6448, source: DataSource.kitsu)]);
      when(() => mockKitsu.getAnimeEpisodes(6448))
          .thenAnswer((_) async => <TvEpisode>[
                const TvEpisode(
                  tmdbShowId: 6448,
                  seasonNumber: 1,
                  episodeNumber: 1,
                  name: 'One',
                  source: DataSource.kitsu,
                ),
                const TvEpisode(
                  tmdbShowId: 6448,
                  seasonNumber: 2,
                  episodeNumber: 2,
                  name: 'Two',
                  source: DataSource.kitsu,
                ),
              ]);
      stubLibrary(anime: <Map<String, dynamic>>[
        animeJson(status: 'completed', lastWatchedAt: '2026-03-03T00:00:00Z'),
      ]);

      await sut.import(opts());

      final int fallback =
          DateTime.parse('2026-03-03T00:00:00Z').millisecondsSinceEpoch;
      expect(capturedMarks(DataSource.kitsu, 6448), <(int, int, int?)>[
        (1, 1, fallback),
        (2, 2, fallback),
      ]);
    });

    test('a failing mark write does not fail the import', () async {
      when(() => mockTvShowDao.markEpisodesWatchedAt(
            any(),
            any(),
            any(),
            any(),
          )).thenThrow(Exception('db down'));
      stubLibrary(shows: <Map<String, dynamic>>[
        showJson(seasons: seasonBlock()),
      ]);

      final UniversalImportResult result = await sut.import(opts());

      expect(result.success, isTrue);
      expect(result.importedByType[MediaType.tvShow], 1);
    });
  });

  group('SimklImportService progress', () {
    test('reports the stages of a run in order', () async {
      stubLibrary(
        movies: <Map<String, dynamic>>[movieJson()],
        shows: <Map<String, dynamic>>[
          showJson(seasons: seasonBlockFor(<int>[1])),
        ],
      );

      final List<ImportStage> stages = <ImportStage>[];
      await sut.import(
        opts(),
        onProgress: (ImportProgress p) {
          if (stages.isEmpty || stages.last != p.stage) stages.add(p.stage);
        },
      );

      expect(
        stages,
        containsAllInOrder(<ImportStage>[
          ImportStage.reading,
          ImportStage.fetchingMovies,
          ImportStage.fetchingTvShows,
          ImportStage.addingItems,
          ImportStage.restoringMedia,
          ImportStage.completed,
        ]),
      );
    });

    test('carries the running tallies into the final progress', () async {
      stubLibrary(movies: <Map<String, dynamic>>[movieJson()]);

      ImportProgress? last;
      await sut.import(opts(), onProgress: (ImportProgress p) => last = p);

      expect(last?.stage, ImportStage.completed);
      expect(last?.imported, 1);
      expect(last?.updated, 0);
    });
  });
}

/// A `seasons` block covering [episodes] with no watch dates.
List<Map<String, dynamic>> seasonBlockFor(List<int> episodes) =>
    <Map<String, dynamic>>[
      <String, dynamic>{
        'number': 1,
        'episodes': <Map<String, dynamic>>[
          for (final int ep in episodes)
            <String, dynamic>{'number': ep, 'watched_at': null},
        ],
      },
    ];
