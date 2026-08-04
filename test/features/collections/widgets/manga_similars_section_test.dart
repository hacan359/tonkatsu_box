// Widget tests for MangaSimilarsSection — render / empty / error / owned badge.

import 'package:core/models/collected_item_info.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/manga.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/mangabaka_api.dart';
import 'package:tonkatsu_box/core/api/mangadex_api.dart';
import 'package:tonkatsu_box/features/collections/providers/collections_provider.dart';
import 'package:tonkatsu_box/features/collections/widgets/manga_similars_section.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(registerAllFallbacks);

  late MockMangaBakaApi mockApi;
  late MockMangaDexApi mockDexApi;

  setUp(() {
    mockApi = MockMangaBakaApi();
    mockDexApi = MockMangaDexApi();
  });

  final Manga mangaBakaSeed =
      createTestManga(id: 42).copyWith(source: DataSource.mangabaka);

  Future<void> pumpSection(
    WidgetTester tester, {
    Manga? seed,
    Map<int, List<CollectedItemInfo>> ownedIds =
        const <int, List<CollectedItemInfo>>{},
  }) {
    return tester.pumpApp(
      SingleChildScrollView(
        child: MangaSimilarsSection(seed: seed ?? mangaBakaSeed),
      ),
      overrides: <Override>[
        mangaBakaApiProvider.overrideWithValue(mockApi),
        mangaDexApiProvider.overrideWithValue(mockDexApi),
        collectedMangaIdsProvider.overrideWith((Ref ref) async => ownedIds),
      ],
    );
  }

  group('MangaSimilarsSection', () {
    testWidgets('renders the similar manga returned by MangaBaka',
        (WidgetTester tester) async {
      when(() => mockApi.getRecommendations(42)).thenAnswer(
        (_) async => <Manga>[
          createTestManga(id: 1, title: 'Berserk'),
          createTestManga(id: 2, title: 'Vinland Saga'),
        ],
      );

      await pumpSection(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Berserk'), findsOneWidget);
      expect(find.text('Vinland Saga'), findsOneWidget);
    });

    testWidgets('hides itself when there are no similar manga',
        (WidgetTester tester) async {
      when(() => mockApi.getRecommendations(42))
          .thenAnswer((_) async => <Manga>[]);

      await pumpSection(tester);

      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('hides itself when the request fails',
        (WidgetTester tester) async {
      when(() => mockApi.getRecommendations(42))
          .thenThrow(Exception('network down'));

      await pumpSection(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('marks a similar manga already in a collection as owned',
        (WidgetTester tester) async {
      when(() => mockApi.getRecommendations(42)).thenAnswer(
        (_) async => <Manga>[
          createTestManga(id: 1, title: 'Berserk'),
          createTestManga(id: 2, title: 'Vinland Saga'),
        ],
      );

      await pumpSection(
        tester,
        ownedIds: <int, List<CollectedItemInfo>>{
          1: <CollectedItemInfo>[
            const CollectedItemInfo(
              recordId: 1,
              collectionId: 1,
              collectionName: 'Reading',
              source: DataSource.mangabaka,
            ),
          ],
        },
      );

      // Only the owned card shows the in-collection badge.
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('ignores an owned id from a different source',
        (WidgetTester tester) async {
      when(() => mockApi.getRecommendations(42)).thenAnswer(
        (_) async => <Manga>[createTestManga(id: 1, title: 'Berserk')],
      );

      await pumpSection(
        tester,
        ownedIds: <int, List<CollectedItemInfo>>{
          1: <CollectedItemInfo>[
            const CollectedItemInfo(
              recordId: 1,
              collectionId: 1,
              collectionName: 'Reading',
              source: DataSource.mangadex,
            ),
          ],
        },
      );

      // Same id but a MangaDex origin — must not mark the MangaBaka card owned.
      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('routes a MangaDex seed to the MangaDex API',
        (WidgetTester tester) async {
      when(() => mockDexApi.getRecommendations('the-uuid')).thenAnswer(
        (_) async => <Manga>[createTestManga(id: 7, title: 'Vagabond')],
      );

      await pumpSection(
        tester,
        seed: createTestManga(id: 99).copyWith(
          source: DataSource.mangadex,
          externalUrl: 'https://mangadex.org/title/the-uuid',
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Vagabond'), findsOneWidget);
      verify(() => mockDexApi.getRecommendations('the-uuid')).called(1);
      verifyNever(() => mockApi.getRecommendations(any()));
    });
  });
}
