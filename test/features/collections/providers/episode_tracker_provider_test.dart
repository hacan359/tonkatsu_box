// Тесты провайдера EpisodeTrackerNotifier.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/core/api/tmdb_api.dart';
import 'package:xerabora/core/database/database_service.dart';
import 'package:xerabora/features/collections/providers/collections_provider.dart';
import 'package:xerabora/features/collections/providers/episode_tracker_provider.dart';
import 'package:xerabora/shared/models/collection_item.dart';
import 'package:xerabora/shared/models/tv_episode.dart';

// Моки
class MockDatabaseService extends Mock implements DatabaseService {}

class MockTmdbApi extends Mock implements TmdbApi {}

class MockCollectionItemsNotifier extends CollectionItemsNotifier {
  @override
  AsyncValue<List<CollectionItem>> build(int? arg) {
    return const AsyncValue<List<CollectionItem>>.data(<CollectionItem>[]);
  }
}

// Тестовые данные
const int testCollectionId = 1;
const int testShowId = 100;

const ({int collectionId, int showId}) testArg = (
  collectionId: testCollectionId,
  showId: testShowId,
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

void main() {
  late MockDatabaseService mockDb;
  late MockTmdbApi mockTmdbApi;

  setUp(() {
    mockDb = MockDatabaseService();
    mockTmdbApi = MockTmdbApi();
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
    test('должен создаваться с пустыми значениями по умолчанию', () {
      const EpisodeTrackerState state = EpisodeTrackerState();

      expect(state.episodesBySeason, isEmpty);
      expect(state.watchedEpisodes, isEmpty);
      expect(state.loadingSeasons, isEmpty);
      expect(state.error, isNull);
    });

    test('должен создаваться с кастомными значениями', () {
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
      test('должен возвращать true для просмотренного эпизода', () {
        const EpisodeTrackerState state = EpisodeTrackerState(
          watchedEpisodes: <(int, int), DateTime?>{(1, 1): null, (1, 2): null},
        );

        expect(state.isEpisodeWatched(1, 1), true);
        expect(state.isEpisodeWatched(1, 2), true);
      });

      test('должен возвращать false для непросмотренного эпизода', () {
        const EpisodeTrackerState state = EpisodeTrackerState(
          watchedEpisodes: <(int, int), DateTime?>{(1, 1): null},
        );

        expect(state.isEpisodeWatched(1, 2), false);
        expect(state.isEpisodeWatched(2, 1), false);
      });
    });

    group('watchedCountForSeason', () {
      test('должен возвращать количество просмотренных эпизодов в сезоне', () {
        const EpisodeTrackerState state = EpisodeTrackerState(
          watchedEpisodes: <(int, int), DateTime?>{(1, 1): null, (1, 2): null, (2, 1): null},
        );

        expect(state.watchedCountForSeason(1), 2);
        expect(state.watchedCountForSeason(2), 1);
        expect(state.watchedCountForSeason(3), 0);
      });
    });

    group('totalWatchedCount', () {
      test('должен возвращать общее количество просмотренных эпизодов', () {
        const EpisodeTrackerState state = EpisodeTrackerState(
          watchedEpisodes: <(int, int), DateTime?>{(1, 1): null, (1, 2): null, (2, 1): null},
        );

        expect(state.totalWatchedCount, 3);
      });

      test('должен возвращать 0 для пустого множества', () {
        const EpisodeTrackerState state = EpisodeTrackerState();

        expect(state.totalWatchedCount, 0);
      });
    });

    group('totalEpisodeCount', () {
      test('должен возвращать общее количество загруженных эпизодов', () {
        const EpisodeTrackerState state = EpisodeTrackerState(
          episodesBySeason: <int, List<TvEpisode>>{
            1: <TvEpisode>[testEpisode1, testEpisode2, testEpisode3],
            2: <TvEpisode>[testEpisode2s1, testEpisode2s2],
          },
        );

        expect(state.totalEpisodeCount, 5);
      });

      test('должен возвращать 0 для пустой карты', () {
        const EpisodeTrackerState state = EpisodeTrackerState();

        expect(state.totalEpisodeCount, 0);
      });
    });
  });

  group('EpisodeTrackerNotifier', () {
    group('build', () {
      test('должен инициализироваться с пустым состоянием', () {
        when(() => mockDb.getWatchedEpisodes(testCollectionId, testShowId))
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
        when(() => mockDb.getWatchedEpisodes(testCollectionId, testShowId))
            .thenAnswer((_) async => watchedEpisodes);

        final ProviderContainer container = createContainer();
        container.read(episodeTrackerNotifierProvider(testArg));

        // Ждём выполнения microtask
        await Future<void>.delayed(Duration.zero);

        final EpisodeTrackerState state =
            container.read(episodeTrackerNotifierProvider(testArg));

        expect(state.watchedEpisodes, watchedEpisodes);
        verify(() => mockDb.getWatchedEpisodes(testCollectionId, testShowId))
            .called(1);
      });

      test('должен обрабатывать ошибку загрузки просмотренных эпизодов',
          () async {
        when(() => mockDb.getWatchedEpisodes(testCollectionId, testShowId))
            .thenThrow(Exception('Database error'));

        final ProviderContainer container = createContainer();
        container.read(episodeTrackerNotifierProvider(testArg));

        // Ждём выполнения microtask
        await Future<void>.delayed(Duration.zero);

        final EpisodeTrackerState state =
            container.read(episodeTrackerNotifierProvider(testArg));

        expect(state.error, contains('Failed to load watched episodes'));
        expect(state.error, contains('Database error'));
      });
    });

    group('loadSeason', () {
      test('должен загружать эпизоды из кеша БД', () async {
        when(() => mockDb.getWatchedEpisodes(testCollectionId, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        final List<TvEpisode> cachedEpisodes = <TvEpisode>[
          testEpisode1,
          testEpisode2,
          testEpisode3,
        ];
        when(() => mockDb.getEpisodesByShowAndSeason(testShowId, 1))
            .thenAnswer((_) async => cachedEpisodes);

        final ProviderContainer container = createContainer();
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        // Ждём выполнения microtask
        await Future<void>.delayed(Duration.zero);

        await notifier.loadSeason(1);

        final EpisodeTrackerState state =
            container.read(episodeTrackerNotifierProvider(testArg));

        expect(state.episodesBySeason[1], cachedEpisodes);
        expect(state.loadingSeasons[1], false);
        expect(state.error, isNull);
        verify(() => mockDb.getEpisodesByShowAndSeason(testShowId, 1))
            .called(1);
        verifyNever(() => mockTmdbApi.getSeasonEpisodes(testShowId, 1));
      });

      test('должен загружать эпизоды из API если кеш пуст', () async {
        when(() => mockDb.getWatchedEpisodes(testCollectionId, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        when(() => mockDb.getEpisodesByShowAndSeason(testShowId, 1))
            .thenAnswer((_) async => <TvEpisode>[]);
        final List<TvEpisode> apiEpisodes = <TvEpisode>[
          testEpisode1,
          testEpisode2,
          testEpisode3,
        ];
        when(() => mockTmdbApi.getSeasonEpisodes(testShowId, 1))
            .thenAnswer((_) async => apiEpisodes);
        when(() => mockDb.upsertEpisodes(any()))
            .thenAnswer((_) async {});

        final ProviderContainer container = createContainer();
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        // Ждём выполнения microtask
        await Future<void>.delayed(Duration.zero);

        await notifier.loadSeason(1);

        final EpisodeTrackerState state =
            container.read(episodeTrackerNotifierProvider(testArg));

        expect(state.episodesBySeason[1], apiEpisodes);
        expect(state.loadingSeasons[1], false);
        expect(state.error, isNull);
        verify(() => mockDb.getEpisodesByShowAndSeason(testShowId, 1))
            .called(1);
        verify(() => mockTmdbApi.getSeasonEpisodes(testShowId, 1)).called(1);
        verify(() => mockDb.upsertEpisodes(apiEpisodes)).called(1);
      });

      test('должен кешировать результаты API в БД', () async {
        when(() => mockDb.getWatchedEpisodes(testCollectionId, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        when(() => mockDb.getEpisodesByShowAndSeason(testShowId, 1))
            .thenAnswer((_) async => <TvEpisode>[]);
        final List<TvEpisode> apiEpisodes = <TvEpisode>[
          testEpisode1,
          testEpisode2,
        ];
        when(() => mockTmdbApi.getSeasonEpisodes(testShowId, 1))
            .thenAnswer((_) async => apiEpisodes);
        when(() => mockDb.upsertEpisodes(any()))
            .thenAnswer((_) async {});

        final ProviderContainer container = createContainer();
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        // Ждём выполнения microtask
        await Future<void>.delayed(Duration.zero);

        await notifier.loadSeason(1);

        verify(() => mockDb.upsertEpisodes(apiEpisodes)).called(1);
      });

      test('не должен кешировать пустой список из API', () async {
        when(() => mockDb.getWatchedEpisodes(testCollectionId, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        when(() => mockDb.getEpisodesByShowAndSeason(testShowId, 1))
            .thenAnswer((_) async => <TvEpisode>[]);
        when(() => mockTmdbApi.getSeasonEpisodes(testShowId, 1))
            .thenAnswer((_) async => <TvEpisode>[]);

        final ProviderContainer container = createContainer();
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        // Ждём выполнения microtask
        await Future<void>.delayed(Duration.zero);

        await notifier.loadSeason(1);

        final EpisodeTrackerState state =
            container.read(episodeTrackerNotifierProvider(testArg));

        expect(state.episodesBySeason[1], isEmpty);
        verifyNever(() => mockDb.upsertEpisodes(any()));
      });

      test('должен обрабатывать ошибку загрузки из API', () async {
        when(() => mockDb.getWatchedEpisodes(testCollectionId, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        when(() => mockDb.getEpisodesByShowAndSeason(testShowId, 1))
            .thenAnswer((_) async => <TvEpisode>[]);
        when(() => mockTmdbApi.getSeasonEpisodes(testShowId, 1))
            .thenThrow(Exception('API error'));

        final ProviderContainer container = createContainer();
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        // Ждём выполнения microtask
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
        when(() => mockDb.getWatchedEpisodes(testCollectionId, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        final List<TvEpisode> cachedEpisodes = <TvEpisode>[testEpisode1];
        when(() => mockDb.getEpisodesByShowAndSeason(testShowId, 1))
            .thenAnswer((_) async => cachedEpisodes);

        final ProviderContainer container = createContainer();
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        // Ждём выполнения microtask
        await Future<void>.delayed(Duration.zero);

        await notifier.loadSeason(1);
        await notifier.loadSeason(1);

        // Должен вызваться только один раз
        verify(() => mockDb.getEpisodesByShowAndSeason(testShowId, 1))
            .called(1);
      });

      test('не должен загружать сезон, который уже загружается', () async {
        when(() => mockDb.getWatchedEpisodes(testCollectionId, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        when(() => mockDb.getEpisodesByShowAndSeason(testShowId, 1))
            .thenAnswer((_) async {
          // Имитируем долгую загрузку
          await Future<void>.delayed(const Duration(milliseconds: 100));
          return <TvEpisode>[testEpisode1];
        });

        final ProviderContainer container = createContainer();
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        // Ждём выполнения microtask
        await Future<void>.delayed(Duration.zero);

        // Запускаем две загрузки параллельно
        final Future<void> load1 = notifier.loadSeason(1);
        final Future<void> load2 = notifier.loadSeason(1);

        await Future.wait(<Future<void>>[load1, load2]);

        // Должен вызваться только один раз
        verify(() => mockDb.getEpisodesByShowAndSeason(testShowId, 1))
            .called(1);
      });

      test('должен устанавливать loading flag во время загрузки', () async {
        when(() => mockDb.getWatchedEpisodes(testCollectionId, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        when(() => mockDb.getEpisodesByShowAndSeason(testShowId, 1))
            .thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return <TvEpisode>[testEpisode1];
        });

        final ProviderContainer container = createContainer();
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        // Ждём выполнения microtask
        await Future<void>.delayed(Duration.zero);

        final Future<void> loadFuture = notifier.loadSeason(1);

        // Проверяем состояние во время загрузки
        await Future<void>.delayed(const Duration(milliseconds: 10));
        EpisodeTrackerState state =
            container.read(episodeTrackerNotifierProvider(testArg));
        expect(state.loadingSeasons[1], true);

        await loadFuture;

        // Проверяем состояние после загрузки
        state = container.read(episodeTrackerNotifierProvider(testArg));
        expect(state.loadingSeasons[1], false);
      });
    });

    group('toggleEpisode', () {
      test('должен отмечать эпизод как просмотренный', () async {
        when(() => mockDb.getWatchedEpisodes(testCollectionId, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        when(() =>
                mockDb.markEpisodeWatched(testCollectionId, testShowId, 1, 1))
            .thenAnswer((_) async {});

        final ProviderContainer container = createContainer();
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        // Ждём выполнения microtask
        await Future<void>.delayed(Duration.zero);

        await notifier.toggleEpisode(1, 1);

        final EpisodeTrackerState state =
            container.read(episodeTrackerNotifierProvider(testArg));

        expect(state.isEpisodeWatched(1, 1), true);
        verify(() =>
                mockDb.markEpisodeWatched(testCollectionId, testShowId, 1, 1))
            .called(1);
      });

      test('должен снимать отметку просмотра с эпизода', () async {
        final Map<(int, int), DateTime?> watchedEpisodes = <(int, int), DateTime?>{(1, 1): null};
        when(() => mockDb.getWatchedEpisodes(testCollectionId, testShowId))
            .thenAnswer((_) async => watchedEpisodes);
        when(
          () => mockDb.markEpisodeUnwatched(testCollectionId, testShowId, 1, 1),
        ).thenAnswer((_) async {});

        final ProviderContainer container = createContainer();
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        // Ждём выполнения microtask
        await Future<void>.delayed(Duration.zero);

        await notifier.toggleEpisode(1, 1);

        final EpisodeTrackerState state =
            container.read(episodeTrackerNotifierProvider(testArg));

        expect(state.isEpisodeWatched(1, 1), false);
        verify(
          () => mockDb.markEpisodeUnwatched(testCollectionId, testShowId, 1, 1),
        ).called(1);
      });

      test('должен обновлять состояние после отметки просмотра', () async {
        when(() => mockDb.getWatchedEpisodes(testCollectionId, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        when(() =>
                mockDb.markEpisodeWatched(testCollectionId, testShowId, 1, 1))
            .thenAnswer((_) async {});
        when(() =>
                mockDb.markEpisodeWatched(testCollectionId, testShowId, 1, 2))
            .thenAnswer((_) async {});

        final ProviderContainer container = createContainer();
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        // Ждём выполнения microtask
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
        when(() => mockDb.getWatchedEpisodes(testCollectionId, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        final List<TvEpisode> cachedEpisodes = <TvEpisode>[testEpisode1];
        when(() => mockDb.getEpisodesByShowAndSeason(testShowId, 1))
            .thenAnswer((_) async => cachedEpisodes);
        final List<TvEpisode> apiEpisodes = <TvEpisode>[
          testEpisode1,
          testEpisode2,
          testEpisode3,
        ];
        when(() => mockTmdbApi.getSeasonEpisodes(testShowId, 1))
            .thenAnswer((_) async => apiEpisodes);
        when(() => mockDb.upsertEpisodes(any()))
            .thenAnswer((_) async {});

        final ProviderContainer container = createContainer();
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        await Future<void>.delayed(Duration.zero);

        // Сначала загружаем из кеша
        await notifier.loadSeason(1);
        EpisodeTrackerState state =
            container.read(episodeTrackerNotifierProvider(testArg));
        expect(state.episodesBySeason[1]?.length, 1);

        // Обновляем из API
        await notifier.refreshSeason(1);
        state = container.read(episodeTrackerNotifierProvider(testArg));
        expect(state.episodesBySeason[1]?.length, 3);
        verify(() => mockTmdbApi.getSeasonEpisodes(testShowId, 1)).called(1);
        verify(() => mockDb.upsertEpisodes(apiEpisodes)).called(1);
      });

      test('должен обновлять эпизоды даже если сезон ещё не загружен',
          () async {
        when(() => mockDb.getWatchedEpisodes(testCollectionId, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        final List<TvEpisode> apiEpisodes = <TvEpisode>[testEpisode1];
        when(() => mockTmdbApi.getSeasonEpisodes(testShowId, 1))
            .thenAnswer((_) async => apiEpisodes);
        when(() => mockDb.upsertEpisodes(any()))
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

      test('должен обрабатывать ошибку API при обновлении', () async {
        when(() => mockDb.getWatchedEpisodes(testCollectionId, testShowId))
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
        when(() => mockDb.getWatchedEpisodes(testCollectionId, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        when(() => mockTmdbApi.getSeasonEpisodes(testShowId, 1))
            .thenAnswer((_) async => <TvEpisode>[]);

        final ProviderContainer container = createContainer();
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        await Future<void>.delayed(Duration.zero);

        await notifier.refreshSeason(1);

        verifyNever(() => mockDb.upsertEpisodes(any()));
      });
    });

    group('toggleSeason', () {
      test('должен отмечать все эпизоды сезона как просмотренные', () async {
        when(() => mockDb.getWatchedEpisodes(testCollectionId, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        when(() => mockDb.getEpisodesByShowAndSeason(testShowId, 1))
            .thenAnswer(
          (_) async => <TvEpisode>[testEpisode1, testEpisode2, testEpisode3],
        );
        when(
          () => mockDb.markSeasonWatched(
            testCollectionId,
            testShowId,
            1,
            <int>[1, 2, 3],
          ),
        ).thenAnswer((_) async {});

        final ProviderContainer container = createContainer();
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        // Ждём выполнения microtask
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
          () => mockDb.markSeasonWatched(
            testCollectionId,
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
        when(() => mockDb.getWatchedEpisodes(testCollectionId, testShowId))
            .thenAnswer((_) async => watchedEpisodes);
        when(() => mockDb.getEpisodesByShowAndSeason(testShowId, 1))
            .thenAnswer(
          (_) async => <TvEpisode>[testEpisode1, testEpisode2, testEpisode3],
        );
        when(() => mockDb.unmarkSeasonWatched(testCollectionId, testShowId, 1))
            .thenAnswer((_) async {});

        final ProviderContainer container = createContainer();
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        // Ждём выполнения microtask
        await Future<void>.delayed(Duration.zero);

        await notifier.loadSeason(1);
        await notifier.toggleSeason(1);

        final EpisodeTrackerState state =
            container.read(episodeTrackerNotifierProvider(testArg));

        expect(state.isEpisodeWatched(1, 1), false);
        expect(state.isEpisodeWatched(1, 2), false);
        expect(state.isEpisodeWatched(1, 3), false);
        expect(state.watchedCountForSeason(1), 0);
        verify(() => mockDb.unmarkSeasonWatched(testCollectionId, testShowId, 1))
            .called(1);
      });

      test('должен отмечать частично просмотренный сезон как полностью просмотренный',
          () async {
        final Map<(int, int), DateTime?> watchedEpisodes = <(int, int), DateTime?>{(1, 1): null};
        when(() => mockDb.getWatchedEpisodes(testCollectionId, testShowId))
            .thenAnswer((_) async => watchedEpisodes);
        when(() => mockDb.getEpisodesByShowAndSeason(testShowId, 1))
            .thenAnswer(
          (_) async => <TvEpisode>[testEpisode1, testEpisode2, testEpisode3],
        );
        when(
          () => mockDb.markSeasonWatched(
            testCollectionId,
            testShowId,
            1,
            <int>[1, 2, 3],
          ),
        ).thenAnswer((_) async {});

        final ProviderContainer container = createContainer();
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        // Ждём выполнения microtask
        await Future<void>.delayed(Duration.zero);

        await notifier.loadSeason(1);
        await notifier.toggleSeason(1);

        final EpisodeTrackerState state =
            container.read(episodeTrackerNotifierProvider(testArg));

        expect(state.watchedCountForSeason(1), 3);
        verify(
          () => mockDb.markSeasonWatched(
            testCollectionId,
            testShowId,
            1,
            <int>[1, 2, 3],
          ),
        ).called(1);
      });

      test('не должен делать ничего если сезон не загружен', () async {
        when(() => mockDb.getWatchedEpisodes(testCollectionId, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});

        final ProviderContainer container = createContainer();
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        // Ждём выполнения microtask
        await Future<void>.delayed(Duration.zero);

        await notifier.toggleSeason(1);

        verifyNever(
          () => mockDb.markSeasonWatched(any(), any(), any(), any()),
        );
        verifyNever(() => mockDb.unmarkSeasonWatched(any(), any(), any()));
      });

      test('не должен делать ничего если сезон пустой', () async {
        when(() => mockDb.getWatchedEpisodes(testCollectionId, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        when(() => mockDb.getEpisodesByShowAndSeason(testShowId, 1))
            .thenAnswer((_) async => <TvEpisode>[]);
        when(() => mockTmdbApi.getSeasonEpisodes(testShowId, 1))
            .thenAnswer((_) async => <TvEpisode>[]);

        final ProviderContainer container = createContainer();
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        // Ждём выполнения microtask
        await Future<void>.delayed(Duration.zero);

        await notifier.loadSeason(1);
        await notifier.toggleSeason(1);

        verifyNever(
          () => mockDb.markSeasonWatched(any(), any(), any(), any()),
        );
        verifyNever(() => mockDb.unmarkSeasonWatched(any(), any(), any()));
      });
    });
  });
}
