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
import 'package:xerabora/shared/widgets/chevron_filter_bar.dart';

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

        // Chevron-бар показывает сегменты для каждого типа медиа
        expect(find.byType(ChevronSegment), findsWidgets);
      });
    });

    group('type chevron-сегменты', () {
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

        // Тапаем на сегмент Games (ChevronSegment с текстом, содержащим Games)
        final Finder gamesSegment = find.textContaining('Games');
        expect(gamesSegment, findsWidgets);
        await tester.tap(gamesSegment.first);
        await tester.pumpAndSettle();

        expect(tappedType, equals(MediaType.game));
      });
    });

    group('платформы (ChoiceChip)', () {
      testWidgets(
        'должен показать платформы из игровых элементов когда активен фильтр Games',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _buildTestApp(
              overrides: _defaultOverrides(),
              child: _buildFilterBar(
                // Фильтр Games активен — платформы видны
                filterTypes: <MediaType>{MediaType.game},
                itemsAsync: AsyncData<List<CollectionItem>>(
                  _gameItemsWithPlatforms,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Платформы отображаются в виде ChoiceChip когда Games выбран
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
                filterTypes: <MediaType>{MediaType.game},
                itemsAsync: AsyncData<List<CollectionItem>>(items),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Нет платформенных чипов — Invalid платформа отфильтрована
          expect(find.byType(ChoiceChip), findsNothing);
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
                filterTypes: <MediaType>{MediaType.game},
                itemsAsync: AsyncData<List<CollectionItem>>(items),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byType(ChoiceChip), findsNothing);
        },
      );

      testWidgets(
        'должен не показывать платформы для не-игровых элементов',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _buildTestApp(
              overrides: _defaultOverrides(),
              child: _buildFilterBar(
                // Фильтр Games НЕ активен — платформы не показываются
                itemsAsync: AsyncData<List<CollectionItem>>(_movieItems),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Нет платформенных чипов для фильмов
          expect(find.byType(ChoiceChip), findsNothing);
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

          expect(find.byType(ChoiceChip), findsNothing);
        },
      );

      testWidgets(
        'должен не показывать платформы когда Games не активен',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _buildTestApp(
              overrides: _defaultOverrides(),
              child: _buildFilterBar(
                // filterTypes пустой — Games не выбран
                itemsAsync: AsyncData<List<CollectionItem>>(
                  _gameItemsWithPlatforms,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byType(ChoiceChip), findsNothing);
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
          // Chevron-бар должен рендериться
          expect(find.byType(ChevronSegment), findsWidgets);
        },
      );
    });
  });
}
