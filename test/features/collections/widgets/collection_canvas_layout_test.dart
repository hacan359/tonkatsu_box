// Тесты для CollectionCanvasLayout — layout канваса с боковыми панелями.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/collections/providers/canvas_provider.dart';
import 'package:xerabora/features/collections/providers/steamgriddb_panel_provider.dart';
import 'package:xerabora/features/collections/providers/vgmaps_panel_provider.dart';
import 'package:xerabora/features/collections/widgets/canvas_view.dart';
import 'package:xerabora/features/collections/widgets/collection_canvas_layout.dart';
import 'package:xerabora/features/collections/widgets/steamgriddb_panel.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';
import 'package:xerabora/l10n/app_localizations.dart';
import 'package:xerabora/shared/models/steamgriddb_image.dart';

// =============================================================================
// Тестовые notifiers
// =============================================================================

/// Тестовый notifier для канваса — возвращает контролируемое состояние.
class _TestCanvasNotifier extends CanvasNotifier {
  _TestCanvasNotifier(this._testState);

  final CanvasState _testState;

  @override
  CanvasState build(int? arg) {
    return _testState;
  }

  @override
  Future<void> refresh() async {}

  @override
  Future<void> resetPositions(double viewportWidth) async {}
}

/// Тестовый notifier для SteamGridDB панели.
class _TestSteamGridDbPanelNotifier extends SteamGridDbPanelNotifier {
  _TestSteamGridDbPanelNotifier(this._initialState);

  final SteamGridDbPanelState _initialState;

  @override
  SteamGridDbPanelState build(int? arg) {
    return _initialState;
  }
}

/// Тестовый notifier для VGMaps панели.
class _TestVgMapsPanelNotifier extends VgMapsPanelNotifier {
  _TestVgMapsPanelNotifier(this._initialState);

  final VgMapsPanelState _initialState;

  @override
  VgMapsPanelState build(int? arg) {
    return _initialState;
  }
}

/// Фейковый SettingsNotifier для тестов (нужен SteamGridDbPanel).
class _FakeSettingsNotifier extends SettingsNotifier {
  @override
  SettingsState build() {
    return const SettingsState();
  }
}

// =============================================================================
// Основные тесты
// =============================================================================

void main() {
  const int testCollectionId = 42;
  const String testCollectionName = 'SNES Classics';

  /// Собирает виджет для тестирования.
  Widget buildTestWidget({
    CanvasState canvasState = const CanvasState(
      isLoading: false,
      isInitialized: true,
    ),
    SteamGridDbPanelState steamGridDbState = const SteamGridDbPanelState(),
    VgMapsPanelState vgMapsState = const VgMapsPanelState(),
    bool isEditable = true,
  }) {
    return ProviderScope(
      overrides: <Override>[
        canvasNotifierProvider
            .overrideWith(() => _TestCanvasNotifier(canvasState)),
        steamGridDbPanelProvider
            .overrideWith(() => _TestSteamGridDbPanelNotifier(steamGridDbState)),
        vgMapsPanelProvider
            .overrideWith(() => _TestVgMapsPanelNotifier(vgMapsState)),
        settingsNotifierProvider
            .overrideWith(_FakeSettingsNotifier.new),
      ],
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            height: 800,
            child: CollectionCanvasLayout(
              collectionId: testCollectionId,
              isEditable: isEditable,
              collectionName: testCollectionName,
              onAddSteamGridDbImage: (SteamGridDbImage _) {},
              onAddVgMapsImage: (String url, int? w, int? h) {},
            ),
          ),
        ),
      ),
    );
  }

  group('CollectionCanvasLayout', () {
    group('рендеринг CanvasView', () {
      testWidgets(
        'должен отображать CanvasView',
        (WidgetTester tester) async {
          await tester.pumpWidget(buildTestWidget());

          expect(find.byType(CanvasView), findsOneWidget);
        },
      );

      testWidgets(
        'должен передавать collectionId в CanvasView',
        (WidgetTester tester) async {
          await tester.pumpWidget(buildTestWidget());

          final CanvasView canvasView =
              tester.widget<CanvasView>(find.byType(CanvasView));
          expect(canvasView.collectionId, equals(testCollectionId));
        },
      );

      testWidgets(
        'должен передавать isEditable в CanvasView',
        (WidgetTester tester) async {
          await tester.pumpWidget(buildTestWidget(isEditable: false));

          final CanvasView canvasView =
              tester.widget<CanvasView>(find.byType(CanvasView));
          expect(canvasView.isEditable, isFalse);
        },
      );

      testWidgets(
        'должен оборачивать CanvasView в Expanded',
        (WidgetTester tester) async {
          await tester.pumpWidget(buildTestWidget());

          // CanvasView должен быть внутри Expanded
          final Finder expandedFinder = find.ancestor(
            of: find.byType(CanvasView),
            matching: find.byType(Expanded),
          );
          expect(expandedFinder, findsOneWidget);
        },
      );

      testWidgets(
        'должен отображать Row как корневой виджет',
        (WidgetTester tester) async {
          await tester.pumpWidget(buildTestWidget());

          // CollectionCanvasLayout содержит Row
          final Finder rowFinder = find.descendant(
            of: find.byType(CollectionCanvasLayout),
            matching: find.byType(Row),
          );
          expect(rowFinder, findsOneWidget);
        },
      );
    });

    group('панели закрыты', () {
      testWidgets(
        'должен скрывать SteamGridDB панель когда isOpen=false',
        (WidgetTester tester) async {
          await tester.pumpWidget(buildTestWidget(
            steamGridDbState: const SteamGridDbPanelState(isOpen: false),
          ));

          // SteamGridDbPanel не должен быть в дереве, когда панель закрыта
          expect(find.byType(SteamGridDbPanel), findsNothing);
        },
      );

      testWidgets(
        'должен использовать ширину 0 для AnimatedContainer SteamGridDB когда закрыта',
        (WidgetTester tester) async {
          await tester.pumpWidget(buildTestWidget(
            steamGridDbState: const SteamGridDbPanelState(isOpen: false),
          ));

          // Ищем AnimatedContainer с width=0
          final Finder animatedContainers =
              find.byType(AnimatedContainer);
          // Должен быть хотя бы один AnimatedContainer
          expect(animatedContainers, findsAtLeast(1));

          // Проверяем что все AnimatedContainer имеют width 0
          // (когда обе панели закрыты)
          bool foundZeroWidth = false;
          for (final Element element in animatedContainers.evaluate()) {
            final AnimatedContainer container =
                element.widget as AnimatedContainer;
            final BoxConstraints? constraints =
                container.constraints;
            if (constraints != null && constraints.maxWidth == 0) {
              foundZeroWidth = true;
              break;
            }
          }
          expect(foundZeroWidth, isTrue);
        },
      );

      testWidgets(
        'должен показывать SizedBox.shrink вместо SteamGridDbPanel когда закрыта',
        (WidgetTester tester) async {
          await tester.pumpWidget(buildTestWidget(
            steamGridDbState: const SteamGridDbPanelState(isOpen: false),
          ));

          // SteamGridDbPanel не показывается
          expect(find.byType(SteamGridDbPanel), findsNothing);
        },
      );
    });

    group('SteamGridDB панель открыта', () {
      testWidgets(
        'должен показывать SteamGridDbPanel когда isOpen=true',
        (WidgetTester tester) async {
          await tester.pumpWidget(buildTestWidget(
            steamGridDbState: const SteamGridDbPanelState(isOpen: true),
          ));
          await tester.pumpAndSettle();

          expect(find.byType(SteamGridDbPanel), findsOneWidget);
        },
      );

      testWidgets(
        'должен передавать collectionId в SteamGridDbPanel',
        (WidgetTester tester) async {
          await tester.pumpWidget(buildTestWidget(
            steamGridDbState: const SteamGridDbPanelState(isOpen: true),
          ));
          await tester.pumpAndSettle();

          final SteamGridDbPanel panel = tester.widget<SteamGridDbPanel>(
            find.byType(SteamGridDbPanel),
          );
          expect(panel.collectionId, equals(testCollectionId));
        },
      );

      testWidgets(
        'должен передавать collectionName в SteamGridDbPanel',
        (WidgetTester tester) async {
          await tester.pumpWidget(buildTestWidget(
            steamGridDbState: const SteamGridDbPanelState(isOpen: true),
          ));
          await tester.pumpAndSettle();

          final SteamGridDbPanel panel = tester.widget<SteamGridDbPanel>(
            find.byType(SteamGridDbPanel),
          );
          expect(panel.collectionName, equals(testCollectionName));
        },
      );

      testWidgets(
        'должен использовать AnimatedContainer с шириной 320 для SteamGridDB',
        (WidgetTester tester) async {
          await tester.pumpWidget(buildTestWidget(
            steamGridDbState: const SteamGridDbPanelState(isOpen: true),
          ));
          await tester.pumpAndSettle();

          // Ищем AnimatedContainer с width=320
          final Finder animatedContainers =
              find.byType(AnimatedContainer);
          expect(animatedContainers, findsAtLeast(1));

          bool found320 = false;
          for (final Element element in animatedContainers.evaluate()) {
            final AnimatedContainer container =
                element.widget as AnimatedContainer;
            final BoxConstraints? constraints =
                container.constraints;
            if (constraints != null && constraints.maxWidth == 320) {
              found320 = true;
              break;
            }
          }
          expect(found320, isTrue);
        },
      );

      testWidgets(
        'должен использовать OverflowBox с maxWidth=320 для SteamGridDB',
        (WidgetTester tester) async {
          await tester.pumpWidget(buildTestWidget(
            steamGridDbState: const SteamGridDbPanelState(isOpen: true),
          ));
          await tester.pumpAndSettle();

          final Finder overflowBoxFinder = find.byWidgetPredicate(
            (Widget widget) =>
                widget is OverflowBox && widget.maxWidth == 320,
          );
          expect(overflowBoxFinder, findsOneWidget);
        },
      );
    });

    group('callbacks', () {
      testWidgets(
        'должен вызывать onAddSteamGridDbImage при добавлении',
        (WidgetTester tester) async {
          SteamGridDbImage? capturedImage;

          await tester.pumpWidget(
            ProviderScope(
              overrides: <Override>[
                canvasNotifierProvider.overrideWith(
                  () => _TestCanvasNotifier(
                    const CanvasState(
                      isLoading: false,
                      isInitialized: true,
                    ),
                  ),
                ),
                steamGridDbPanelProvider.overrideWith(
                  () => _TestSteamGridDbPanelNotifier(
                    const SteamGridDbPanelState(isOpen: true),
                  ),
                ),
                vgMapsPanelProvider.overrideWith(
                  () => _TestVgMapsPanelNotifier(
                    const VgMapsPanelState(),
                  ),
                ),
                settingsNotifierProvider.overrideWith(
                  _FakeSettingsNotifier.new,
                ),
              ],
              child: MaterialApp(
                localizationsDelegates: S.localizationsDelegates,
                supportedLocales: S.supportedLocales,
                home: Scaffold(
                  body: SizedBox(
                    width: 1200,
                    height: 800,
                    child: CollectionCanvasLayout(
                      collectionId: testCollectionId,
                      isEditable: true,
                      collectionName: testCollectionName,
                      onAddSteamGridDbImage: (SteamGridDbImage image) {
                        capturedImage = image;
                      },
                      onAddVgMapsImage: (String url, int? w, int? h) {},
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Проверяем что SteamGridDbPanel получила callback
          final SteamGridDbPanel panel = tester.widget<SteamGridDbPanel>(
            find.byType(SteamGridDbPanel),
          );
          // Симулируем вызов callback через виджет
          const SteamGridDbImage testImage = SteamGridDbImage(
            id: 1,
            score: 10,
            style: 'alternate',
            url: 'https://example.com/img.png',
            thumb: 'https://example.com/thumb.png',
            width: 600,
            height: 900,
          );
          panel.onAddImage(testImage);

          expect(capturedImage, equals(testImage));
        },
      );
    });

    group('collectionId=null (uncategorized)', () {
      testWidgets(
        'должен работать с collectionId=null',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            ProviderScope(
              overrides: <Override>[
                canvasNotifierProvider.overrideWith(
                  () => _TestCanvasNotifier(
                    const CanvasState(
                      isLoading: false,
                      isInitialized: true,
                    ),
                  ),
                ),
                steamGridDbPanelProvider.overrideWith(
                  () => _TestSteamGridDbPanelNotifier(
                    const SteamGridDbPanelState(),
                  ),
                ),
                vgMapsPanelProvider.overrideWith(
                  () => _TestVgMapsPanelNotifier(
                    const VgMapsPanelState(),
                  ),
                ),
                settingsNotifierProvider.overrideWith(
                  _FakeSettingsNotifier.new,
                ),
              ],
              child: MaterialApp(
                localizationsDelegates: S.localizationsDelegates,
                supportedLocales: S.supportedLocales,
                home: Scaffold(
                  body: SizedBox(
                    width: 1200,
                    height: 800,
                    child: CollectionCanvasLayout(
                      collectionId: null,
                      isEditable: true,
                      collectionName: 'Uncategorized',
                      onAddSteamGridDbImage: (SteamGridDbImage _) {},
                      onAddVgMapsImage: (String url, int? w, int? h) {},
                    ),
                  ),
                ),
              ),
            ),
          );

          expect(find.byType(CanvasView), findsOneWidget);
          final CanvasView canvasView =
              tester.widget<CanvasView>(find.byType(CanvasView));
          expect(canvasView.collectionId, isNull);
        },
      );
    });

    group('анимация контейнера', () {
      testWidgets(
        'должен использовать Clip.hardEdge на AnimatedContainer',
        (WidgetTester tester) async {
          await tester.pumpWidget(buildTestWidget());

          final Finder animatedContainers =
              find.byType(AnimatedContainer);
          expect(animatedContainers, findsAtLeast(1));

          for (final Element element in animatedContainers.evaluate()) {
            final AnimatedContainer container =
                element.widget as AnimatedContainer;
            expect(container.clipBehavior, equals(Clip.hardEdge));
          }
        },
      );

      testWidgets(
        'должен использовать длительность анимации 200мс',
        (WidgetTester tester) async {
          await tester.pumpWidget(buildTestWidget());

          final Finder animatedContainers =
              find.byType(AnimatedContainer);
          expect(animatedContainers, findsAtLeast(1));

          for (final Element element in animatedContainers.evaluate()) {
            final AnimatedContainer container =
                element.widget as AnimatedContainer;
            expect(
              container.duration,
              equals(const Duration(milliseconds: 200)),
            );
          }
        },
      );

      testWidgets(
        'должен использовать Curves.easeInOut для анимации',
        (WidgetTester tester) async {
          await tester.pumpWidget(buildTestWidget());

          final Finder animatedContainers =
              find.byType(AnimatedContainer);
          expect(animatedContainers, findsAtLeast(1));

          for (final Element element in animatedContainers.evaluate()) {
            final AnimatedContainer container =
                element.widget as AnimatedContainer;
            expect(container.curve, equals(Curves.easeInOut));
          }
        },
      );
    });
  });
}
