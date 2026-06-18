import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/anilist_api.dart';
import 'package:tonkatsu_box/core/import/sources/anilist/anilist_import_service.dart';
import 'package:tonkatsu_box/core/services/import_service.dart';
import 'package:tonkatsu_box/shared/models/anime.dart';
import 'package:tonkatsu_box/shared/models/collection_item.dart';
import 'package:tonkatsu_box/shared/models/item_status.dart';
import 'package:tonkatsu_box/shared/models/manga.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';
import 'package:tonkatsu_box/shared/models/universal_import_result.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  late AniListImportService sut;
  late MockAniListApi mockAniList;
  late MockDatabaseService mockDb;
  late MockAnimeDao mockAnimeDao;
  late MockMangaDao mockMangaDao;
  late MockCollectionRepository mockRepo;
  late MockWishlistRepository mockWishlist;

  setUpAll(() {
    registerAllFallbacks();
    registerFallbackValue(<Map<String, dynamic>>[]);
    registerFallbackValue(<(int, Map<String, dynamic>)>[]);
  });

  setUp(() {
    mockAniList = MockAniListApi();
    mockDb = MockDatabaseService();
    mockAnimeDao = MockAnimeDao();
    mockMangaDao = MockMangaDao();
    when(() => mockDb.animeDao).thenReturn(mockAnimeDao);
    when(() => mockDb.mangaDao).thenReturn(mockMangaDao);
    mockRepo = MockCollectionRepository();
    mockWishlist = MockWishlistRepository();

    sut = AniListImportService(
      aniListApi: mockAniList,
      database: mockDb,
      repository: mockRepo,
      wishlistRepository: mockWishlist,
    );

    when(() => mockAnimeDao.upsertAnimes(any())).thenAnswer((_) async {});
    when(() => mockMangaDao.upsertMangas(any())).thenAnswer((_) async {});
    when(() => mockRepo.create(
          name: any(named: 'name'),
          author: any(named: 'author'),
        )).thenAnswer((_) async => createTestCollection(id: 42));
    when(() => mockRepo.getById(any()))
        .thenAnswer((_) async => createTestCollection(id: 1));
    when(() => mockRepo.getItems(any()))
        .thenAnswer((_) async => <CollectionItem>[]);
    when(() => mockRepo.addItemsBatch(any(), any())).thenAnswer(
        (Invocation inv) async =>
            (inv.positionalArguments[1] as List<dynamic>).length);
    when(() => mockRepo.updateItemFieldsBatch(any())).thenAnswer((_) async {});
  });

  void stubAnime(List<AniListListEntry> entries) {
    when(() => mockAniList.fetchUserMediaList(
          userName: any(named: 'userName'),
          type: MediaType.anime,
        )).thenAnswer((_) async => entries);
  }

  void stubManga(List<AniListListEntry> entries) {
    when(() => mockAniList.fetchUserMediaList(
          userName: any(named: 'userName'),
          type: MediaType.manga,
        )).thenAnswer((_) async => entries);
  }

  AniListListEntry animeEntry({
    int mediaId = 100922,
    String rawStatus = 'COMPLETED',
    int progress = 12,
    int repeat = 0,
    int? scoreRaw100 = 85,
    String? notes,
    int? episodes = 12,
  }) {
    return AniListListEntry(
      mediaId: mediaId,
      mediaType: MediaType.anime,
      rawStatus: rawStatus,
      progress: progress,
      progressVolumes: 0,
      repeat: repeat,
      scoreRaw100: scoreRaw100,
      notes: notes,
      anime: Anime(id: mediaId, title: 'Grand Blue', episodes: episodes),
    );
  }

  AniListListEntry mangaEntry({
    int mediaId = 30013,
    String rawStatus = 'CURRENT',
    int progress = 50,
    int progressVolumes = 5,
  }) {
    return AniListListEntry(
      mediaId: mediaId,
      mediaType: MediaType.manga,
      rawStatus: rawStatus,
      progress: progress,
      progressVolumes: progressVolumes,
      repeat: 0,
      manga: Manga(id: mediaId, title: 'Berserk'),
    );
  }

  AniListImportOptions opts({
    ImportMode mode = ImportMode.newOnly,
    bool includeAnime = true,
    bool includeManga = true,
    int? collectionId = 1,
  }) =>
      AniListImportOptions(
        userName: 'u',
        mode: mode,
        author: 'me',
        newCollectionName: 'AniList',
        includeAnime: includeAnime,
        includeManga: includeManga,
        collectionId: collectionId,
      );

  List<Map<String, dynamic>> capturedItemRows() =>
      verify(() => mockRepo.addItemsBatch(any(), captureAny())).captured.single
          as List<Map<String, dynamic>>;

  List<(int, Map<String, dynamic>)> capturedUpdates() =>
      verify(() => mockRepo.updateItemFieldsBatch(captureAny())).captured.single
          as List<(int, Map<String, dynamic>)>;

  group('AniListImportService.import', () {
    test('should throw ArgumentError when nothing is selected', () async {
      expect(
        () => sut.import(opts(includeAnime: false, includeManga: false)),
        throwsArgumentError,
      );
    });

    test('should throw FormatException when both lists are empty', () async {
      stubAnime(<AniListListEntry>[]);
      stubManga(<AniListListEntry>[]);

      expect(
        () => sut.import(opts()),
        throwsA(isA<FormatException>()),
      );
    });

    test('should fetch only the requested types', () async {
      stubAnime(<AniListListEntry>[animeEntry()]);

      await sut.import(opts(includeManga: false));

      verify(() => mockAniList.fetchUserMediaList(
            userName: 'u',
            type: MediaType.anime,
          )).called(1);
      verifyNever(() => mockAniList.fetchUserMediaList(
            userName: any(named: 'userName'),
            type: MediaType.manga,
          ));
    });

    test('should create the collection and tally imports per type', () async {
      stubAnime(<AniListListEntry>[animeEntry()]);
      stubManga(<AniListListEntry>[mangaEntry()]);

      final UniversalImportResult result =
          await sut.import(opts(collectionId: null));

      verify(() => mockRepo.create(
            name: any(named: 'name'),
            author: any(named: 'author'),
          )).called(1);
      expect(result.success, isTrue);
      expect(result.effectiveCollectionId, 42);
      expect(result.importedByType[MediaType.anime], 1);
      expect(result.importedByType[MediaType.manga], 1);
    });

    test('should skip existing items in newOnly mode', () async {
      stubAnime(<AniListListEntry>[animeEntry()]);
      stubManga(<AniListListEntry>[]);
      when(() => mockRepo.getItems(any())).thenAnswer((_) async =>
          <CollectionItem>[
            createTestCollectionItem(
              id: 7,
              mediaType: MediaType.anime,
              externalId: 100922,
            ),
          ]);

      final UniversalImportResult result =
          await sut.import(opts(mode: ImportMode.newOnly));

      expect(result.importedByType[MediaType.anime] ?? 0, 0);
      expect(result.totalUpdated, 0);
      expect(capturedItemRows(), isEmpty);
    });

    test('should update existing items in overwrite mode', () async {
      stubAnime(<AniListListEntry>[animeEntry(scoreRaw100: 90, progress: 12)]);
      stubManga(<AniListListEntry>[]);
      when(() => mockRepo.getItems(any())).thenAnswer((_) async =>
          <CollectionItem>[
            createTestCollectionItem(
              id: 7,
              mediaType: MediaType.anime,
              externalId: 100922,
              status: ItemStatus.inProgress,
              userRating: 7,
              currentEpisode: 5,
            ),
          ]);

      final UniversalImportResult result =
          await sut.import(opts(mode: ImportMode.overwrite));

      expect(result.updatedByType[MediaType.anime], 1);
      expect(result.importedByType[MediaType.anime] ?? 0, 0);
      final (int, Map<String, dynamic>) update = capturedUpdates().single;
      expect(update.$1, 7);
      expect(update.$2['user_rating'], 9.0);
    });

    test('should top up episodes when status is COMPLETED', () async {
      stubAnime(<AniListListEntry>[animeEntry(progress: 8, episodes: 12)]);
      stubManga(<AniListListEntry>[]);

      await sut.import(opts());

      final Map<String, dynamic> row = capturedItemRows().single;
      expect(row['current_episode'], 12);
      expect(row.containsKey('current_season'), isFalse);
    });

    test('should map score 0 to no rating, 100 to 10, 47 to 4.7', () async {
      stubAnime(<AniListListEntry>[
        animeEntry(mediaId: 1, scoreRaw100: 0),
        animeEntry(mediaId: 2, scoreRaw100: 100),
        animeEntry(mediaId: 3, scoreRaw100: 47),
      ]);
      stubManga(<AniListListEntry>[]);

      await sut.import(opts());

      final List<Map<String, dynamic>> rows = capturedItemRows();
      Map<String, dynamic> rowFor(int id) =>
          rows.firstWhere((Map<String, dynamic> r) => r['external_id'] == id);
      expect(rowFor(1).containsKey('user_rating'), isFalse);
      expect(rowFor(2)['user_rating'], 10.0);
      expect(rowFor(3)['user_rating'], 4.7);
    });

    test('should map AniList status values to ItemStatus', () async {
      const Map<String, ItemStatus> mapping = <String, ItemStatus>{
        'CURRENT': ItemStatus.inProgress,
        'REPEATING': ItemStatus.inProgress,
        'COMPLETED': ItemStatus.completed,
        'PLANNING': ItemStatus.planned,
        'DROPPED': ItemStatus.dropped,
        'PAUSED': ItemStatus.dropped,
      };

      for (final MapEntry<String, ItemStatus> e in mapping.entries) {
        clearInteractions(mockRepo);
        stubAnime(<AniListListEntry>[animeEntry(rawStatus: e.key)]);
        stubManga(<AniListListEntry>[]);

        await sut.import(opts());

        expect(capturedItemRows().single['status'], e.value.value);
      }
    });

    test('should include the AniList URL, repeat count and notes in the comment',
        () async {
      stubAnime(<AniListListEntry>[animeEntry(repeat: 3, notes: 'great show')]);
      stubManga(<AniListListEntry>[]);

      await sut.import(opts());

      final String comment = capturedItemRows().single['user_comment'] as String;
      expect(comment, contains('https://anilist.co/anime/100922'));
      expect(comment, contains('Rewatched times: 3'));
      expect(comment, contains('great show'));
    });

    test('should top up manga chapters and volumes when COMPLETED', () async {
      stubAnime(<AniListListEntry>[]);
      stubManga(<AniListListEntry>[
        const AniListListEntry(
          mediaId: 30013,
          mediaType: MediaType.manga,
          rawStatus: 'COMPLETED',
          progress: 100,
          progressVolumes: 8,
          repeat: 0,
          manga: Manga(id: 30013, title: 'x', chapters: 150, volumes: 10),
        ),
      ]);

      await sut.import(opts());

      final Map<String, dynamic> row = capturedItemRows().single;
      expect(row['current_episode'], 150);
      expect(row['current_season'], 10);
    });

    test('should report progress ending in the completed stage', () async {
      stubAnime(<AniListListEntry>[animeEntry()]);
      stubManga(<AniListListEntry>[]);
      final List<ImportProgress> updates = <ImportProgress>[];

      await sut.import(opts(), onProgress: updates.add);

      expect(updates.last.stage, ImportStage.completed);
    });
  });
}
