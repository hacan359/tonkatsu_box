import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/navigation/frame_chrome.dart';
import 'package:tonkatsu_box/shared/navigation/frame_inset.dart';
import 'package:tonkatsu_box/shared/theme/app_surface.dart';

import '../../helpers/test_helpers.dart';

const Size _phone = Size(400, 800);
const Size _desktop = Size(1200, 800);
const EdgeInsets _bars = EdgeInsets.only(top: 50, bottom: 30);

void main() {
  late FrameChromeController controller;

  setUp(() {
    AppSurface.skin = AppSkin.glass;
    controller = FrameChromeController();
  });

  tearDown(() {
    AppSurface.skin = AppSkin.glass;
    controller.dispose();
  });

  Widget scoped(Widget child) =>
      FrameChromeScope(controller: controller, child: child);

  group('frameFloats', () {
    Future<bool> resolve(
      WidgetTester tester, {
      required Size size,
      bool inFrame = true,
    }) async {
      late bool result;
      final Widget probe = Builder(
        builder: (BuildContext context) {
          result = frameFloats(context);
          return const SizedBox.shrink();
        },
      );
      await tester.pumpApp(
        inFrame ? scoped(probe) : probe,
        mediaQuerySize: size,
      );
      return result;
    }

    testWidgets('should float on a phone inside a floating frame', (
      WidgetTester tester,
    ) async {
      expect(await resolve(tester, size: _phone), isTrue);
    });

    testWidgets('should not float on a wide window', (
      WidgetTester tester,
    ) async {
      expect(await resolve(tester, size: _desktop), isFalse);
    });

    testWidgets('should not float when the skin keeps its bars in bands', (
      WidgetTester tester,
    ) async {
      AppSurface.skin = AppSkin.classic;

      expect(await resolve(tester, size: _phone), isFalse);
    });

    testWidgets('should not float outside a frame', (
      WidgetTester tester,
    ) async {
      expect(await resolve(tester, size: _phone, inFrame: false), isFalse);
    });
  });

  group('frameStripInset', () {
    Future<EdgeInsets> resolve(WidgetTester tester, Size size) async {
      late EdgeInsets result;
      await tester.pumpApp(
        scoped(
          Builder(
            builder: (BuildContext context) {
              result = frameStripInset(context);
              return const SizedBox.shrink();
            },
          ),
        ),
        mediaQuerySize: size,
      );
      return result;
    }

    testWidgets('should drop the inset of a lent strip', (
      WidgetTester tester,
    ) async {
      expect(await resolve(tester, _phone), EdgeInsets.zero);
    });

    testWidgets('should inset a strip that stays in the page', (
      WidgetTester tester,
    ) async {
      expect(await resolve(tester, _desktop), isNot(EdgeInsets.zero));
    });
  });

  group('FrameRouteInset', () {
    const Key box = ValueKey<String>('box');

    Widget route(Widget child) => FrameBarInsets(
      insets: _bars,
      child: FrameRouteInset(child: child),
    );

    testWidgets('should keep a page clear of the bars when nothing bleeds', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(route(const SizedBox.expand(key: box)));

      final Rect screen = tester.getRect(find.byType(FrameRouteInset));
      final Rect rect = tester.getRect(find.byKey(box));
      expect(rect.top, screen.top + _bars.top);
      expect(rect.bottom, screen.bottom - _bars.bottom);
    });

    testWidgets('should let a bleeding page run under the bars', (
      WidgetTester tester,
    ) async {
      late EdgeInsets handed;
      await tester.pumpApp(
        route(
          FrameBleed(
            builder: (BuildContext context, EdgeInsets bars) {
              handed = bars;
              return const SizedBox.expand(key: box);
            },
          ),
        ),
      );

      expect(
        tester.getRect(find.byKey(box)),
        tester.getRect(find.byType(FrameRouteInset)),
      );
      expect(handed, _bars);
    });

    testWidgets('should pad the page again once the bleeder is gone', (
      WidgetTester tester,
    ) async {
      final ValueNotifier<bool> bleed = ValueNotifier<bool>(true);
      addTearDown(bleed.dispose);
      await tester.pumpApp(
        route(
          ValueListenableBuilder<bool>(
            valueListenable: bleed,
            builder: (BuildContext context, bool on, Widget? _) => on
                ? FrameBleed(
                    builder: (BuildContext context, EdgeInsets bars) =>
                        const SizedBox.expand(),
                  )
                : const SizedBox.expand(key: box),
          ),
        ),
      );

      bleed.value = false;
      await tester.pumpAndSettle();

      final Rect screen = tester.getRect(find.byType(FrameRouteInset));
      expect(tester.getRect(find.byKey(box)).top, screen.top + _bars.top);
    });
  });

  group('FrameBleed', () {
    testWidgets('should hand out no insets outside a frame route', (
      WidgetTester tester,
    ) async {
      late EdgeInsets handed;
      await tester.pumpApp(
        FrameBleed(
          builder: (BuildContext context, EdgeInsets bars) {
            handed = bars;
            return const SizedBox.shrink();
          },
        ),
      );

      expect(handed, EdgeInsets.zero);
      expect(tester.takeException(), isNull);
    });
  });

  group('FrameStrip', () {
    const Widget strip = Text('strip');
    const Widget body = Text('body');

    testWidgets('should draw the strip in the page when bars do not float', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        scoped(const FrameStrip(strip: <Widget>[strip], child: body)),
        mediaQuerySize: _desktop,
        wrapInScaffold: true,
      );

      expect(find.text('strip'), findsOneWidget);
      expect(find.text('body'), findsOneWidget);
      expect(controller.current, isNull);
    });

    testWidgets('should lend the strip to a floating frame', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        scoped(const FrameStrip(strip: <Widget>[strip], child: body)),
        mediaQuerySize: _phone,
        wrapInScaffold: true,
      );

      expect(find.text('strip'), findsNothing);
      expect(find.text('body'), findsOneWidget);
      expect(controller.current?.below, isNotNull);
    });

    testWidgets('should lend nothing when the strip is empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        scoped(const FrameStrip(strip: <Widget>[], child: body)),
        mediaQuerySize: _phone,
        wrapInScaffold: true,
      );

      expect(find.text('body'), findsOneWidget);
      expect(controller.current?.below, isNull);
    });
  });
}
