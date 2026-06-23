import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/collections/providers/collections_provider.dart';
import 'package:tonkatsu_box/features/collections/widgets/collection_items_view.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';
import 'package:tonkatsu_box/shared/models/collection_item.dart';
import 'package:tonkatsu_box/shared/models/collection_sort_mode.dart';
import 'package:tonkatsu_box/shared/models/game.dart';
import 'package:tonkatsu_box/shared/models/item_status.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';
import 'package:tonkatsu_box/shared/widgets/media_poster_card.dart';
import 'package:tonkatsu_box/features/settings/providers/settings_provider.dart';

CollectionItem _makeItem({
  int id = 1,
  int? collectionId = 1,
  MediaType mediaType = MediaType.game,
  int externalId = 100,
  ItemStatus status = ItemStatus.notStarted,
  int sortOrder = 0,
  String gameName = 'Test Game',
  double? userRating,
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
    group('пустое состояние', () {
      testWidgets(
        'should show пустое состояние when empty списке элементов',
        (WidgetTester tester) async {
          await tester.pumpWidget(_buildTestApp(
            child: CollectionItemsView(
              collectionId: 1,
              items: const <CollectionItem>[],
              canEdit: true,
              onItemTap: (_) {},
            ),
          ));
          await tester.pumpAndSettle();

          expect(find.byIcon(Icons.shelves), findsOneWidget);
          expect(find.text('No Items Yet'), findsOneWidget);
        },
      );

      testWidgets(
        'should show текст "Add items..." когда canEdit=true и список пуст',
        (WidgetTester tester) async {
          await tester.pumpWidget(_buildTestApp(
            child: CollectionItemsView(
              collectionId: 1,
              items: const <CollectionItem>[],
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
        'should show "This collection is empty." когда canEdit=false и список пуст',
        (WidgetTester tester) async {
          await tester.pumpWidget(_buildTestApp(
            child: CollectionItemsView(
              collectionId: 1,
              items: const <CollectionItem>[],
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
        'should show пустое состояние при collectionId=null и пустом списке',
        (WidgetTester tester) async {
          await tester.pumpWidget(_buildTestApp(
            child: CollectionItemsView(
              collectionId: null,
              items: const <CollectionItem>[],
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

    group('grid-режим', () {
      testWidgets(
        'should show GridView с непустым списком',
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
              canEdit: true,
              onItemTap: (_) {},
            ),
          ));
          await tester.pumpAndSettle();

          expect(find.byType(GridView), findsOneWidget);
        },
      );

      testWidgets(
        'should show MediaPosterCard для каждого элемента',
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
              canEdit: true,
              onItemTap: (_) {},
            ),
          ));
          await tester.pumpAndSettle();

          expect(find.byType(MediaPosterCard), findsNWidgets(3));
        },
      );

      testWidgets(
        'should call onItemTap when pressed на карточку',
        (WidgetTester tester) async {
          CollectionItem? tappedItem;
          final List<CollectionItem> items = <CollectionItem>[
            _makeItem(id: 42, gameName: 'Tapped Game'),
          ];

          await tester.pumpWidget(_buildTestApp(
            overrides: _defaultOverrides(),
            child: CollectionItemsView(
              collectionId: 1,
              items: items,
              canEdit: true,
              onItemTap: (CollectionItem item) => tappedItem = item,
            ),
          ));
          await tester.pumpAndSettle();

          await tester.tap(find.byType(MediaPosterCard));
          expect(tappedItem, isNotNull);
          expect(tappedItem!.id, equals(42));
        },
      );

      testWidgets(
        'should show grid вне зависимости от sort mode',
        (WidgetTester tester) async {
          final List<CollectionItem> items = <CollectionItem>[
            _makeItem(id: 1, gameName: 'Manual Sort'),
          ];

          await tester.pumpWidget(_buildTestApp(
            overrides: _defaultOverrides(sortMode: CollectionSortMode.manual),
            child: CollectionItemsView(
              collectionId: 1,
              items: items,
              canEdit: true,
              onItemTap: (_) {},
            ),
          ));
          await tester.pumpAndSettle();

          expect(find.byType(GridView), findsOneWidget);
          expect(find.byType(MediaPosterCard), findsOneWidget);
        },
      );
    });

    group('RefreshIndicator', () {
      testWidgets(
        'should contain RefreshIndicator в grid-режиме',
        (WidgetTester tester) async {
          final List<CollectionItem> items = <CollectionItem>[
            _makeItem(id: 1, gameName: 'Grid Refreshable'),
          ];

          await tester.pumpWidget(_buildTestApp(
            overrides: _defaultOverrides(),
            child: CollectionItemsView(
              collectionId: 1,
              items: items,
              canEdit: true,
              onItemTap: (_) {},
            ),
          ));
          await tester.pumpAndSettle();

          expect(find.byType(RefreshIndicator), findsOneWidget);
        },
      );
    });

    group('контекстное меню ПКМ', () {
      testWidgets(
        'should show контекстное меню при правом клике на карточку',
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
              canEdit: true,
              onItemTap: (_) {},
              onItemMove: (_) => moveCalled = true,
              onItemClone: (_) => cloneCalled = true,
              onItemRemove: (_) => removeCalled = true,
            ),
          ));
          await tester.pumpAndSettle();

          final Offset center =
              tester.getCenter(find.byType(MediaPosterCard));
          final TestGesture gesture = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
            buttons: kSecondaryMouseButton,
          );
          await gesture.addPointer(location: center);
          await gesture.down(center);
          await gesture.up();
          await tester.pumpAndSettle();

          // Menu shows favorite + move/clone/remove + status header + status pill.
          expect(find.byType(PopupMenuItem<String>), findsNWidgets(6));

          expect(moveCalled, isFalse);
          expect(cloneCalled, isFalse);
          expect(removeCalled, isFalse);
        },
      );

      testWidgets(
        'should call onItemMove при выборе "move" из контекстного меню',
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
              canEdit: true,
              onItemTap: (_) {},
              onItemMove: (CollectionItem item) => movedItem = item,
              onItemClone: (_) {},
              onItemRemove: (_) {},
            ),
          ));
          await tester.pumpAndSettle();

          final Offset center =
              tester.getCenter(find.byType(MediaPosterCard));
          final TestGesture gesture = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
            buttons: kSecondaryMouseButton,
          );
          await gesture.addPointer(location: center);
          await gesture.down(center);
          await gesture.up();
          await tester.pumpAndSettle();

          await tester.tap(
            find.widgetWithIcon(
              PopupMenuItem<String>,
              Icons.drive_file_move_outlined,
            ),
          );
          await tester.pumpAndSettle();

          expect(movedItem, isNotNull);
          expect(movedItem!.id, equals(1));
        },
      );

      testWidgets(
        'не should show контекстное меню при canEdit=false',
        (WidgetTester tester) async {
          final List<CollectionItem> items = <CollectionItem>[
            _makeItem(id: 1, gameName: 'Read Only Game'),
          ];

          await tester.pumpWidget(_buildTestApp(
            overrides: _defaultOverrides(),
            child: CollectionItemsView(
              collectionId: 1,
              items: items,
              canEdit: false,
              onItemTap: (_) {},
              onItemMove: (_) {},
            ),
          ));
          await tester.pumpAndSettle();

          final Offset center =
              tester.getCenter(find.byType(MediaPosterCard));
          final TestGesture gesture = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
            buttons: kSecondaryMouseButton,
          );
          await gesture.addPointer(location: center);
          await gesture.down(center);
          await gesture.up();
          await tester.pumpAndSettle();

          expect(find.byType(PopupMenuItem<String>), findsNothing);
        },
      );
    });
  });
}

class _FakeSortNotifier extends CollectionSortNotifier {
  _FakeSortNotifier(this._mode);

  final CollectionSortMode _mode;

  @override
  CollectionSortMode build(int? arg) => _mode;

  @override
  Future<void> setSortMode(CollectionSortMode mode) async {}
}

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
