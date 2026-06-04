import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/anilist_api.dart';
import 'package:tonkatsu_box/core/services/anilist_import_service.dart';
import 'package:tonkatsu_box/shared/models/anime.dart';
import 'package:tonkatsu_box/shared/models/item_status.dart';
import 'package:tonkatsu_box/shared/models/manga.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';

import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(registerAllFallbacks);

  late AniListImportService sut;
  late MockAniListApi mockAniList;
  late MockDatabaseService mockDb;
  late MockAnimeDao mockAnimeDao;
  late MockMangaDao mockMangaDao;

  setUp(() {
    mockAniList = MockAniListApi();
    mockDb = MockDatabaseService();
    mockAnimeDao = MockAnimeDao();
    mockMangaDao = MockMangaDao();
    when(() => mockDb.animeDao).thenReturn(mockAnimeDao);
    when(() => mockDb.mangaDao).thenReturn(mockMangaDao);
    sut = AniListImportService(aniListApi: mockAniList, database: mockDb);

    when(() => mockAnimeDao.upsertAnimes(any())).thenAnswer((_) async {});
    when(() => mockMangaDao.upsertMangas(any())).thenAnswer((_) async {});
    when(() => mockDb.findCollectionItem(
      collectionId: any(named: 'collectionId'),
      mediaType: any(named: 'mediaType'),
      externalId: any(named: 'externalId'),
    )).thenAnswer((_) async => null);
    when(() => mockDb.addItemToCollection(
      collectionId: any(named: 'collectionId'),
      mediaType: any(named: 'mediaType'),
      externalId: any(named: 'externalId'),
      status: any(named: 'status'),
    )).thenAnswer((_) async => 999);
    when(() => mockDb.updateItemProgress(
      any(),
      currentEpisode: any(named: 'currentEpisode'),
      currentSeason: any(named: 'currentSeason'),
    )).thenAnswer((_) async {});
    when(() => mockDb.updateItemUserRating(any(), any()))
        .thenAnswer((_) async {});
    when(() => mockDb.updateItemActivityDates(
      any(),
      startedAt: any(named: 'startedAt'),
      completedAt: any(named: 'completedAt'),
      lastActivityAt: any(named: 'lastActivityAt'),
    )).thenAnswer((_) async {});
    when(() => mockDb.updateItemUserComment(any(), any()))
        .thenAnswer((_) async {});
    when(() => mockDb.updateItemStatus(
      any(),
      any(),
      mediaType: any(named: 'mediaType'),
    )).thenAnswer((_) async {});
  });

  AniListListEntry animeEntry({
    int mediaId = 100922,
    String rawStatus = 'COMPLETED',
    int progress = 12,
    int repeat = 0,
    int? scoreRaw100 = 85,
    String? notes,
    DateTime? startedAt,
    DateTime? completedAt,
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
      startedAt: startedAt,
      completedAt: completedAt,
      anime: Anime(id: mediaId, title: 'Grand Blue', episodes: episodes),
    );
  }

  AniListListEntry mangaEntry({
    int mediaId = 30013,
    String rawStatus = 'CURRENT',
    int progress = 50,
    int progressVolumes = 5,
    int? chapters,
    int? volumes,
  }) {
    return AniListListEntry(
      mediaId: mediaId,
      mediaType: MediaType.manga,
      rawStatus: rawStatus,
      progress: progress,
      progressVolumes: progressVolumes,
      repeat: 0,
      manga: Manga(
        id: mediaId,
        title: 'Berserk',
        chapters: chapters,
        volumes: volumes,
      ),
    );
  }

  group('AniListImportService', () {
    group('importUserLists', () {
      test('should throw ArgumentError when nothing to import', () async {
        expect(
              () => sut.importUserLists(
            userName: 'u',
            mode: ImportMode.newOnly,
            includeAnime: false,
            includeManga: false,
            collectionId: 1,
            onProgress: (_) {},
          ),
          throwsArgumentError,
        );
      });

      test('should throw ArgumentError without collection target', () async {
        expect(
              () => sut.importUserLists(
            userName: 'u',
            mode: ImportMode.newOnly,
            onProgress: (_) {},
          ),
          throwsArgumentError,
        );
      });

      test('should throw FormatException when both lists are empty', () async {
        when(() => mockAniList.fetchUserMediaList(
          userName: any(named: 'userName'),
          type: any(named: 'type'),
        )).thenAnswer((_) async => <AniListListEntry>[]);

        expect(
              () => sut.importUserLists(
            userName: 'u',
            mode: ImportMode.newOnly,
            collectionId: 1,
            onProgress: (_) {},
          ),
          throwsA(isA<FormatException>()),
        );
      });

      test('should fetch only requested types', () async {
        when(() => mockAniList.fetchUserMediaList(
          userName: any(named: 'userName'),
          type: MediaType.anime,
        )).thenAnswer((_) async => <AniListListEntry>[animeEntry()]);

        await sut.importUserLists(
          userName: 'u',
          mode: ImportMode.newOnly,
          includeAnime: true,
          includeManga: false,
          collectionId: 1,
          onProgress: (_) {},
        );

        verify(() => mockAniList.fetchUserMediaList(
          userName: 'u',
          type: MediaType.anime,
        )).called(1);
        verifyNever(() => mockAniList.fetchUserMediaList(
          userName: any(named: 'userName'),
          type: MediaType.manga,
        ));
      });

      test('should create collection lazily and import counts per type',
              () async {
            when(() => mockAniList.fetchUserMediaList(
              userName: any(named: 'userName'),
              type: MediaType.anime,
            )).thenAnswer((_) async => <AniListListEntry>[animeEntry()]);
            when(() => mockAniList.fetchUserMediaList(
              userName: any(named: 'userName'),
              type: MediaType.manga,
            )).thenAnswer((_) async => <AniListListEntry>[mangaEntry()]);

            int factoryCalls = 0;
            final AniListImportResult result = await sut.importUserLists(
              userName: 'tester',
              mode: ImportMode.newOnly,
              createCollection: () async {
                factoryCalls++;
                return 42;
              },
              onProgress: (_) {},
            );

            expect(factoryCalls, 1);
            expect(result.collectionId, 42);
            expect(result.animeImported, 1);
            expect(result.mangaImported, 1);
            expect(result.total, 2);
            expect(result.updated, 0);
          });

      test('should skip existing items in newOnly mode', () async {
        when(() => mockAniList.fetchUserMediaList(
          userName: any(named: 'userName'),
          type: MediaType.anime,
        )).thenAnswer((_) async => <AniListListEntry>[animeEntry()]);
        when(() => mockAniList.fetchUserMediaList(
          userName: any(named: 'userName'),
          type: MediaType.manga,
        )).thenAnswer((_) async => <AniListListEntry>[]);
        when(() => mockDb.findCollectionItem(
          collectionId: any(named: 'collectionId'),
          mediaType: MediaType.anime,
          externalId: 100922,
        )).thenAnswer((_) async => createTestCollectionItem(
          id: 7,
          collectionId: 1,
          mediaType: MediaType.anime,
          externalId: 100922,
        ));

        final AniListImportResult result = await sut.importUserLists(
          userName: 'u',
          mode: ImportMode.newOnly,
          collectionId: 1,
          onProgress: (_) {},
        );

        expect(result.animeImported, 0);
        expect(result.animeUpdated, 0);
        verifyNever(() => mockDb.addItemToCollection(
          collectionId: any(named: 'collectionId'),
          mediaType: any(named: 'mediaType'),
          externalId: any(named: 'externalId'),
          status: any(named: 'status'),
        ));
      });

      test('should update existing items in overwrite mode', () async {
        when(() => mockAniList.fetchUserMediaList(
          userName: any(named: 'userName'),
          type: MediaType.anime,
        )).thenAnswer((_) async => <AniListListEntry>[
          animeEntry(scoreRaw100: 90, progress: 12),
        ]);
        when(() => mockAniList.fetchUserMediaList(
          userName: any(named: 'userName'),
          type: MediaType.manga,
        )).thenAnswer((_) async => <AniListListEntry>[]);
        when(() => mockDb.findCollectionItem(
          collectionId: any(named: 'collectionId'),
          mediaType: MediaType.anime,
          externalId: 100922,
        )).thenAnswer((_) async => createTestCollectionItem(
          id: 7,
          collectionId: 1,
          mediaType: MediaType.anime,
          externalId: 100922,
          status: ItemStatus.inProgress,
          userRating: 7,
          currentEpisode: 5,
        ));

        final AniListImportResult result = await sut.importUserLists(
          userName: 'u',
          mode: ImportMode.overwrite,
          collectionId: 1,
          onProgress: (_) {},
        );

        expect(result.animeUpdated, 1);
        expect(result.animeImported, 0);
        verify(() => mockDb.updateItemUserRating(7, 9)).called(1);
      });

      test('should top up episodes when status is COMPLETED', () async {
        when(() => mockAniList.fetchUserMediaList(
          userName: any(named: 'userName'),
          type: MediaType.anime,
        )).thenAnswer((_) async => <AniListListEntry>[
          animeEntry(progress: 8, episodes: 12),
        ]);
        when(() => mockAniList.fetchUserMediaList(
          userName: any(named: 'userName'),
          type: MediaType.manga,
        )).thenAnswer((_) async => <AniListListEntry>[]);

        await sut.importUserLists(
          userName: 'u',
          mode: ImportMode.newOnly,
          collectionId: 1,
          onProgress: (_) {},
        );

        verify(() => mockDb.updateItemProgress(
          999,
          currentEpisode: 12,
          currentSeason: null,
        )).called(1);
      });

      test('should map score 0 to null and 100 to 10', () async {
        when(() => mockAniList.fetchUserMediaList(
          userName: any(named: 'userName'),
          type: MediaType.anime,
        )).thenAnswer((_) async => <AniListListEntry>[
          animeEntry(mediaId: 1, scoreRaw100: 0),
          animeEntry(mediaId: 2, scoreRaw100: 100),
          animeEntry(mediaId: 3, scoreRaw100: 47),
        ]);
        when(() => mockAniList.fetchUserMediaList(
          userName: any(named: 'userName'),
          type: MediaType.manga,
        )).thenAnswer((_) async => <AniListListEntry>[]);

        await sut.importUserLists(
          userName: 'u',
          mode: ImportMode.newOnly,
          collectionId: 1,
          onProgress: (_) {},
        );

        // Score 0 → no rating call at all.
        // Score 100 → 10.0. Score 47 → 4.7 (POINT_100 / 10.0).
        verify(() => mockDb.updateItemUserRating(999, 10.0)).called(1);
        verify(() => mockDb.updateItemUserRating(999, 4.7)).called(1);
        verifyNever(() => mockDb.updateItemUserRating(999, 0));
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
          clearInteractions(mockDb);
          when(() => mockAniList.fetchUserMediaList(
            userName: any(named: 'userName'),
            type: MediaType.anime,
          )).thenAnswer((_) async => <AniListListEntry>[
            animeEntry(rawStatus: e.key),
          ]);
          when(() => mockAniList.fetchUserMediaList(
            userName: any(named: 'userName'),
            type: MediaType.manga,
          )).thenAnswer((_) async => <AniListListEntry>[]);

          await sut.importUserLists(
            userName: 'u',
            mode: ImportMode.newOnly,
            collectionId: 1,
            onProgress: (_) {},
          );

          verify(() => mockDb.addItemToCollection(
            collectionId: 1,
            mediaType: MediaType.anime,
            externalId: 100922,
            status: e.value,
          )).called(1);
        }
      });

      test(
          'should include AniList URL and repeat count in user comment',
              () async {
            when(() => mockAniList.fetchUserMediaList(
              userName: any(named: 'userName'),
              type: MediaType.anime,
            )).thenAnswer((_) async => <AniListListEntry>[
              animeEntry(repeat: 3, notes: 'great show'),
            ]);
            when(() => mockAniList.fetchUserMediaList(
              userName: any(named: 'userName'),
              type: MediaType.manga,
            )).thenAnswer((_) async => <AniListListEntry>[]);

            final List<String?> captured = <String?>[];
            when(() => mockDb.updateItemUserComment(any(), captureAny()))
                .thenAnswer((Invocation invocation) async {
              captured.add(invocation.positionalArguments[1] as String?);
            });

            await sut.importUserLists(
              userName: 'u',
              mode: ImportMode.newOnly,
              collectionId: 1,
              onProgress: (_) {},
            );

            expect(captured, hasLength(1));
            final String comment = captured.first!;
            expect(comment, contains('https://anilist.co/anime/100922'));
            expect(comment, contains('Rewatched times: 3'));
            expect(comment, contains('great show'));
          });

      test(
          'should reuse animeEntry totals for manga when COMPLETED tops up chapters and volumes',
              () async {
            when(() => mockAniList.fetchUserMediaList(
              userName: any(named: 'userName'),
              type: MediaType.anime,
            )).thenAnswer((_) async => <AniListListEntry>[]);
            when(() => mockAniList.fetchUserMediaList(
              userName: any(named: 'userName'),
              type: MediaType.manga,
            )).thenAnswer((_) async => <AniListListEntry>[
              const AniListListEntry(
                mediaId: 30013,
                mediaType: MediaType.manga,
                rawStatus: 'COMPLETED',
                progress: 100,
                progressVolumes: 8,
                repeat: 0,
                manga: Manga(
                  id: 30013,
                  title: 'x',
                  chapters: 150,
                  volumes: 10,
                ),
              ),
            ]);

            await sut.importUserLists(
              userName: 'u',
              mode: ImportMode.newOnly,
              collectionId: 1,
              onProgress: (_) {},
            );

            verify(() => mockDb.updateItemProgress(
              999,
              currentEpisode: 150,
              currentSeason: 10,
            )).called(1);
          });
    });
  });
}
