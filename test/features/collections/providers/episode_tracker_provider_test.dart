// Тесты провайдера EpisodeTrackerNotifier.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/core/api/tmdb_api.dart';
import 'package:xerabora/core/database/database_service.dart';
import 'package:xerabora/features/collections/providers/collections_provider.dart';
import 'package:xerabora/features/collections/providers/episode_tracker_provider.dart';
import 'package:xerabora/shared/models/collection_item.dart';
import 'package:xerabora/shared/models/item_status.dart';
import 'package:xerabora/shared/models/media_type.dart';
import 'package:xerabora/shared/models/tv_episode.dart';
import 'package:xerabora/shared/models/tv_show.dart';

// Моки
class MockDatabaseService extends Mock implements DatabaseService {}

class MockTmdbApi extends Mock implements TmdbApi {}

class MockCollectionItemsNotifier extends CollectionItemsNotifier {
  @override
  AsyncValue<List<CollectionItem>> build(int? arg) {
    return const AsyncValue<List<CollectionItem>>.data(<CollectionItem>[]);
  }
}

/// Mock CollectionItemsNotifier, который хранит заданный список items
/// и записывает вызовы updateStatus для проверки.
class TrackingCollectionItemsNotifier extends CollectionItemsNotifier {
  TrackingCollectionItemsNotifier(this._items);

  final List<CollectionItem> _items;

  /// Записанные вызовы updateStatus: (id, status, mediaType).
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
    // Зеркалим реальную логику CollectionItemsNotifier.updateStatus
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
    // Дефолтный мок getTvShow — возвращает null (не нашёл на TMDB)
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

    group('_updateAutoStatus (через toggleEpisode)', () {
      late TrackingCollectionItemsNotifier lastTracking;

      /// Создаёт контейнер с TrackingCollectionItemsNotifier.
      ProviderContainer createTrackingContainer(
          List<CollectionItem> items) {
        final ProviderContainer container = ProviderContainer(
          overrides: <Override>[
            databaseServiceProvider.overrideWithValue(mockDb),
            tmdbApiProvider.overrideWithValue(mockTmdbApi),
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
      }) {
        return CollectionItem(
          id: id,
          collectionId: testCollectionId,
          mediaType: mediaType,
          externalId: testShowId,
          status: status,
          addedAt: DateTime(2024),
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
        when(() => mockDb.getWatchedEpisodes(testCollectionId, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        when(() =>
                mockDb.markEpisodeWatched(testCollectionId, testShowId, 1, 1))
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
        when(() => mockDb.getWatchedEpisodes(testCollectionId, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        when(() =>
                mockDb.markEpisodeWatched(testCollectionId, testShowId, 1, 1))
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

      test('должен перевести в completed когда все эпизоды просмотрены',
          () async {
        final CollectionItem item =
            createTvItem(totalEpisodes: 2, status: ItemStatus.notStarted);
        // Уже просмотрен 1 эпизод (s1e1)
        when(() => mockDb.getWatchedEpisodes(testCollectionId, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{
                  (1, 1): DateTime(2024),
                });
        when(() =>
                mockDb.markEpisodeWatched(testCollectionId, testShowId, 1, 2))
            .thenAnswer((_) async {});

        final ProviderContainer container =
            createTrackingContainer(<CollectionItem>[item]);
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        await Future<void>.delayed(Duration.zero);
        // Отмечаем второй — теперь 2/2
        await notifier.toggleEpisode(1, 2);
        await Future<void>.delayed(Duration.zero);

        // Сразу completed (все эпизоды просмотрены)
        expect(lastTracking.updateStatusCalls, hasLength(1));
        expect(lastTracking.updateStatusCalls[0].$2, ItemStatus.completed);
      });

      test('НЕ должен делать auto-complete если totalEpisodes == 0',
          () async {
        final CollectionItem item =
            createTvItem(totalEpisodes: 0, status: ItemStatus.notStarted);
        when(() => mockDb.getWatchedEpisodes(testCollectionId, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        when(() =>
                mockDb.markEpisodeWatched(testCollectionId, testShowId, 1, 1))
            .thenAnswer((_) async {});

        final ProviderContainer container =
            createTrackingContainer(<CollectionItem>[item]);
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        await Future<void>.delayed(Duration.zero);
        await notifier.toggleEpisode(1, 1);
        await Future<void>.delayed(Duration.zero);

        // Только inProgress (notStarted → inProgress), без completed
        expect(lastTracking.updateStatusCalls, hasLength(1));
        expect(lastTracking.updateStatusCalls.first.$2, ItemStatus.inProgress);
      });

      test(
          'должен делать auto-complete через fallback если totalEpisodes == 0 но все сезоны загружены',
          () async {
        // totalEpisodes=0 (TMDB не вернул), но totalSeasons=1,
        // и сезон 1 загружен (3 эпизода)
        final CollectionItem item = createTvItem(
          totalEpisodes: 0,
          totalSeasons: 1,
          status: ItemStatus.notStarted,
        );
        when(() => mockDb.getWatchedEpisodes(testCollectionId, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        when(() => mockDb.getEpisodesByShowAndSeason(testShowId, 1))
            .thenAnswer((_) async =>
                <TvEpisode>[testEpisode1, testEpisode2, testEpisode3]);
        when(() => mockDb.markSeasonWatched(
              testCollectionId,
              testShowId,
              1,
              <int>[1, 2, 3],
            )).thenAnswer((_) async {});

        final ProviderContainer container =
            createTrackingContainer(<CollectionItem>[item]);
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        await Future<void>.delayed(Duration.zero);

        // Загружаем сезон и помечаем все эпизоды
        await notifier.loadSeason(1);
        await notifier.toggleSeason(1);
        await Future<void>.delayed(Duration.zero);

        // Сразу completed через fallback (3 загруженных == 3 просмотренных)
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

      test('должен сбрасывать в notStarted при снятии всех отметок',
          () async {
        final CollectionItem item =
            createTvItem(status: ItemStatus.inProgress);
        // 1 эпизод просмотрен
        when(() => mockDb.getWatchedEpisodes(testCollectionId, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{
                  (1, 1): DateTime(2024),
                });
        when(() => mockDb.markEpisodeUnwatched(
                testCollectionId, testShowId, 1, 1))
            .thenAnswer((_) async {});

        final ProviderContainer container =
            createTrackingContainer(<CollectionItem>[item]);
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        await Future<void>.delayed(Duration.zero);
        // Снимаем единственный просмотренный
        await notifier.toggleEpisode(1, 1);
        await Future<void>.delayed(Duration.zero);

        expect(lastTracking.updateStatusCalls, hasLength(1));
        expect(lastTracking.updateStatusCalls.first.$2, ItemStatus.notStarted);
      });

      test('должен перевести completed → inProgress при частичном снятии',
          () async {
        final CollectionItem item =
            createTvItem(totalEpisodes: 3, status: ItemStatus.completed);
        // 3 эпизода просмотрено
        when(() => mockDb.getWatchedEpisodes(testCollectionId, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{
                  (1, 1): DateTime(2024),
                  (1, 2): DateTime(2024),
                  (1, 3): DateTime(2024),
                });
        when(() => mockDb.markEpisodeUnwatched(
                testCollectionId, testShowId, 1, 3))
            .thenAnswer((_) async {});

        final ProviderContainer container =
            createTrackingContainer(<CollectionItem>[item]);
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        await Future<void>.delayed(Duration.zero);
        // Снимаем один из трёх
        await notifier.toggleEpisode(1, 3);
        await Future<void>.delayed(Duration.zero);

        expect(lastTracking.updateStatusCalls, hasLength(1));
        expect(lastTracking.updateStatusCalls.first.$2, ItemStatus.inProgress);
      });

      test('должен находить item по MediaType.animation', () async {
        final CollectionItem item = createTvItem(
          mediaType: MediaType.animation,
        );
        when(() => mockDb.getWatchedEpisodes(testCollectionId, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        when(() =>
                mockDb.markEpisodeWatched(testCollectionId, testShowId, 1, 1))
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
        // 1 эпизод уже просмотрен
        when(() => mockDb.getWatchedEpisodes(testCollectionId, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{
                  (1, 1): DateTime(2024),
                });
        when(() =>
                mockDb.markEpisodeWatched(testCollectionId, testShowId, 1, 2))
            .thenAnswer((_) async {});

        final ProviderContainer container =
            createTrackingContainer(<CollectionItem>[item]);
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        await Future<void>.delayed(Duration.zero);
        await notifier.toggleEpisode(1, 2);
        await Future<void>.delayed(Duration.zero);

        // Dropped не должен автоматически меняться
        expect(lastTracking.updateStatusCalls, isEmpty);
      });

      test('не должен менять статус если collectionId == null', () async {
        when(() => mockDb.getWatchedEpisodes(any(), testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});

        const ({int? collectionId, int showId}) uncatArg = (
          collectionId: null,
          showId: testShowId,
        );
        final ProviderContainer container =
            createTrackingContainer(<CollectionItem>[]);
        // Инициализируем провайдер с null collectionId
        container.read(episodeTrackerNotifierProvider(uncatArg));

        await Future<void>.delayed(Duration.zero);

        // toggleEpisode не вызывается (collectionId == null → return в build)
        // Нотификатор возвращает пустое состояние
        expect(lastTracking.updateStatusCalls, isEmpty);
      });

      test(
          'должен заполнять completedAt при пометке всех эпизодов всех сезонов через toggleSeason',
          () async {
        // Сезон 1: 3 эпизода, сезон 2: 2 эпизода = 5 итого
        final CollectionItem item =
            createTvItem(totalEpisodes: 5, status: ItemStatus.notStarted);

        when(() => mockDb.getWatchedEpisodes(testCollectionId, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});

        // Загрузка сезонов из кеша БД
        when(() => mockDb.getEpisodesByShowAndSeason(testShowId, 1))
            .thenAnswer((_) async =>
                <TvEpisode>[testEpisode1, testEpisode2, testEpisode3]);
        when(() => mockDb.getEpisodesByShowAndSeason(testShowId, 2))
            .thenAnswer(
                (_) async => <TvEpisode>[testEpisode2s1, testEpisode2s2]);

        // Моки для markSeasonWatched
        when(() => mockDb.markSeasonWatched(
              testCollectionId,
              testShowId,
              1,
              <int>[1, 2, 3],
            )).thenAnswer((_) async {});
        when(() => mockDb.markSeasonWatched(
              testCollectionId,
              testShowId,
              2,
              <int>[1, 2],
            )).thenAnswer((_) async {});

        final ProviderContainer container =
            createTrackingContainer(<CollectionItem>[item]);
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        await Future<void>.delayed(Duration.zero);

        // Загружаем оба сезона
        await notifier.loadSeason(1);
        await notifier.loadSeason(2);

        // Отмечаем все эпизоды сезона 1
        await notifier.toggleSeason(1);
        await Future<void>.delayed(Duration.zero);

        // После сезона 1: 3/5 — должен стать inProgress
        expect(lastTracking.updateStatusCalls, hasLength(1));
        expect(lastTracking.updateStatusCalls[0].$2, ItemStatus.inProgress);

        // Отмечаем все эпизоды сезона 2
        await notifier.toggleSeason(2);
        await Future<void>.delayed(Duration.zero);

        // После сезона 2: 5/5 — должен стать completed
        expect(lastTracking.updateStatusCalls, hasLength(2));
        expect(lastTracking.updateStatusCalls[1].$2, ItemStatus.completed);

        // Проверяем, что completedAt заполнен в state
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
        // 1 сезон, 3 эпизода
        final CollectionItem item =
            createTvItem(totalEpisodes: 3, status: ItemStatus.notStarted);

        when(() => mockDb.getWatchedEpisodes(testCollectionId, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        when(() => mockDb.getEpisodesByShowAndSeason(testShowId, 1))
            .thenAnswer((_) async =>
                <TvEpisode>[testEpisode1, testEpisode2, testEpisode3]);
        when(() => mockDb.markSeasonWatched(
              testCollectionId,
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

        // Сразу completed (3/3 — все просмотрены)
        expect(lastTracking.updateStatusCalls, hasLength(1));
        expect(lastTracking.updateStatusCalls[0].$2, ItemStatus.completed);

        // completedAt и startedAt заполнены
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
        when(() => mockDb.getWatchedEpisodes(testCollectionId, testShowId))
            .thenAnswer((_) async => <(int, int), DateTime?>{});
        when(() =>
                mockDb.markEpisodeWatched(testCollectionId, testShowId, 1, 1))
            .thenAnswer((_) async {});

        // Создаём контейнер с обычным mock (возвращает пустой список)
        final ProviderContainer container = createContainer();
        final EpisodeTrackerNotifier notifier =
            container.read(episodeTrackerNotifierProvider(testArg).notifier);

        await Future<void>.delayed(Duration.zero);
        // toggleEpisode — item не будет найден (пустой список)
        await notifier.toggleEpisode(1, 1);
        await Future<void>.delayed(Duration.zero);

        // Не упал — просто ничего не сделал
      });
    });
  });
}
