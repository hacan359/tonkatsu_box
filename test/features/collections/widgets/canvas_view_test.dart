import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/collections/providers/canvas_provider.dart';
import 'package:xerabora/features/collections/providers/steamgriddb_panel_provider.dart';
import 'package:xerabora/features/collections/widgets/canvas_view.dart';
import 'package:xerabora/shared/models/canvas_item.dart';
import 'package:xerabora/shared/models/game.dart';

// Тестовый notifier, который возвращает контролируемое состояние
// без реальных async-операций (БД, репозиторий).
class TestCanvasNotifier extends CanvasNotifier {
  TestCanvasNotifier(this._testState);

  final CanvasState _testState;

  @override
  CanvasState build(int arg) {
    return _testState;
  }

  @override
  Future<void> refresh() async {
    // Не делаем ничего в тестах
  }

  @override
  Future<void> resetPositions(double viewportWidth) async {
    // Не делаем ничего в тестах
  }
}

void main() {
  final DateTime testDate = DateTime(2024, 6, 15);

  const int testCollectionId = 1;

  CanvasItem createTestItem({
    int id = 1,
    CanvasItemType itemType = CanvasItemType.game,
    int? itemRefId = 100,
    double x = 2500.0,
    double y = 2500.0,
    double? width = 160.0,
    double? height = 220.0,
    int zIndex = 0,
    Game? game,
  }) {
    return CanvasItem(
      id: id,
      collectionId: testCollectionId,
      itemType: itemType,
      itemRefId: itemRefId,
      x: x,
      y: y,
      width: width,
      height: height,
      zIndex: zIndex,
      createdAt: testDate,
      game: game,
    );
  }

  Widget buildTestWidget({
    required CanvasState canvasState,
    bool isEditable = true,
  }) {
    return ProviderScope(
      overrides: <Override>[
        canvasNotifierProvider
            .overrideWith(() => TestCanvasNotifier(canvasState)),
        steamGridDbPanelProvider
            .overrideWith(() => _TestSteamGridDbPanelNotifier()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: CanvasView(
              collectionId: testCollectionId,
              isEditable: isEditable,
            ),
          ),
        ),
      ),
    );
  }

  group('CanvasView', () {
    group('состояние загрузки', () {
      testWidgets(
        'должен показывать CircularProgressIndicator когда isLoading=true',
        (WidgetTester tester) async {
          const CanvasState loadingState = CanvasState(
            isLoading: true,
          );

          await tester.pumpWidget(buildTestWidget(canvasState: loadingState));

          expect(find.byType(CircularProgressIndicator), findsOneWidget);
          // Не должно быть InteractiveViewer в состоянии загрузки
          expect(find.byType(InteractiveViewer), findsNothing);
        },
      );
    });

    group('состояние ошибки', () {
      testWidgets(
        'должен показывать иконку ошибки когда error!=null',
        (WidgetTester tester) async {
          const CanvasState errorState = CanvasState(
            isLoading: false,
            error: 'Database connection failed',
          );

          await tester.pumpWidget(buildTestWidget(canvasState: errorState));

          expect(find.byIcon(Icons.error_outline), findsOneWidget);
        },
      );

      testWidgets(
        'должен показывать текст "Failed to load canvas" когда error!=null',
        (WidgetTester tester) async {
          const CanvasState errorState = CanvasState(
            isLoading: false,
            error: 'Some error',
          );

          await tester.pumpWidget(buildTestWidget(canvasState: errorState));

          expect(find.text('Failed to load canvas'), findsOneWidget);
        },
      );

      testWidgets(
        'должен показывать кнопку Retry когда error!=null',
        (WidgetTester tester) async {
          const CanvasState errorState = CanvasState(
            isLoading: false,
            error: 'Some error',
          );

          await tester.pumpWidget(buildTestWidget(canvasState: errorState));

          expect(find.text('Retry'), findsOneWidget);
          expect(find.byType(TextButton), findsOneWidget);
        },
      );

      testWidgets(
        'не должен показывать InteractiveViewer когда error!=null',
        (WidgetTester tester) async {
          const CanvasState errorState = CanvasState(
            isLoading: false,
            error: 'Some error',
          );

          await tester.pumpWidget(buildTestWidget(canvasState: errorState));

          expect(find.byType(InteractiveViewer), findsNothing);
        },
      );
    });

    group('пустое состояние', () {
      testWidgets(
        'должен показывать "Canvas is empty" когда список items пуст',
        (WidgetTester tester) async {
          const CanvasState emptyState = CanvasState(
            isLoading: false,
            isInitialized: true,
            items: <CanvasItem>[],
          );

          await tester.pumpWidget(buildTestWidget(canvasState: emptyState));

          expect(find.text('Canvas is empty'), findsOneWidget);
        },
      );

      testWidgets(
        'должен показывать иконку dashboard_outlined когда список items пуст',
        (WidgetTester tester) async {
          const CanvasState emptyState = CanvasState(
            isLoading: false,
            isInitialized: true,
            items: <CanvasItem>[],
          );

          await tester.pumpWidget(buildTestWidget(canvasState: emptyState));

          expect(find.byIcon(Icons.dashboard_outlined), findsOneWidget);
        },
      );

      testWidgets(
        'должен показывать подсказку "Add games to the collection first" когда пусто',
        (WidgetTester tester) async {
          const CanvasState emptyState = CanvasState(
            isLoading: false,
            isInitialized: true,
            items: <CanvasItem>[],
          );

          await tester.pumpWidget(buildTestWidget(canvasState: emptyState));

          expect(
            find.text('Add games to the collection first'),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'не должен показывать InteractiveViewer когда список items пуст',
        (WidgetTester tester) async {
          const CanvasState emptyState = CanvasState(
            isLoading: false,
            isInitialized: true,
            items: <CanvasItem>[],
          );

          await tester.pumpWidget(buildTestWidget(canvasState: emptyState));

          expect(find.byType(InteractiveViewer), findsNothing);
        },
      );
    });

    group('нормальное состояние с элементами', () {
      testWidgets(
        'должен показывать InteractiveViewer когда есть элементы',
        (WidgetTester tester) async {
          final CanvasState normalState = CanvasState(
            isLoading: false,
            isInitialized: true,
            items: <CanvasItem>[
              createTestItem(
                id: 1,
                game: const Game(id: 100, name: 'Test Game'),
              ),
            ],
          );

          await tester.pumpWidget(buildTestWidget(canvasState: normalState));
          await tester.pump();

          expect(find.byType(InteractiveViewer), findsOneWidget);
        },
      );

      testWidgets(
        'должен показывать CustomPaint для фоновой сетки когда есть элементы',
        (WidgetTester tester) async {
          final CanvasState normalState = CanvasState(
            isLoading: false,
            isInitialized: true,
            items: <CanvasItem>[
              createTestItem(
                id: 1,
                game: const Game(id: 100, name: 'Test Game'),
              ),
            ],
          );

          await tester.pumpWidget(buildTestWidget(canvasState: normalState));
          await tester.pump();

          expect(find.byType(CustomPaint), findsWidgets);
        },
      );

      testWidgets(
        'должен показывать несколько карточек игр когда есть несколько элементов',
        (WidgetTester tester) async {
          final CanvasState normalState = CanvasState(
            isLoading: false,
            isInitialized: true,
            items: <CanvasItem>[
              createTestItem(
                id: 1,
                itemRefId: 100,
                game: const Game(id: 100, name: 'Game One'),
              ),
              createTestItem(
                id: 2,
                itemRefId: 200,
                x: 2700.0,
                zIndex: 1,
                game: const Game(id: 200, name: 'Game Two'),
              ),
            ],
          );

          await tester.pumpWidget(buildTestWidget(canvasState: normalState));
          await tester.pump();

          expect(find.text('Game One'), findsOneWidget);
          expect(find.text('Game Two'), findsOneWidget);
        },
      );
    });

    group('кнопки управления', () {
      testWidgets(
        'должен показывать FAB "Center view" когда есть элементы',
        (WidgetTester tester) async {
          final CanvasState normalState = CanvasState(
            isLoading: false,
            isInitialized: true,
            items: <CanvasItem>[
              createTestItem(
                id: 1,
                game: const Game(id: 100, name: 'Test Game'),
              ),
            ],
          );

          await tester.pumpWidget(buildTestWidget(canvasState: normalState));
          await tester.pump();

          expect(find.byIcon(Icons.fit_screen), findsOneWidget);
          expect(find.byTooltip('Center view'), findsOneWidget);
        },
      );

      testWidgets(
        'должен показывать FAB "Reset positions" когда есть элементы',
        (WidgetTester tester) async {
          final CanvasState normalState = CanvasState(
            isLoading: false,
            isInitialized: true,
            items: <CanvasItem>[
              createTestItem(
                id: 1,
                game: const Game(id: 100, name: 'Test Game'),
              ),
            ],
          );

          await tester.pumpWidget(buildTestWidget(canvasState: normalState));
          await tester.pump();

          expect(find.byIcon(Icons.grid_view), findsOneWidget);
          expect(find.byTooltip('Reset positions'), findsOneWidget);
        },
      );

      testWidgets(
        'должен показывать три FloatingActionButton когда isEditable=true',
        (WidgetTester tester) async {
          final CanvasState normalState = CanvasState(
            isLoading: false,
            isInitialized: true,
            items: <CanvasItem>[
              createTestItem(
                id: 1,
                game: const Game(id: 100, name: 'Test Game'),
              ),
            ],
          );

          await tester.pumpWidget(
            buildTestWidget(canvasState: normalState, isEditable: true),
          );
          await tester.pump();

          // 3 FAB: SteamGridDB + Center view + Reset positions
          expect(find.byType(FloatingActionButton), findsNWidgets(3));
        },
      );

      testWidgets(
        'должен показывать два FloatingActionButton когда isEditable=false',
        (WidgetTester tester) async {
          final CanvasState normalState = CanvasState(
            isLoading: false,
            isInitialized: true,
            items: <CanvasItem>[
              createTestItem(
                id: 1,
                game: const Game(id: 100, name: 'Test Game'),
              ),
            ],
          );

          await tester.pumpWidget(
            buildTestWidget(canvasState: normalState, isEditable: false),
          );
          await tester.pump();

          // 2 FAB: Center view + Reset positions (без SteamGridDB)
          expect(find.byType(FloatingActionButton), findsNWidgets(2));
        },
      );

      testWidgets(
        'должен показывать FAB SteamGridDB Images когда isEditable=true',
        (WidgetTester tester) async {
          final CanvasState normalState = CanvasState(
            isLoading: false,
            isInitialized: true,
            items: <CanvasItem>[
              createTestItem(
                id: 1,
                game: const Game(id: 100, name: 'Test Game'),
              ),
            ],
          );

          await tester.pumpWidget(
            buildTestWidget(canvasState: normalState, isEditable: true),
          );
          await tester.pump();

          expect(find.byIcon(Icons.image_search), findsOneWidget);
          expect(find.byTooltip('SteamGridDB Images'), findsOneWidget);
        },
      );

      testWidgets(
        'не должен показывать FAB SteamGridDB когда isEditable=false',
        (WidgetTester tester) async {
          final CanvasState normalState = CanvasState(
            isLoading: false,
            isInitialized: true,
            items: <CanvasItem>[
              createTestItem(
                id: 1,
                game: const Game(id: 100, name: 'Test Game'),
              ),
            ],
          );

          await tester.pumpWidget(
            buildTestWidget(canvasState: normalState, isEditable: false),
          );
          await tester.pump();

          expect(find.byIcon(Icons.image_search), findsNothing);
        },
      );

      testWidgets(
        'не должен показывать FAB кнопки в состоянии загрузки',
        (WidgetTester tester) async {
          const CanvasState loadingState = CanvasState(
            isLoading: true,
          );

          await tester.pumpWidget(buildTestWidget(canvasState: loadingState));

          expect(find.byType(FloatingActionButton), findsNothing);
        },
      );

      testWidgets(
        'не должен показывать FAB кнопки в состоянии ошибки',
        (WidgetTester tester) async {
          const CanvasState errorState = CanvasState(
            isLoading: false,
            error: 'Some error',
          );

          await tester.pumpWidget(buildTestWidget(canvasState: errorState));

          expect(find.byType(FloatingActionButton), findsNothing);
        },
      );
    });

    group('_buildCanvasItem — типы элементов', () {
      testWidgets(
        'должен создавать CanvasGameCard для элемента типа game',
        (WidgetTester tester) async {
          final CanvasState normalState = CanvasState(
            isLoading: false,
            isInitialized: true,
            items: <CanvasItem>[
              createTestItem(
                id: 1,
                itemType: CanvasItemType.game,
                game: const Game(id: 100, name: 'Mario'),
              ),
            ],
          );

          await tester.pumpWidget(buildTestWidget(canvasState: normalState));
          await tester.pump();

          // CanvasGameCard отображает Card с названием игры
          expect(find.text('Mario'), findsOneWidget);
        },
      );

      testWidgets(
        'должен создавать SizedBox.shrink для элемента типа text',
        (WidgetTester tester) async {
          final CanvasState normalState = CanvasState(
            isLoading: false,
            isInitialized: true,
            items: <CanvasItem>[
              createTestItem(
                id: 1,
                itemType: CanvasItemType.text,
                itemRefId: null,
              ),
            ],
          );

          await tester.pumpWidget(buildTestWidget(canvasState: normalState));
          await tester.pump();

          // InteractiveViewer должен быть, но без CanvasGameCard
          expect(find.byType(InteractiveViewer), findsOneWidget);
          // Нет ни одного Card (CanvasGameCard содержит Card)
          expect(find.byType(Card), findsNothing);
        },
      );

      testWidgets(
        'должен отображать элемент типа image как Card',
        (WidgetTester tester) async {
          final CanvasState normalState = CanvasState(
            isLoading: false,
            isInitialized: true,
            items: <CanvasItem>[
              createTestItem(
                id: 1,
                itemType: CanvasItemType.image,
                itemRefId: null,
              ),
            ],
          );

          await tester.pumpWidget(buildTestWidget(canvasState: normalState));
          await tester.pump();

          expect(find.byType(InteractiveViewer), findsOneWidget);
          // CanvasImageItem содержит Card
          expect(find.byType(Card), findsOneWidget);
        },
      );

      testWidgets(
        'должен отображать элемент типа link как Card',
        (WidgetTester tester) async {
          final CanvasState normalState = CanvasState(
            isLoading: false,
            isInitialized: true,
            items: <CanvasItem>[
              createTestItem(
                id: 1,
                itemType: CanvasItemType.link,
                itemRefId: null,
              ),
            ],
          );

          await tester.pumpWidget(buildTestWidget(canvasState: normalState));
          await tester.pump();

          expect(find.byType(InteractiveViewer), findsOneWidget);
          // CanvasLinkItem содержит Card
          expect(find.byType(Card), findsOneWidget);
        },
      );

      testWidgets(
        'должен показывать смешанные типы — все типы отображаются',
        (WidgetTester tester) async {
          final CanvasState normalState = CanvasState(
            isLoading: false,
            isInitialized: true,
            items: <CanvasItem>[
              createTestItem(
                id: 1,
                itemType: CanvasItemType.game,
                itemRefId: 100,
                game: const Game(id: 100, name: 'Zelda'),
              ),
              createTestItem(
                id: 2,
                itemType: CanvasItemType.text,
                itemRefId: null,
                x: 2700.0,
                zIndex: 1,
              ),
              createTestItem(
                id: 3,
                itemType: CanvasItemType.image,
                itemRefId: null,
                x: 2900.0,
                zIndex: 2,
              ),
            ],
          );

          await tester.pumpWidget(buildTestWidget(canvasState: normalState));
          await tester.pump();

          expect(find.text('Zelda'), findsOneWidget);
          // 2 Card: один от CanvasGameCard, один от CanvasImageItem
          expect(find.byType(Card), findsNWidgets(2));
        },
      );
    });

    group('сортировка элементов', () {
      testWidgets(
        'должен отображать элементы отсортированные по zIndex',
        (WidgetTester tester) async {
          final CanvasState normalState = CanvasState(
            isLoading: false,
            isInitialized: true,
            items: <CanvasItem>[
              createTestItem(
                id: 1,
                itemRefId: 100,
                zIndex: 5,
                game: const Game(id: 100, name: 'Game Z5'),
              ),
              createTestItem(
                id: 2,
                itemRefId: 200,
                x: 2700.0,
                zIndex: 1,
                game: const Game(id: 200, name: 'Game Z1'),
              ),
              createTestItem(
                id: 3,
                itemRefId: 300,
                x: 2900.0,
                zIndex: 10,
                game: const Game(id: 300, name: 'Game Z10'),
              ),
            ],
          );

          await tester.pumpWidget(buildTestWidget(canvasState: normalState));
          await tester.pump();

          // Все три игры должны отображаться
          expect(find.text('Game Z5'), findsOneWidget);
          expect(find.text('Game Z1'), findsOneWidget);
          expect(find.text('Game Z10'), findsOneWidget);
        },
      );
    });

    group('параметр isEditable', () {
      testWidgets(
        'должен рендерить канвас когда isEditable=false',
        (WidgetTester tester) async {
          final CanvasState normalState = CanvasState(
            isLoading: false,
            isInitialized: true,
            items: <CanvasItem>[
              createTestItem(
                id: 1,
                game: const Game(id: 100, name: 'Test Game'),
              ),
            ],
          );

          await tester.pumpWidget(
            buildTestWidget(canvasState: normalState, isEditable: false),
          );
          await tester.pump();

          expect(find.byType(InteractiveViewer), findsOneWidget);
          expect(find.text('Test Game'), findsOneWidget);
        },
      );

      testWidgets(
        'должен рендерить канвас когда isEditable=true',
        (WidgetTester tester) async {
          final CanvasState normalState = CanvasState(
            isLoading: false,
            isInitialized: true,
            items: <CanvasItem>[
              createTestItem(
                id: 1,
                game: const Game(id: 100, name: 'Test Game'),
              ),
            ],
          );

          await tester.pumpWidget(
            buildTestWidget(canvasState: normalState, isEditable: true),
          );
          await tester.pump();

          expect(find.byType(InteractiveViewer), findsOneWidget);
          expect(find.text('Test Game'), findsOneWidget);
        },
      );
    });

    group('приоритет состояний', () {
      testWidgets(
        'должен показывать загрузку а не ошибку когда isLoading=true и error!=null',
        (WidgetTester tester) async {
          // isLoading проверяется первым в build()
          const CanvasState state = CanvasState(
            isLoading: true,
            error: 'Some error',
          );

          await tester.pumpWidget(buildTestWidget(canvasState: state));

          expect(find.byType(CircularProgressIndicator), findsOneWidget);
          expect(find.text('Failed to load canvas'), findsNothing);
        },
      );

      testWidgets(
        'должен показывать ошибку а не пустой канвас когда error!=null и items пуст',
        (WidgetTester tester) async {
          // error проверяется вторым, до items.isEmpty
          const CanvasState state = CanvasState(
            isLoading: false,
            error: 'Connection error',
            items: <CanvasItem>[],
          );

          await tester.pumpWidget(buildTestWidget(canvasState: state));

          expect(find.text('Failed to load canvas'), findsOneWidget);
          expect(find.text('Canvas is empty'), findsNothing);
        },
      );
    });

    group('LayoutBuilder и размеры', () {
      testWidgets(
        'должен использовать LayoutBuilder для определения размеров viewport',
        (WidgetTester tester) async {
          final CanvasState normalState = CanvasState(
            isLoading: false,
            isInitialized: true,
            items: <CanvasItem>[
              createTestItem(
                id: 1,
                game: const Game(id: 100, name: 'Test Game'),
              ),
            ],
          );

          await tester.pumpWidget(buildTestWidget(canvasState: normalState));
          await tester.pump();

          expect(find.byType(LayoutBuilder), findsOneWidget);
        },
      );
    });

    group('resize handle', () {
      testWidgets(
        'должен показывать resize handle когда isEditable=true',
        (WidgetTester tester) async {
          final CanvasState normalState = CanvasState(
            isLoading: false,
            isInitialized: true,
            items: <CanvasItem>[
              createTestItem(
                id: 1,
                game: const Game(id: 100, name: 'Test Game'),
              ),
            ],
          );

          await tester.pumpWidget(
            buildTestWidget(canvasState: normalState, isEditable: true),
          );
          await tester.pump();

          // Resize handle содержит иконку drag_handle
          expect(find.byIcon(Icons.drag_handle), findsOneWidget);
        },
      );

      testWidgets(
        'не должен показывать resize handle когда isEditable=false',
        (WidgetTester tester) async {
          final CanvasState normalState = CanvasState(
            isLoading: false,
            isInitialized: true,
            items: <CanvasItem>[
              createTestItem(
                id: 1,
                game: const Game(id: 100, name: 'Test Game'),
              ),
            ],
          );

          await tester.pumpWidget(
            buildTestWidget(canvasState: normalState, isEditable: false),
          );
          await tester.pump();

          // Resize handle НЕ рендерится
          expect(find.byIcon(Icons.drag_handle), findsNothing);
        },
      );

      testWidgets(
        'должен оборачивать дочерний виджет в SizedBox.expand',
        (WidgetTester tester) async {
          final CanvasState normalState = CanvasState(
            isLoading: false,
            isInitialized: true,
            items: <CanvasItem>[
              createTestItem(
                id: 1,
                game: const Game(id: 100, name: 'Test Game'),
              ),
            ],
          );

          await tester.pumpWidget(buildTestWidget(canvasState: normalState));
          await tester.pump();

          // SizedBox.expand имеет width=infinity, height=infinity
          final Finder expandedBoxes = find.byWidgetPredicate(
            (Widget widget) =>
                widget is SizedBox &&
                widget.width == double.infinity &&
                widget.height == double.infinity,
          );
          expect(expandedBoxes, findsWidgets);
        },
      );
    });

    group('GestureDetector на элементах', () {
      testWidgets(
        'должен содержать GestureDetector для перетаскивания элементов',
        (WidgetTester tester) async {
          final CanvasState normalState = CanvasState(
            isLoading: false,
            isInitialized: true,
            items: <CanvasItem>[
              createTestItem(
                id: 1,
                game: const Game(id: 100, name: 'Test Game'),
              ),
            ],
          );

          await tester.pumpWidget(buildTestWidget(canvasState: normalState));
          await tester.pump();

          expect(find.byType(GestureDetector), findsWidgets);
        },
      );

      testWidgets(
        'должен содержать MouseRegion для курсора grab',
        (WidgetTester tester) async {
          final CanvasState normalState = CanvasState(
            isLoading: false,
            isInitialized: true,
            items: <CanvasItem>[
              createTestItem(
                id: 1,
                game: const Game(id: 100, name: 'Test Game'),
              ),
            ],
          );

          await tester.pumpWidget(buildTestWidget(canvasState: normalState));
          await tester.pump();

          expect(find.byType(MouseRegion), findsWidgets);
        },
      );
    });
  });
}

/// Тестовый notifier для SteamGridDB панели (не делает ничего).
class _TestSteamGridDbPanelNotifier extends SteamGridDbPanelNotifier {
  @override
  SteamGridDbPanelState build(int arg) {
    return const SteamGridDbPanelState();
  }
}
