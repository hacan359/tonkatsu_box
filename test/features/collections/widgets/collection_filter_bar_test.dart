// Виджет-тесты для CollectionFilterBar.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/data/repositories/collection_repository.dart';
import 'package:xerabora/features/collections/providers/collections_provider.dart';
import 'package:xerabora/features/collections/widgets/collection_filter_bar.dart';
import 'package:xerabora/l10n/app_localizations.dart';
import 'package:xerabora/shared/models/collection_item.dart';
import 'package:xerabora/shared/models/collection_sort_mode.dart';
import 'package:xerabora/shared/models/item_status.dart';
import 'package:xerabora/shared/models/media_type.dart';
import 'package:xerabora/shared/models/collection_tag.dart';
import 'package:xerabora/shared/models/platform.dart' as p;

// ==================== Тестовые Notifier-ы ====================

/// Тестовый notifier для режима сортировки.
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

/// Тестовый notifier для направления сортировки.
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

// ==================== Тестовые данные ====================

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

const List<CollectionTag> _testTags = <CollectionTag>[
  CollectionTag(
    id: 1,
    collectionId: _testCollectionId,
    name: 'Favorites',
    color: 0xFFFF0000,
    createdAt: 1700000000,
  ),
  CollectionTag(
    id: 2,
    collectionId: _testCollectionId,
    name: 'Backlog',
    createdAt: 1700000000,
  ),
];

// ==================== Вспомогательные функции ====================

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
  Set<int> filterTagIds = const <int>{},
  List<CollectionTag> tags = const <CollectionTag>[],
  TextEditingController? searchController,
  String searchQuery = '',
  ValueChanged<MediaType?>? onTypeToggled,
  ValueChanged<int?>? onPlatformToggled,
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
    filterTagIds: filterTagIds,
    filterStatus: filterStatus,
    tags: tags,
    searchController: searchController ?? TextEditingController(),
    searchQuery: searchQuery,
    onTypeToggled: onTypeToggled ?? (_) {},
    onPlatformToggled: onPlatformToggled ?? (_) {},
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

      testWidgets('должен отобразить поле поиска', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          _buildTestApp(
            overrides: _defaultOverrides(),
            child: _buildFilterBar(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsOneWidget);
        expect(find.byIcon(Icons.search), findsOneWidget);
      });

      testWidgets('должен отобразить placeholder "Search..." в поле поиска', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          _buildTestApp(
            overrides: _defaultOverrides(),
            child: _buildFilterBar(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Search...'), findsOneWidget);
      });

      testWidgets(
        'должен отобразить кнопку очистки при непустом searchQuery',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _buildTestApp(
              overrides: _defaultOverrides(),
              child: _buildFilterBar(searchQuery: 'test'),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byIcon(Icons.close), findsOneWidget);
        },
      );

      testWidgets(
        'должен не отображать кнопку очистки при пустом searchQuery',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _buildTestApp(
              overrides: _defaultOverrides(),
              child: _buildFilterBar(searchQuery: ''),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byIcon(Icons.close), findsNothing);
        },
      );
    });

    group('type chips', () {
      testWidgets('должен показать чипы типов', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          _buildTestApp(
            overrides: _defaultOverrides(),
            child: _buildFilterBar(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ChoiceChip), findsWidgets);
      });

      testWidgets('должен вызвать onTypeToggled с типом при тапе', (
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

        final Finder gamesChip = find.textContaining('Games');
        expect(gamesChip, findsWidgets);
        await tester.tap(gamesChip.first);
        await tester.pumpAndSettle();

        expect(tappedType, equals(MediaType.game));
      });

      testWidgets('должен вызвать onTypeToggled с null при тапе на All', (
        WidgetTester tester,
      ) async {
        bool callbackCalled = false;
        MediaType? resultType = MediaType.game;

        await tester.pumpWidget(
          _buildTestApp(
            overrides: _defaultOverrides(),
            child: _buildFilterBar(
              filterTypes: <MediaType>{MediaType.game},
              onTypeToggled: (MediaType? type) {
                callbackCalled = true;
                resultType = type;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        final Finder allChip = find.textContaining('All');
        expect(allChip, findsWidgets);
        await tester.tap(allChip.first);
        await tester.pumpAndSettle();

        expect(callbackCalled, isTrue);
        expect(resultType, isNull);
      });
    });

    group('dropdown сортировки', () {
      testWidgets('должен отобразить dropdown сортировки', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          _buildTestApp(
            overrides: _defaultOverrides(
              sortMode: CollectionSortMode.addedDate,
            ),
            child: _buildFilterBar(),
          ),
        );
        await tester.pumpAndSettle();

        // Короткий лейбл для addedDate: "Date"
        expect(find.text('Date'), findsOneWidget);
      });

      testWidgets(
        'должен показать иконку arrow_upward при ascending сортировке',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _buildTestApp(
              overrides: _defaultOverrides(isDescending: false),
              child: _buildFilterBar(),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
        },
      );

      testWidgets(
        'должен показать иконку arrow_downward при descending сортировке',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _buildTestApp(
              overrides: _defaultOverrides(isDescending: true),
              child: _buildFilterBar(),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
        },
      );

      testWidgets('должен отобразить "Manual" при сортировке manual', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          _buildTestApp(
            overrides: _defaultOverrides(
              sortMode: CollectionSortMode.manual,
            ),
            child: _buildFilterBar(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Manual'), findsOneWidget);
      });
    });


    group('платформы в expand-панели', () {
      /// Раскрывает панель фильтров (desktop: тап на стрелку).
      Future<void> expandFilters(WidgetTester tester) async {
        final Finder arrow = find.byIcon(Icons.keyboard_arrow_down_rounded);
        if (arrow.evaluate().isNotEmpty) {
          await tester.tap(arrow);
          await tester.pumpAndSettle();
        }
      }

      testWidgets(
        'должен показать платформы из игровых элементов после раскрытия',
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
          await expandFilters(tester);

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
                itemsAsync: AsyncData<List<CollectionItem>>(
                  _gameItemsWithPlatforms,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await expandFilters(tester);

          // 2 элемента с SNES, 1 с PS1 — но SNES только 1 раз
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
                itemsAsync: AsyncData<List<CollectionItem>>(items),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Нет стрелки — нет платформ
          expect(
            find.byIcon(Icons.keyboard_arrow_down_rounded),
            findsNothing,
          );
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
              // platform == null
            ),
          ];

          await tester.pumpWidget(
            _buildTestApp(
              overrides: _defaultOverrides(),
              child: _buildFilterBar(
                itemsAsync: AsyncData<List<CollectionItem>>(items),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(
            find.byIcon(Icons.keyboard_arrow_down_rounded),
            findsNothing,
          );
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

          // Нет стрелки — нет платформ для фильмов
          expect(
            find.byIcon(Icons.keyboard_arrow_down_rounded),
            findsNothing,
          );
        },
      );

      testWidgets(
        'должен вызвать onPlatformToggled при тапе на платформу',
        (WidgetTester tester) async {
          int? tappedPlatformId;

          await tester.pumpWidget(
            _buildTestApp(
              overrides: _defaultOverrides(),
              child: _buildFilterBar(
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
          await expandFilters(tester);

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
                itemsAsync: const AsyncLoading<List<CollectionItem>>(),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(
            find.byIcon(Icons.keyboard_arrow_down_rounded),
            findsNothing,
          );
        },
      );
    });

    group('теги в expand-панели', () {
      testWidgets(
        'не должен показывать стрелку если нет ни платформ ни тегов',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _buildTestApp(
              overrides: _defaultOverrides(),
              child: _buildFilterBar(),
            ),
          );
          await tester.pumpAndSettle();

          expect(
            find.byIcon(Icons.keyboard_arrow_down_rounded),
            findsNothing,
          );
        },
      );
    });

    group('очистка фильтров', () {
      Future<void> expandFilters(WidgetTester tester) async {
        final Finder arrow = find.byIcon(Icons.keyboard_arrow_down_rounded);
        if (arrow.evaluate().isNotEmpty) {
          await tester.tap(arrow);
          await tester.pumpAndSettle();
        }
      }

      testWidgets(
        'кнопка Clear вызывает все три callback с null',
        (WidgetTester tester) async {
          bool typeCalled = false;
          bool platformCalled = false;
          bool tagCalled = false;

          await tester.pumpWidget(
            _buildTestApp(
              overrides: _defaultOverrides(),
              child: _buildFilterBar(
                tags: _testTags,
                filterTypes: <MediaType>{MediaType.game},
                filterTagIds: <int>{1},
                onTypeToggled: (MediaType? type) {
                  typeCalled = true;
                  expect(type, isNull);
                },
                onPlatformToggled: (int? id) {
                  platformCalled = true;
                  expect(id, isNull);
                },
                onTagToggled: (int? id) {
                  tagCalled = true;
                  expect(id, isNull);
                },
              ),
            ),
          );
          await tester.pumpAndSettle();
          await expandFilters(tester);

          await tester.tap(find.text('Clear'));
          await tester.pumpAndSettle();

          expect(typeCalled, isTrue);
          expect(platformCalled, isTrue);
          expect(tagCalled, isTrue);
        },
      );

      testWidgets(
        'кнопка Clear не отображается без активных фильтров',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _buildTestApp(
              overrides: _defaultOverrides(),
              child: _buildFilterBar(tags: _testTags),
            ),
          );
          await tester.pumpAndSettle();
          await expandFilters(tester);

          expect(find.text('Clear'), findsNothing);
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
          // Type chip "All" + status dropdown "All"
          expect(find.text('All'), findsNWidgets(2));
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
          expect(find.byType(TextField), findsOneWidget);
        },
      );
    });

  });
}
