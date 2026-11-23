import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:tonkatsu_box/shared/theme/app_surface.dart';
import 'package:tonkatsu_box/shared/widgets/glass_panel.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('GlassPanel', () {
    tearDown(() => AppSurface.skin = AppSkin.glass);

    group('on liquid glass', () {
      testWidgets('should render refracting glass around the child', (
        WidgetTester tester,
      ) async {
        AppSurface.skin = AppSkin.glass;

        await tester.pumpApp(const GlassPanel(child: Text('inside')));

        expect(find.byType(GlassContainer), findsOneWidget);
        expect(find.text('inside'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should keep a sheet rounded only on top on glass too', (
        WidgetTester tester,
      ) async {
        AppSurface.skin = AppSkin.glass;

        await tester.pumpApp(
          const GlassPanel(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            child: Text('sheet'),
          ),
        );

        expect(find.byType(GlassContainer), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should round by the largest corner asked for', (
        WidgetTester tester,
      ) async {
        AppSurface.skin = AppSkin.glass;

        await tester.pumpApp(
          const GlassPanel(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
            child: Text('sheet'),
          ),
        );

        final GlassContainer glass = tester.widget<GlassContainer>(
          find.byType(GlassContainer),
        );
        expect((glass.shape as LiquidRoundedSuperellipse).borderRadius, 18);
      });
    });

    testWidgets('should not render glass on a skin without it', (
      WidgetTester tester,
    ) async {
      AppSurface.skin = AppSkin.classic;

      await tester.pumpApp(const GlassPanel(child: Text('inside')));

      expect(find.byType(GlassContainer), findsNothing);
      expect(find.text('inside'), findsOneWidget);
    });

    testWidgets('без размытия не ставит BackdropFilter', (
      WidgetTester tester,
    ) async {
      AppSurface.skin = AppSkin.classic;
      await tester.pumpApp(
        const GlassPanel(blurSigma: 0, child: SizedBox(width: 10, height: 10)),
      );

      expect(find.byType(BackdropFilter), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('с размытием ставит ровно один BackdropFilter', (
      WidgetTester tester,
    ) async {
      AppSurface.skin = AppSkin.classic;
      await tester.pumpApp(
        const GlassPanel(blurSigma: 5, child: SizedBox(width: 10, height: 10)),
      );

      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('рисует ребёнка', (WidgetTester tester) async {
      await tester.pumpApp(const GlassPanel(child: Text('inside')));

      expect(find.text('inside'), findsOneWidget);
    });
  });

  group('GlassTile', () {
    testWidgets('кладёт фон под ребёнка', (WidgetTester tester) async {
      const Key bg = Key('bg');
      await tester.pumpApp(
        const GlassTile(
          background: ColoredBox(key: bg, color: Colors.red),
          child: Text('inside'),
        ),
      );

      expect(find.byKey(bg), findsOneWidget);
      expect(find.text('inside'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('без фона обходится без Stack', (WidgetTester tester) async {
      await tester.pumpApp(const GlassTile(child: Text('inside')));

      expect(
        find.descendant(
          of: find.byType(GlassTile),
          matching: find.byType(Stack),
        ),
        findsNothing,
      );
    });
  });
}
