import 'package:core/models/anime.dart';
import 'package:core/models/collection_item.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/item_status.dart';
import 'package:core/models/manga.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/anilist_api.dart';
import 'package:tonkatsu_box/core/api/mangabaka_api.dart';
import 'package:tonkatsu_box/core/api/mangadex_api.dart';
import 'package:tonkatsu_box/core/api/tmdb_api.dart';
import 'package:tonkatsu_box/core/database/database_service.dart';
import 'package:tonkatsu_box/features/home/providers/all_items_provider.dart';
import 'package:tonkatsu_box/features/recommendations/providers/recommendations_provider.dart';
import 'package:tonkatsu_box/features/settings/providers/settings_provider.dart';

import '../../../helpers/test_helpers.dart';

class _FakeAllItemsNotifier extends AllItemsNotifier {
  _FakeAllItemsNotifier(this._items);

  final List<CollectionItem> _items;

  @override
  AsyncValue<List<CollectionItem>> build() =>
      AsyncData<List<CollectionItem>>(_items);
}

class _NoKeySettingsNotifier extends SettingsNotifier {
  @override
  SettingsState build() => const SettingsState();
}

void main() {
  setUpAll(registerAllFallbacks);

  late MockAniListApi mockAniList;
  late MockMangaBakaApi mockMangaBaka;
  late MockMangaDexApi mockMangaDex;
  late MockTmdbApi mockTmdb;
  late MockDatabaseService mockDb;
  late MockMovieDao mockMovieDao;

  setUp(() {
    mockAniList = MockAniListApi();
    mockMangaBaka = MockMangaBakaApi();
    mockMangaDex = MockMangaDexApi();
    mockTmdb = MockTmdbApi();
    mockDb = MockDatabaseService();
    mockMovieDao = MockMovieDao();
    when(() => mockDb.movieDao).thenReturn(mockMovieDao);
    when(() => mockMovieDao.getTmdbGenreMap(any(), lang: any(named: 'lang')))
        .thenAnswer((_) async => <String, String>{});
  });

  ProviderContainer makeContainer(List<CollectionItem> library) {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        allItemsNotifierProvider
            .overrideWith(() => _FakeAllItemsNotifier(library)),
        settingsNotifierProvider.overrideWith(_NoKeySettingsNotifier.new),
        databaseServiceProvider.overrideWithValue(mockDb),
        aniListApiProvider.overrideWithValue(mockAniList),
        mangaBakaApiProvider.overrideWithValue(mockMangaBaka),
        mangaDexApiProvider.overrideWithValue(mockMangaDex),
        tmdbApiProvider.overrideWithValue(mockTmdb),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  CollectionItem completedAnime({
    required int id,
    List<String> genres = const <String>['Action'],
    List<String> tags = const <String>['Shounen'],
  }) =>
      createTestCollectionItem(
        id: id,
        mediaType: MediaType.anime,
        externalId: id,
        source: DataSource.anilist,
        status: ItemStatus.completed,
        userRating: 9,
        isFavorite: true,
        anime: createTestAnime(id: id, genres: genres, tags: tags),
      );

  Anime candidateAnime(int id) => createTestAnime(
        id: id,
        title: 'Candidate $id',
        genres: <String>['Action'],
        tags: <String>['Shounen'],
      );

  group('recommendationsProvider', () {
    test('should build anime rows without a TMDB key (keyless domain)',
        () async {
      when(() => mockAniList.getAnimeRecommendationsBatch(any())).thenAnswer(
        (_) async => <int, List<Anime>>{
          21: <Anime>[candidateAnime(11061), candidateAnime(20)],
        },
      );

      final ProviderContainer container = makeContainer(<CollectionItem>[
        completedAnime(id: 21),
      ]);
      final RecommendationResult result =
          await container.read(recommendationsProvider.future);

      expect(result.status, RecommendationStatus.ready);
      expect(result.rows, isNotEmpty);
      final RecommendedItem item = result.rows.first.items.first;
      expect(item.mediaType, MediaType.anime);
      expect(item.source, DataSource.anilist);
      verifyNever(() => mockTmdb.discoverMovies(
            genreId: any(named: 'genreId'),
            voteCountGte: any(named: 'voteCountGte'),
            page: any(named: 'page'),
          ));
    });

    test('should exclude anime the library already owns', () async {
      when(() => mockAniList.getAnimeRecommendationsBatch(any())).thenAnswer(
        (_) async => <int, List<Anime>>{
          21: <Anime>[candidateAnime(11061), candidateAnime(20)],
        },
      );

      final ProviderContainer container = makeContainer(<CollectionItem>[
        completedAnime(id: 21),
        // Candidate 20 is already collected (any status counts as owned).
        createTestCollectionItem(
          id: 2,
          mediaType: MediaType.anime,
          externalId: 20,
          source: DataSource.anilist,
          anime: createTestAnime(id: 20),
        ),
      ]);
      final RecommendationResult result =
          await container.read(recommendationsProvider.future);

      final Iterable<int> ids = result.rows
          .expand((RecommendationRowUi r) => r.items)
          .map((RecommendedItem i) => i.externalId);
      expect(ids, contains(11061));
      expect(ids, isNot(contains(20)));
    });

    test('should build manga rows from a MangaBaka profile', () async {
      when(() => mockMangaBaka.getRecommendations(any())).thenAnswer(
        (_) async => <Manga>[
          createTestManga(id: 7, title: 'Similar').copyWith(
            source: DataSource.mangabaka,
            genres: <String>['Action'],
            tags: <String>['Seinen'],
          ),
        ],
      );

      final ProviderContainer container = makeContainer(<CollectionItem>[
        createTestCollectionItem(
          id: 1,
          mediaType: MediaType.manga,
          externalId: 42,
          source: DataSource.mangabaka,
          status: ItemStatus.completed,
          userRating: 9,
          isFavorite: true,
          manga: createTestManga(id: 42).copyWith(
            source: DataSource.mangabaka,
            genres: <String>['Action'],
            tags: <String>['Seinen'],
          ),
        ),
      ]);
      final RecommendationResult result =
          await container.read(recommendationsProvider.future);

      expect(result.status, RecommendationStatus.ready);
      expect(result.rows.first.items.single.mediaType, MediaType.manga);
      expect(result.rows.first.items.single.source, DataSource.mangabaka);
      verifyNever(() => mockAniList.getMangaRecommendationsBatch(any()));
      verifyNever(() => mockMangaDex.getRecommendations(any()));
    });

    test('should report empty for an empty library', () async {
      final ProviderContainer container = makeContainer(<CollectionItem>[]);
      final RecommendationResult result =
          await container.read(recommendationsProvider.future);

      expect(result.status, RecommendationStatus.empty);
    });

    test(
        'should report noCandidates when a profile exists but the fetch '
        'returns nothing', () async {
      when(() => mockAniList.getAnimeRecommendationsBatch(any()))
          .thenAnswer((_) async => <int, List<Anime>>{});

      final ProviderContainer container = makeContainer(<CollectionItem>[
        completedAnime(id: 21),
      ]);
      final RecommendationResult result =
          await container.read(recommendationsProvider.future);

      expect(result.status, RecommendationStatus.noCandidates);
    });

    test(
        'should report noApiKey only when the movie/TV profile is the sole '
        'one and the key is missing', () async {
      final ProviderContainer container = makeContainer(<CollectionItem>[
        createTestCollectionItem(
          id: 1,
          mediaType: MediaType.movie,
          externalId: 603,
          status: ItemStatus.completed,
          userRating: 9,
          isFavorite: true,
          movie: createTestMovie(
            tmdbId: 603,
            genres: <String>['Action', 'Sci-Fi'],
          ),
        ),
      ]);
      final RecommendationResult result =
          await container.read(recommendationsProvider.future);

      expect(result.status, RecommendationStatus.noApiKey);
    });

    test('should survive a failing anime backend with manga rows intact',
        () async {
      when(() => mockAniList.getAnimeRecommendationsBatch(any()))
          .thenThrow(Exception('AniList down'));
      when(() => mockMangaBaka.getRecommendations(any())).thenAnswer(
        (_) async => <Manga>[
          createTestManga(id: 7, title: 'Similar').copyWith(
            source: DataSource.mangabaka,
            genres: <String>['Action'],
          ),
        ],
      );

      final ProviderContainer container = makeContainer(<CollectionItem>[
        completedAnime(id: 21),
        createTestCollectionItem(
          id: 2,
          mediaType: MediaType.manga,
          externalId: 42,
          source: DataSource.mangabaka,
          status: ItemStatus.completed,
          userRating: 9,
          isFavorite: true,
          manga: createTestManga(id: 42).copyWith(
            source: DataSource.mangabaka,
            genres: <String>['Action'],
          ),
        ),
      ]);
      final RecommendationResult result =
          await container.read(recommendationsProvider.future);

      expect(result.status, RecommendationStatus.ready);
      expect(
        result.rows.expand((RecommendationRowUi r) => r.items).single.mediaType,
        MediaType.manga,
      );
    });
  });
}
