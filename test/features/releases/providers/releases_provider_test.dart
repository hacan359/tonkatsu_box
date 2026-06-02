import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/tmdb_api.dart';
import 'package:tonkatsu_box/core/database/database_service.dart';
import 'package:tonkatsu_box/features/releases/models/release_event.dart';
import 'package:tonkatsu_box/features/releases/providers/releases_provider.dart';
import 'package:tonkatsu_box/shared/models/data_source.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';
import 'package:tonkatsu_box/shared/models/tracked_release.dart';
import 'package:tonkatsu_box/shared/models/tv_episode.dart';
import 'package:tonkatsu_box/shared/models/tv_season.dart';

import '../../../helpers/test_helpers.dart';

class _FakeReleasesNotifier extends ReleasesNotifier {
  _FakeReleasesNotifier(this._data);

  final ReleasesCalendarData _data;

  @override
  Future<ReleasesCalendarData> build() async => _data;
}

ReleaseEvent _eventOn(DateTime date) => ReleaseEvent(
      externalId: 1,
      mediaType: MediaType.tvShow,
      showTitle: 'S',
      season: 1,
      episode: 1,
      airDate: date,
      watched: false,
      isUpcoming: true,
    );

void main() {
  setUpAll(() {
    registerAllFallbacks();
    registerFallbackValue(<TvSeason>[]);
    registerFallbackValue(<TvEpisode>[]);
  });

  late MockDatabaseService mockDb;
  late MockTrackedReleaseDao trackedDao;
  late MockTvShowDao tvDao;
  late MockCollectionDao collDao;

  TrackedRelease tracked(int id, DataSource source, MediaType type) =>
      TrackedRelease(
        externalId: id,
        source: source,
        mediaType: type,
        createdAt: DateTime(2024),
      );

  TvEpisode episode(int show, int s, int e, String? air) => TvEpisode(
        tmdbShowId: show,
        seasonNumber: s,
        episodeNumber: e,
        name: 'E$e',
        airDate: air,
      );

  // Comfortably in the future so the "upcoming only" filter keeps these.
  const String future = '2999-01-01';
  const String past = '2000-01-01';

  setUp(() {
    mockDb = MockDatabaseService();
    trackedDao = MockTrackedReleaseDao();
    tvDao = MockTvShowDao();
    collDao = MockCollectionDao();
    when(() => mockDb.trackedReleaseDao).thenReturn(trackedDao);
    when(() => mockDb.tvShowDao).thenReturn(tvDao);
    when(() => mockDb.collectionDao).thenReturn(collDao);

    // By default every tracked show still lives in a collection.
    when(() => collDao.findCollectionItem(
          collectionId: any(named: 'collectionId'),
          mediaType: any(named: 'mediaType'),
          externalId: any(named: 'externalId'),
        )).thenAnswer((_) async => createTestCollectionItem());
    when(() => tvDao.getTvShowByTmdbId(any())).thenAnswer((_) async => null);
    when(() => tvDao.getEpisodesByShowId(any()))
        .thenAnswer((_) async => <TvEpisode>[]);
  });

  ProviderContainer makeContainer() {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        databaseServiceProvider.overrideWithValue(mockDb),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('ReleasesNotifier', () {
    test('should return empty data when nothing is tracked', () async {
      when(() => trackedDao.getAll())
          .thenAnswer((_) async => <TrackedRelease>[]);

      final ReleasesCalendarData data =
          await makeContainer().read(releasesProvider.future);

      expect(data.trackedCount, 0);
      expect(data.events, isEmpty);
    });

    test('should keep only TMDB TV and anime subscriptions', () async {
      when(() => trackedDao.getAll()).thenAnswer((_) async => <TrackedRelease>[
            tracked(1, DataSource.tmdb, MediaType.tvShow),
            tracked(2, DataSource.anilist, MediaType.manga),
            tracked(3, DataSource.tmdb, MediaType.movie),
          ]);
      when(() => tvDao.getEpisodesByShowId(1))
          .thenAnswer((_) async => <TvEpisode>[episode(1, 1, 1, future)]);

      final ReleasesCalendarData data =
          await makeContainer().read(releasesProvider.future);

      expect(data.trackedCount, 1);
      expect(data.events.map((ReleaseEvent e) => e.externalId), <int>[1]);
    });

    test('should list upcoming episodes only and drop past ones', () async {
      when(() => trackedDao.getAll()).thenAnswer((_) async =>
          <TrackedRelease>[tracked(1, DataSource.tmdb, MediaType.tvShow)]);
      when(() => tvDao.getEpisodesByShowId(1)).thenAnswer(
        (_) async => <TvEpisode>[
          episode(1, 1, 1, past),
          episode(1, 1, 2, future),
        ],
      );

      final ReleasesCalendarData data =
          await makeContainer().read(releasesProvider.future);

      expect(data.events.length, 1);
      final ReleaseEvent only = data.events.single;
      expect(only.episode, 2);
      expect(only.isUpcoming, isTrue);
    });

    test('should drop a show no longer in any collection', () async {
      when(() => trackedDao.getAll()).thenAnswer((_) async =>
          <TrackedRelease>[tracked(1, DataSource.tmdb, MediaType.tvShow)]);
      when(() => tvDao.getEpisodesByShowId(1))
          .thenAnswer((_) async => <TvEpisode>[episode(1, 1, 1, future)]);
      when(() => collDao.findCollectionItem(
            collectionId: any(named: 'collectionId'),
            mediaType: any(named: 'mediaType'),
            externalId: any(named: 'externalId'),
          )).thenAnswer((_) async => null);

      final ReleasesCalendarData data =
          await makeContainer().read(releasesProvider.future);

      expect(data.trackedCount, 1);
      expect(data.events, isEmpty);
    });

    test('refreshFromApi caches TMDB shows and skips other providers',
        () async {
      final MockTmdbApi api = MockTmdbApi();
      when(() => trackedDao.getAll()).thenAnswer((_) async => <TrackedRelease>[
            tracked(1, DataSource.tmdb, MediaType.tvShow),
            tracked(2, DataSource.anilist, MediaType.manga),
          ]);
      when(() => api.getTvSeasons(1)).thenAnswer(
          (_) async => <TvSeason>[const TvSeason(tmdbShowId: 1, seasonNumber: 1)]);
      when(() => api.getSeasonEpisodes(1, 1))
          .thenAnswer((_) async => <TvEpisode>[episode(1, 1, 1, future)]);
      when(() => mockDb.upsertTvSeasons(any())).thenAnswer((_) async {});
      when(() => mockDb.upsertEpisodes(any())).thenAnswer((_) async {});

      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          databaseServiceProvider.overrideWithValue(mockDb),
          tmdbApiProvider.overrideWithValue(api),
        ],
      );
      addTearDown(container.dispose);

      await container.read(releasesProvider.notifier).refreshFromApi();

      verify(() => api.getTvSeasons(1)).called(greaterThanOrEqualTo(1));
      verifyNever(() => api.getTvSeasons(2));
      verify(() => mockDb.upsertEpisodes(any())).called(greaterThanOrEqualTo(1));
    });

    test('releasesTodayCountProvider counts only today episodes', () async {
      final DateTime now = DateTime.now();
      final ReleasesCalendarData data = ReleasesCalendarData(
        trackedCount: 1,
        events: <ReleaseEvent>[
          _eventOn(now),
          _eventOn(now.add(const Duration(days: 5))),
        ],
      );
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          releasesProvider.overrideWith(() => _FakeReleasesNotifier(data)),
        ],
      );
      addTearDown(container.dispose);
      await container.read(releasesProvider.future);

      expect(container.read(releasesTodayCountProvider), 1);
    });

    test('should skip episodes without a parseable air date', () async {
      when(() => trackedDao.getAll()).thenAnswer((_) async =>
          <TrackedRelease>[tracked(1, DataSource.tmdb, MediaType.tvShow)]);
      when(() => tvDao.getEpisodesByShowId(1)).thenAnswer(
        (_) async => <TvEpisode>[
          episode(1, 1, 1, null),
          episode(1, 1, 2, future),
        ],
      );

      final ReleasesCalendarData data =
          await makeContainer().read(releasesProvider.future);

      expect(data.events.length, 1);
      expect(data.events.single.episode, 2);
    });
  });
}
