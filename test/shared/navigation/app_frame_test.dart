import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/navigation/app_frame.dart';
import 'package:tonkatsu_box/shared/navigation/frame_chrome.dart';
import 'package:tonkatsu_box/shared/navigation/frame_inset.dart';
import 'package:tonkatsu_box/shared/theme/app_surface.dart';
import 'package:tonkatsu_box/shared/widgets/glass_panel.dart';

import '../../helpers/test_helpers.dart';

class _Probe extends StatefulWidget {
  const _Probe({super.key});

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  Widget build(BuildContext context) => const Text('probe');
}

void main() {
  group('AppFrame', () {
    Widget frame({required bool compact, required Key probeKey}) => AppFrame(
      compact: compact,
      topZone: const Text('top'),
      menuZone: const Text('menu'),
      child: _Probe(key: probeKey),
    );

    testWidgets('рисует зоны и контент', (WidgetTester tester) async {
      await tester.pumpApp(frame(compact: false, probeKey: GlobalKey()));

      expect(find.text('top'), findsOneWidget);
      expect(find.text('menu'), findsOneWidget);
      expect(find.text('probe'), findsOneWidget);
      // Glass pages lie on the picture: only the search row and rail.
      expect(find.byType(GlassPanel), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('should back the content with a panel on classic', (
      WidgetTester tester,
    ) async {
      AppSurface.skin = AppSkin.classic;
      addTearDown(() => AppSurface.skin = AppSkin.glass);

      await tester.pumpApp(frame(compact: false, probeKey: GlobalKey()));

      expect(find.byType(GlassPanel), findsNWidgets(3));
      expect(find.text('probe'), findsOneWidget);
    });

    testWidgets('смена compact/wide сохраняет элемент контента', (
      WidgetTester tester,
    ) async {
      final GlobalKey<_ProbeState> key = GlobalKey<_ProbeState>();
      await tester.pumpApp(frame(compact: false, probeKey: key));
      final _ProbeState? before = key.currentState;
      expect(before, isNotNull);

      await tester.pumpApp(frame(compact: true, probeKey: key));

      expect(key.currentState, same(before));
      expect(tester.takeException(), isNull);
    });

    testWidgets('контент получает нулевой MediaQuery.padding', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        MediaQuery(
          data: const MediaQueryData(padding: EdgeInsets.all(20)),
          child: AppFrame(
            compact: true,
            topZone: const SizedBox(),
            menuZone: const SizedBox(),
            child: Builder(
              builder: (BuildContext context) =>
                  Text('${MediaQuery.paddingOf(context)}'),
            ),
          ),
        ),
      );

      expect(find.text('${EdgeInsets.zero}'), findsOneWidget);
    });

    group('floating bars', () {
      tearDown(() => AppSurface.skin = AppSkin.glass);

      Future<EdgeInsets> barInsets(
        WidgetTester tester, {
        required bool compact,
      }) async {
        late EdgeInsets result;
        await tester.pumpApp(
          AppFrame(
            compact: compact,
            topZone: const Text('top'),
            menuZone: const Text('menu'),
            child: Builder(
              builder: (BuildContext context) {
                result = FrameBarInsets.of(context);
                return const SizedBox.expand();
              },
            ),
          ),
        );
        return result;
      }

      testWidgets('should tell a phone page how much the bars cover', (
        WidgetTester tester,
      ) async {
        final EdgeInsets insets = await barInsets(tester, compact: true);

        expect(insets.top, greaterThan(0));
        expect(insets.bottom, greaterThan(0));
        expect(find.text('top'), findsOneWidget);
        expect(find.text('menu'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should cover nothing on a wide window', (
        WidgetTester tester,
      ) async {
        expect(await barInsets(tester, compact: false), EdgeInsets.zero);
      });

      testWidgets('should cover nothing when the skin keeps bands', (
        WidgetTester tester,
      ) async {
        AppSurface.skin = AppSkin.classic;

        expect(await barInsets(tester, compact: true), EdgeInsets.zero);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should draw a lent strip and grow the top inset by it', (
        WidgetTester tester,
      ) async {
        final EdgeInsets bare = await barInsets(tester, compact: true);
        final FrameChromeController controller = FrameChromeController();
        addTearDown(controller.dispose);
        controller.set(
          Object(),
          const FrameChrome(below: SizedBox(height: 40, child: Text('lent'))),
        );
        late EdgeInsets withStrip;

        await tester.pumpApp(
          FrameChromeScope(
            controller: controller,
            child: AppFrame(
              compact: true,
              topZone: const Text('top'),
              menuZone: const Text('menu'),
              child: Builder(
                builder: (BuildContext context) {
                  withStrip = FrameBarInsets.of(context);
                  return const SizedBox.expand();
                },
              ),
            ),
          ),
        );

        expect(find.text('lent'), findsOneWidget);
        expect(withStrip.top, greaterThan(bare.top));
      });

      group('lent strip folding', () {
        late FrameChromeController controller;
        late EdgeInsets insets;

        setUp(() {
          controller = FrameChromeController();
          controller.set(
            Object(),
            const FrameChrome(below: SizedBox(height: 40, child: Text('lent'))),
          );
        });

        tearDown(() => controller.dispose());

        Widget rows(int count) => ListView.builder(
          itemCount: count,
          itemBuilder: (BuildContext context, int i) =>
              SizedBox(height: 60, child: Text('row $i')),
        );

        Future<void> pumpScrollingPage(
          WidgetTester tester, {
          WidgetBuilder? page,
        }) async {
          await tester.pumpApp(
            FrameChromeScope(
              controller: controller,
              child: AppFrame(
                compact: true,
                topZone: const Text('top'),
                menuZone: const Text('menu'),
                child: Builder(
                  builder: (BuildContext context) {
                    insets = FrameBarInsets.of(context);
                    return page?.call(context) ?? rows(100);
                  },
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
        }

        Finder lent() => find.text('lent').hitTestable();

        testWidgets('should fold the strip when the page scrolls down', (
          WidgetTester tester,
        ) async {
          await pumpScrollingPage(tester);
          final EdgeInsets unfolded = insets;

          await tester.drag(find.byType(ListView), const Offset(0, -400));
          await tester.pumpAndSettle();

          expect(lent(), findsNothing);
          // Pages keep the room, so the list does not jump under the finger.
          expect(insets, unfolded);
          expect(find.text('top').hitTestable(), findsOneWidget);
        });

        testWidgets('should bring the strip back when the page scrolls up', (
          WidgetTester tester,
        ) async {
          await pumpScrollingPage(tester);
          await tester.drag(find.byType(ListView), const Offset(0, -600));
          await tester.pumpAndSettle();

          await tester.drag(find.byType(ListView), const Offset(0, 100));
          await tester.pumpAndSettle();

          expect(lent(), findsOneWidget);
        });

        testWidgets('should ignore a jitter shorter than the threshold', (
          WidgetTester tester,
        ) async {
          await pumpScrollingPage(tester);
          await tester.drag(find.byType(ListView), const Offset(0, -400));
          await tester.pumpAndSettle();

          await tester.drag(find.byType(ListView), const Offset(0, 10));
          await tester.pumpAndSettle();

          expect(lent(), findsNothing);
        });

        testWidgets(
          'should bring the strip back when the list can no longer scroll',
          (WidgetTester tester) async {
            final ValueNotifier<int> count = ValueNotifier<int>(100);
            addTearDown(count.dispose);
            await pumpScrollingPage(
              tester,
              page: (BuildContext _) => ValueListenableBuilder<int>(
                valueListenable: count,
                builder: (BuildContext _, int n, Widget? _) => rows(n),
              ),
            );
            await tester.drag(find.byType(ListView), const Offset(0, -400));
            await tester.pumpAndSettle();
            expect(lent(), findsNothing);

            count.value = 3;
            await tester.pumpAndSettle();

            expect(lent(), findsOneWidget);
          },
        );

        testWidgets('should ignore a list nested in the page list', (
          WidgetTester tester,
        ) async {
          const Key inner = ValueKey<String>('inner');
          await pumpScrollingPage(
            tester,
            page: (BuildContext _) => ListView.builder(
              itemCount: 100,
              itemBuilder: (BuildContext context, int i) => i == 10
                  ? SizedBox(key: inner, height: 240, child: rows(50))
                  : SizedBox(height: 60, child: Text('outer $i')),
            ),
          );
          await tester.drag(find.text('outer 2'), const Offset(0, -400));
          await tester.pumpAndSettle();
          expect(lent(), findsNothing);

          // Back at its own top, the inner list must not pass for the page.
          await tester.drag(find.byKey(inner), const Offset(0, -100));
          await tester.pumpAndSettle();
          await tester.drag(find.byKey(inner), const Offset(0, 200));
          await tester.pumpAndSettle();

          expect(lent(), findsNothing);
        });

        testWidgets('should fold under a wrapper with nothing to scroll', (
          WidgetTester tester,
        ) async {
          await pumpScrollingPage(
            tester,
            page: (BuildContext _) => CustomScrollView(
              slivers: <Widget>[SliverFillRemaining(child: rows(100))],
            ),
          );

          await tester.drag(find.byType(ListView), const Offset(0, -400));
          await tester.pumpAndSettle();

          expect(lent(), findsNothing);
        });

        testWidgets('should unfold the strip for another page', (
          WidgetTester tester,
        ) async {
          await pumpScrollingPage(tester);
          await tester.drag(find.byType(ListView), const Offset(0, -400));
          await tester.pumpAndSettle();
          expect(lent(), findsNothing);

          controller.set(
            Object(),
            const FrameChrome(below: SizedBox(height: 40, child: Text('lent'))),
          );
          await tester.pumpAndSettle();

          expect(lent(), findsOneWidget);
        });
      });
    });

    group('frameChromeHeight', () {
      tearDown(() => AppSurface.skin = AppSkin.glass);

      test('should take no bar height on a phone when bars float', () {
        AppSurface.skin = AppSkin.glass;

        expect(
          frameChromeHeight(compact: true),
          lessThan(frameChromeHeight(compact: false)),
        );
      });

      test('should count both bands on a phone when bars do not float', () {
        AppSurface.skin = AppSkin.classic;

        expect(
          frameChromeHeight(compact: true),
          greaterThan(frameChromeHeight(compact: false)),
        );
      });
    });
  });
}
