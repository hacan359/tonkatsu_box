// Виджет-тесты для CollectionItemsView.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/collections/providers/collections_provider.dart';
import 'package:xerabora/features/collections/widgets/collection_item_tile.dart';
import 'package:xerabora/features/collections/widgets/collection_items_view.dart';
import 'package:xerabora/l10n/app_localizations.dart';
import 'package:xerabora/shared/models/collection_item.dart';
import 'package:xerabora/shared/models/collection_sort_mode.dart';
import 'package:xerabora/shared/models/game.dart';
import 'package:xerabora/shared/models/item_status.dart';
import 'package:xerabora/shared/models/media_type.dart';
import 'package:xerabora/shared/widgets/media_poster_card.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';

// -- Тестовые данные --

CollectionItem _makeItem({
  int id = 1,
  int? collectionId = 1,
  MediaType mediaType = MediaType.game,
  int externalId = 100,
  ItemStatus status = ItemStatus.notStarted,
  int sortOrder = 0,
  String gameName = 'Test Game',
  int? userRating,
}) {
  return CollectionItem(
    id: id,
    collectionId: collectionId,
    mediaType: mediaType,
    externalId: externalId,
    status: status,
    sortOrder: sortOrder,
    userRating: userRating,
    addedAt: DateTime(2024),
    game: mediaType == MediaType.game
        ? Game(id: externalId, name: gameName)
        : null,
  );
}

// -- Тестовый wrapper --

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

/// Формирует стандартные overrides для провайдеров, которые читает виджет.
List<Override> _defaultOverrides({
  CollectionSortMode sortMode = CollectionSortMode.addedDate,
}) {
  return <Override>[
    collectionSortProvider.overrideWith(
      () => _FakeSortNotifier(sortMode),
    ),
    collectionItemsNotifierProvider.overrideWith(
      _FakeItemsNotifier.new,
    ),
    settingsNotifierProvider.overrideWith(
      _FakeSettingsNotifier.new,
    ),
  ];
}

void main() {
  group('CollectionItemsView', () {
    // ==================== Пустое состояние ====================

    group('пустое состояние', () {
      testWidgets(
        'должен показать пустое состояние при пустом списке элементов',
        (WidgetTester tester) async {
          await tester.pumpWidget(_buildTestApp(
            child: CollectionItemsView(
              collectionId: 1,
              items: const <CollectionItem>[],
              isGridMode: false,
              canEdit: true,
              onItemTap: (_) {},
            ),
          ));
          await tester.pumpAndSettle();

          // Иконка shelves в пустом состоянии
          expect(find.byIcon(Icons.shelves), findsOneWidget);
          // Заголовок "No Items Yet"
          expect(find.text('No Items Yet'), findsOneWidget);
        },
      );

      testWidgets(
        'должен показать текст "Add items..." когда canEdit=true и список пуст',
        (WidgetTester tester) async {
          await tester.pumpWidget(_buildTestApp(
            child: CollectionItemsView(
              collectionId: 1,
              items: const <CollectionItem>[],
              isGridMode: false,
              canEdit: true,
              onItemTap: (_) {},
            ),
          ));
          await tester.pumpAndSettle();

          expect(
            find.text('Add items to start building your collection.'),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'должен показать "This collection is empty." когда canEdit=false и список пуст',
        (WidgetTester tester) async {
          await tester.pumpWidget(_buildTestApp(
            child: CollectionItemsView(
              collectionId: 1,
              items: const <CollectionItem>[],
              isGridMode: false,
              canEdit: false,
              onItemTap: (_) {},
            ),
          ));
          await tester.pumpAndSettle();

          expect(
            find.text('This collection is empty.'),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'должен показать пустое состояние в grid-режиме при пустом списке',
        (WidgetTester tester) async {
          await tester.pumpWidget(_buildTestApp(
            child: CollectionItemsView(
              collectionId: 1,
              items: const <CollectionItem>[],
              isGridMode: true,
              canEdit: true,
              onItemTap: (_) {},
            ),
          ));
          await tester.pumpAndSettle();

          // Пустое состояние показывается вне зависимости от режима
          expect(find.byIcon(Icons.shelves), findsOneWidget);
          expect(find.text('No Items Yet'), findsOneWidget);
        },
      );
    });

    // ==================== Grid-режим ====================

    group('grid-режим', () {
      testWidgets(
        'должен показать GridView когда isGridMode=true',
        (WidgetTester tester) async {
          final List<CollectionItem> items = <CollectionItem>[
            _makeItem(id: 1, gameName: 'Game One'),
            _makeItem(id: 2, externalId: 101, gameName: 'Game Two'),
          ];

          await tester.pumpWidget(_buildTestApp(
            overrides: _defaultOverrides(),
            child: CollectionItemsView(
              collectionId: 1,
              items: items,
              isGridMode: true,
              canEdit: true,
              onItemTap: (_) {},
            ),
          ));
          await tester.pumpAndSettle();

          expect(find.byType(GridView), findsOneWidget);
          // Не должно быть ListView
          expect(find.byType(ListView), findsNothing);
        },
      );

      testWidgets(
        'должен показать MediaPosterCard для каждого элемента в grid-режиме',
        (WidgetTester tester) async {
          final List<CollectionItem> items = <CollectionItem>[
            _makeItem(id: 1, gameName: 'Game A'),
            _makeItem(id: 2, externalId: 102, gameName: 'Game B'),
            _makeItem(id: 3, externalId: 103, gameName: 'Game C'),
          ];

          await tester.pumpWidget(_buildTestApp(
            overrides: _defaultOverrides(),
            child: CollectionItemsView(
              collectionId: 1,
              items: items,
              isGridMode: true,
              canEdit: true,
              onItemTap: (_) {},
            ),
          ));
          await tester.pumpAndSettle();

          expect(find.byType(MediaPosterCard), findsNWidgets(3));
        },
      );

      testWidgets(
        'должен вызвать onItemTap при нажатии на карточку в grid-режиме',
        (WidgetTester tester) async {
          CollectionItem? tappedItem;
          final List<CollectionItem> items = <CollectionItem>[
            _makeItem(id: 1, gameName: 'Tapped Game'),
          ];

          await tester.pumpWidget(_buildTestApp(
            overrides: _defaultOverrides(),
            child: CollectionItemsView(
              collectionId: 1,
              items: items,
              isGridMode: true,
              canEdit: true,
              onItemTap: (CollectionItem item) => tappedItem = item,
            ),
          ));
          await tester.pumpAndSettle();

          await tester.tap(find.byType(MediaPosterCard));
          expect(tappedItem, isNotNull);
          expect(tappedItem!.id, equals(1));
        },
      );
    });

    // ==================== List-режим ====================

    group('list-режим', () {
      testWidgets(
        'должен показать ListView когда isGridMode=false',
        (WidgetTester tester) async {
          final List<CollectionItem> items = <CollectionItem>[
            _makeItem(id: 1, gameName: 'Game One'),
          ];

          await tester.pumpWidget(_buildTestApp(
            overrides: _defaultOverrides(),
            child: CollectionItemsView(
              collectionId: 1,
              items: items,
              isGridMode: false,
              canEdit: true,
              onItemTap: (_) {},
            ),
          ));
          await tester.pumpAndSettle();

          // ListView оборачивается в RefreshIndicator
          expect(find.byType(RefreshIndicator), findsOneWidget);
          expect(find.byType(ListView), findsOneWidget);
          expect(find.byType(GridView), findsNothing);
        },
      );

      testWidgets(
        'должен показать CollectionItemTile для каждого элемента в list-режиме',
        (WidgetTester tester) async {
          final List<CollectionItem> items = <CollectionItem>[
            _makeItem(id: 1, gameName: 'Game A'),
            _makeItem(id: 2, externalId: 102, gameName: 'Game B'),
          ];

          await tester.pumpWidget(_buildTestApp(
            overrides: _defaultOverrides(),
            child: CollectionItemsView(
              collectionId: 1,
              items: items,
              isGridMode: false,
              canEdit: true,
              onItemTap: (_) {},
            ),
          ));
          await tester.pumpAndSettle();

          expect(find.byType(CollectionItemTile), findsNWidgets(2));
        },
      );

      testWidgets(
        'должен вызвать onItemTap при нажатии на tile в list-режиме',
        (WidgetTester tester) async {
          CollectionItem? tappedItem;
          final List<CollectionItem> items = <CollectionItem>[
            _makeItem(id: 42, gameName: 'Clickable Game'),
          ];

          await tester.pumpWidget(_buildTestApp(
            overrides: _defaultOverrides(),
            child: CollectionItemsView(
              collectionId: 1,
              items: items,
              isGridMode: false,
              canEdit: true,
              onItemTap: (CollectionItem item) => tappedItem = item,
            ),
          ));
          await tester.pumpAndSettle();

          await tester.tap(find.byType(CollectionItemTile));
          expect(tappedItem, isNotNull);
          expect(tappedItem!.id, equals(42));
        },
      );

      testWidgets(
        'должен не показывать CollectionItemTile в grid-режиме',
        (WidgetTester tester) async {
          final List<CollectionItem> items = <CollectionItem>[
            _makeItem(id: 1, gameName: 'Game A'),
          ];

          await tester.pumpWidget(_buildTestApp(
            overrides: _defaultOverrides(),
            child: CollectionItemsView(
              collectionId: 1,
              items: items,
              isGridMode: true,
              canEdit: true,
              onItemTap: (_) {},
            ),
          ));
          await tester.pumpAndSettle();

          // В grid-режиме используются MediaPosterCard, а не CollectionItemTile
          expect(find.byType(CollectionItemTile), findsNothing);
          expect(find.byType(MediaPosterCard), findsOneWidget);
        },
      );
    });

    // ==================== Reorderable list ====================

    group('reorderable list', () {
      testWidgets(
        'должен показать ReorderableListView при manual sort и canEdit=true',
        (WidgetTester tester) async {
          final List<CollectionItem> items = <CollectionItem>[
            _makeItem(id: 1, sortOrder: 0, gameName: 'First'),
            _makeItem(id: 2, externalId: 102, sortOrder: 1, gameName: 'Second'),
          ];

          await tester.pumpWidget(_buildTestApp(
            overrides: _defaultOverrides(sortMode: CollectionSortMode.manual),
            child: CollectionItemsView(
              collectionId: 1,
              items: items,
              isGridMode: false,
              canEdit: true,
              onItemTap: (_) {},
            ),
          ));
          await tester.pumpAndSettle();

          expect(find.byType(ReorderableListView), findsOneWidget);
        },
      );

      testWidgets(
        'должен показать drag handle в reorderable list',
        (WidgetTester tester) async {
          final List<CollectionItem> items = <CollectionItem>[
            _makeItem(id: 1, sortOrder: 0, gameName: 'Draggable'),
          ];

          await tester.pumpWidget(_buildTestApp(
            overrides: _defaultOverrides(sortMode: CollectionSortMode.manual),
            child: CollectionItemsView(
              collectionId: 1,
              items: items,
              isGridMode: false,
              canEdit: true,
              onItemTap: (_) {},
            ),
          ));
          await tester.pumpAndSettle();

          // drag_handle иконка внутри CollectionItemTile с showDragHandle=true
          expect(find.byIcon(Icons.drag_handle), findsOneWidget);
        },
      );

      testWidgets(
        'должен показать обычный ListView при manual sort и canEdit=false',
        (WidgetTester tester) async {
          final List<CollectionItem> items = <CollectionItem>[
            _makeItem(id: 1, sortOrder: 0, gameName: 'Item'),
          ];

          await tester.pumpWidget(_buildTestApp(
            overrides: _defaultOverrides(sortMode: CollectionSortMode.manual),
            child: CollectionItemsView(
              collectionId: 1,
              items: items,
              isGridMode: false,
              canEdit: false,
              onItemTap: (_) {},
            ),
          ));
          await tester.pumpAndSettle();

          // canEdit=false -> не reorderable, а обычный ListView
          expect(find.byType(ReorderableListView), findsNothing);
          expect(find.byType(ListView), findsOneWidget);
        },
      );

      testWidgets(
        'должен не показывать ReorderableListView в grid-режиме даже при manual sort',
        (WidgetTester tester) async {
          final List<CollectionItem> items = <CollectionItem>[
            _makeItem(id: 1, sortOrder: 0, gameName: 'Grid Item'),
          ];

          await tester.pumpWidget(_buildTestApp(
            overrides: _defaultOverrides(sortMode: CollectionSortMode.manual),
            child: CollectionItemsView(
              collectionId: 1,
              items: items,
              isGridMode: true,
              canEdit: true,
              onItemTap: (_) {},
            ),
          ));
          await tester.pumpAndSettle();

          // Grid-режим приоритетнее manual sort
          expect(find.byType(ReorderableListView), findsNothing);
          expect(find.byType(GridView), findsOneWidget);
        },
      );
    });

    // ==================== collectionId == null (uncategorized) ====================

    group('uncategorized (collectionId=null)', () {
      testWidgets(
        'должен корректно отображать list-режим при collectionId=null',
        (WidgetTester tester) async {
          final List<CollectionItem> items = <CollectionItem>[
            _makeItem(
              id: 1,
              collectionId: null,
              gameName: 'Uncategorized Game',
            ),
          ];

          await tester.pumpWidget(_buildTestApp(
            overrides: _defaultOverrides(),
            child: CollectionItemsView(
              collectionId: null,
              items: items,
              isGridMode: false,
              canEdit: true,
              onItemTap: (_) {},
            ),
          ));
          await tester.pumpAndSettle();

          expect(find.byType(CollectionItemTile), findsOneWidget);
        },
      );

      testWidgets(
        'должен показать пустое состояние при collectionId=null и пустом списке',
        (WidgetTester tester) async {
          await tester.pumpWidget(_buildTestApp(
            child: CollectionItemsView(
              collectionId: null,
              items: const <CollectionItem>[],
              isGridMode: false,
              canEdit: false,
              onItemTap: (_) {},
            ),
          ));
          await tester.pumpAndSettle();

          expect(find.text('No Items Yet'), findsOneWidget);
          expect(find.text('This collection is empty.'), findsOneWidget);
        },
      );
    });

    // ==================== Callbacks ====================

    group('callbacks', () {
      testWidgets(
        'должен передать правильный элемент в onItemTap в list-режиме',
        (WidgetTester tester) async {
          final List<CollectionItem> tappedItems = <CollectionItem>[];
          final List<CollectionItem> items = <CollectionItem>[
            _makeItem(id: 10, gameName: 'First Game'),
            _makeItem(id: 20, externalId: 200, gameName: 'Second Game'),
          ];

          await tester.pumpWidget(_buildTestApp(
            overrides: _defaultOverrides(),
            child: CollectionItemsView(
              collectionId: 1,
              items: items,
              isGridMode: false,
              canEdit: false,
              onItemTap: (CollectionItem item) => tappedItems.add(item),
            ),
          ));
          await tester.pumpAndSettle();

          // Нажимаем на первый элемент
          await tester.tap(find.byType(CollectionItemTile).first);

          expect(tappedItems.length, equals(1));
          expect(tappedItems.first.id, equals(10));
        },
      );

      testWidgets(
        'должен показать несколько элементов в list-режиме',
        (WidgetTester tester) async {
          final List<CollectionItem> items = List<CollectionItem>.generate(
            5,
            (int i) => _makeItem(
              id: i + 1,
              externalId: 100 + i,
              gameName: 'Game $i',
            ),
          );

          await tester.pumpWidget(_buildTestApp(
            overrides: _defaultOverrides(),
            child: CollectionItemsView(
              collectionId: 1,
              items: items,
              isGridMode: false,
              canEdit: true,
              onItemTap: (_) {},
            ),
          ));
          await tester.pumpAndSettle();

          expect(find.byType(CollectionItemTile), findsNWidgets(5));
        },
      );
    });

    // ==================== Режимы сортировки не-manual ====================

    group('режимы сортировки не-manual', () {
      testWidgets(
        'должен показать обычный ListView при сортировке по имени',
        (WidgetTester tester) async {
          final List<CollectionItem> items = <CollectionItem>[
            _makeItem(id: 1, gameName: 'Alpha'),
            _makeItem(id: 2, externalId: 102, gameName: 'Beta'),
          ];

          await tester.pumpWidget(_buildTestApp(
            overrides: _defaultOverrides(sortMode: CollectionSortMode.name),
            child: CollectionItemsView(
              collectionId: 1,
              items: items,
              isGridMode: false,
              canEdit: true,
              onItemTap: (_) {},
            ),
          ));
          await tester.pumpAndSettle();

          // Не-manual сортировки -> обычный ListView, не Reorderable
          expect(find.byType(ReorderableListView), findsNothing);
          expect(find.byType(ListView), findsOneWidget);
        },
      );

      testWidgets(
        'должен показать обычный ListView при сортировке по рейтингу',
        (WidgetTester tester) async {
          final List<CollectionItem> items = <CollectionItem>[
            _makeItem(id: 1, gameName: 'Rated Game', userRating: 8),
          ];

          await tester.pumpWidget(_buildTestApp(
            overrides: _defaultOverrides(sortMode: CollectionSortMode.rating),
            child: CollectionItemsView(
              collectionId: 1,
              items: items,
              isGridMode: false,
              canEdit: true,
              onItemTap: (_) {},
            ),
          ));
          await tester.pumpAndSettle();

          expect(find.byType(ReorderableListView), findsNothing);
          expect(find.byType(ListView), findsOneWidget);
        },
      );

      testWidgets(
        'должен показать обычный ListView при сортировке по статусу',
        (WidgetTester tester) async {
          final List<CollectionItem> items = <CollectionItem>[
            _makeItem(
              id: 1,
              gameName: 'Status Game',
              status: ItemStatus.inProgress,
            ),
          ];

          await tester.pumpWidget(_buildTestApp(
            overrides: _defaultOverrides(sortMode: CollectionSortMode.status),
            child: CollectionItemsView(
              collectionId: 1,
              items: items,
              isGridMode: false,
              canEdit: true,
              onItemTap: (_) {},
            ),
          ));
          await tester.pumpAndSettle();

          expect(find.byType(ReorderableListView), findsNothing);
          expect(find.byType(ListView), findsOneWidget);
        },
      );
    });

    // ==================== RefreshIndicator ====================

    group('RefreshIndicator', () {
      testWidgets(
        'должен содержать RefreshIndicator в list-режиме',
        (WidgetTester tester) async {
          final List<CollectionItem> items = <CollectionItem>[
            _makeItem(id: 1, gameName: 'Refreshable'),
          ];

          await tester.pumpWidget(_buildTestApp(
            overrides: _defaultOverrides(),
            child: CollectionItemsView(
              collectionId: 1,
              items: items,
              isGridMode: false,
              canEdit: true,
              onItemTap: (_) {},
            ),
          ));
          await tester.pumpAndSettle();

          expect(find.byType(RefreshIndicator), findsOneWidget);
        },
      );

      testWidgets(
        'должен содержать RefreshIndicator в grid-режиме',
        (WidgetTester tester) async {
          final List<CollectionItem> items = <CollectionItem>[
            _makeItem(id: 1, gameName: 'Grid Refreshable'),
          ];

          await tester.pumpWidget(_buildTestApp(
            overrides: _defaultOverrides(),
            child: CollectionItemsView(
              collectionId: 1,
              items: items,
              isGridMode: true,
              canEdit: true,
              onItemTap: (_) {},
            ),
          ));
          await tester.pumpAndSettle();

          expect(find.byType(RefreshIndicator), findsOneWidget);
        },
      );

      testWidgets(
        'должен не содержать RefreshIndicator в reorderable-режиме',
        (WidgetTester tester) async {
          final List<CollectionItem> items = <CollectionItem>[
            _makeItem(id: 1, gameName: 'Non-refreshable'),
          ];

          await tester.pumpWidget(_buildTestApp(
            overrides: _defaultOverrides(sortMode: CollectionSortMode.manual),
            child: CollectionItemsView(
              collectionId: 1,
              items: items,
              isGridMode: false,
              canEdit: true,
              onItemTap: (_) {},
            ),
          ));
          await tester.pumpAndSettle();

          // ReorderableListView не оборачивается в RefreshIndicator
          expect(find.byType(RefreshIndicator), findsNothing);
          expect(find.byType(ReorderableListView), findsOneWidget);
        },
      );
    });

    // ==================== Контекстное меню ПКМ ====================

    group('контекстное меню ПКМ', () {
      testWidgets(
        'должен показать контекстное меню при правом клике в list-режиме',
        (WidgetTester tester) async {
          final List<CollectionItem> items = <CollectionItem>[
            _makeItem(id: 1, gameName: 'Right Click Game'),
          ];
          bool moveCalled = false;
          bool cloneCalled = false;
          bool removeCalled = false;

          await tester.pumpWidget(_buildTestApp(
            overrides: _defaultOverrides(),
            child: CollectionItemsView(
              collectionId: 1,
              items: items,
              isGridMode: false,
              canEdit: true,
              onItemTap: (_) {},
              onItemMove: (_) => moveCalled = true,
              onItemClone: (_) => cloneCalled = true,
              onItemRemove: (_) => removeCalled = true,
            ),
          ));
          await tester.pumpAndSettle();

          // Правый клик на карточке.
          final Offset center =
              tester.getCenter(find.byType(CollectionItemTile));
          final TestGesture gesture = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
            buttons: kSecondaryMouseButton,
          );
          await gesture.addPointer(location: center);
          await gesture.down(center);
          await gesture.up();
          await tester.pumpAndSettle();

          // Контекстное меню должно появиться с тремя опциями.
          expect(find.byType(PopupMenuItem<String>), findsNWidgets(3));

          // Не вызвано пока не выбрали.
          expect(moveCalled, isFalse);
          expect(cloneCalled, isFalse);
          expect(removeCalled, isFalse);
        },
      );

      testWidgets(
        'должен вызвать onItemMove при выборе "move" из контекстного меню',
        (WidgetTester tester) async {
          final List<CollectionItem> items = <CollectionItem>[
            _makeItem(id: 1, gameName: 'Move Game'),
          ];
          CollectionItem? movedItem;

          await tester.pumpWidget(_buildTestApp(
            overrides: _defaultOverrides(),
            child: CollectionItemsView(
              collectionId: 1,
              items: items,
              isGridMode: false,
              canEdit: true,
              onItemTap: (_) {},
              onItemMove: (CollectionItem item) => movedItem = item,
              onItemClone: (_) {},
              onItemRemove: (_) {},
            ),
          ));
          await tester.pumpAndSettle();

          // Правый клик.
          final Offset center =
              tester.getCenter(find.byType(CollectionItemTile));
          final TestGesture gesture = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
            buttons: kSecondaryMouseButton,
          );
          await gesture.addPointer(location: center);
          await gesture.down(center);
          await gesture.up();
          await tester.pumpAndSettle();

          // Нажимаем на пункт "move".
          await tester.tap(find.byType(PopupMenuItem<String>).first);
          await tester.pumpAndSettle();

          expect(movedItem, isNotNull);
          expect(movedItem!.id, equals(1));
        },
      );

      testWidgets(
        'не должен показывать контекстное меню при canEdit=false',
        (WidgetTester tester) async {
          final List<CollectionItem> items = <CollectionItem>[
            _makeItem(id: 1, gameName: 'Read Only Game'),
          ];

          await tester.pumpWidget(_buildTestApp(
            overrides: _defaultOverrides(),
            child: CollectionItemsView(
              collectionId: 1,
              items: items,
              isGridMode: false,
              canEdit: false,
              onItemTap: (_) {},
              onItemMove: (_) {},
            ),
          ));
          await tester.pumpAndSettle();

          // Правый клик.
          final Offset center =
              tester.getCenter(find.byType(CollectionItemTile));
          final TestGesture gesture = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
            buttons: kSecondaryMouseButton,
          );
          await gesture.addPointer(location: center);
          await gesture.down(center);
          await gesture.up();
          await tester.pumpAndSettle();

          // Контекстное меню не должно появиться.
          expect(find.byType(PopupMenuItem<String>), findsNothing);
        },
      );
    });

    // ==================== Приоритет isGridMode ====================

    group('приоритет isGridMode', () {
      testWidgets(
        'должен использовать grid-режим вне зависимости от sort mode',
        (WidgetTester tester) async {
          final List<CollectionItem> items = <CollectionItem>[
            _makeItem(id: 1, gameName: 'Priority Test'),
          ];

          // Даже при manual sort, grid-режим должен использоваться
          await tester.pumpWidget(_buildTestApp(
            overrides: _defaultOverrides(sortMode: CollectionSortMode.manual),
            child: CollectionItemsView(
              collectionId: 1,
              items: items,
              isGridMode: true,
              canEdit: true,
              onItemTap: (_) {},
            ),
          ));
          await tester.pumpAndSettle();

          expect(find.byType(GridView), findsOneWidget);
          expect(find.byType(ReorderableListView), findsNothing);
          expect(find.byType(MediaPosterCard), findsOneWidget);
        },
      );
    });
  });
}

// ==================== Fake notifiers для тестов ====================

/// Fake [CollectionSortNotifier] для тестов.
///
/// Возвращает заданный [CollectionSortMode] без обращения к SharedPreferences.
class _FakeSortNotifier extends CollectionSortNotifier {
  _FakeSortNotifier(this._mode);

  final CollectionSortMode _mode;

  @override
  CollectionSortMode build(int? arg) => _mode;

  @override
  Future<void> setSortMode(CollectionSortMode mode) async {}
}

/// Fake [CollectionItemsNotifier] для тестов.
///
/// Возвращает пустой AsyncData без обращения к БД.
class _FakeItemsNotifier extends CollectionItemsNotifier {
  @override
  AsyncValue<List<CollectionItem>> build(int? arg) =>
      const AsyncData<List<CollectionItem>>(<CollectionItem>[]);

  @override
  Future<void> refresh() async {}

  @override
  Future<void> reorderItem(int oldIndex, int newIndex) async {}
}

class _FakeSettingsNotifier extends SettingsNotifier {
  @override
  SettingsState build() => const SettingsState();
}
