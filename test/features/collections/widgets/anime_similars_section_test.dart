import 'package:core/models/anime.dart';
import 'package:core/models/collected_item_info.dart';
import 'package:core/models/data_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/anilist_api.dart';
import 'package:tonkatsu_box/core/api/kitsu_api.dart';
import 'package:tonkatsu_box/features/collections/providers/collections_provider.dart';
import 'package:tonkatsu_box/features/collections/widgets/anime_similars_section.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(registerAllFallbacks);

  late MockAniListApi mockAniList;
  late MockKitsuApi mockKitsu;

  setUp(() {
    mockAniList = MockAniListApi();
    mockKitsu = MockKitsuApi();
  });

  final Anime aniListSeed = createTestAnime(id: 21);
  final Anime kitsuSeed = createTestAnime(id: 12, source: DataSource.kitsu);

  Anime kitsuAnime(int id, String title) =>
      createTestAnime(id: id, source: DataSource.kitsu, title: title);

  Future<void> pumpSection(
    WidgetTester tester, {
    Anime? seed,
    Map<int, List<CollectedItemInfo>> ownedIds =
        const <int, List<CollectedItemInfo>>{},
  }) {
    return tester.pumpApp(
      SingleChildScrollView(
        child: AnimeSimilarsSection(seed: seed ?? aniListSeed),
      ),
      overrides: <Override>[
        aniListApiProvider.overrideWithValue(mockAniList),
        kitsuApiProvider.overrideWithValue(mockKitsu),
        collectedAnimeIdsProvider.overrideWith((Ref ref) async => ownedIds),
      ],
    );
  }

  group('AnimeSimilarsSection', () {
    testWidgets(
        'should render recommendations as Kitsu titles for an AniList seed',
        (WidgetTester tester) async {
      when(() => mockAniList.getAnimeRecommendations(21)).thenAnswer(
        (_) async => <Anime>[
          createTestAnime(id: 11061, title: 'HxH (AniList)'),
          createTestAnime(id: 20, title: 'Naruto (AniList)'),
        ],
      );
      when(() => mockKitsu.getAnimeByAniListIds(<int>[11061, 20])).thenAnswer(
        (_) async => <int, Anime>{
          11061: kitsuAnime(6448, 'HxH (Kitsu)'),
          20: kitsuAnime(11, 'Naruto (Kitsu)'),
        },
      );

      await pumpSection(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('HxH (Kitsu)'), findsOneWidget);
      expect(find.text('Naruto (Kitsu)'), findsOneWidget);
      expect(find.text('HxH (AniList)'), findsNothing);
      verifyNever(() => mockKitsu.getAniListAnimeId(any()));
    });

    testWidgets('should drop candidates without a Kitsu mapping',
        (WidgetTester tester) async {
      when(() => mockAniList.getAnimeRecommendations(21)).thenAnswer(
        (_) async => <Anime>[
          createTestAnime(id: 11061, title: 'Mapped'),
          createTestAnime(id: 999, title: 'Unmapped'),
        ],
      );
      when(() => mockKitsu.getAnimeByAniListIds(<int>[11061, 999])).thenAnswer(
        (_) async => <int, Anime>{11061: kitsuAnime(6448, 'Mapped (Kitsu)')},
      );

      await pumpSection(tester);

      expect(find.text('Mapped (Kitsu)'), findsOneWidget);
      expect(find.text('Unmapped'), findsNothing);
    });

    testWidgets('should bridge a Kitsu seed to its AniList id first',
        (WidgetTester tester) async {
      when(() => mockKitsu.getAniListAnimeId(12))
          .thenAnswer((_) async => 21);
      when(() => mockAniList.getAnimeRecommendations(21)).thenAnswer(
        (_) async => <Anime>[createTestAnime(id: 20, title: 'Rec')],
      );
      when(() => mockKitsu.getAnimeByAniListIds(<int>[20])).thenAnswer(
        (_) async => <int, Anime>{20: kitsuAnime(11, 'Rec (Kitsu)')},
      );

      await pumpSection(tester, seed: kitsuSeed);

      expect(find.text('Rec (Kitsu)'), findsOneWidget);
      verify(() => mockKitsu.getAniListAnimeId(12)).called(1);
    });

    testWidgets('should hide itself when a Kitsu seed has no AniList mapping',
        (WidgetTester tester) async {
      when(() => mockKitsu.getAniListAnimeId(12))
          .thenAnswer((_) async => null);

      await pumpSection(tester, seed: kitsuSeed);

      expect(find.byType(ListView), findsNothing);
      verifyNever(() => mockAniList.getAnimeRecommendations(any()));
    });

    testWidgets('should hide itself when there are no recommendations',
        (WidgetTester tester) async {
      when(() => mockAniList.getAnimeRecommendations(21))
          .thenAnswer((_) async => <Anime>[]);

      await pumpSection(tester);

      expect(find.byType(ListView), findsNothing);
      verifyNever(() => mockKitsu.getAnimeByAniListIds(any()));
    });

    testWidgets('should hide itself when the request fails',
        (WidgetTester tester) async {
      when(() => mockAniList.getAnimeRecommendations(21))
          .thenThrow(Exception('network down'));

      await pumpSection(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('should mark a Kitsu-owned similar anime as owned',
        (WidgetTester tester) async {
      when(() => mockAniList.getAnimeRecommendations(21)).thenAnswer(
        (_) async => <Anime>[
          createTestAnime(id: 11061, title: 'A'),
          createTestAnime(id: 20, title: 'B'),
        ],
      );
      when(() => mockKitsu.getAnimeByAniListIds(<int>[11061, 20])).thenAnswer(
        (_) async => <int, Anime>{
          11061: kitsuAnime(6448, 'A (Kitsu)'),
          20: kitsuAnime(11, 'B (Kitsu)'),
        },
      );

      await pumpSection(
        tester,
        ownedIds: <int, List<CollectedItemInfo>>{
          6448: <CollectedItemInfo>[
            const CollectedItemInfo(
              recordId: 1,
              collectionId: 1,
              collectionName: 'Watching',
              source: DataSource.kitsu,
            ),
          ],
        },
      );

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('should ignore an owned id whose source is not Kitsu',
        (WidgetTester tester) async {
      when(() => mockAniList.getAnimeRecommendations(21)).thenAnswer(
        (_) async => <Anime>[createTestAnime(id: 11061, title: 'A')],
      );
      when(() => mockKitsu.getAnimeByAniListIds(<int>[11061])).thenAnswer(
        (_) async => <int, Anime>{11061: kitsuAnime(6448, 'A (Kitsu)')},
      );

      await pumpSection(
        tester,
        ownedIds: <int, List<CollectedItemInfo>>{
          6448: <CollectedItemInfo>[
            const CollectedItemInfo(
              recordId: 1,
              collectionId: 1,
              collectionName: 'Watching',
              source: DataSource.anilist,
            ),
          ],
        },
      );

      expect(find.byIcon(Icons.check), findsNothing);
    });
  });
}
