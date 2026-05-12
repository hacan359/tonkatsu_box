import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/data/repositories/canvas_repository.dart';
import 'package:xerabora/features/collections/helpers/collection_actions.dart';
import 'package:xerabora/features/collections/providers/canvas_provider.dart';
import 'package:xerabora/features/collections/providers/collections_provider.dart';
import 'package:xerabora/l10n/app_localizations.dart';
import 'package:xerabora/shared/models/canvas_item.dart';
import 'package:xerabora/shared/models/collection.dart';
import 'package:xerabora/shared/models/steamgriddb_image.dart';

class _TestCanvasNotifier extends CanvasNotifier {
  _TestCanvasNotifier();

  final List<_AddImageCall> addImageCalls = <_AddImageCall>[];

  @override
  CanvasState build(int? arg) {
    return const CanvasState(isLoading: false, isInitialized: true);
  }

  @override
  Future<void> refresh() async {}

  @override
  Future<void> resetPositions(double viewportWidth) async {}

  @override
  Future<CanvasItem> addImageItem(
    double x,
    double y,
    Map<String, dynamic> imageData, {
    double width = 200,
    double height = 200,
  }) async {
    addImageCalls.add(_AddImageCall(
      x: x,
      y: y,
      imageData: imageData,
      width: width,
      height: height,
    ));
    return CanvasItem(
      id: 999,
      collectionId: 1,
      itemType: CanvasItemType.image,
      x: x,
      y: y,
      width: width,
      height: height,
      data: imageData,
      createdAt: DateTime.now(),
    );
  }
}

class _AddImageCall {
  const _AddImageCall({
    required this.x,
    required this.y,
    required this.imageData,
    required this.width,
    required this.height,
  });

  final double x;
  final double y;
  final Map<String, dynamic> imageData;
  final double width;
  final double height;
}

class _TestCollectionsNotifier extends CollectionsNotifier {
  _TestCollectionsNotifier();

  bool renameCalled = false;
  bool deleteCalled = false;

  @override
  Future<List<Collection>> build() async {
    return <Collection>[];
  }

  @override
  Future<void> rename(int id, String newName) async {
    renameCalled = true;
  }

  @override
  Future<void> delete(int id) async {
    deleteCalled = true;
  }
}

WidgetRef? _capturedRef;
BuildContext? _capturedContext;

Widget _buildTestApp({
  required List<Override> overrides,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: Consumer(
        builder: (BuildContext context, WidgetRef ref, Widget? child) {
          _capturedRef = ref;
          _capturedContext = context;
          return const Scaffold(
            body: SizedBox.shrink(),
          );
        },
      ),
    ),
  );
}

void main() {
  final DateTime testDate = DateTime(2024, 6, 15);

  final Collection testCollection = Collection(
    id: 1,
    name: 'Test Collection',
    author: 'Test Author',
    type: CollectionType.own,
    createdAt: testDate,
  );

  setUp(() {
    _capturedRef = null;
    _capturedContext = null;
  });

  group('CollectionActions', () {
    group('addSteamGridDbImage', () {
      testWidgets(
        'должен вызвать addImageItem на canvasNotifier с правильными параметрами',
        (WidgetTester tester) async {
          final _TestCanvasNotifier canvasNotifier = _TestCanvasNotifier();

          await tester.pumpWidget(_buildTestApp(
            overrides: <Override>[
              canvasNotifierProvider.overrideWith(() => canvasNotifier),
            ],
          ));
          await tester.pumpAndSettle();

          const SteamGridDbImage image = SteamGridDbImage(
            id: 1,
            score: 10,
            style: 'alternate',
            url: 'https://example.com/grid.png',
            thumb: 'https://example.com/thumb.png',
            width: 600,
            height: 900,
          );

          CollectionActions.addSteamGridDbImage(
            context: _capturedContext!,
            ref: _capturedRef!,
            collectionId: 1,
            image: image,
          );

          expect(canvasNotifier.addImageCalls, hasLength(1));

          final _AddImageCall call = canvasNotifier.addImageCalls.first;
          expect(call.imageData, equals(<String, dynamic>{'url': image.url}));
        },
      );

      testWidgets(
        'должен масштабировать ширину до maxWidth=300 если изображение шире',
        (WidgetTester tester) async {
          final _TestCanvasNotifier canvasNotifier = _TestCanvasNotifier();

          await tester.pumpWidget(_buildTestApp(
            overrides: <Override>[
              canvasNotifierProvider.overrideWith(() => canvasNotifier),
            ],
          ));
          await tester.pumpAndSettle();

          const SteamGridDbImage wideImage = SteamGridDbImage(
            id: 2,
            score: 5,
            style: 'blurred',
            url: 'https://example.com/wide.png',
            thumb: 'https://example.com/thumb.png',
            width: 600,
            height: 900,
          );

          CollectionActions.addSteamGridDbImage(
            context: _capturedContext!,
            ref: _capturedRef!,
            collectionId: 1,
            image: wideImage,
          );

          final _AddImageCall call = canvasNotifier.addImageCalls.first;
          expect(call.width, equals(300.0));
          expect(call.height, equals(450.0));
        },
      );

      testWidgets(
        'должен использовать оригинальную ширину если она <= 300',
        (WidgetTester tester) async {
          final _TestCanvasNotifier canvasNotifier = _TestCanvasNotifier();

          await tester.pumpWidget(_buildTestApp(
            overrides: <Override>[
              canvasNotifierProvider.overrideWith(() => canvasNotifier),
            ],
          ));
          await tester.pumpAndSettle();

          const SteamGridDbImage smallImage = SteamGridDbImage(
            id: 3,
            score: 8,
            style: 'material',
            url: 'https://example.com/small.png',
            thumb: 'https://example.com/thumb.png',
            width: 200,
            height: 300,
          );

          CollectionActions.addSteamGridDbImage(
            context: _capturedContext!,
            ref: _capturedRef!,
            collectionId: 1,
            image: smallImage,
          );

          final _AddImageCall call = canvasNotifier.addImageCalls.first;
          expect(call.width, equals(200.0));
          expect(call.height, equals(300.0));
        },
      );

      testWidgets(
        'должен использовать defaultSize=200 если width или height равны 0',
        (WidgetTester tester) async {
          final _TestCanvasNotifier canvasNotifier = _TestCanvasNotifier();

          await tester.pumpWidget(_buildTestApp(
            overrides: <Override>[
              canvasNotifierProvider.overrideWith(() => canvasNotifier),
            ],
          ));
          await tester.pumpAndSettle();

          const SteamGridDbImage zeroImage = SteamGridDbImage(
            id: 4,
            score: 0,
            style: 'alternate',
            url: 'https://example.com/zero.png',
            thumb: 'https://example.com/thumb.png',
            width: 0,
            height: 0,
          );

          CollectionActions.addSteamGridDbImage(
            context: _capturedContext!,
            ref: _capturedRef!,
            collectionId: 1,
            image: zeroImage,
          );

          final _AddImageCall call = canvasNotifier.addImageCalls.first;
          expect(call.width, equals(200.0));
          expect(call.height, equals(200.0));
        },
      );

      testWidgets(
        'должен центрировать изображение на канвасе',
        (WidgetTester tester) async {
          final _TestCanvasNotifier canvasNotifier = _TestCanvasNotifier();

          await tester.pumpWidget(_buildTestApp(
            overrides: <Override>[
              canvasNotifierProvider.overrideWith(() => canvasNotifier),
            ],
          ));
          await tester.pumpAndSettle();

          const SteamGridDbImage image = SteamGridDbImage(
            id: 5,
            score: 10,
            style: 'alternate',
            url: 'https://example.com/img.png',
            thumb: 'https://example.com/thumb.png',
            width: 200,
            height: 200,
          );

          CollectionActions.addSteamGridDbImage(
            context: _capturedContext!,
            ref: _capturedRef!,
            collectionId: 1,
            image: image,
          );

          final _AddImageCall call = canvasNotifier.addImageCalls.first;
          expect(
            call.x,
            equals(CanvasRepository.initialCenterX - 200.0 / 2),
          );
          expect(
            call.y,
            equals(CanvasRepository.initialCenterY - 200.0 / 2),
          );
        },
      );

      testWidgets(
        'должен работать с collectionId=null',
        (WidgetTester tester) async {
          final _TestCanvasNotifier canvasNotifier = _TestCanvasNotifier();

          await tester.pumpWidget(_buildTestApp(
            overrides: <Override>[
              canvasNotifierProvider.overrideWith(() => canvasNotifier),
            ],
          ));
          await tester.pumpAndSettle();

          const SteamGridDbImage image = SteamGridDbImage(
            id: 6,
            score: 10,
            style: 'alternate',
            url: 'https://example.com/img.png',
            thumb: 'https://example.com/thumb.png',
            width: 100,
            height: 100,
          );

          CollectionActions.addSteamGridDbImage(
            context: _capturedContext!,
            ref: _capturedRef!,
            collectionId: null,
            image: image,
          );

          expect(canvasNotifier.addImageCalls, hasLength(1));
        },
      );

      testWidgets(
        'должен показать SnackBar с сообщением об успехе',
        (WidgetTester tester) async {
          final _TestCanvasNotifier canvasNotifier = _TestCanvasNotifier();

          await tester.pumpWidget(_buildTestApp(
            overrides: <Override>[
              canvasNotifierProvider.overrideWith(() => canvasNotifier),
            ],
          ));
          await tester.pumpAndSettle();

          const SteamGridDbImage image = SteamGridDbImage(
            id: 7,
            score: 10,
            style: 'alternate',
            url: 'https://example.com/img.png',
            thumb: 'https://example.com/thumb.png',
            width: 100,
            height: 100,
          );

          CollectionActions.addSteamGridDbImage(
            context: _capturedContext!,
            ref: _capturedRef!,
            collectionId: 1,
            image: image,
          );
          await tester.pump();

          expect(find.byType(SnackBar), findsOneWidget);
        },
      );
    });

    group('addVgMapsImage', () {
      testWidgets(
        'должен вызвать addImageItem на canvasNotifier',
        (WidgetTester tester) async {
          final _TestCanvasNotifier canvasNotifier = _TestCanvasNotifier();

          await tester.pumpWidget(_buildTestApp(
            overrides: <Override>[
              canvasNotifierProvider.overrideWith(() => canvasNotifier),
            ],
          ));
          await tester.pumpAndSettle();

          CollectionActions.addVgMapsImage(
            context: _capturedContext!,
            ref: _capturedRef!,
            collectionId: 1,
            url: 'https://vgmaps.de/map.png',
            width: 800,
            height: 600,
          );

          expect(canvasNotifier.addImageCalls, hasLength(1));

          final _AddImageCall call = canvasNotifier.addImageCalls.first;
          expect(
            call.imageData,
            equals(<String, dynamic>{'url': 'https://vgmaps.de/map.png'}),
          );
        },
      );

      testWidgets(
        'должен масштабировать ширину до maxWidth=400 если изображение шире',
        (WidgetTester tester) async {
          final _TestCanvasNotifier canvasNotifier = _TestCanvasNotifier();

          await tester.pumpWidget(_buildTestApp(
            overrides: <Override>[
              canvasNotifierProvider.overrideWith(() => canvasNotifier),
            ],
          ));
          await tester.pumpAndSettle();

          CollectionActions.addVgMapsImage(
            context: _capturedContext!,
            ref: _capturedRef!,
            collectionId: 1,
            url: 'https://vgmaps.de/wide_map.png',
            width: 1600,
            height: 800,
          );

          final _AddImageCall call = canvasNotifier.addImageCalls.first;
          expect(call.width, equals(400.0));
          expect(call.height, equals(200.0));
        },
      );

      testWidgets(
        'должен использовать оригинальную ширину если она <= 400',
        (WidgetTester tester) async {
          final _TestCanvasNotifier canvasNotifier = _TestCanvasNotifier();

          await tester.pumpWidget(_buildTestApp(
            overrides: <Override>[
              canvasNotifierProvider.overrideWith(() => canvasNotifier),
            ],
          ));
          await tester.pumpAndSettle();

          CollectionActions.addVgMapsImage(
            context: _capturedContext!,
            ref: _capturedRef!,
            collectionId: 1,
            url: 'https://vgmaps.de/small_map.png',
            width: 300,
            height: 150,
          );

          final _AddImageCall call = canvasNotifier.addImageCalls.first;
          expect(call.width, equals(300.0));
          expect(call.height, equals(150.0));
        },
      );

      testWidgets(
        'должен использовать defaultSize=400 если width или height равны null',
        (WidgetTester tester) async {
          final _TestCanvasNotifier canvasNotifier = _TestCanvasNotifier();

          await tester.pumpWidget(_buildTestApp(
            overrides: <Override>[
              canvasNotifierProvider.overrideWith(() => canvasNotifier),
            ],
          ));
          await tester.pumpAndSettle();

          CollectionActions.addVgMapsImage(
            context: _capturedContext!,
            ref: _capturedRef!,
            collectionId: 1,
            url: 'https://vgmaps.de/unknown.png',
            width: null,
            height: null,
          );

          final _AddImageCall call = canvasNotifier.addImageCalls.first;
          expect(call.width, equals(400.0));
          expect(call.height, equals(400.0));
        },
      );

      testWidgets(
        'должен использовать defaultSize=400 если width=0 и height=0',
        (WidgetTester tester) async {
          final _TestCanvasNotifier canvasNotifier = _TestCanvasNotifier();

          await tester.pumpWidget(_buildTestApp(
            overrides: <Override>[
              canvasNotifierProvider.overrideWith(() => canvasNotifier),
            ],
          ));
          await tester.pumpAndSettle();

          CollectionActions.addVgMapsImage(
            context: _capturedContext!,
            ref: _capturedRef!,
            collectionId: 1,
            url: 'https://vgmaps.de/zero.png',
            width: 0,
            height: 0,
          );

          final _AddImageCall call = canvasNotifier.addImageCalls.first;
          expect(call.width, equals(400.0));
          expect(call.height, equals(400.0));
        },
      );

      testWidgets(
        'должен центрировать карту на канвасе',
        (WidgetTester tester) async {
          final _TestCanvasNotifier canvasNotifier = _TestCanvasNotifier();

          await tester.pumpWidget(_buildTestApp(
            overrides: <Override>[
              canvasNotifierProvider.overrideWith(() => canvasNotifier),
            ],
          ));
          await tester.pumpAndSettle();

          CollectionActions.addVgMapsImage(
            context: _capturedContext!,
            ref: _capturedRef!,
            collectionId: 1,
            url: 'https://vgmaps.de/map.png',
            width: 400,
            height: 200,
          );

          final _AddImageCall call = canvasNotifier.addImageCalls.first;
          expect(
            call.x,
            equals(CanvasRepository.initialCenterX - 400.0 / 2),
          );
          expect(
            call.y,
            equals(CanvasRepository.initialCenterY - 200.0 / 2),
          );
        },
      );

      testWidgets(
        'должен показать SnackBar с сообщением об успехе',
        (WidgetTester tester) async {
          final _TestCanvasNotifier canvasNotifier = _TestCanvasNotifier();

          await tester.pumpWidget(_buildTestApp(
            overrides: <Override>[
              canvasNotifierProvider.overrideWith(() => canvasNotifier),
            ],
          ));
          await tester.pumpAndSettle();

          CollectionActions.addVgMapsImage(
            context: _capturedContext!,
            ref: _capturedRef!,
            collectionId: 1,
            url: 'https://vgmaps.de/map.png',
            width: 800,
            height: 600,
          );
          await tester.pump();

          expect(find.byType(SnackBar), findsOneWidget);
        },
      );
    });

    group('renameCollection', skip: 'Переписано на EditCollectionDialog — тесты будут обновлены отдельно', () {
      testWidgets(
        'должен вернуть null если диалог отменён',
        (WidgetTester tester) async {
          final _TestCollectionsNotifier collectionsNotifier =
              _TestCollectionsNotifier();

          await tester.pumpWidget(
            ProviderScope(
              overrides: <Override>[
                collectionsProvider
                    .overrideWith(() => collectionsNotifier),
              ],
              child: MaterialApp(
                localizationsDelegates: S.localizationsDelegates,
                supportedLocales: S.supportedLocales,
                home: Consumer(
                  builder:
                      (BuildContext context, WidgetRef ref, Widget? child) {
                    _capturedRef = ref;
                    _capturedContext = context;
                    return const Scaffold(body: SizedBox.shrink());
                  },
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final Future<bool> resultFuture =
              CollectionActions.renameCollection(
            context: _capturedContext!,
            ref: _capturedRef!,
            collection: testCollection,
          );
          await tester.pumpAndSettle();

          expect(find.byType(AlertDialog), findsOneWidget);

          final Finder cancelButton = find.widgetWithText(
            TextButton,
            'Cancel',
          );
          expect(cancelButton, findsOneWidget);
          await tester.tap(cancelButton);
          await tester.pumpAndSettle();

          final bool result = await resultFuture;
          expect(result, isFalse);

          expect(collectionsNotifier.renameCalled, isFalse);
        },
      );

      testWidgets(
        'должен вернуть null если новое имя совпадает с текущим',
        (WidgetTester tester) async {
          final _TestCollectionsNotifier collectionsNotifier =
              _TestCollectionsNotifier();

          await tester.pumpWidget(
            ProviderScope(
              overrides: <Override>[
                collectionsProvider
                    .overrideWith(() => collectionsNotifier),
              ],
              child: MaterialApp(
                localizationsDelegates: S.localizationsDelegates,
                supportedLocales: S.supportedLocales,
                home: Consumer(
                  builder:
                      (BuildContext context, WidgetRef ref, Widget? child) {
                    _capturedRef = ref;
                    _capturedContext = context;
                    return const Scaffold(body: SizedBox.shrink());
                  },
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final Future<bool> resultFuture =
              CollectionActions.renameCollection(
            context: _capturedContext!,
            ref: _capturedRef!,
            collection: testCollection,
          );
          await tester.pumpAndSettle();

          expect(find.byType(AlertDialog), findsOneWidget);

          final Finder renameButton = find.widgetWithText(
            FilledButton,
            'Rename',
          );
          expect(renameButton, findsOneWidget);
          await tester.tap(renameButton);
          await tester.pumpAndSettle();

          final bool result = await resultFuture;
          expect(result, isFalse);

          expect(collectionsNotifier.renameCalled, isFalse);
        },
      );

      testWidgets(
        'должен вернуть новое имя если переименование успешно',
        (WidgetTester tester) async {
          final _TestCollectionsNotifier collectionsNotifier =
              _TestCollectionsNotifier();

          await tester.pumpWidget(
            ProviderScope(
              overrides: <Override>[
                collectionsProvider
                    .overrideWith(() => collectionsNotifier),
              ],
              child: MaterialApp(
                localizationsDelegates: S.localizationsDelegates,
                supportedLocales: S.supportedLocales,
                home: Consumer(
                  builder:
                      (BuildContext context, WidgetRef ref, Widget? child) {
                    _capturedRef = ref;
                    _capturedContext = context;
                    return const Scaffold(body: SizedBox.shrink());
                  },
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final Future<bool> resultFuture =
              CollectionActions.renameCollection(
            context: _capturedContext!,
            ref: _capturedRef!,
            collection: testCollection,
          );
          await tester.pumpAndSettle();

          final Finder textField = find.byType(TextFormField);
          expect(textField, findsOneWidget);
          await tester.enterText(textField, 'New Name');
          await tester.pumpAndSettle();

          final Finder renameButton = find.widgetWithText(
            FilledButton,
            'Rename',
          );
          await tester.tap(renameButton);
          await tester.pumpAndSettle();

          final bool result = await resultFuture;
          expect(result, isTrue);
          expect(collectionsNotifier.renameCalled, isTrue);
        },
      );
    });

    group('deleteCollection', () {
      testWidgets(
        'должен вернуть false если диалог отменён',
        (WidgetTester tester) async {
          final _TestCollectionsNotifier collectionsNotifier =
              _TestCollectionsNotifier();

          await tester.pumpWidget(
            ProviderScope(
              overrides: <Override>[
                collectionsProvider
                    .overrideWith(() => collectionsNotifier),
              ],
              child: MaterialApp(
                localizationsDelegates: S.localizationsDelegates,
                supportedLocales: S.supportedLocales,
                home: Consumer(
                  builder:
                      (BuildContext context, WidgetRef ref, Widget? child) {
                    _capturedRef = ref;
                    _capturedContext = context;
                    return const Scaffold(body: SizedBox.shrink());
                  },
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final Future<bool> resultFuture =
              CollectionActions.deleteCollection(
            context: _capturedContext!,
            ref: _capturedRef!,
            collection: testCollection,
          );
          await tester.pumpAndSettle();

          expect(find.byType(AlertDialog), findsOneWidget);

          final Finder cancelButton = find.widgetWithText(
            TextButton,
            'Cancel',
          );
          expect(cancelButton, findsOneWidget);
          await tester.tap(cancelButton);
          await tester.pumpAndSettle();

          final bool result = await resultFuture;
          expect(result, isFalse);

          expect(collectionsNotifier.deleteCalled, isFalse);
        },
      );

      testWidgets(
        'должен вернуть true если удаление подтверждено',
        (WidgetTester tester) async {
          final _TestCollectionsNotifier collectionsNotifier =
              _TestCollectionsNotifier();

          await tester.pumpWidget(
            ProviderScope(
              overrides: <Override>[
                collectionsProvider
                    .overrideWith(() => collectionsNotifier),
              ],
              child: MaterialApp(
                localizationsDelegates: S.localizationsDelegates,
                supportedLocales: S.supportedLocales,
                home: Consumer(
                  builder:
                      (BuildContext context, WidgetRef ref, Widget? child) {
                    _capturedRef = ref;
                    _capturedContext = context;
                    return const Scaffold(body: SizedBox.shrink());
                  },
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final Future<bool> resultFuture =
              CollectionActions.deleteCollection(
            context: _capturedContext!,
            ref: _capturedRef!,
            collection: testCollection,
          );
          await tester.pumpAndSettle();

          expect(find.byType(AlertDialog), findsOneWidget);

          final Finder deleteButton = find.widgetWithText(
            FilledButton,
            'Delete',
          );
          expect(deleteButton, findsOneWidget);
          await tester.tap(deleteButton);
          await tester.pumpAndSettle();

          final bool result = await resultFuture;
          expect(result, isTrue);

          expect(collectionsNotifier.deleteCalled, isTrue);
        },
      );

      testWidgets(
        'должен показать SnackBar при успешном удалении',
        (WidgetTester tester) async {
          final _TestCollectionsNotifier collectionsNotifier =
              _TestCollectionsNotifier();

          await tester.pumpWidget(
            ProviderScope(
              overrides: <Override>[
                collectionsProvider
                    .overrideWith(() => collectionsNotifier),
              ],
              child: MaterialApp(
                localizationsDelegates: S.localizationsDelegates,
                supportedLocales: S.supportedLocales,
                home: Consumer(
                  builder:
                      (BuildContext context, WidgetRef ref, Widget? child) {
                    _capturedRef = ref;
                    _capturedContext = context;
                    return const Scaffold(body: SizedBox.shrink());
                  },
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          CollectionActions.deleteCollection(
            context: _capturedContext!,
            ref: _capturedRef!,
            collection: testCollection,
          );
          await tester.pumpAndSettle();

          final Finder deleteButton = find.widgetWithText(
            FilledButton,
            'Delete',
          );
          await tester.tap(deleteButton);
          await tester.pumpAndSettle();

          expect(find.byType(SnackBar), findsOneWidget);
        },
      );
    });

    group('addSteamGridDbImage — граничные случаи масштабирования', () {
      testWidgets(
        'должен обработать изображение с width>0 и height=0 как defaultSize',
        (WidgetTester tester) async {
          final _TestCanvasNotifier canvasNotifier = _TestCanvasNotifier();

          await tester.pumpWidget(_buildTestApp(
            overrides: <Override>[
              canvasNotifierProvider.overrideWith(() => canvasNotifier),
            ],
          ));
          await tester.pumpAndSettle();

          const SteamGridDbImage image = SteamGridDbImage(
            id: 10,
            score: 1,
            style: 'alternate',
            url: 'https://example.com/edge.png',
            thumb: 'https://example.com/thumb.png',
            width: 500,
            height: 0,
          );

          CollectionActions.addSteamGridDbImage(
            context: _capturedContext!,
            ref: _capturedRef!,
            collectionId: 1,
            image: image,
          );

          final _AddImageCall call = canvasNotifier.addImageCalls.first;
          // width>0 but height=0 falls through to defaultSize.
          expect(call.width, equals(200.0));
          expect(call.height, equals(200.0));
        },
      );

      testWidgets(
        'должен обработать изображение ровно 300px по ширине',
        (WidgetTester tester) async {
          final _TestCanvasNotifier canvasNotifier = _TestCanvasNotifier();

          await tester.pumpWidget(_buildTestApp(
            overrides: <Override>[
              canvasNotifierProvider.overrideWith(() => canvasNotifier),
            ],
          ));
          await tester.pumpAndSettle();

          const SteamGridDbImage image = SteamGridDbImage(
            id: 11,
            score: 1,
            style: 'alternate',
            url: 'https://example.com/exact.png',
            thumb: 'https://example.com/thumb.png',
            width: 300,
            height: 450,
          );

          CollectionActions.addSteamGridDbImage(
            context: _capturedContext!,
            ref: _capturedRef!,
            collectionId: 1,
            image: image,
          );

          final _AddImageCall call = canvasNotifier.addImageCalls.first;
          expect(call.width, equals(300.0));
          expect(call.height, equals(450.0));
        },
      );
    });

    group('addVgMapsImage — граничные случаи масштабирования', () {
      testWidgets(
        'должен обработать карту ровно 400px по ширине',
        (WidgetTester tester) async {
          final _TestCanvasNotifier canvasNotifier = _TestCanvasNotifier();

          await tester.pumpWidget(_buildTestApp(
            overrides: <Override>[
              canvasNotifierProvider.overrideWith(() => canvasNotifier),
            ],
          ));
          await tester.pumpAndSettle();

          CollectionActions.addVgMapsImage(
            context: _capturedContext!,
            ref: _capturedRef!,
            collectionId: 1,
            url: 'https://vgmaps.de/exact.png',
            width: 400,
            height: 200,
          );

          final _AddImageCall call = canvasNotifier.addImageCalls.first;
          expect(call.width, equals(400.0));
          expect(call.height, equals(200.0));
        },
      );

      testWidgets(
        'должен обработать null width с non-null height как default',
        (WidgetTester tester) async {
          final _TestCanvasNotifier canvasNotifier = _TestCanvasNotifier();

          await tester.pumpWidget(_buildTestApp(
            overrides: <Override>[
              canvasNotifierProvider.overrideWith(() => canvasNotifier),
            ],
          ));
          await tester.pumpAndSettle();

          CollectionActions.addVgMapsImage(
            context: _capturedContext!,
            ref: _capturedRef!,
            collectionId: 1,
            url: 'https://vgmaps.de/partial.png',
            width: null,
            height: 300,
          );

          final _AddImageCall call = canvasNotifier.addImageCalls.first;
          // null width disables scaling and defaults to 400x400.
          expect(call.width, equals(400.0));
          expect(call.height, equals(400.0));
        },
      );
    });
  });
}
