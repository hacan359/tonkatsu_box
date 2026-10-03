import 'package:core/models/data_source.dart';
import 'package:core/models/game.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/movie.dart';
import 'package:core/models/tv_show.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/tmdb_api.dart';
import 'package:tonkatsu_box/core/import/title_lookup/lookup_candidate.dart';
import 'package:tonkatsu_box/core/import/title_lookup/lookup_chains.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late MockTmdbApi tmdb;
  late MockTvdbApi tvdb;
  late MockTvMazeApi tvmaze;
  late MockIgdbApi igdb;
  late MockKitsuApi kitsu;
  late MockAniListApi anilist;
  late MockMangaDexApi mangadex;
  late MockMangaBakaApi mangabaka;
  late MockVndbApi vndb;
  late MockOpenLibraryApi openLibrary;
  late MockGoogleBooksApi googleBooks;
  late MockHardcoverApi hardcover;
  late MockFantlabApi fantlab;

  LookupChains chains({
    LookupKeys keys = const LookupKeys(
      tmdb: true,
      tvdb: true,
      igdb: true,
      hardcover: true,
    ),
  }) =>
      LookupChains(
        keys: keys,
        tmdb: tmdb,
        tvdb: tvdb,
        tvmaze: tvmaze,
        igdb: igdb,
        kitsu: kitsu,
        anilist: anilist,
        mangadex: mangadex,
        mangabaka: mangabaka,
        vndb: vndb,
        openLibrary: openLibrary,
        googleBooks: googleBooks,
        hardcover: hardcover,
        fantlab: fantlab,
      );

  List<DataSource> sourcesOf(MediaType type, [String title = 'Dune']) =>
      chains().chainFor(type, title).map((LookupSource s) => s.source).toList();

  setUp(() {
    tmdb = MockTmdbApi();
    tvdb = MockTvdbApi();
    tvmaze = MockTvMazeApi();
    igdb = MockIgdbApi();
    kitsu = MockKitsuApi();
    anilist = MockAniListApi();
    mangadex = MockMangaDexApi();
    mangabaka = MockMangaBakaApi();
    vndb = MockVndbApi();
    openLibrary = MockOpenLibraryApi();
    googleBooks = MockGoogleBooksApi();
    hardcover = MockHardcoverApi();
    fantlab = MockFantlabApi();
  });

  group('LookupChains', () {
    group('chainFor', () {
      test('movie: TMDB then TheTVDB', () {
        expect(
          sourcesOf(MediaType.movie),
          <DataSource>[DataSource.tmdb, DataSource.tvdb],
        );
      });

      test('a source without its key is skipped', () {
        final LookupChains noTvdb = chains(
          keys: const LookupKeys(
            tmdb: true,
            tvdb: false,
            igdb: true,
            hardcover: false,
          ),
        );
        expect(
          noTvdb
              .chainFor(MediaType.movie, 'Dune')
              .map((LookupSource s) => s.source),
          <DataSource>[DataSource.tmdb],
        );
        final LookupChains none = chains(
          keys: const LookupKeys(
            tmdb: false,
            tvdb: false,
            igdb: false,
            hardcover: false,
          ),
        );
        expect(none.chainFor(MediaType.movie, 'Dune'), isEmpty);
        expect(none.chainFor(MediaType.game, 'Dune'), isEmpty);
        expect(
          none
              .chainFor(MediaType.book, 'Dune')
              .map((LookupSource s) => s.source),
          <DataSource>[DataSource.openLibrary, DataSource.googleBooks],
        );
      });

      test('tv show: TMDB, TVmaze, TheTVDB', () {
        expect(
          sourcesOf(MediaType.tvShow),
          <DataSource>[DataSource.tmdb, DataSource.tvmaze, DataSource.tvdb],
        );
      });

      test('animation: TMDB only', () {
        expect(sourcesOf(MediaType.animation), <DataSource>[DataSource.tmdb]);
      });

      test('game: IGDB only', () {
        expect(sourcesOf(MediaType.game), <DataSource>[DataSource.igdb]);
      });

      test('anime: Kitsu before AniList', () {
        expect(
          sourcesOf(MediaType.anime),
          <DataSource>[DataSource.kitsu, DataSource.anilist],
        );
      });

      test('manga: AniList, MangaDex, MangaBaka, Kitsu', () {
        expect(
          sourcesOf(MediaType.manga),
          <DataSource>[
            DataSource.anilist,
            DataSource.mangadex,
            DataSource.mangabaka,
            DataSource.kitsu,
          ],
        );
      });

      test('visual novel: VNDB only', () {
        expect(
          sourcesOf(MediaType.visualNovel),
          <DataSource>[DataSource.vndb],
        );
      });

      test('book: OpenLibrary, Google Books, Hardcover', () {
        expect(
          sourcesOf(MediaType.book),
          <DataSource>[
            DataSource.openLibrary,
            DataSource.googleBooks,
            DataSource.hardcover,
          ],
        );
      });

      test('book with a Cyrillic title asks Fantlab first', () {
        expect(
          sourcesOf(MediaType.book, 'Пикник на обочине'),
          <DataSource>[
            DataSource.fantlab,
            DataSource.openLibrary,
            DataSource.googleBooks,
            DataSource.hardcover,
          ],
        );
      });

      test('audio and custom have no chain', () {
        expect(sourcesOf(MediaType.audio), isEmpty);
        expect(sourcesOf(MediaType.custom), isEmpty);
      });
    });

    group('TMDB', () {
      test('movie keeps the file type even for an animated hit', () async {
        when(() => tmdb.searchMovies('Dune', year: 2021)).thenAnswer(
          (_) async => <Movie>[
            createTestMovie(
              tmdbId: 1,
              title: 'Dune',
              releaseYear: 2021,
              genres: <String>['Animation'],
            ),
          ],
        );

        final List<LookupCandidate> hits = await chains()
            .chainFor(MediaType.movie, 'Dune')
            .first
            .search(const TitleQuery(title: 'Dune', year: 2021));

        expect(hits.single.mediaType, MediaType.movie);
        expect(hits.single.platformId, isNull);
        expect(hits.single.externalId, 1);
        expect(hits.single.source, DataSource.tmdb);
        expect(hits.single.year, 2021);
      });

      test('animation searches both endpoints and keeps animated hits only',
          () async {
        when(() => tmdb.searchMovies('Spirited Away', year: null)).thenAnswer(
          (_) async => <Movie>[
            createTestMovie(
              tmdbId: 1,
              title: 'Spirited Away',
              genres: <String>['Animation'],
            ),
            createTestMovie(tmdbId: 2, title: 'Spirited Away (live)'),
          ],
        );
        when(() => tmdb.searchTvShows('Spirited Away', firstAirDateYear: null))
            .thenAnswer(
          (_) async => <TvShow>[
            createTestTvShow(
              tmdbId: 3,
              title: 'Spirited Away',
              genres: <String>['Animation'],
            ),
          ],
        );

        final List<LookupCandidate> hits = await chains()
            .chainFor(MediaType.animation, 'Spirited Away')
            .single
            .search(const TitleQuery(title: 'Spirited Away'));

        expect(hits.length, 2);
        expect(
          hits.map((LookupCandidate c) => c.mediaType).toSet(),
          <MediaType>{MediaType.animation},
        );
        expect(hits[0].externalId, 1);
        expect(hits[0].platformId, AnimationSource.movie);
        expect(hits[1].externalId, 3);
        expect(hits[1].platformId, AnimationSource.tvShow);
      });

      test('should surface an animation 429 as a rate limit', () async {
        when(() => tmdb.searchMovies('Akira', year: null))
            .thenThrow(const TmdbApiException('x', statusCode: 429));
        when(() => tmdb.searchTvShows('Akira', firstAirDateYear: null))
            .thenAnswer((_) async => <TvShow>[]);
        final LookupSource source =
            chains().chainFor(MediaType.animation, 'Akira').single;

        bool rateLimited = false;
        try {
          await source.search(const TitleQuery(title: 'Akira'));
        } on Object catch (e) {
          rateLimited = source.isRateLimit(e);
        }

        expect(rateLimited, isTrue);
      });

      test('429 counts as a rate limit, 500 does not', () {
        final LookupSource source =
            chains().chainFor(MediaType.movie, 'Dune').first;
        expect(
          source.isRateLimit(const TmdbApiException('x', statusCode: 429)),
          isTrue,
        );
        expect(
          source.isRateLimit(const TmdbApiException('x', statusCode: 500)),
          isFalse,
        );
        expect(source.isRateLimit(StateError('x')), isFalse);
      });
    });

    group('IGDB', () {
      test('passes the platform filter through and exposes platform ids',
          () async {
        when(
          () => igdb.searchGames(query: 'Chrono Trigger', platformIds: <int>[19]),
        ).thenAnswer(
          (_) async => <Game>[
            createTestGame(
              id: 7,
              name: 'Chrono Trigger',
              platformIds: <int>[19, 8],
              releaseDate: DateTime(1995, 3, 11),
            ),
          ],
        );

        final List<LookupCandidate> hits = await chains()
            .chainFor(MediaType.game, 'Chrono Trigger')
            .single
            .search(const TitleQuery(title: 'Chrono Trigger', platformId: 19));

        expect(hits.single.externalId, 7);
        expect(hits.single.platformIds, <int>[19, 8]);
        expect(hits.single.year, 1995);
        expect(hits.single.source, DataSource.igdb);
      });

      test('no platform in the file means no platform filter', () async {
        when(() => igdb.searchGames(query: 'Doom', platformIds: null))
            .thenAnswer((_) async => <Game>[]);

        await chains()
            .chainFor(MediaType.game, 'Doom')
            .single
            .search(const TitleQuery(title: 'Doom'));

        verify(() => igdb.searchGames(query: 'Doom', platformIds: null))
            .called(1);
      });
    });
  });
}
