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
import 'package:xerabora/shared/models/platform.dart';

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

const Platform _platformSnes = Platform(
  id: 19,
  name: 'Super Nintendo Entertainment System',
  abbreviation: 'SNES',
);

const Platform _platformPs1 = Platform(
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
  MediaType? filterType,
  int? filterPlatformId,
  TextEditingController? searchController,
  String searchQuery = '',
  bool isGridMode = true,
  ValueChanged<MediaType?>? onFilterTypeChanged,
  ValueChanged<int?>? onPlatformFilterChanged,
  VoidCallback? onGridModeChanged,
}) {
  return CollectionFilterBar(
    collectionId: collectionId,
    statsAsync: statsAsync,
    itemsAsync: itemsAsync,
    filterType: filterType,
    filterPlatformId: filterPlatformId,
    searchController: searchController ?? TextEditingController(),
    searchQuery: searchQuery,
    isGridMode: isGridMode,
    onFilterTypeChanged: onFilterTypeChanged ?? (_) {},
    onPlatformFilterChanged: onPlatformFilterChanged ?? (_) {},
    onGridModeChanged: onGridModeChanged ?? () {},
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

    group('dropdown типа медиа', () {
      testWidgets('должен отобразить dropdown типа медиа с иконкой фильтра', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          _buildTestApp(
            overrides: _defaultOverrides(),
            child: _buildFilterBar(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.filter_list), findsOneWidget);
        expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
      });

      testWidgets('должен показать "All" когда filterType == null', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          _buildTestApp(
            overrides: _defaultOverrides(),
            child: _buildFilterBar(filterType: null),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('All'), findsOneWidget);
      });

      testWidgets(
        'должен показать название типа с количеством при выбранном фильтре',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _buildTestApp(
              overrides: _defaultOverrides(),
              child: _buildFilterBar(filterType: MediaType.game),
            ),
          );
          await tester.pumpAndSettle();

          // "Games (8)" или локализованный вариант "Game (8)"
          expect(find.textContaining('(8)'), findsOneWidget);
        },
      );

      testWidgets(
        'должен вызвать onFilterTypeChanged при выборе типа медиа',
        (WidgetTester tester) async {
          MediaType? selectedType;

          await tester.pumpWidget(
            _buildTestApp(
              overrides: _defaultOverrides(),
              child: _buildFilterBar(
                onFilterTypeChanged: (MediaType? type) {
                  selectedType = type;
                },
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Открываем popup menu dropdown типа медиа
          await tester.tap(find.byIcon(Icons.filter_list));
          await tester.pumpAndSettle();

          // Выбираем "Games" из popup menu
          // Ищем пункт меню с текстом "Games (8)"
          final Finder gamesItem = find.textContaining('Games');
          expect(gamesItem, findsWidgets);
          await tester.tap(gamesItem.last);
          await tester.pumpAndSettle();

          expect(selectedType, equals(MediaType.game));
        },
      );

      testWidgets(
        'должен вызвать onFilterTypeChanged с null при выборе "All"',
        (WidgetTester tester) async {
          bool callbackCalled = false;
          MediaType? resultType = MediaType.game;

          await tester.pumpWidget(
            _buildTestApp(
              overrides: _defaultOverrides(),
              child: _buildFilterBar(
                filterType: MediaType.game,
                onFilterTypeChanged: (MediaType? type) {
                  callbackCalled = true;
                  resultType = type;
                },
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Открываем popup menu dropdown типа медиа
          await tester.tap(find.byIcon(Icons.filter_list));
          await tester.pumpAndSettle();

          // Выбираем "All" из popup menu
          final Finder allItem = find.textContaining('All');
          expect(allItem, findsWidgets);
          await tester.tap(allItem.last);
          await tester.pumpAndSettle();

          expect(callbackCalled, isTrue);
          expect(resultType, isNull);
        },
      );
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

    group('переключатель grid/list', () {
      testWidgets(
        'должен показать иконку view_list при isGridMode == true',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _buildTestApp(
              overrides: _defaultOverrides(),
              child: _buildFilterBar(isGridMode: true),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byIcon(Icons.view_list), findsOneWidget);
        },
      );

      testWidgets(
        'должен показать иконку grid_view при isGridMode == false',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _buildTestApp(
              overrides: _defaultOverrides(),
              child: _buildFilterBar(isGridMode: false),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byIcon(Icons.grid_view), findsOneWidget);
        },
      );

      testWidgets('должен вызвать onGridModeChanged при нажатии на toggle', (
        WidgetTester tester,
      ) async {
        bool callbackCalled = false;

        await tester.pumpWidget(
          _buildTestApp(
            overrides: _defaultOverrides(),
            child: _buildFilterBar(
              isGridMode: true,
              onGridModeChanged: () {
                callbackCalled = true;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.view_list));
        await tester.pumpAndSettle();

        expect(callbackCalled, isTrue);
      });

      testWidgets(
        'должен иметь tooltip "List view" при isGridMode == true',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _buildTestApp(
              overrides: _defaultOverrides(),
              child: _buildFilterBar(isGridMode: true),
            ),
          );
          await tester.pumpAndSettle();

          final Finder iconButton = find.byWidgetPredicate(
            (Widget widget) =>
                widget is IconButton && widget.tooltip == 'List view',
          );
          expect(iconButton, findsOneWidget);
        },
      );

      testWidgets(
        'должен иметь tooltip "Grid view" при isGridMode == false',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _buildTestApp(
              overrides: _defaultOverrides(),
              child: _buildFilterBar(isGridMode: false),
            ),
          );
          await tester.pumpAndSettle();

          final Finder iconButton = find.byWidgetPredicate(
            (Widget widget) =>
                widget is IconButton && widget.tooltip == 'Grid view',
          );
          expect(iconButton, findsOneWidget);
        },
      );
    });

    group('чипсы платформ', () {
      testWidgets(
        'должен показать чипсы платформ когда filterType == MediaType.game',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _buildTestApp(
              overrides: _defaultOverrides(),
              child: _buildFilterBar(
                filterType: MediaType.game,
                itemsAsync: AsyncData<List<CollectionItem>>(
                  _gameItemsWithPlatforms,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // "All" чип + 2 платформы (PS1, SNES)
          expect(find.byType(ChoiceChip), findsNWidgets(3));
          expect(find.text('PS1'), findsOneWidget);
          expect(find.text('SNES'), findsOneWidget);
        },
      );

      testWidgets(
        'должен скрывать чипсы платформ когда filterType != game',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _buildTestApp(
              overrides: _defaultOverrides(),
              child: _buildFilterBar(
                filterType: MediaType.movie,
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

      testWidgets(
        'должен скрывать чипсы платформ когда filterType == null',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _buildTestApp(
              overrides: _defaultOverrides(),
              child: _buildFilterBar(
                filterType: null,
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

      testWidgets(
        'должен скрывать чипсы платформ когда itemsAsync is loading',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _buildTestApp(
              overrides: _defaultOverrides(),
              child: _buildFilterBar(
                filterType: MediaType.game,
                itemsAsync:
                    const AsyncLoading<List<CollectionItem>>(),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byType(ChoiceChip), findsNothing);
        },
      );

      testWidgets(
        'должен скрывать чипсы когда нет элементов с платформами',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _buildTestApp(
              overrides: _defaultOverrides(),
              child: _buildFilterBar(
                filterType: MediaType.game,
                itemsAsync: AsyncData<List<CollectionItem>>(_movieItems),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byType(ChoiceChip), findsNothing);
        },
      );

      testWidgets(
        'должен вызвать onPlatformFilterChanged при выборе чипса платформы',
        (WidgetTester tester) async {
          int? selectedPlatformId = -1;

          await tester.pumpWidget(
            _buildTestApp(
              overrides: _defaultOverrides(),
              child: _buildFilterBar(
                filterType: MediaType.game,
                itemsAsync: AsyncData<List<CollectionItem>>(
                  _gameItemsWithPlatforms,
                ),
                onPlatformFilterChanged: (int? id) {
                  selectedPlatformId = id;
                },
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Скроллим к чипу "PS1" и тапаем
          final Finder ps1Chip = find.widgetWithText(ChoiceChip, 'PS1');
          await tester.ensureVisible(ps1Chip);
          await tester.pumpAndSettle();
          await tester.tap(ps1Chip);
          await tester.pumpAndSettle();

          expect(selectedPlatformId, equals(7));
        },
      );

      testWidgets(
        'должен вызвать onPlatformFilterChanged с null при снятии выбора',
        (WidgetTester tester) async {
          int? selectedPlatformId = 7;

          await tester.pumpWidget(
            _buildTestApp(
              overrides: _defaultOverrides(),
              child: _buildFilterBar(
                filterType: MediaType.game,
                filterPlatformId: 7,
                itemsAsync: AsyncData<List<CollectionItem>>(
                  _gameItemsWithPlatforms,
                ),
                onPlatformFilterChanged: (int? id) {
                  selectedPlatformId = id;
                },
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Тапаем на уже выбранный чип "PS1" для снятия выбора
          final Finder ps1Chip = find.widgetWithText(ChoiceChip, 'PS1');
          await tester.ensureVisible(ps1Chip);
          await tester.pumpAndSettle();
          await tester.tap(ps1Chip);
          await tester.pumpAndSettle();

          expect(selectedPlatformId, isNull);
        },
      );

      testWidgets(
        'должен показать "All" чип как первый в строке платформ',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _buildTestApp(
              overrides: _defaultOverrides(),
              child: _buildFilterBar(
                filterType: MediaType.game,
                itemsAsync: AsyncData<List<CollectionItem>>(
                  _gameItemsWithPlatforms,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // "All" чип в строке платформ
          final Finder allChip = find.widgetWithText(ChoiceChip, 'All');
          expect(allChip, findsOneWidget);
        },
      );

      testWidgets(
        'должен сортировать платформы по названию в алфавитном порядке',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _buildTestApp(
              overrides: _defaultOverrides(),
              child: _buildFilterBar(
                filterType: MediaType.game,
                itemsAsync: AsyncData<List<CollectionItem>>(
                  _gameItemsWithPlatforms,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Находим все ChoiceChip
          final Finder chips = find.byType(ChoiceChip);
          expect(chips, findsNWidgets(3));

          // Проверяем порядок: All, PS1, SNES (алфавитный по displayName)
          final List<ChoiceChip> chipWidgets = tester
              .widgetList<ChoiceChip>(chips)
              .toList();

          final String firstChipText =
              (chipWidgets[0].label as Text).data ?? '';
          final String secondChipText =
              (chipWidgets[1].label as Text).data ?? '';
          final String thirdChipText =
              (chipWidgets[2].label as Text).data ?? '';

          expect(firstChipText, equals('All'));
          expect(secondChipText, equals('PS1'));
          expect(thirdChipText, equals('SNES'));
        },
      );

      testWidgets(
        'должен игнорировать элементы с platformId == -1',
        (WidgetTester tester) async {
          final List<CollectionItem> itemsWithInvalidPlatform =
              <CollectionItem>[
            CollectionItem(
              id: 100,
              collectionId: _testCollectionId,
              mediaType: MediaType.game,
              externalId: 999,
              status: ItemStatus.notStarted,
              addedAt: DateTime(2024),
              platformId: -1,
              platform: const Platform(id: -1, name: 'Invalid'),
            ),
          ];

          await tester.pumpWidget(
            _buildTestApp(
              overrides: _defaultOverrides(),
              child: _buildFilterBar(
                filterType: MediaType.game,
                itemsAsync: AsyncData<List<CollectionItem>>(
                  itemsWithInvalidPlatform,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Нет чипсов — невалидная платформа отфильтрована
          expect(find.byType(ChoiceChip), findsNothing);
        },
      );

      testWidgets(
        'должен игнорировать элементы с platform == null',
        (WidgetTester tester) async {
          final List<CollectionItem> itemsWithNullPlatform = <CollectionItem>[
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
                filterType: MediaType.game,
                itemsAsync: AsyncData<List<CollectionItem>>(
                  itemsWithNullPlatform,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Нет чипсов — platform == null
          expect(find.byType(ChoiceChip), findsNothing);
        },
      );

      testWidgets(
        'должен дедуплицировать платформы из нескольких элементов',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _buildTestApp(
              overrides: _defaultOverrides(),
              child: _buildFilterBar(
                filterType: MediaType.game,
                itemsAsync: AsyncData<List<CollectionItem>>(
                  _gameItemsWithPlatforms,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // 2 элемента с SNES, 1 с PS1 — но только 2 уникальные платформы + All
          expect(find.byType(ChoiceChip), findsNWidgets(3));
          // SNES встречается ровно 1 раз (не дублируется)
          expect(find.text('SNES'), findsOneWidget);
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
          expect(find.text('All'), findsOneWidget);
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

    group('скрытие платформ для разных типов медиа', () {
      testWidgets(
        'должен скрывать чипсы платформ для tvShow',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _buildTestApp(
              overrides: _defaultOverrides(),
              child: _buildFilterBar(
                filterType: MediaType.tvShow,
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

      testWidgets(
        'должен скрывать чипсы платформ для animation',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _buildTestApp(
              overrides: _defaultOverrides(),
              child: _buildFilterBar(
                filterType: MediaType.animation,
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

      testWidgets(
        'должен скрывать чипсы платформ для visualNovel',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _buildTestApp(
              overrides: _defaultOverrides(),
              child: _buildFilterBar(
                filterType: MediaType.visualNovel,
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
  });
}
