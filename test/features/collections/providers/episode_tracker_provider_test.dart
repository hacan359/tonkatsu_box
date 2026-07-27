import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/kitsu_api.dart';
import 'package:tonkatsu_box/core/api/tmdb_api.dart';
import 'package:tonkatsu_box/core/database/database_service.dart';
import 'package:tonkatsu_box/features/collections/providers/collections_provider.dart';
import 'package:tonkatsu_box/features/collections/providers/episode_tracker_provider.dart';
import 'package:tonkatsu_box/shared/models/anime.dart';
import 'package:tonkatsu_box/shared/models/collection_item.dart';
import 'package:tonkatsu_box/shared/models/data_source.dart';
import 'package:tonkatsu_box/shared/models/item_status.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';
import 'package:tonkatsu_box/shared/models/tv_episode.dart';
import 'package:tonkatsu_box/shared/models/tv_season.dart';
import 'package:tonkatsu_box/shared/models/tv_show.dart';

import '../../../helpers/test_helpers.dart';

class TrackingCollectionItemsNotifier extends CollectionItemsNotifier {
  TrackingCollectionItemsNotifier(this._items);

  final List<CollectionItem> _items;

  final List<(int, ItemStatus, MediaType)> updateStatusCalls =
      <(int, ItemStatus, MediaType)>[];

  @override
  AsyncValue<List<CollectionItem>> build(int? arg) {
    return AsyncValue<List<CollectionItem>>.data(_items);
  }

  @override
  Future<void> updateStatus(
      int id, ItemStatus status, MediaType mediaType) async {
    updateStatusCalls.add((id, status, mediaType));
    // Mirrors real CollectionItemsNotifier.updateStatus logic.
    final List<CollectionItem>? current = state.valueOrNull;
    if (current != null) {
      final DateTime now = DateTime.now();
      state = AsyncData<List<CollectionItem>>(
        current.map((CollectionItem i) {
          if (i.id == id) {
            if (status == ItemStatus.notStarted) {
              return i.copyWith(
                status: status,
                clearStartedAt: true,
                clearCompletedAt: true,
                lastActivityAt: now,
              );
            }
            if (status == ItemStatus.inProgress) {
              return i.copyWith(
                status: status,
                startedAt: i.startedAt ?? now,
                clearCompletedAt: true,
                lastActivityAt: now,
              );
            }
            if (status == ItemStatus.completed) {
              return i.copyWith(
                status: status,
                startedAt: i.startedAt ?? now,
                completedAt: now,
                lastActivityAt: now,
              );
            }
            return i.copyWith(status: status);
          }
          return i;
        }).toList(),
      );
    }
  }
}

const int testCollectionId = 1;
const int testShowId = 100;

const ({int collectionId, int showId, DataSource source}) testArg = (
  collectionId: testCollectionId,
  showId: testShowId,
  source: DataSource.tmdb,
);

const TvEpisode testEpisode1 = TvEpisode(
  tmdbShowId: testShowId,
  seasonNumber: 1,
  episodeNumber: 1,
  name: 'Episode 1',
  overview: 'First episode',
  airDate: '2023-01-01',
  stillUrl: 'https://example.com/s1e1.jpg',
  runtime: 45,
);

const TvEpisode testEpisode2 = TvEpisode(
  tmdbShowId: testShowId,
  seasonNumber: 1,
  episodeNumber: 2,
  name: 'Episode 2',
  overview: 'Second episode',
  airDate: '2023-01-08',
  stillUrl: 'https://example.com/s1e2.jpg',
  runtime: 45,
);

const TvEpisode testEpisode3 = TvEpisode(
  tmdbShowId: testShowId,
  seasonNumber: 1,
  episodeNumber: 3,
  name: 'Episode 3',
  overview: 'Third episode',
  airDate: '2023-01-15',
  stillUrl: 'https://example.com/s1e3.jpg',
  runtime: 45,
);

const TvEpisode testEpisode2s1 = TvEpisode(
  tmdbShowId: testShowId,
  seasonNumber: 2,
  episodeNumber: 1,
  name: 'Season 2 Episode 1',
  overview: 'First episode of season 2',
  airDate: '2023-02-01',
  stillUrl: 'https://example.com/s2e1.jpg',
  runtime: 45,
);

const TvEpisode testEpisode2s2 = TvEpisode(
  tmdbShowId: testShowId,
  seasonNumber: 2,
  episodeNumber: 2,
  name: 'Season 2 Episode 2',
  overview: 'Second episode of season 2',
  airDate: '2023-02-08',
  stillUrl: 'https://example.com/s2e2.jpg',
  runtime: 45,
);

const TvEpisode testEpisodeSpecial = TvEpisode(
  tmdbShowId: testShowId,
  seasonNumber: 0,
  episodeNumber: 1,
  name: 'Special 1',
  overview: 'OVA special',
  airDate: '2023-03-01',
  stillUrl: 'https://example.com/s0e1.jpg',
  runtime: 24,
);

void main() {
  late MockDatabaseService mockDb;
  late MockTvShowDao mockTvShowDao;
  late MockTmdbApi mockTmdbApi;

  setUpAll(registerAllFallbacks);

  setUp(() {
    mockDb = MockDatabaseService();
    mockTvShowDao = MockTvShowDao();
    when(() => mockDb.tvShowDao).thenReturn(mockTvShowDao);
    // Eager cache load on build; default to no cached episodes so tests that
    // don't care about it are unaffected.
    when(() => mockTvShowDao.getEpisodesByShowId(any(), any()))
        .thenAnswer((_) async => <TvEpisode>[]);
    when(() => mockTvShowDao.getTvShowByTmdbId(any(),
        source: any(named: 'source'))).thenAnswer((_) async => null);
    when(() => mockTvShowDao.getTvSeasonsByShowId(any(), any()))
        .thenAnswer((_) async => <TvSeason>[]);
    mockTmdbApi = MockTmdbApi();
    when(() => mockTmdbApi.getTvShow(any()))
        .thenAnswer((_) async => null);
  });

  ProviderContainer createContainer() {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        databaseServiceProvider.overrideWithValue(mockDb),
        tmdbApiProvider.overrideWithValue(mockTmdbApi),
        collectionItemsNotifierProvider.overrideWith(
          MockCollectionItemsNotifier.new,
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('EpisodeTrackerState', () {
    test('should createся с пустыми значениями по умолчанию', () {
      const EpisodeTrackerState state = EpisodeTrackerState();

      expect(state.episodesBySeason, isEmpty);
      expect(state.watchedEpisodes, isEmpty);
      expect(state.loadingSeasons, isEmpty);
      expect(state.error, isNull);
    });

    test('should createся с кастомными значениями', () {
      final Map<int, List<TvEpisode>> episodes = <int, List<TvEpisode>>{
        1: <TvEpisode>[testEpisode1, testEpisode2],
      };
      final Map<(int, int), DateTime?> watched = <(int, int), DateTime?>{(1, 1): null};
      final Map<int, bool> loading = <int, bool>{1: false};

      final EpisodeTrackerState state = EpisodeTrackerState(
        episodesBySeason: episodes,
        watchedEpisodes: watched,
        loadingSeasons: loading,
        error: 'Test error',
      );

      expect(state.episodesBySeason.length, 1);
      expect(state.episodesBySeason[1]?.length, 2);
      expect(state.watchedEpisodes.length, 1);
      expect(state.watchedEpisodes.containsKey((1, 1)), true);
      expect(state.loadingSeasons[1], false);
      expect(state.error, 'Test error');
    });

    group('copyWith', () {
      test('должен копировать с изменёнными episodesBySeason', () {
        const EpisodeTrackerState original = EpisodeTrackerState();
        final Map<int, List<TvEpisode>> newEpisodes = <int, List<TvEpisode>>{
          1: <TvEpisode>[testEpisode1],
        };

        final EpisodeTrackerState copy =
            original.copyWith(episodesBySeason: newEpisodes);

        expect(copy.episodesBySeason.length, 1);
        expect(copy.watchedEpisodes, original.watchedEpisodes);
        expect(copy.loadingSeasons, original.loadingSeasons);
      });

      test('должен копировать с изменёнными watchedEpisodes', () {
        const EpisodeTrackerState original = EpisodeTrackerState();
        final Map<(int, int), DateTime?> newWatched = <(int, int), DateTime?>{(1, 1): null};

        final EpisodeTrackerState copy =
            original.copyWith(watchedEpisodes: newWatched);

        expect(copy.watchedEpisodes.length, 1);
        expect(copy.episodesBySeason, original.episodesBySeason);
      });

      test('должен копировать с изменёнными loadingSeasons', () {
        const EpisodeTrackerState original = EpisodeTrackerState();
        final Map<int, bool> newLoading = <int, bool>{1: true};

        final EpisodeTrackerState copy =
            original.copyWith(loadingSeasons: newLoading);

        expect(copy.loadingSeasons[1], true);
        expect(copy.episodesBySeason, original.episodesBySeason);
      });

      test('должен копировать с изменённой ошибкой', () {
        const EpisodeTrackerState original = EpisodeTrackerState();

        final EpisodeTrackerState copy =
            original.copyWith(error: 'New error');

        expect(copy.error, 'New error');
      });
    });

    group('isEpisodeWatched', () {
      test('should return true для просмотренного эпизода', () {
        const EpisodeTrackerState state = EpisodeTrackerState(
          watchedEpisodes: <(int, int), DateTime?>{(1, 1): null, (1, 2): null},
        );

        expect(state.isEpisodeWatched(1, 1), true);
        expect(state.isEpisodeWatched(1, 2), true);
      });

      test('should return false для непросмотренного эпизода', () {
        const EpisodeTrackerState state = EpisodeTrackerState(
          watchedEpisodes: <(int, int), DateTime?>{(1, 1): null},
        );

        expect(state.isEpisodeWatched(1, 2), false);
        expect(state.isEpisodeWatched(2, 1), false);
      });
    });

    group('watchedCountForSeason', () {
      test('should return количество просмотренных эпизодов в сезоне', () {
        const EpisodeTrackerState state = EpisodeTrackerState(
          watchedEpisodes: <(int, int), DateTime?>{(1, 1): null, (1, 2): null, (2, 1): null},
        );

        expect(state.watchedCountForSeason(1), 2);
        expect(state.watchedCountForSeason(2), 1);
        expect(state.watchedCountForSeason(3), 0);
      });
    });

    group('totalWatchedCount', () {
      test('should return общее количество просмотренных эпизодов', () {
        const EpisodeTrackerState state = EpisodeTrackerState(
          watchedEpisodes: <(int, int), DateTime?>{(1, 1): null, (1, 2): null, (2, 1): null},
        );

        expect(state.totalWatchedCount, 3);
      });

      test('should return 0 для пустого множества', () {
        const EpisodeTrackerState state = EpisodeTrackerState();

        expect(state.totalWatchedCount, 0);
      });

      test('не должен считать спецвыпуски (season 0)', () {
        const EpisodeTrackerState state = EpisodeTrackerState(
          watchedEpisodes: <(int, int), DateTime?>{
            (0, 1): null,
            (0, 2): null,
            (1, 1): null,
          },
        );

        expect(state.totalWatchedCount, 1);
      });

      test('should return 0 если просмотрены только спецвыпуски', () {
        const EpisodeTrackerState state = EpisodeTrackerState(
          watchedEpisodes: <(int, int), DateTime?>{(0, 1): null},
        );

        expect(state.totalWatchedCount, 0);
      });
    });

    group('totalEpisodeCount', () {
      test('should return общее количество загруженных эпизодов', () {
        const EpisodeTrackerState state = EpisodeTrackerState(
          episodesBySeason: <int, List<TvEpisode>>{
            1: <TvEpisode>[testEpisode1, testEpisode2, testEpisode3],
            2: <TvEpisode>[testEpisode2s1, testEpisode2s2],
          },
        );

        expect(state.totalEpisodeCount, 5);
      });

      test('should return 0 для пустой карты', () {
        const EpisodeTrackerState state = EpisodeTrackerState();

        expect(state.totalEpisodeCount, 0);
      });

      test('не должен считать эпизоды спецвыпусков (season 0)', () {
        const EpisodeTrackerState state = EpisodeTrackerState(
          episodesBySeason: <int, List<TvEpisode>>{
            0: <TvEpisode>[testEpisode2s1, testEpisode2s2],
            1: <TvEpisode>[testEpisode1, testEpisode2, testEpisode3],
          },
        );

        expect(state.totalEpisodeCount, 3);
      });
    });
  });

  group('EpisodeTrackerNotifier', () {
    group('build', () {
      test('должен инициализироваться с пустым состоянием', () {
        when(() => mockTvShowDao.getWatchedEpisodes(testCollectionId, DataSource.tmdb, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});

        final ProviderContainer container = createContainer();
        final EpisodeTrackerState state =
            container.read(episodeTrackerNotifierProvider(testArg));

        expect(state.episodesBySeason, isEmpty);
        expect(state.watchedEpisodes, isEmpty);
        expect(state.loadingSeasons, isEmpty);
        expect(state.error, isNull);
      });

      test('должен загружать просмотренные эпизоды из БД', () async {
        final Map<(int, int), DateTime?> watchedEpisodes = <(int, int), DateTime?>{
          (1, 1): null,
          (1, 2): null,
          (2, 1): null,
        };
        when(() => mockTvShowDao.getWatchedEpisodes(testCollectionId, DataSource.tmdb, testShowId))
            .thenAnswer((_) async => watchedEpisodes);

        final ProviderContainer container = createContainer();
        container.read(episodeTrackerNotifierProvider(testArg));

        await Future<void>.delayed(Duration.zero);

        final EpisodeTrackerState state =
            container.read(episodeTrackerNotifierProvider(testArg));

        expect(state.watchedEpisodes, watchedEpisodes);
        verify(() => mockTvShowDao.getWatchedEpisodes(testCollectionId, DataSource.tmdb, testShowId))
            .called(1);
      });

      test(
          'should load cached episodes once via ensureCachedEpisodesLoaded, '
          'not on build', () async {
        when(() => mockTvShowDao.getWatchedEpisodes(testCollectionId, DataSource.tmdb, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        when(() => mockTvShowDao.getEpisodesByShowId(DataSource.tmdb, testShowId)).thenAnswer(
          (_) async => <TvEpisode>[
            testEpisode1,
            testEpisode2,
            testEpisode2s1,
          ],
        );

        final ProviderContainer container = createContainer();
        final EpisodeTrackerNotifier notifier = container
            .read(episodeTrackerNotifierProvider(testArg).notifier);

        await Future<void>.delayed(Duration.zero);

        // Grid cards watch this provider; building it must not pull the
        // full episode cache.
        verifyNever(() => mockTvShowDao.getEpisodesByShowId(any(), any()));

        await notifier.ensureCachedEpisodesLoaded();
        await notifier.ensureCachedEpisodesLoaded();

        final EpisodeTrackerState state =
            container.read(episodeTrackerNotifierProvider(testArg));

        expect(state.episodesBySeason[1], hasLength(2));
        expect(state.episodesBySeason[2], hasLength(1));
        verify(() => mockTvShowDao.getEpisodesByShowId(DataSource.tmdb, testShowId)).called(1);
      });

      test('should handle ошибку загрузки просмотренных эпизодов',
          () async {
        when(() => mockTvShowDao.getWatchedEpisodes(testCollectionId, DataSource.tmdb, testShowId))
            .thenThrow(Exception('Database error'));

        final ProviderContainer container = createContainer();
        container.read(episodeTrackerNotifierProvider(testArg));

        await Future<void>.delayed(Duration.zero);

        final EpisodeTrackerState state =
            container.read(episodeTrackerNotifierProvider(testArg));

        expect(state.error, contains('Failed to load watched episodes'));
        expect(state.error, contains('Database error'));
      });

      test('должен публиковать totals из кэшированной карточки шоу',
          () async {
        when(() => mockTvShowDao.getWatchedEpisodes(
                testCollectionId, DataSource.tmdb, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        when(() => mockTvShowDao.getTvShowByTmdbId(testShowId,
                source: any(named: 'source')))
            .thenAnswer((_) async => const TvShow(
                  tmdbId: testShowId,
                  title: 'Show',
                  totalEpisodes: 38,
                ));

        final ProviderContainer container = createContainer();
        container.read(episodeTrackerNotifierProvider(testArg));

        await Future<void>.delayed(Duration.zero);

        expect(
          container.read(episodeTrackerNotifierProvider(testArg))
              .totalEpisodes,
          38,
        );
      });

      test(
          'должен считать totals по кэшу сезонов без спецвыпусков, '
          'когда карточка шоу без totals', () async {
        when(() => mockTvShowDao.getWatchedEpisodes(
                testCollectionId, DataSource.tmdb, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        when(() => mockTvShowDao.getTvSeasonsByShowId(
                DataSource.tmdb, testShowId))
            .thenAnswer((_) async => const <TvSeason>[
                  TvSeason(
                    tmdbShowId: testShowId,
                    seasonNumber: 0,
                    episodeCount: 5,
                  ),
                  TvSeason(
                    tmdbShowId: testShowId,
                    seasonNumber: 1,
                    episodeCount: 10,
                  ),
                  TvSeason(
                    tmdbShowId: testShowId,
                    seasonNumber: 2,
                    episodeCount: 8,
                  ),
                ]);

        final ProviderContainer container = createContainer();
        container.read(episodeTrackerNotifierProvider(testArg));

        await Future<void>.delayed(Duration.zero);

        expect(
          container.read(episodeTrackerNotifierProvider(testArg))
              .totalEpisodes,
          18,
        );
      });

      test('totals остаются null, когда в кэше ничего нет', () async {
        when(() => mockTvShowDao.getWatchedEpisodes(
                testCollectionId, DataSource.tmdb, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});

        final ProviderContainer container = createContainer();
        container.read(episodeTrackerNotifierProvider(testArg));

        await Future<void>.delayed(Duration.zero);

        expect(
          container.read(episodeTrackerNotifierProvider(testArg))
              .totalEpisodes,
          isNull,
        );
      });
    });

    group('loadSeason', () {
      test('должен загружать эпизоды из кеша БД', () async {
        when(() => mockTvShowDao.getWatchedEpisodes(testCollectionId, DataSource.tmdb, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        final List<TvEpisode> cachedEpisodes = <TvEpisode>[
          testEpisode1,
          testEpisode2,
          testEpisode3,
        ];
        when(() => mockTvShowDao.getEpisodesByShowAndSeason(
                DataSource.tmdb, testShowId, 1))
            .thenAnswer((_) async => cachedEpisodes);

        final ProviderContainer container = createContainer();
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        await Future<void>.delayed(Duration.zero);

        await notifier.loadSeason(1);

        final EpisodeTrackerState state =
            container.read(episodeTrackerNotifierProvider(testArg));

        expect(state.episodesBySeason[1], cachedEpisodes);
        expect(state.loadingSeasons[1], false);
        expect(state.error, isNull);
        verify(() => mockTvShowDao.getEpisodesByShowAndSeason(
                DataSource.tmdb, testShowId, 1))
            .called(1);
        verifyNever(() => mockTmdbApi.getSeasonEpisodes(testShowId, 1));
      });

      test('должен загружать эпизоды из API если кеш пуст', () async {
        when(() => mockTvShowDao.getWatchedEpisodes(testCollectionId, DataSource.tmdb, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        when(() => mockTvShowDao.getEpisodesByShowAndSeason(
                DataSource.tmdb, testShowId, 1))
            .thenAnswer((_) async => <TvEpisode>[]);
        final List<TvEpisode> apiEpisodes = <TvEpisode>[
          testEpisode1,
          testEpisode2,
          testEpisode3,
        ];
        when(() => mockTmdbApi.getSeasonEpisodes(testShowId, 1))
            .thenAnswer((_) async => apiEpisodes);
        when(() => mockTvShowDao.upsertEpisodes(any()))
            .thenAnswer((_) async {});

        final ProviderContainer container = createContainer();
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        await Future<void>.delayed(Duration.zero);

        await notifier.loadSeason(1);

        final EpisodeTrackerState state =
            container.read(episodeTrackerNotifierProvider(testArg));

        expect(state.episodesBySeason[1], apiEpisodes);
        expect(state.loadingSeasons[1], false);
        expect(state.error, isNull);
        verify(() => mockTvShowDao.getEpisodesByShowAndSeason(
                DataSource.tmdb, testShowId, 1))
            .called(1);
        verify(() => mockTmdbApi.getSeasonEpisodes(testShowId, 1)).called(1);
        verify(() => mockTvShowDao.upsertEpisodes(apiEpisodes)).called(1);
      });

      test('должен кешировать результаты API в БД', () async {
        when(() => mockTvShowDao.getWatchedEpisodes(testCollectionId, DataSource.tmdb, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        when(() => mockTvShowDao.getEpisodesByShowAndSeason(
                DataSource.tmdb, testShowId, 1))
            .thenAnswer((_) async => <TvEpisode>[]);
        final List<TvEpisode> apiEpisodes = <TvEpisode>[
          testEpisode1,
          testEpisode2,
        ];
        when(() => mockTmdbApi.getSeasonEpisodes(testShowId, 1))
            .thenAnswer((_) async => apiEpisodes);
        when(() => mockTvShowDao.upsertEpisodes(any()))
            .thenAnswer((_) async {});

        final ProviderContainer container = createContainer();
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        await Future<void>.delayed(Duration.zero);

        await notifier.loadSeason(1);

        verify(() => mockTvShowDao.upsertEpisodes(apiEpisodes)).called(1);
      });

      test('не должен кешировать пустой список из API', () async {
        when(() => mockTvShowDao.getWatchedEpisodes(testCollectionId, DataSource.tmdb, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        when(() => mockTvShowDao.getEpisodesByShowAndSeason(
                DataSource.tmdb, testShowId, 1))
            .thenAnswer((_) async => <TvEpisode>[]);
        when(() => mockTmdbApi.getSeasonEpisodes(testShowId, 1))
            .thenAnswer((_) async => <TvEpisode>[]);

        final ProviderContainer container = createContainer();
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        await Future<void>.delayed(Duration.zero);

        await notifier.loadSeason(1);

        final EpisodeTrackerState state =
            container.read(episodeTrackerNotifierProvider(testArg));

        expect(state.episodesBySeason[1], isEmpty);
        verifyNever(() => mockTvShowDao.upsertEpisodes(any()));
      });

      test('should handle ошибку загрузки из API', () async {
        when(() => mockTvShowDao.getWatchedEpisodes(testCollectionId, DataSource.tmdb, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        when(() => mockTvShowDao.getEpisodesByShowAndSeason(
                DataSource.tmdb, testShowId, 1))
            .thenAnswer((_) async => <TvEpisode>[]);
        when(() => mockTmdbApi.getSeasonEpisodes(testShowId, 1))
            .thenThrow(Exception('API error'));

        final ProviderContainer container = createContainer();
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        await Future<void>.delayed(Duration.zero);

        await notifier.loadSeason(1);

        final EpisodeTrackerState state =
            container.read(episodeTrackerNotifierProvider(testArg));

        expect(state.episodesBySeason[1], isNull);
        expect(state.loadingSeasons[1], false);
        expect(state.error, contains('Failed to load season 1'));
        expect(state.error, contains('API error'));
      });

      test('не должен загружать уже загруженный сезон', () async {
        when(() => mockTvShowDao.getWatchedEpisodes(testCollectionId, DataSource.tmdb, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        final List<TvEpisode> cachedEpisodes = <TvEpisode>[testEpisode1];
        when(() => mockTvShowDao.getEpisodesByShowAndSeason(
                DataSource.tmdb, testShowId, 1))
            .thenAnswer((_) async => cachedEpisodes);

        final ProviderContainer container = createContainer();
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        await Future<void>.delayed(Duration.zero);

        await notifier.loadSeason(1);
        await notifier.loadSeason(1);

        verify(() => mockTvShowDao.getEpisodesByShowAndSeason(
                DataSource.tmdb, testShowId, 1))
            .called(1);
      });

      test('не должен загружать сезон, который уже загружается', () async {
        when(() => mockTvShowDao.getWatchedEpisodes(testCollectionId, DataSource.tmdb, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        when(() => mockTvShowDao.getEpisodesByShowAndSeason(
                DataSource.tmdb, testShowId, 1))
            .thenAnswer((_) async {
          // Simulate slow load to exercise the in-flight guard.
          await Future<void>.delayed(const Duration(milliseconds: 100));
          return <TvEpisode>[testEpisode1];
        });

        final ProviderContainer container = createContainer();
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        await Future<void>.delayed(Duration.zero);

        final Future<void> load1 = notifier.loadSeason(1);
        final Future<void> load2 = notifier.loadSeason(1);

        await Future.wait(<Future<void>>[load1, load2]);

        verify(() => mockTvShowDao.getEpisodesByShowAndSeason(
                DataSource.tmdb, testShowId, 1))
            .called(1);
      });

      test('should set loading flag во время загрузки', () async {
        when(() => mockTvShowDao.getWatchedEpisodes(testCollectionId, DataSource.tmdb, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        when(() => mockTvShowDao.getEpisodesByShowAndSeason(
                DataSource.tmdb, testShowId, 1))
            .thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return <TvEpisode>[testEpisode1];
        });

        final ProviderContainer container = createContainer();
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        await Future<void>.delayed(Duration.zero);

        final Future<void> loadFuture = notifier.loadSeason(1);

        await Future<void>.delayed(const Duration(milliseconds: 10));
        EpisodeTrackerState state =
            container.read(episodeTrackerNotifierProvider(testArg));
        expect(state.loadingSeasons[1], true);

        await loadFuture;

        state = container.read(episodeTrackerNotifierProvider(testArg));
        expect(state.loadingSeasons[1], false);
      });
    });

    group('toggleEpisode', () {
      test('должен отмечать эпизод как просмотренный', () async {
        when(() => mockTvShowDao.getWatchedEpisodes(testCollectionId, DataSource.tmdb, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        when(() =>
                mockTvShowDao.markEpisodeWatched(testCollectionId, DataSource.tmdb, testShowId, 1, 1))
            .thenAnswer((_) async {});

        final ProviderContainer container = createContainer();
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        await Future<void>.delayed(Duration.zero);

        await notifier.toggleEpisode(1, 1);

        final EpisodeTrackerState state =
            container.read(episodeTrackerNotifierProvider(testArg));

        expect(state.isEpisodeWatched(1, 1), true);
        verify(() =>
                mockTvShowDao.markEpisodeWatched(testCollectionId, DataSource.tmdb, testShowId, 1, 1))
            .called(1);
      });

      test('должен снимать отметку просмотра с эпизода', () async {
        final Map<(int, int), DateTime?> watchedEpisodes = <(int, int), DateTime?>{(1, 1): null};
        when(() => mockTvShowDao.getWatchedEpisodes(testCollectionId, DataSource.tmdb, testShowId))
            .thenAnswer((_) async => watchedEpisodes);
        when(
          () => mockTvShowDao.markEpisodeUnwatched(testCollectionId, DataSource.tmdb, testShowId, 1, 1),
        ).thenAnswer((_) async {});

        final ProviderContainer container = createContainer();
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        await Future<void>.delayed(Duration.zero);

        await notifier.toggleEpisode(1, 1);

        final EpisodeTrackerState state =
            container.read(episodeTrackerNotifierProvider(testArg));

        expect(state.isEpisodeWatched(1, 1), false);
        verify(
          () => mockTvShowDao.markEpisodeUnwatched(testCollectionId, DataSource.tmdb, testShowId, 1, 1),
        ).called(1);
      });

      test('should update состояние после отметки просмотра', () async {
        when(() => mockTvShowDao.getWatchedEpisodes(testCollectionId, DataSource.tmdb, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        when(() =>
                mockTvShowDao.markEpisodeWatched(testCollectionId, DataSource.tmdb, testShowId, 1, 1))
            .thenAnswer((_) async {});
        when(() =>
                mockTvShowDao.markEpisodeWatched(testCollectionId, DataSource.tmdb, testShowId, 1, 2))
            .thenAnswer((_) async {});

        final ProviderContainer container = createContainer();
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        await Future<void>.delayed(Duration.zero);

        await notifier.toggleEpisode(1, 1);
        await notifier.toggleEpisode(1, 2);

        final EpisodeTrackerState state =
            container.read(episodeTrackerNotifierProvider(testArg));

        expect(state.watchedEpisodes.length, 2);
        expect(state.isEpisodeWatched(1, 1), true);
        expect(state.isEpisodeWatched(1, 2), true);
      });
    });

    group('refreshSeason', () {
      test('должен принудительно загружать эпизоды из API', () async {
        when(() => mockTvShowDao.getWatchedEpisodes(testCollectionId, DataSource.tmdb, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        final List<TvEpisode> cachedEpisodes = <TvEpisode>[testEpisode1];
        when(() => mockTvShowDao.getEpisodesByShowAndSeason(
                DataSource.tmdb, testShowId, 1))
            .thenAnswer((_) async => cachedEpisodes);
        final List<TvEpisode> apiEpisodes = <TvEpisode>[
          testEpisode1,
          testEpisode2,
          testEpisode3,
        ];
        when(() => mockTmdbApi.getSeasonEpisodes(testShowId, 1))
            .thenAnswer((_) async => apiEpisodes);
        when(() => mockTvShowDao.upsertEpisodes(any()))
            .thenAnswer((_) async {});

        final ProviderContainer container = createContainer();
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        await Future<void>.delayed(Duration.zero);

        await notifier.loadSeason(1);
        EpisodeTrackerState state =
            container.read(episodeTrackerNotifierProvider(testArg));
        expect(state.episodesBySeason[1]?.length, 1);

        await notifier.refreshSeason(1);
        state = container.read(episodeTrackerNotifierProvider(testArg));
        expect(state.episodesBySeason[1]?.length, 3);
        verify(() => mockTmdbApi.getSeasonEpisodes(testShowId, 1)).called(1);
        verify(() => mockTvShowDao.upsertEpisodes(apiEpisodes)).called(1);
      });

      test('should update эпизоды даже если сезон ещё не загружен',
          () async {
        when(() => mockTvShowDao.getWatchedEpisodes(testCollectionId, DataSource.tmdb, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        final List<TvEpisode> apiEpisodes = <TvEpisode>[testEpisode1];
        when(() => mockTmdbApi.getSeasonEpisodes(testShowId, 1))
            .thenAnswer((_) async => apiEpisodes);
        when(() => mockTvShowDao.upsertEpisodes(any()))
            .thenAnswer((_) async {});

        final ProviderContainer container = createContainer();
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        await Future<void>.delayed(Duration.zero);

        await notifier.refreshSeason(1);

        final EpisodeTrackerState state =
            container.read(episodeTrackerNotifierProvider(testArg));
        expect(state.episodesBySeason[1], apiEpisodes);
        expect(state.loadingSeasons[1], false);
      });

      test('should handle ошибку API при обновлении', () async {
        when(() => mockTvShowDao.getWatchedEpisodes(testCollectionId, DataSource.tmdb, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        when(() => mockTmdbApi.getSeasonEpisodes(testShowId, 1))
            .thenThrow(Exception('API unavailable'));

        final ProviderContainer container = createContainer();
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        await Future<void>.delayed(Duration.zero);

        await notifier.refreshSeason(1);

        final EpisodeTrackerState state =
            container.read(episodeTrackerNotifierProvider(testArg));
        expect(state.error, contains('Failed to refresh season 1'));
        expect(state.loadingSeasons[1], false);
      });

      test('не должен кешировать пустой результат API', () async {
        when(() => mockTvShowDao.getWatchedEpisodes(testCollectionId, DataSource.tmdb, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        when(() => mockTmdbApi.getSeasonEpisodes(testShowId, 1))
            .thenAnswer((_) async => <TvEpisode>[]);

        final ProviderContainer container = createContainer();
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        await Future<void>.delayed(Duration.zero);

        await notifier.refreshSeason(1);

        verifyNever(() => mockTvShowDao.upsertEpisodes(any()));
      });
    });

    group('toggleSeason', () {
      test('должен отмечать все эпизоды сезона как просмотренные', () async {
        when(() => mockTvShowDao.getWatchedEpisodes(testCollectionId, DataSource.tmdb, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        when(() => mockTvShowDao.getEpisodesByShowAndSeason(
                DataSource.tmdb, testShowId, 1))
            .thenAnswer(
          (_) async => <TvEpisode>[testEpisode1, testEpisode2, testEpisode3],
        );
        when(
          () => mockTvShowDao.markSeasonWatched(
            testCollectionId,
            DataSource.tmdb,
            testShowId,
            1,
            <int>[1, 2, 3],
          ),
        ).thenAnswer((_) async {});

        final ProviderContainer container = createContainer();
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        await Future<void>.delayed(Duration.zero);

        await notifier.loadSeason(1);
        await notifier.toggleSeason(1);

        final EpisodeTrackerState state =
            container.read(episodeTrackerNotifierProvider(testArg));

        expect(state.isEpisodeWatched(1, 1), true);
        expect(state.isEpisodeWatched(1, 2), true);
        expect(state.isEpisodeWatched(1, 3), true);
        expect(state.watchedCountForSeason(1), 3);
        verify(
          () => mockTvShowDao.markSeasonWatched(
            testCollectionId,
            DataSource.tmdb,
            testShowId,
            1,
            <int>[1, 2, 3],
          ),
        ).called(1);
      });

      test('должен снимать отметку просмотра со всех эпизодов сезона',
          () async {
        final Map<(int, int), DateTime?> watchedEpisodes = <(int, int), DateTime?>{
          (1, 1): null,
          (1, 2): null,
          (1, 3): null,
        };
        when(() => mockTvShowDao.getWatchedEpisodes(testCollectionId, DataSource.tmdb, testShowId))
            .thenAnswer((_) async => watchedEpisodes);
        when(() => mockTvShowDao.getEpisodesByShowAndSeason(
                DataSource.tmdb, testShowId, 1))
            .thenAnswer(
          (_) async => <TvEpisode>[testEpisode1, testEpisode2, testEpisode3],
        );
        when(() => mockTvShowDao.unmarkSeasonWatched(testCollectionId, DataSource.tmdb, testShowId, 1))
            .thenAnswer((_) async {});

        final ProviderContainer container = createContainer();
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        await Future<void>.delayed(Duration.zero);

        await notifier.loadSeason(1);
        await notifier.toggleSeason(1);

        final EpisodeTrackerState state =
            container.read(episodeTrackerNotifierProvider(testArg));

        expect(state.isEpisodeWatched(1, 1), false);
        expect(state.isEpisodeWatched(1, 2), false);
        expect(state.isEpisodeWatched(1, 3), false);
        expect(state.watchedCountForSeason(1), 0);
        verify(() => mockTvShowDao.unmarkSeasonWatched(testCollectionId, DataSource.tmdb, testShowId, 1))
            .called(1);
      });

      test('должен отмечать частично просмотренный сезон как полностью просмотренный',
          () async {
        final Map<(int, int), DateTime?> watchedEpisodes = <(int, int), DateTime?>{(1, 1): null};
        when(() => mockTvShowDao.getWatchedEpisodes(testCollectionId, DataSource.tmdb, testShowId))
            .thenAnswer((_) async => watchedEpisodes);
        when(() => mockTvShowDao.getEpisodesByShowAndSeason(
                DataSource.tmdb, testShowId, 1))
            .thenAnswer(
          (_) async => <TvEpisode>[testEpisode1, testEpisode2, testEpisode3],
        );
        when(
          () => mockTvShowDao.markSeasonWatched(
            testCollectionId,
            DataSource.tmdb,
            testShowId,
            1,
            <int>[1, 2, 3],
          ),
        ).thenAnswer((_) async {});

        final ProviderContainer container = createContainer();
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        await Future<void>.delayed(Duration.zero);

        await notifier.loadSeason(1);
        await notifier.toggleSeason(1);

        final EpisodeTrackerState state =
            container.read(episodeTrackerNotifierProvider(testArg));

        expect(state.watchedCountForSeason(1), 3);
        verify(
          () => mockTvShowDao.markSeasonWatched(
            testCollectionId,
            DataSource.tmdb,
            testShowId,
            1,
            <int>[1, 2, 3],
          ),
        ).called(1);
      });

      test('не должен делать ничего если сезон не загружен', () async {
        when(() => mockTvShowDao.getWatchedEpisodes(testCollectionId, DataSource.tmdb, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});

        final ProviderContainer container = createContainer();
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        await Future<void>.delayed(Duration.zero);

        await notifier.toggleSeason(1);

        verifyNever(
          () => mockTvShowDao.markSeasonWatched(any(), any(), any(), any(), any()),
        );
        verifyNever(() => mockTvShowDao.unmarkSeasonWatched(any(), any(), any(), any()));
      });

      test('не должен делать ничего если сезон пустой', () async {
        when(() => mockTvShowDao.getWatchedEpisodes(testCollectionId, DataSource.tmdb, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        when(() => mockTvShowDao.getEpisodesByShowAndSeason(
                DataSource.tmdb, testShowId, 1))
            .thenAnswer((_) async => <TvEpisode>[]);
        when(() => mockTmdbApi.getSeasonEpisodes(testShowId, 1))
            .thenAnswer((_) async => <TvEpisode>[]);

        final ProviderContainer container = createContainer();
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        await Future<void>.delayed(Duration.zero);

        await notifier.loadSeason(1);
        await notifier.toggleSeason(1);

        verifyNever(
          () => mockTvShowDao.markSeasonWatched(any(), any(), any(), any(), any()),
        );
        verifyNever(() => mockTvShowDao.unmarkSeasonWatched(any(), any(), any(), any()));
      });
    });

    group('_updateAutoStatus (через toggleEpisode)', () {
      late TrackingCollectionItemsNotifier lastTracking;

      ProviderContainer createTrackingContainer(
          List<CollectionItem> items) {
        // Kitsu anime resolve their totals through the Kitsu source; without
        // the override the resolver would build a real networked client.
        final MockKitsuApi mockKitsuApi = MockKitsuApi();
        when(() => mockKitsuApi.getAnimeById(any()))
            .thenAnswer((_) async => null);
        when(() => mockKitsuApi.getAnimeEpisodes(any()))
            .thenAnswer((_) async => <TvEpisode>[]);
        when(() => mockKitsuApi.getAnimeEpisodeCount(any()))
            .thenAnswer((_) async => null);

        final ProviderContainer container = ProviderContainer(
          overrides: <Override>[
            databaseServiceProvider.overrideWithValue(mockDb),
            tmdbApiProvider.overrideWithValue(mockTmdbApi),
            kitsuApiProvider.overrideWithValue(mockKitsuApi),
            collectionItemsNotifierProvider.overrideWith(
              () {
                lastTracking = TrackingCollectionItemsNotifier(items);
                return lastTracking;
              },
            ),
          ],
        );
        addTearDown(container.dispose);
        return container;
      }

      CollectionItem createTvItem({
        int id = 1,
        ItemStatus status = ItemStatus.notStarted,
        MediaType mediaType = MediaType.tvShow,
        int totalEpisodes = 10,
        int? totalSeasons,
        int? platformId,
      }) {
        return CollectionItem(
          id: id,
          collectionId: testCollectionId,
          mediaType: mediaType,
          externalId: testShowId,
          status: status,
          addedAt: DateTime(2024),
          platformId: platformId,
          tvShow: TvShow(
            tmdbId: testShowId,
            title: 'Test Show',
            posterUrl: null,
            totalEpisodes: totalEpisodes,
            totalSeasons: totalSeasons,
          ),
        );
      }

      test('должен перевести в inProgress при первом отмеченном эпизоде',
          () async {
        final CollectionItem item = createTvItem();
        when(() => mockTvShowDao.getWatchedEpisodes(testCollectionId, DataSource.tmdb, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        when(() =>
                mockTvShowDao.markEpisodeWatched(testCollectionId, DataSource.tmdb, testShowId, 1, 1))
            .thenAnswer((_) async {});

        final ProviderContainer container =
            createTrackingContainer(<CollectionItem>[item]);
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        await Future<void>.delayed(Duration.zero);
        await notifier.toggleEpisode(1, 1);
        await Future<void>.delayed(Duration.zero);

        expect(lastTracking.updateStatusCalls, hasLength(1));
        expect(lastTracking.updateStatusCalls.first.$1, item.id);
        expect(lastTracking.updateStatusCalls.first.$2, ItemStatus.inProgress);
        expect(lastTracking.updateStatusCalls.first.$3, MediaType.tvShow);
      });

      test('должен перевести в inProgress при статусе planned', () async {
        final CollectionItem item =
            createTvItem(status: ItemStatus.planned);
        when(() => mockTvShowDao.getWatchedEpisodes(testCollectionId, DataSource.tmdb, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        when(() =>
                mockTvShowDao.markEpisodeWatched(testCollectionId, DataSource.tmdb, testShowId, 1, 1))
            .thenAnswer((_) async {});

        final ProviderContainer container =
            createTrackingContainer(<CollectionItem>[item]);
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        await Future<void>.delayed(Duration.zero);
        await notifier.toggleEpisode(1, 1);
        await Future<void>.delayed(Duration.zero);

        expect(lastTracking.updateStatusCalls, hasLength(1));
        expect(lastTracking.updateStatusCalls.first.$2, ItemStatus.inProgress);
      });

      // Kitsu anime run on the same tracker; their totals come from the anime
      // record instead of a cached `tvShow` row.
      CollectionItem createKitsuAnimeItem({
        ItemStatus status = ItemStatus.notStarted,
        int episodes = 10,
      }) {
        return CollectionItem(
          id: 1,
          collectionId: testCollectionId,
          mediaType: MediaType.anime,
          externalId: testShowId,
          status: status,
          addedAt: DateTime(2024),
          anime: Anime(
            id: testShowId,
            source: DataSource.kitsu,
            title: 'Test Anime',
            episodes: episodes,
          ),
        );
      }

      const ({int collectionId, int showId, DataSource source}) kitsuArg = (
        collectionId: testCollectionId,
        showId: testShowId,
        source: DataSource.kitsu,
      );

      test('kitsu-аниме: первый эпизод переводит в inProgress', () async {
        when(() => mockTvShowDao.getWatchedEpisodes(
                testCollectionId, DataSource.kitsu, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        when(() => mockTvShowDao.markEpisodeWatched(
                testCollectionId, DataSource.kitsu, testShowId, 1, 1))
            .thenAnswer((_) async {});

        final ProviderContainer container = createTrackingContainer(
            <CollectionItem>[createKitsuAnimeItem()]);
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(kitsuArg).notifier);

        await Future<void>.delayed(Duration.zero);
        await notifier.toggleEpisode(1, 1);
        await Future<void>.delayed(Duration.zero);

        expect(lastTracking.updateStatusCalls, hasLength(1));
        expect(lastTracking.updateStatusCalls.first.$2, ItemStatus.inProgress);
        expect(lastTracking.updateStatusCalls.first.$3, MediaType.anime);
      });

      test('kitsu-аниме: последний эпизод переводит в completed', () async {
        when(() => mockTvShowDao.getWatchedEpisodes(
                testCollectionId, DataSource.kitsu, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{
                  (1, 1): DateTime(2024),
                });
        when(() => mockTvShowDao.markEpisodeWatched(
                testCollectionId, DataSource.kitsu, testShowId, 1, 2))
            .thenAnswer((_) async {});

        final ProviderContainer container = createTrackingContainer(
            <CollectionItem>[createKitsuAnimeItem(episodes: 2)]);
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(kitsuArg).notifier);

        await Future<void>.delayed(Duration.zero);
        await notifier.toggleEpisode(1, 2);
        await Future<void>.delayed(Duration.zero);

        expect(lastTracking.updateStatusCalls, hasLength(1));
        expect(lastTracking.updateStatusCalls.first.$2, ItemStatus.completed);
      });

      test('должен перевести в completed когда все эпизоды просмотрены',
          () async {
        final CollectionItem item =
            createTvItem(totalEpisodes: 2, status: ItemStatus.notStarted);
        when(() => mockTvShowDao.getWatchedEpisodes(testCollectionId, DataSource.tmdb, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{
                  (1, 1): DateTime(2024),
                });
        when(() =>
                mockTvShowDao.markEpisodeWatched(testCollectionId, DataSource.tmdb, testShowId, 1, 2))
            .thenAnswer((_) async {});

        final ProviderContainer container =
            createTrackingContainer(<CollectionItem>[item]);
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        await Future<void>.delayed(Duration.zero);
        await notifier.toggleEpisode(1, 2);
        await Future<void>.delayed(Duration.zero);

        expect(lastTracking.updateStatusCalls, hasLength(1));
        expect(lastTracking.updateStatusCalls[0].$2, ItemStatus.completed);
      });

      test('НЕ должен делать auto-complete если totalEpisodes == 0',
          () async {
        final CollectionItem item =
            createTvItem(totalEpisodes: 0, status: ItemStatus.notStarted);
        when(() => mockTvShowDao.getWatchedEpisodes(testCollectionId, DataSource.tmdb, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        when(() =>
                mockTvShowDao.markEpisodeWatched(testCollectionId, DataSource.tmdb, testShowId, 1, 1))
            .thenAnswer((_) async {});

        final ProviderContainer container =
            createTrackingContainer(<CollectionItem>[item]);
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        await Future<void>.delayed(Duration.zero);
        await notifier.toggleEpisode(1, 1);
        await Future<void>.delayed(Duration.zero);

        expect(lastTracking.updateStatusCalls, hasLength(1));
        expect(lastTracking.updateStatusCalls.first.$2, ItemStatus.inProgress);
      });

      test(
          'должен делать auto-complete через fallback если totalEpisodes == 0 но все сезоны загружены',
          () async {
        final CollectionItem item = createTvItem(
          totalEpisodes: 0,
          totalSeasons: 1,
          status: ItemStatus.notStarted,
        );
        when(() => mockTvShowDao.getWatchedEpisodes(testCollectionId, DataSource.tmdb, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        when(() => mockTvShowDao.getEpisodesByShowAndSeason(
                DataSource.tmdb, testShowId, 1))
            .thenAnswer((_) async =>
                <TvEpisode>[testEpisode1, testEpisode2, testEpisode3]);
        when(() => mockTvShowDao.markSeasonWatched(
              testCollectionId,
              DataSource.tmdb,
              testShowId,
              1,
              <int>[1, 2, 3],
            )).thenAnswer((_) async {});

        final ProviderContainer container =
            createTrackingContainer(<CollectionItem>[item]);
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        await Future<void>.delayed(Duration.zero);

        await notifier.loadSeason(1);
        await notifier.toggleSeason(1);
        await Future<void>.delayed(Duration.zero);

        expect(lastTracking.updateStatusCalls, hasLength(1));
        expect(lastTracking.updateStatusCalls[0].$2, ItemStatus.completed);

        final List<CollectionItem>? items = container
            .read(collectionItemsNotifierProvider(testCollectionId))
            .valueOrNull;
        final CollectionItem updatedItem = items!.firstWhere(
          (CollectionItem ci) => ci.externalId == testShowId,
        );
        expect(updatedItem.completedAt, isNotNull);
      });

      test(
          'просмотренные спецвыпуски не должны давать досрочный completed',
          () async {
        final CollectionItem item =
            createTvItem(totalEpisodes: 2, status: ItemStatus.notStarted);
        when(() => mockTvShowDao.getWatchedEpisodes(testCollectionId, DataSource.tmdb, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{
                  (0, 1): DateTime(2024),
                });
        when(() =>
                mockTvShowDao.markEpisodeWatched(testCollectionId, DataSource.tmdb, testShowId, 1, 1))
            .thenAnswer((_) async {});

        final ProviderContainer container =
            createTrackingContainer(<CollectionItem>[item]);
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        await Future<void>.delayed(Duration.zero);
        await notifier.toggleEpisode(1, 1);
        await Future<void>.delayed(Duration.zero);

        // 1 regular of 2 plus a special: inProgress, not completed.
        expect(lastTracking.updateStatusCalls, hasLength(1));
        expect(lastTracking.updateStatusCalls.first.$2, ItemStatus.inProgress);
      });

      test('отметка только спецвыпуска не должна включать inProgress',
          () async {
        final CollectionItem item = createTvItem();
        when(() => mockTvShowDao.getWatchedEpisodes(testCollectionId, DataSource.tmdb, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        when(() =>
                mockTvShowDao.markEpisodeWatched(testCollectionId, DataSource.tmdb, testShowId, 0, 1))
            .thenAnswer((_) async {});

        final ProviderContainer container =
            createTrackingContainer(<CollectionItem>[item]);
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        await Future<void>.delayed(Duration.zero);
        await notifier.toggleEpisode(0, 1);
        await Future<void>.delayed(Duration.zero);

        expect(lastTracking.updateStatusCalls, isEmpty);
      });

      test('fallback не должен считать season 0 загруженным сезоном',
          () async {
        final CollectionItem item = createTvItem(
          totalEpisodes: 0,
          totalSeasons: 2,
          status: ItemStatus.notStarted,
        );
        when(() => mockTvShowDao.getWatchedEpisodes(testCollectionId, DataSource.tmdb, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        when(() => mockTvShowDao.getEpisodesByShowAndSeason(
                DataSource.tmdb, testShowId, 0))
            .thenAnswer((_) async => <TvEpisode>[testEpisodeSpecial]);
        when(() => mockTvShowDao.getEpisodesByShowAndSeason(
                DataSource.tmdb, testShowId, 1))
            .thenAnswer((_) async =>
                <TvEpisode>[testEpisode1, testEpisode2, testEpisode3]);
        when(() => mockTvShowDao.markSeasonWatched(
              testCollectionId,
              DataSource.tmdb,
              testShowId,
              1,
              <int>[1, 2, 3],
            )).thenAnswer((_) async {});

        final ProviderContainer container =
            createTrackingContainer(<CollectionItem>[item]);
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        await Future<void>.delayed(Duration.zero);

        // Season 0 and season 1 loaded out of two regular seasons: season 0
        // must not satisfy the "all seasons loaded" condition.
        await notifier.loadSeason(0);
        await notifier.loadSeason(1);
        await notifier.toggleSeason(1);
        await Future<void>.delayed(Duration.zero);

        expect(lastTracking.updateStatusCalls, hasLength(1));
        expect(lastTracking.updateStatusCalls.first.$2, ItemStatus.inProgress);
      });

      test('должен сбрасывать в notStarted при снятии всех отметок',
          () async {
        final CollectionItem item =
            createTvItem(status: ItemStatus.inProgress);
        when(() => mockTvShowDao.getWatchedEpisodes(testCollectionId, DataSource.tmdb, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{
                  (1, 1): DateTime(2024),
                });
        when(() => mockTvShowDao.markEpisodeUnwatched(
                testCollectionId, DataSource.tmdb, testShowId, 1, 1))
            .thenAnswer((_) async {});

        final ProviderContainer container =
            createTrackingContainer(<CollectionItem>[item]);
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        await Future<void>.delayed(Duration.zero);
        await notifier.toggleEpisode(1, 1);
        await Future<void>.delayed(Duration.zero);

        expect(lastTracking.updateStatusCalls, hasLength(1));
        expect(lastTracking.updateStatusCalls.first.$2, ItemStatus.notStarted);
      });

      test('должен перевести completed → inProgress при частичном снятии',
          () async {
        final CollectionItem item =
            createTvItem(totalEpisodes: 3, status: ItemStatus.completed);
        when(() => mockTvShowDao.getWatchedEpisodes(testCollectionId, DataSource.tmdb, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{
                  (1, 1): DateTime(2024),
                  (1, 2): DateTime(2024),
                  (1, 3): DateTime(2024),
                });
        when(() => mockTvShowDao.markEpisodeUnwatched(
                testCollectionId, DataSource.tmdb, testShowId, 1, 3))
            .thenAnswer((_) async {});

        final ProviderContainer container =
            createTrackingContainer(<CollectionItem>[item]);
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        await Future<void>.delayed(Duration.zero);
        await notifier.toggleEpisode(1, 3);
        await Future<void>.delayed(Duration.zero);

        expect(lastTracking.updateStatusCalls, hasLength(1));
        expect(lastTracking.updateStatusCalls.first.$2, ItemStatus.inProgress);
      });

      // Only the TV-show flavour of animation runs on the tracker; an
      // animated movie has no episode grid to mark from.
      test('должен находить анимационный сериал (MediaType.animation)',
          () async {
        final CollectionItem item = createTvItem(
          mediaType: MediaType.animation,
          platformId: AnimationSource.tvShow,
        );
        when(() => mockTvShowDao.getWatchedEpisodes(testCollectionId, DataSource.tmdb, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        when(() =>
                mockTvShowDao.markEpisodeWatched(testCollectionId, DataSource.tmdb, testShowId, 1, 1))
            .thenAnswer((_) async {});

        final ProviderContainer container =
            createTrackingContainer(<CollectionItem>[item]);
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        await Future<void>.delayed(Duration.zero);
        await notifier.toggleEpisode(1, 1);
        await Future<void>.delayed(Duration.zero);

        expect(lastTracking.updateStatusCalls, hasLength(1));
        expect(lastTracking.updateStatusCalls.first.$3, MediaType.animation);
      });

      test('не должен менять статус dropped при отметке эпизода', () async {
        final CollectionItem item =
            createTvItem(status: ItemStatus.dropped);
        when(() => mockTvShowDao.getWatchedEpisodes(testCollectionId, DataSource.tmdb, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{
                  (1, 1): DateTime(2024),
                });
        when(() =>
                mockTvShowDao.markEpisodeWatched(testCollectionId, DataSource.tmdb, testShowId, 1, 2))
            .thenAnswer((_) async {});

        final ProviderContainer container =
            createTrackingContainer(<CollectionItem>[item]);
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        await Future<void>.delayed(Duration.zero);
        await notifier.toggleEpisode(1, 2);
        await Future<void>.delayed(Duration.zero);

        expect(lastTracking.updateStatusCalls, isEmpty);
      });

      test('не должен менять статус если collectionId == null', () async {
        when(() => mockTvShowDao.getWatchedEpisodes(any(), any(), testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});

        const ({int? collectionId, int showId, DataSource source}) uncatArg =
            (
          collectionId: null,
          showId: testShowId,
          source: DataSource.tmdb,
        );
        final ProviderContainer container =
            createTrackingContainer(<CollectionItem>[]);
        container.read(episodeTrackerNotifierProvider(uncatArg));

        await Future<void>.delayed(Duration.zero);

        expect(lastTracking.updateStatusCalls, isEmpty);
      });

      test(
          'должен заполнять completedAt при пометке всех эпизодов всех сезонов через toggleSeason',
          () async {
        final CollectionItem item =
            createTvItem(totalEpisodes: 5, status: ItemStatus.notStarted);

        when(() => mockTvShowDao.getWatchedEpisodes(testCollectionId, DataSource.tmdb, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});

        when(() => mockTvShowDao.getEpisodesByShowAndSeason(
                DataSource.tmdb, testShowId, 1))
            .thenAnswer((_) async =>
                <TvEpisode>[testEpisode1, testEpisode2, testEpisode3]);
        when(() => mockTvShowDao.getEpisodesByShowAndSeason(
                DataSource.tmdb, testShowId, 2))
            .thenAnswer(
                (_) async => <TvEpisode>[testEpisode2s1, testEpisode2s2]);

        when(() => mockTvShowDao.markSeasonWatched(
              testCollectionId,
              DataSource.tmdb,
              testShowId,
              1,
              <int>[1, 2, 3],
            )).thenAnswer((_) async {});
        when(() => mockTvShowDao.markSeasonWatched(
              testCollectionId,
              DataSource.tmdb,
              testShowId,
              2,
              <int>[1, 2],
            )).thenAnswer((_) async {});

        final ProviderContainer container =
            createTrackingContainer(<CollectionItem>[item]);
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        await Future<void>.delayed(Duration.zero);

        await notifier.loadSeason(1);
        await notifier.loadSeason(2);

        await notifier.toggleSeason(1);
        await Future<void>.delayed(Duration.zero);

        expect(lastTracking.updateStatusCalls, hasLength(1));
        expect(lastTracking.updateStatusCalls[0].$2, ItemStatus.inProgress);

        await notifier.toggleSeason(2);
        await Future<void>.delayed(Duration.zero);

        expect(lastTracking.updateStatusCalls, hasLength(2));
        expect(lastTracking.updateStatusCalls[1].$2, ItemStatus.completed);

        final List<CollectionItem>? items = container
            .read(collectionItemsNotifierProvider(testCollectionId))
            .valueOrNull;
        expect(items, isNotNull);

        final CollectionItem updatedItem = items!.firstWhere(
          (CollectionItem ci) => ci.externalId == testShowId,
        );
        expect(updatedItem.status, ItemStatus.completed);
        expect(updatedItem.completedAt, isNotNull);
        expect(updatedItem.startedAt, isNotNull);
      });

      test(
          'должен заполнять completedAt при пометке единственного сезона через toggleSeason',
          () async {
        final CollectionItem item =
            createTvItem(totalEpisodes: 3, status: ItemStatus.notStarted);

        when(() => mockTvShowDao.getWatchedEpisodes(testCollectionId, DataSource.tmdb, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        when(() => mockTvShowDao.getEpisodesByShowAndSeason(
                DataSource.tmdb, testShowId, 1))
            .thenAnswer((_) async =>
                <TvEpisode>[testEpisode1, testEpisode2, testEpisode3]);
        when(() => mockTvShowDao.markSeasonWatched(
              testCollectionId,
              DataSource.tmdb,
              testShowId,
              1,
              <int>[1, 2, 3],
            )).thenAnswer((_) async {});

        final ProviderContainer container =
            createTrackingContainer(<CollectionItem>[item]);
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        await Future<void>.delayed(Duration.zero);

        await notifier.loadSeason(1);
        await notifier.toggleSeason(1);
        await Future<void>.delayed(Duration.zero);

        expect(lastTracking.updateStatusCalls, hasLength(1));
        expect(lastTracking.updateStatusCalls[0].$2, ItemStatus.completed);

        final List<CollectionItem>? items = container
            .read(collectionItemsNotifierProvider(testCollectionId))
            .valueOrNull;
        expect(items, isNotNull);

        final CollectionItem updatedItem = items!.firstWhere(
          (CollectionItem ci) => ci.externalId == testShowId,
        );
        expect(updatedItem.status, ItemStatus.completed);
        expect(updatedItem.completedAt, isNotNull);
        expect(updatedItem.startedAt, isNotNull);
      });

      test('не должен менять статус если items == null', () async {
        when(() => mockTvShowDao.getWatchedEpisodes(testCollectionId, DataSource.tmdb, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        when(() =>
                mockTvShowDao.markEpisodeWatched(testCollectionId, DataSource.tmdb, testShowId, 1, 1))
            .thenAnswer((_) async {});

        final ProviderContainer container = createContainer();
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        await Future<void>.delayed(Duration.zero);
        await notifier.toggleEpisode(1, 1);
        await Future<void>.delayed(Duration.zero);
      });

      test('should publish totals from the cached show into state', () async {
        final CollectionItem item = createTvItem(totalEpisodes: 22);
        when(() => mockTvShowDao.getWatchedEpisodes(
                testCollectionId, DataSource.tmdb, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        when(() => mockTvShowDao.markEpisodeWatched(
                testCollectionId, DataSource.tmdb, testShowId, 1, 1))
            .thenAnswer((_) async {});

        final ProviderContainer container =
            createTrackingContainer(<CollectionItem>[item]);
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        await Future<void>.delayed(Duration.zero);
        await notifier.toggleEpisode(1, 1);
        await Future<void>.delayed(Duration.zero);

        expect(
          container.read(episodeTrackerNotifierProvider(testArg)).totalEpisodes,
          22,
        );
      });

      test('should publish totals fetched from the API when the cache has none',
          () async {
        final CollectionItem item =
            createTvItem(totalEpisodes: 0, totalSeasons: 0);
        when(() => mockTvShowDao.getWatchedEpisodes(
                testCollectionId, DataSource.tmdb, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        when(() => mockTvShowDao.markEpisodeWatched(
                testCollectionId, DataSource.tmdb, testShowId, 1, 1))
            .thenAnswer((_) async {});
        when(() => mockTvShowDao.upsertTvShow(any())).thenAnswer((_) async {});
        when(() => mockTmdbApi.getTvShow(testShowId)).thenAnswer(
          (_) async => const TvShow(
            tmdbId: testShowId,
            title: 'Test Show',
            totalEpisodes: 22,
            totalSeasons: 2,
          ),
        );

        final ProviderContainer container =
            createTrackingContainer(<CollectionItem>[item]);
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        await Future<void>.delayed(Duration.zero);
        await notifier.toggleEpisode(1, 1);
        await Future<void>.delayed(Duration.zero);

        expect(
          container.read(episodeTrackerNotifierProvider(testArg)).totalEpisodes,
          22,
        );
        verify(() => mockTvShowDao.upsertTvShow(any())).called(1);
      });
    });
  });
}
