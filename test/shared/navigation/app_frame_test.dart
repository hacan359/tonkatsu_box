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
      expect(find.byType(GlassPanel), findsNWidgets(3));
      expect(tester.takeException(), isNull);
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
