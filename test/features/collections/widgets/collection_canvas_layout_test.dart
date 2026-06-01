import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/collections/providers/canvas_provider.dart';
import 'package:tonkatsu_box/features/collections/providers/steamgriddb_panel_provider.dart';
import 'package:tonkatsu_box/features/collections/providers/vgmaps_panel_provider.dart';
import 'package:tonkatsu_box/features/collections/widgets/canvas_view.dart';
import 'package:tonkatsu_box/features/collections/widgets/collection_canvas_layout.dart';
import 'package:tonkatsu_box/features/collections/widgets/steamgriddb_panel.dart';
import 'package:tonkatsu_box/features/settings/providers/settings_provider.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';
import 'package:tonkatsu_box/shared/models/steamgriddb_image.dart';

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

class _TestSteamGridDbPanelNotifier extends SteamGridDbPanelNotifier {
  _TestSteamGridDbPanelNotifier(this._initialState);

  final SteamGridDbPanelState _initialState;

  @override
  SteamGridDbPanelState build(int? arg) {
    return _initialState;
  }
}

class _TestVgMapsPanelNotifier extends VgMapsPanelNotifier {
  _TestVgMapsPanelNotifier(this._initialState);

  final VgMapsPanelState _initialState;

  @override
  VgMapsPanelState build(int? arg) {
    return _initialState;
  }
}

// SteamGridDbPanel requires SettingsNotifier in scope.
class _FakeSettingsNotifier extends SettingsNotifier {
  @override
  SettingsState build() {
    return const SettingsState();
  }
}

void main() {
  const int testCollectionId = 42;
  const String testCollectionName = 'SNES Classics';

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
        'should hide SteamGridDB панель когда isOpen=false',
        (WidgetTester tester) async {
          await tester.pumpWidget(buildTestWidget(
            steamGridDbState: const SteamGridDbPanelState(isOpen: false),
          ));

          expect(find.byType(SteamGridDbPanel), findsNothing);
        },
      );

      testWidgets(
        'should use ширину 0 для AnimatedContainer SteamGridDB когда закрыта',
        (WidgetTester tester) async {
          await tester.pumpWidget(buildTestWidget(
            steamGridDbState: const SteamGridDbPanelState(isOpen: false),
          ));

          final Finder animatedContainers =
              find.byType(AnimatedContainer);
          expect(animatedContainers, findsAtLeast(1));

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
        'should show SizedBox.shrink вместо SteamGridDbPanel когда закрыта',
        (WidgetTester tester) async {
          await tester.pumpWidget(buildTestWidget(
            steamGridDbState: const SteamGridDbPanelState(isOpen: false),
          ));

          expect(find.byType(SteamGridDbPanel), findsNothing);
        },
      );
    });

    group('SteamGridDB панель открыта', () {
      testWidgets(
        'should show SteamGridDbPanel когда isOpen=true',
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
        'should use AnimatedContainer с шириной 320 для SteamGridDB',
        (WidgetTester tester) async {
          await tester.pumpWidget(buildTestWidget(
            steamGridDbState: const SteamGridDbPanelState(isOpen: true),
          ));
          await tester.pumpAndSettle();

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
        'should use OverflowBox с maxWidth=320 для SteamGridDB',
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
        'should call onAddSteamGridDbImage при добавлении',
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

          final SteamGridDbPanel panel = tester.widget<SteamGridDbPanel>(
            find.byType(SteamGridDbPanel),
          );
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
        'should use Clip.hardEdge на AnimatedContainer',
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
        'should use длительность анимации 200мс',
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
        'should use Curves.easeInOut для анимации',
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
