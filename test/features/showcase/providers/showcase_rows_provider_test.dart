import 'package:core/models/tv_show.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/tmdb_api.dart';
import 'package:tonkatsu_box/features/search/providers/genre_provider.dart';
import 'package:tonkatsu_box/features/settings/providers/settings_provider.dart';
import 'package:tonkatsu_box/features/showcase/models/showcase_item.dart';
import 'package:tonkatsu_box/features/showcase/providers/showcase_clock_provider.dart';
import 'package:tonkatsu_box/features/showcase/providers/showcase_rows_provider.dart';

import '../../../helpers/test_helpers.dart';

class _FakeSettingsNotifier extends SettingsNotifier {
  @override
  SettingsState build() => const SettingsState();
}

void main() {
  late MockTmdbApi tmdb;
  final DateTime now = DateTime(2026, 9, 11, 12);

  setUpAll(registerAllFallbacks);

  setUp(() {
    tmdb = MockTmdbApi();
    when(() => tmdb.hasApiKey).thenReturn(true);
  });

  ProviderContainer createContainer() {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        tmdbApiProvider.overrideWithValue(tmdb),
        settingsNotifierProvider.overrideWith(_FakeSettingsNotifier.new),
        tvGenreMapProvider
            .overrideWith((Ref ref) async => const <String, String>{}),
        showcaseClockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  void answerDiscover(List<TvShow> shows) {
    when(() => tmdb.discoverTvShows(
          airDateGte: any(named: 'airDateGte'),
          airDateLte: any(named: 'airDateLte'),
          withoutGenreIds: any(named: 'withoutGenreIds'),
          voteCountGte: any(named: 'voteCountGte'),
        )).thenAnswer((_) async => shows);
  }

  group('tvEpisodesThisWeekProvider', () {
    test('should ask for a week of episodes without the noise genres',
        () async {
      answerDiscover(const <TvShow>[]);

      await createContainer().read(tvEpisodesThisWeekProvider.future);

      final VerificationResult call = verify(() => tmdb.discoverTvShows(
            airDateGte: captureAny(named: 'airDateGte'),
            airDateLte: captureAny(named: 'airDateLte'),
            withoutGenreIds: captureAny(named: 'withoutGenreIds'),
            voteCountGte: any(named: 'voteCountGte'),
          ));
      call.called(1);
      expect(call.captured[0], '2026-09-11');
      expect(call.captured[1], '2026-09-18');
      // Animation is excluded on purpose: anime has its own AniList rows.
      expect(call.captured[2], contains(16));
    });

    test('should attach the next episode of every show', () async {
      answerDiscover(<TvShow>[
        createTestTvShow(tmdbId: 1, title: 'Reacher'),
        createTestTvShow(tmdbId: 2, title: 'Ted Lasso'),
      ]);
      when(() => tmdb.getNextEpisodeToAir(1)).thenAnswer(
        (_) async => (season: 4, episode: 8, airDate: '2026-09-16'),
      );
      when(() => tmdb.getNextEpisodeToAir(2)).thenAnswer((_) async => null);

      final List<ShowcaseItem> items =
          await createContainer().read(tvEpisodesThisWeekProvider.future);

      expect(items, hasLength(2));
      expect(items[0].nextSeason, 4);
      expect(items[0].nextEpisode, 8);
      expect(items[0].nextDate, DateTime(2026, 9, 16));
      expect(items[1].nextDate, isNull);
    });

    test('should keep the row when one details call fails', () async {
      answerDiscover(<TvShow>[
        createTestTvShow(tmdbId: 1, title: 'Reacher'),
        createTestTvShow(tmdbId: 2, title: 'Ted Lasso'),
      ]);
      when(() => tmdb.getNextEpisodeToAir(1))
          .thenThrow(const TmdbApiException('boom'));
      when(() => tmdb.getNextEpisodeToAir(2)).thenAnswer(
        (_) async => (season: 4, episode: 7, airDate: '2026-09-15'),
      );

      final List<ShowcaseItem> items =
          await createContainer().read(tvEpisodesThisWeekProvider.future);

      expect(items, hasLength(2));
      expect(items[0].nextEpisode, isNull);
      expect(items[1].nextEpisode, 7);
    });

    test('should cap the row and ask for details only that many times',
        () async {
      answerDiscover(<TvShow>[
        for (int i = 1; i <= tvEpisodesRowLimit + 5; i++)
          createTestTvShow(tmdbId: i, title: 'Show $i'),
      ]);
      when(() => tmdb.getNextEpisodeToAir(any())).thenAnswer((_) async => null);

      final List<ShowcaseItem> items =
          await createContainer().read(tvEpisodesThisWeekProvider.future);

      expect(items, hasLength(tvEpisodesRowLimit));
      verify(() => tmdb.getNextEpisodeToAir(any()))
          .called(tvEpisodesRowLimit);
    });

    test('should skip TMDB entirely without an API key', () async {
      when(() => tmdb.hasApiKey).thenReturn(false);

      final List<ShowcaseItem> items =
          await createContainer().read(tvEpisodesThisWeekProvider.future);

      expect(items, isEmpty);
      verifyNever(() => tmdb.discoverTvShows());
    });
  });
}
