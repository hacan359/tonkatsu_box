import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/data/repositories/collection_repository.dart';
import 'package:tonkatsu_box/features/collections/providers/collections_provider.dart';
import 'package:tonkatsu_box/features/collections/widgets/collection_filter_bar.dart';
import 'package:tonkatsu_box/features/settings/providers/settings_provider.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';
import 'package:tonkatsu_box/shared/models/collection_item.dart';
import 'package:tonkatsu_box/shared/models/collection_sort_mode.dart';
import 'package:tonkatsu_box/shared/models/item_status.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';
import 'package:tonkatsu_box/shared/models/collection_tag.dart';
import 'package:tonkatsu_box/shared/models/manga.dart';
import 'package:tonkatsu_box/shared/models/platform.dart' as p;
import 'package:tonkatsu_box/shared/widgets/chevron_filter_bar.dart';
import 'package:tonkatsu_box/shared/widgets/filter_subfilter_bar.dart';

class TestSettingsNotifier extends SettingsNotifier {
  TestSettingsNotifier({this.hideEmptyChevrons = false});

  final bool hideEmptyChevrons;

  @override
  SettingsState build() {
    return SettingsState(hideEmptyMediaTypeChevrons: hideEmptyChevrons);
  }
}

class TestCollectionSortNotifier extends CollectionSortNotifier {
  TestCollectionSortNotifier(this._initialMode);

  final CollectionSortMode _initialMode;

  @override
  CollectionSortMode build(int? arg) {
    return _initialMode;
  }

  @override
  Future<void> setSortMode(CollectionSortMode mode) async {
    state = mode;
  }
}

class TestCollectionSortDescNotifier extends CollectionSortDescNotifier {
  TestCollectionSortDescNotifier(this._initialValue);

  final bool _initialValue;

  @override
  bool build(int? arg) {
    return _initialValue;
  }

  @override
  Future<void> toggle() async {
    state = !state;
  }

  @override
  Future<void> setDescending({required bool descending}) async {
    state = descending;
  }
}

const int _testCollectionId = 42;

const CollectionStats _testStats = CollectionStats(
  total: 15,
  completed: 5,
  inProgress: 3,
  notStarted: 4,
  dropped: 1,
  planned: 2,
  gameCount: 8,
  movieCount: 3,
  tvShowCount: 2,
  animationCount: 1,
  visualNovelCount: 1,
);

const CollectionStats _emptyStats = CollectionStats(
  total: 0,
  completed: 0,
  inProgress: 0,
  notStarted: 0,
  dropped: 0,
  planned: 0,
);

const p.Platform _platformSnes = p.Platform(
  id: 19,
  name: 'Super Nintendo Entertainment System',
  abbreviation: 'SNES',
);

const p.Platform _platformPs1 = p.Platform(
  id: 7,
  name: 'PlayStation',
  abbreviation: 'PS1',
);

final List<CollectionItem> _gameItemsWithPlatforms = <CollectionItem>[
  CollectionItem(
    id: 1,
    collectionId: _testCollectionId,
    mediaType: MediaType.game,
    externalId: 100,
    status: ItemStatus.completed,
    addedAt: DateTime(2024),
    platformId: 19,
    platform: _platformSnes,
  ),
  CollectionItem(
    id: 2,
    collectionId: _testCollectionId,
    mediaType: MediaType.game,
    externalId: 200,
    status: ItemStatus.inProgress,
    addedAt: DateTime(2024),
    platformId: 7,
    platform: _platformPs1,
  ),
  CollectionItem(
    id: 3,
    collectionId: _testCollectionId,
    mediaType: MediaType.game,
    externalId: 300,
    status: ItemStatus.notStarted,
    addedAt: DateTime(2024),
    platformId: 19,
    platform: _platformSnes,
  ),
];

final List<CollectionItem> _movieItems = <CollectionItem>[
  CollectionItem(
    id: 10,
    collectionId: _testCollectionId,
    mediaType: MediaType.movie,
    externalId: 500,
    status: ItemStatus.completed,
    addedAt: DateTime(2024),
  ),
];

final List<CollectionItem> _mangaItemsWithFormats = <CollectionItem>[
  CollectionItem(
    id: 30,
    collectionId: _testCollectionId,
    mediaType: MediaType.manga,
    externalId: 700,
    status: ItemStatus.completed,
    addedAt: DateTime(2024),
    manga: const Manga(id: 700, title: 'Solo Leveling', format: 'MANHWA'),
  ),
  CollectionItem(
    id: 31,
    collectionId: _testCollectionId,
    mediaType: MediaType.manga,
    externalId: 701,
    status: ItemStatus.notStarted,
    addedAt: DateTime(2024),
    manga: const Manga(id: 701, title: 'Berserk', format: 'MANGA'),
  ),
];

Widget _buildTestApp({
  required Widget child,
  List<Override> overrides = const <Override>[],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

Widget _buildFilterBar({
  int? collectionId = _testCollectionId,
  AsyncValue<CollectionStats> statsAsync =
      const AsyncData<CollectionStats>(_testStats),
  AsyncValue<List<CollectionItem>> itemsAsync =
      const AsyncData<List<CollectionItem>>(<CollectionItem>[]),
  Set<MediaType> filterTypes = const <MediaType>{},
  Set<int> filterPlatformIds = const <int>{},
  Set<String> filterMangaFormats = const <String>{},
  Set<String> filterAnimeFormats = const <String>{},
  Set<int> filterTagIds = const <int>{},
  List<CollectionTag> tags = const <CollectionTag>[],
  String searchQuery = '',
  ValueChanged<MediaType?>? onTypeToggled,
  ValueChanged<int?>? onPlatformToggled,
  ValueChanged<String?>? onMangaFormatToggled,
  ValueChanged<String?>? onAnimeFormatToggled,
  ValueChanged<int?>? onTagToggled,
  ValueChanged<ItemStatus?>? onStatusChanged,
  ItemStatus? filterStatus,
}) {
  return CollectionFilterBar(
    collectionId: collectionId,
    statsAsync: statsAsync,
    itemsAsync: itemsAsync,
    filterTypes: filterTypes,
    filterPlatformIds: filterPlatformIds,
    filterMangaFormats: filterMangaFormats,
    filterAnimeFormats: filterAnimeFormats,
    filterTagIds: filterTagIds,
    filterStatus: filterStatus,
    tags: tags,
    searchQuery: searchQuery,
    onTypeToggled: onTypeToggled ?? (_) {},
    onPlatformToggled: onPlatformToggled ?? (_) {},
    onMangaFormatToggled: onMangaFormatToggled ?? (_) {},
    onAnimeFormatToggled: onAnimeFormatToggled ?? (_) {},
    onTagToggled: onTagToggled ?? (_) {},
    onStatusChanged: onStatusChanged ?? (_) {},
    onGroupToggled: () {},
  );
}

List<Override> _defaultOverrides({
  CollectionSortMode sortMode = CollectionSortMode.addedDate,
  bool isDescending = false,
}) {
  return <Override>[
    collectionSortProvider
        .overrideWith(() => TestCollectionSortNotifier(sortMode)),
    collectionSortDescProvider
        .overrideWith(() => TestCollectionSortDescNotifier(isDescending)),
    settingsNotifierProvider.overrideWith(TestSettingsNotifier.new),
  ];
}

void main() {
  group('CollectionFilterBar', () {
    group('рендеринг строки фильтров', () {
      testWidgets('должен отобразить строку фильтров', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          _buildTestApp(
            overrides: _defaultOverrides(),
            child: _buildFilterBar(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CollectionFilterBar), findsOneWidget);
      });

      testWidgets('должен отобразить chevron-сегменты типов медиа', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          _buildTestApp(
            overrides: _defaultOverrides(),
            child: _buildFilterBar(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ChevronSegment), findsWidgets);
      });
    });

    group('type chevron-сегменты', () {
      testWidgets('should call onTypeToggled с типом when tapped', (
        WidgetTester tester,
      ) async {
        MediaType? tappedType;

        await tester.pumpWidget(
          _buildTestApp(
            overrides: _defaultOverrides(),
            child: _buildFilterBar(
              onTypeToggled: (MediaType? type) {
                tappedType = type;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        final Finder gamesSegment = find.textContaining('Games');
        expect(gamesSegment, findsWidgets);
        await tester.tap(gamesSegment.first);
        await tester.pumpAndSettle();

        expect(tappedType, equals(MediaType.game));
      });
    });

    group('формат (чипы)', () {
      testWidgets(
        'shows manga format chips when manga is selected and items carry formats',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _buildTestApp(
              overrides: _defaultOverrides(),
              child: _buildFilterBar(
                filterTypes: <MediaType>{MediaType.manga},
                itemsAsync: AsyncData<List<CollectionItem>>(
                  _mangaItemsWithFormats,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.byType(FilterTabChip), findsWidgets);
          expect(find.text('Manhwa'), findsOneWidget);
        },
      );

      testWidgets(
        'hides format chips when manga is not selected',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _buildTestApp(
              overrides: _defaultOverrides(),
              child: _buildFilterBar(
                itemsAsync: AsyncData<List<CollectionItem>>(
                  _mangaItemsWithFormats,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byType(FilterTabChip), findsNothing);
        },
      );
    });

    group('платформы (чипы)', () {
      testWidgets(
        'should show платформы из игровых элементов когда активен фильтр Games',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _buildTestApp(
              overrides: _defaultOverrides(),
              child: _buildFilterBar(
                filterTypes: <MediaType>{MediaType.game},
                itemsAsync: AsyncData<List<CollectionItem>>(
                  _gameItemsWithPlatforms,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('PS1'), findsOneWidget);
          expect(find.text('SNES'), findsOneWidget);
        },
      );

      testWidgets(
        'должен дедуплицировать платформы из нескольких элементов',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _buildTestApp(
              overrides: _defaultOverrides(),
              child: _buildFilterBar(
                filterTypes: <MediaType>{MediaType.game},
                itemsAsync: AsyncData<List<CollectionItem>>(
                  _gameItemsWithPlatforms,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('SNES'), findsOneWidget);
        },
      );

      testWidgets(
        'должен игнорировать элементы с platformId == -1',
        (WidgetTester tester) async {
          final List<CollectionItem> items = <CollectionItem>[
            CollectionItem(
              id: 100,
              collectionId: _testCollectionId,
              mediaType: MediaType.game,
              externalId: 999,
              status: ItemStatus.notStarted,
              addedAt: DateTime(2024),
              platformId: -1,
              platform: const p.Platform(id: -1, name: 'Invalid'),
            ),
          ];

          await tester.pumpWidget(
            _buildTestApp(
              overrides: _defaultOverrides(),
              child: _buildFilterBar(
                filterTypes: <MediaType>{MediaType.game},
                itemsAsync: AsyncData<List<CollectionItem>>(items),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byType(FilterTabChip), findsNothing);
        },
      );

      testWidgets(
        'должен игнорировать элементы с platform == null',
        (WidgetTester tester) async {
          final List<CollectionItem> items = <CollectionItem>[
            CollectionItem(
              id: 101,
              collectionId: _testCollectionId,
              mediaType: MediaType.game,
              externalId: 888,
              status: ItemStatus.notStarted,
              addedAt: DateTime(2024),
              platformId: 19,
            ),
          ];

          await tester.pumpWidget(
            _buildTestApp(
              overrides: _defaultOverrides(),
              child: _buildFilterBar(
                filterTypes: <MediaType>{MediaType.game},
                itemsAsync: AsyncData<List<CollectionItem>>(items),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byType(FilterTabChip), findsNothing);
        },
      );

      testWidgets(
        'должен не показывать платформы для не-игровых элементов',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _buildTestApp(
              overrides: _defaultOverrides(),
              child: _buildFilterBar(
                itemsAsync: AsyncData<List<CollectionItem>>(_movieItems),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byType(FilterTabChip), findsNothing);
        },
      );

      testWidgets(
        'should call onPlatformToggled when tapped on платформу',
        (WidgetTester tester) async {
          int? tappedPlatformId;

          await tester.pumpWidget(
            _buildTestApp(
              overrides: _defaultOverrides(),
              child: _buildFilterBar(
                filterTypes: <MediaType>{MediaType.game},
                itemsAsync: AsyncData<List<CollectionItem>>(
                  _gameItemsWithPlatforms,
                ),
                onPlatformToggled: (int? id) {
                  tappedPlatformId = id;
                },
              ),
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.text('PS1'));
          await tester.pumpAndSettle();

          expect(tappedPlatformId, equals(7));
        },
      );

      testWidgets(
        'должен не показывать платформы при loading items',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _buildTestApp(
              overrides: _defaultOverrides(),
              child: _buildFilterBar(
                filterTypes: <MediaType>{MediaType.game},
                itemsAsync: const AsyncLoading<List<CollectionItem>>(),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byType(FilterTabChip), findsNothing);
        },
      );

      testWidgets(
        'должен не показывать платформы когда Games не активен',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _buildTestApp(
              overrides: _defaultOverrides(),
              child: _buildFilterBar(
                itemsAsync: AsyncData<List<CollectionItem>>(
                  _gameItemsWithPlatforms,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byType(FilterTabChip), findsNothing);
        },
      );
    });

    group('состояние пустой статистики', () {
      testWidgets(
        'должен корректно отображаться с пустой статистикой',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _buildTestApp(
              overrides: _defaultOverrides(),
              child: _buildFilterBar(
                statsAsync:
                    const AsyncData<CollectionStats>(_emptyStats),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byType(CollectionFilterBar), findsOneWidget);
        },
      );

      testWidgets(
        'должен корректно отображаться при loading статистике',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _buildTestApp(
              overrides: _defaultOverrides(),
              child: _buildFilterBar(
                statsAsync: const AsyncLoading<CollectionStats>(),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byType(CollectionFilterBar), findsOneWidget);
        },
      );
    });

    group('collectionId == null (uncategorized)', () {
      testWidgets(
        'должен корректно отображаться без collectionId',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _buildTestApp(
              overrides: _defaultOverrides(),
              child: _buildFilterBar(collectionId: null),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byType(CollectionFilterBar), findsOneWidget);
          expect(find.byType(ChevronSegment), findsWidgets);
        },
      );
    });
  });
}
