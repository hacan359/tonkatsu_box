import 'dart:async';

import 'package:core/models/collection.dart';
import 'package:core/models/collection_item.dart';
import 'package:core/models/item_status.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/platform.dart' as model;
import 'package:core/models/profile.dart';
import 'package:core/models/tv_episode.dart';
import 'package:core/models/tv_season.dart';
import 'package:core/models/visual_novel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tonkatsu_box/core/database/database_service.dart';
import 'package:tonkatsu_box/data/repositories/collection_repository.dart';
import 'package:tonkatsu_box/features/collections/providers/episode_tracker_provider.dart';
import 'package:tonkatsu_box/features/collections/widgets/bulk_action_bar.dart';
import 'package:tonkatsu_box/features/collections/screens/collection_screen.dart';
import 'package:tonkatsu_box/features/home/screens/all_items_screen.dart';
import 'package:tonkatsu_box/features/settings/providers/profile_provider.dart';
import 'package:tonkatsu_box/features/settings/providers/settings_provider.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';
import 'package:tonkatsu_box/shared/navigation/search_providers.dart';
import 'package:tonkatsu_box/shared/widgets/logo_loader.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(registerAllFallbacks);

  late MockCollectionRepository mockRepo;
  late MockDatabaseService mockDb;
  late SharedPreferences prefs;

  final List<CollectionItem> testItems = <CollectionItem>[
    CollectionItem(
      id: 1,
      collectionId: 10,
      mediaType: MediaType.game,
      externalId: 100,
      platformId: 19,
      sortOrder: 0,
      status: ItemStatus.completed,
      addedAt: DateTime(2025, 1, 1),
      platform: const model.Platform(
        id: 19,
        name: 'Super Nintendo',
        abbreviation: 'SNES',
      ),
    ),
    CollectionItem(
      id: 2,
      collectionId: 10,
      mediaType: MediaType.movie,
      externalId: 200,
      sortOrder: 1,
      status: ItemStatus.inProgress,
      addedAt: DateTime(2025, 2, 1),
    ),
    CollectionItem(
      id: 3,
      collectionId: 20,
      mediaType: MediaType.tvShow,
      externalId: 300,
      sortOrder: 0,
      status: ItemStatus.notStarted,
      addedAt: DateTime(2025, 3, 1),
    ),
    CollectionItem(
      id: 4,
      collectionId: 10,
      mediaType: MediaType.game,
      externalId: 100,
      platformId: 24,
      sortOrder: 2,
      status: ItemStatus.notStarted,
      addedAt: DateTime(2025, 4, 1),
      platform: const model.Platform(
        id: 24,
        name: 'Game Boy Advance',
        abbreviation: 'GBA',
      ),
    ),
    CollectionItem(
      id: 5,
      collectionId: 20,
      mediaType: MediaType.visualNovel,
      externalId: 500,
      sortOrder: 1,
      status: ItemStatus.notStarted,
      addedAt: DateTime(2025, 5, 1),
      visualNovel: const VisualNovel(id: 'v500', title: 'Steins;Gate'),
    ),
  ];

  final List<Collection> testCollections = <Collection>[
    Collection(
      id: 10,
      name: 'My Games',
      author: 'User',
      type: CollectionType.own,
      createdAt: DateTime(2025),
    ),
    Collection(
      id: 20,
      name: 'Watch List',
      author: 'User',
      type: CollectionType.own,
      createdAt: DateTime(2025),
    ),
  ];

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'home_status_filter_test': 'all',
    });
    prefs = await SharedPreferences.getInstance();

    mockRepo = MockCollectionRepository();
    when(() => mockRepo.getAllItemsWithData(mediaType: any(named: 'mediaType')))
        .thenAnswer((_) async => testItems);
    when(() => mockRepo.getAll())
        .thenAnswer((_) async => testCollections);
    when(() => mockRepo.getStats(any()))
        .thenAnswer((_) async => CollectionStats.empty);

    mockDb = MockDatabaseService();
    when(mockDb.warmUp).thenAnswer((_) async {});
    // TV cards spin up a real episode tracker for the progress badge.
    final MockTvShowDao mockTvShowDao = MockTvShowDao();
    when(() => mockDb.tvShowDao).thenReturn(mockTvShowDao);
    when(() => mockTvShowDao.getWatchedEpisodes(any(), any(), any()))
        .thenAnswer((_) async => <(int, int), DateTime?>{});
    when(() => mockTvShowDao.getEpisodesByShowId(any(), any()))
        .thenAnswer((_) async => <TvEpisode>[]);
    when(() => mockTvShowDao.getTvShowByTmdbId(any(),
        source: any(named: 'source'))).thenAnswer((_) async => null);
    when(() => mockTvShowDao.getTvSeasonsByShowId(any(), any()))
        .thenAnswer((_) async => <TvSeason>[]);
    final MockGameDao mockGameDao = MockGameDao();
    when(() => mockDb.gameDao).thenReturn(mockGameDao);
    when(() => mockGameDao.getPlatformsByIds(any())).thenAnswer(
      (Invocation inv) async {
        final List<int> ids = inv.positionalArguments.first as List<int>;
        return <model.Platform>[
          if (ids.contains(19))
            const model.Platform(
              id: 19,
              name: 'Super Nintendo',
              abbreviation: 'SNES',
            ),
          if (ids.contains(24))
            const model.Platform(
              id: 24,
              name: 'Game Boy Advance',
              abbreviation: 'GBA',
            ),
        ];
      },
    );
  });

  Widget buildTestWidget({
    bool alwaysShowSubcategories = false,
    List<Override> extraOverrides = const <Override>[],
  }) {
    return ProviderScope(
      overrides: <Override>[
        collectionRepositoryProvider.overrideWithValue(mockRepo),
        databaseServiceProvider.overrideWithValue(mockDb),
        sharedPreferencesProvider.overrideWithValue(prefs),
        settingsNotifierProvider.overrideWith(
          () => _FakeSettingsNotifier(
            alwaysShowSubcategories: alwaysShowSubcategories,
          ),
        ),
        currentProfileProvider.overrideWithValue(Profile(
          id: 'test',
          name: 'Test',
          color: '#FF0000',
          createdAt: DateTime(2025),
        )),
        ...extraOverrides,
      ],
      child: const MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(body: AllItemsScreen()),
      ),
    );
  }

  group('AllItemsScreen', () {
    testWidgets('показывает сегменты типов медиа',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Games'), findsOneWidget);
      expect(find.text('Movies'), findsOneWidget);
      expect(find.text('TV Shows'), findsOneWidget);
      expect(find.text('Animation'), findsOneWidget);
      expect(find.text('Visual Novels'), findsOneWidget);
    });

    testWidgets('long-press выделяет элемент и передаёт его в BulkActionBar',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(BulkActionBar), findsNothing);

      await tester.ensureVisible(find.text('Steins;Gate'));
      await tester.longPress(find.text('Steins;Gate'));
      await tester.pumpAndSettle();

      // Bulk actions must receive exactly the selected item, from the
      // unfiltered list — this is what move/clone will operate on.
      final BulkActionBar bar =
          tester.widget<BulkActionBar>(find.byType(BulkActionBar));
      expect(bar.items.map((CollectionItem i) => i.id).toList(), <int>[5]);

      // A second tap toggles the item off; the bar leaves with the selection.
      await tester.tap(find.text('Steins;Gate'));
      await tester.pumpAndSettle();

      expect(find.byType(BulkActionBar), findsNothing);
    });

    testWidgets('показывает счётчики на сегментах после загрузки',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Games (2)'), findsOneWidget);
      expect(find.text('Movies (1)'), findsOneWidget);
      expect(find.text('TV Shows (1)'), findsOneWidget);
      expect(find.text('Visual Novels (1)'), findsOneWidget);
      expect(find.text('Animation'), findsOneWidget);
    });

    testWidgets(
        'заголовок группы с длинным именем не переполняется на узком экране',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      when(() => mockRepo.getAll()).thenAnswer(
        (_) async => <Collection>[
          Collection(
            id: 10,
            name: 'Очень длинное название коллекции, которое никак не влезает',
            author: 'User',
            type: CollectionType.own,
            createdAt: DateTime(2025),
          ),
          testCollections[1],
        ],
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('показывает chevron-dropdown статуса с текстом "All"',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('All'), findsOneWidget);
      expect(find.byIcon(Icons.filter_list), findsNothing);
    });

    testWidgets('dropdown статуса открывает popup и фильтрует',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);

      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      expect(find.text('My Games'), findsOneWidget);
      expect(find.textContaining('Watch List'), findsNothing);
    });

    testWidgets('выбор "All" в dropdown сбрасывает фильтр статуса',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Watch List'), findsNothing);

      // The menu stays open for multi-select, so "All" is still on screen.
      await tester.tap(find.text('All').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('Watch List'), findsOneWidget);
    });

    testWidgets('dropdown статуса набирает несколько статусов за одно открытие',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Watch List'), findsNothing);

      await tester.tap(find.text('Not Started'));
      await tester.pumpAndSettle();

      expect(find.text('My Games'), findsOneWidget);
      expect(find.textContaining('Watch List'), findsOneWidget);
    });

    testWidgets('показывает loading state при запуске',
        (WidgetTester tester) async {
      final Completer<List<CollectionItem>> completer =
          Completer<List<CollectionItem>>();
      when(() =>
              mockRepo.getAllItemsWithData(mediaType: any(named: 'mediaType')))
          .thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(LogoLoader), findsOneWidget);

      // Complete the future to avoid leaving a pending timer.
      completer.complete(testItems);
      await tester.pumpAndSettle();
    });

    testWidgets('показывает empty state когда нет элементов',
        (WidgetTester tester) async {
      when(() =>
              mockRepo.getAllItemsWithData(mediaType: any(named: 'mediaType')))
          .thenAnswer((_) async => <CollectionItem>[]);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('No items yet'), findsOneWidget);
    });

    testWidgets('показывает grid после загрузки данных',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('показывает разделители коллекций',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('My Games'), findsOneWidget);
      expect(find.text('Watch List'), findsOneWidget);
    });

    testWidgets('разделители обновляются при фильтрации',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Games (2)'));
      await tester.pumpAndSettle();

      expect(find.text('My Games'), findsOneWidget);
      expect(find.textContaining('Watch List'), findsNothing);
    });
  });

  group('AllItemsScreen фильтрация', () {
    testWidgets('нажатие на Games фильтрует по типу',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Games (2)'));
      await tester.pumpAndSettle();

      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('повторное нажатие на Games сбрасывает фильтр',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Games (2)'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Watch List'), findsNothing);

      await tester.tap(find.text('Games (2)'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Watch List'), findsOneWidget);
    });

    testWidgets('можно выбрать несколько типов одновременно',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Games (2)'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Watch List'), findsNothing);

      await tester.tap(find.text('TV Shows (1)'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Watch List'), findsOneWidget);
      expect(find.textContaining('My Games'), findsOneWidget);
    });

    testWidgets('фильтр Избранное оставляет только избранные и сбрасывается',
        (WidgetTester tester) async {
      when(() =>
              mockRepo.getAllItemsWithData(mediaType: any(named: 'mediaType')))
          .thenAnswer((_) async => <CollectionItem>[
                testItems[0].copyWith(isFavorite: true), // game, My Games
                testItems[2], // tvShow, Watch List, not favorite
              ]);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('My Games'), findsOneWidget);
      expect(find.textContaining('Watch List'), findsOneWidget);

      await tester.tap(find.text('Favorite'));
      await tester.pumpAndSettle();
      expect(find.textContaining('My Games'), findsOneWidget);
      expect(find.textContaining('Watch List'), findsNothing);

      await tester.tap(find.text('Favorite'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Watch List'), findsOneWidget);
    });
  });

  group('AllItemsScreen платформенный фильтр', () {
    testWidgets('при выборе Games показывает мини-чипы платформ',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Games (2)'));
      await tester.pumpAndSettle();

      expect(find.text('SNES'), findsOneWidget);
      expect(find.text('GBA'), findsOneWidget);
    });

    testWidgets('при выборе Movies не показывает чипы платформ',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Movies (1)'));
      await tester.pumpAndSettle();

      expect(find.text('SNES'), findsNothing);
      expect(find.text('GBA'), findsNothing);
    });

    testWidgets('отмена выбора Games убирает чипы платформ',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Games (2)'));
      await tester.pumpAndSettle();
      expect(find.text('SNES'), findsOneWidget);

      await tester.tap(find.text('Games (2)'));
      await tester.pumpAndSettle();
      expect(find.text('SNES'), findsNothing);
    });

    testWidgets('тап по мини-чипу платформы фильтрует элементы',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Games (2)'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('SNES'));
      await tester.pumpAndSettle();

      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets(
        'показывает чипы платформ без выбора Games когда настройка включена',
        (WidgetTester tester) async {
      await tester
          .pumpWidget(buildTestWidget(alwaysShowSubcategories: true));
      await tester.pumpAndSettle();

      expect(find.text('SNES'), findsOneWidget);
      expect(find.text('GBA'), findsOneWidget);
    });
  });

  group('AllItemsScreen Visual Novel фильтр', () {
    testWidgets('нажатие на Visual Novels фильтрует по типу',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // VN chip may be off-screen; scroll it into view.
      final Finder vnChip = find.text('Visual Novels (1)');
      await tester.ensureVisible(vnChip);
      await tester.pumpAndSettle();

      await tester.tap(vnChip);
      await tester.pumpAndSettle();

      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(find.textContaining('Watch List'), findsOneWidget);
      expect(find.textContaining('My Games'), findsNothing);
    });

    testWidgets('при выборе Visual Novels не показывает чипсы платформ',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final Finder vnChip = find.text('Visual Novels (1)');
      await tester.ensureVisible(vnChip);
      await tester.pumpAndSettle();

      await tester.tap(vnChip);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ChoiceChip, 'SNES'), findsNothing);
      expect(find.widgetWithText(ChoiceChip, 'GBA'), findsNothing);
    });

    group('chevron counts and visibility under search', () {
      Widget buildWithHideEmpty() => ProviderScope(
            overrides: <Override>[
              collectionRepositoryProvider.overrideWithValue(mockRepo),
              databaseServiceProvider.overrideWithValue(mockDb),
              sharedPreferencesProvider.overrideWithValue(prefs),
              settingsNotifierProvider.overrideWith(
                () => _FakeSettingsNotifier(hideEmptyMediaTypeChevrons: true),
              ),
              currentProfileProvider.overrideWithValue(Profile(
                id: 'test',
                name: 'Test',
                color: '#FF0000',
                createdAt: DateTime(2025),
              )),
            ],
            child: const MaterialApp(
              localizationsDelegates: S.localizationsDelegates,
              supportedLocales: S.supportedLocales,
              home: Scaffold(body: AllItemsScreen()),
            ),
          );

      testWidgets(
          'should keep chevrons with non-zero totals visible even when search '
          'filters them out', (WidgetTester tester) async {
        await tester.pumpWidget(buildWithHideEmpty());
        await tester.pumpAndSettle();

        // Sanity: with the flag on, only types present in data are listed.
        expect(find.text('Games (2)'), findsOneWidget);
        expect(find.text('Movies (1)'), findsOneWidget);

        final ProviderContainer container = ProviderScope.containerOf(
          tester.element(find.byType(AllItemsScreen)),
        );
        container.read(homeSearchQueryProvider.notifier).state = 'zzz_no_match';
        await tester.pumpAndSettle();

        // Counts collapse to 0 across the board, but the chevrons must stay
        // mounted because the underlying totals are still non-zero.
        expect(find.textContaining('Games'), findsOneWidget);
        expect(find.textContaining('Movies'), findsOneWidget);
      });
    });
  });

  group('AllItemsScreen прогресс трекера эпизодов', () {
    const EpisodeTrackerState trackedState = EpisodeTrackerState(
      watchedEpisodes: <(int, int), DateTime?>{(1, 1): null, (1, 2): null},
      totalEpisodes: 24,
    );

    CollectionItem makeTvItem({int? collectionId = 20}) {
      return CollectionItem(
        id: 3,
        collectionId: collectionId,
        mediaType: MediaType.tvShow,
        externalId: 300,
        sortOrder: 0,
        status: ItemStatus.notStarted,
        addedAt: DateTime(2025, 3, 1),
      );
    }

    Future<void> pumpWithTvItem(
      WidgetTester tester,
      CollectionItem item,
    ) async {
      when(() =>
              mockRepo.getAllItemsWithData(mediaType: any(named: 'mediaType')))
          .thenAnswer((_) async => <CollectionItem>[item]);
      await tester.pumpWidget(buildTestWidget(extraOverrides: <Override>[
        episodeTrackerNotifierProvider
            .overrideWith(() => _FakeEpisodeTrackerNotifier(trackedState)),
      ]));
      await tester.pumpAndSettle();
    }

    testWidgets('показывает счётчик просмотренных серий для сериала',
        (WidgetTester tester) async {
      await pumpWithTvItem(tester, makeTvItem());

      expect(find.text('2/24'), findsOneWidget);
    });

    testWidgets('не показывает счётчик для сериала без коллекции',
        (WidgetTester tester) async {
      await pumpWithTvItem(tester, makeTvItem(collectionId: null));

      expect(find.text('2/24'), findsNothing);
    });
  });
  group('AllItemsScreen collection headers', () {
    testWidgets('should open the collection when its header is tapped',
        (WidgetTester tester) async {
      when(() => mockRepo.getById(any())).thenAnswer(
        (Invocation inv) async => testCollections.firstWhere(
          (Collection c) => c.id == inv.positionalArguments[0] as int,
        ),
      );
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('My Games'));
      // CollectionScreen keeps a shimmer running, so pumpAndSettle times out.
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      final CollectionScreen screen =
          tester.widget<CollectionScreen>(find.byType(CollectionScreen));
      expect(screen.collectionId, 10);
    });

    testWidgets('should stay on the screen while a selection is active',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Steins;Gate'));
      await tester.longPress(find.text('Steins;Gate'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('My Games'));
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.byType(CollectionScreen), findsNothing);
      expect(find.byType(BulkActionBar), findsOneWidget);
    });
  });
}

class _FakeEpisodeTrackerNotifier extends EpisodeTrackerNotifier {
  _FakeEpisodeTrackerNotifier(this._state);

  final EpisodeTrackerState _state;

  @override
  EpisodeTrackerState build(EpisodeTrackerArg arg) => _state;
}

class _FakeSettingsNotifier extends SettingsNotifier {
  _FakeSettingsNotifier({
    this.hideEmptyMediaTypeChevrons = false,
    this.alwaysShowSubcategories = false,
  });

  final bool hideEmptyMediaTypeChevrons;
  final bool alwaysShowSubcategories;

  @override
  SettingsState build() => SettingsState(
        hideEmptyMediaTypeChevrons: hideEmptyMediaTypeChevrons,
        alwaysShowSubcategories: alwaysShowSubcategories,
      );

}
