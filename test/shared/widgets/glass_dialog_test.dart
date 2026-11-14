import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/widgets/glass_dialog.dart';
import 'package:tonkatsu_box/shared/widgets/glass_panel.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('showGlassSheet', () {
    Future<Future<String?>> open(
      WidgetTester tester, {
      required bool selfBacked,
    }) async {
      late Future<String?> result;
      await tester.pumpApp(
        Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () => result = showGlassSheet<String>(
              context: context,
              selfBacked: selfBacked,
              builder: (BuildContext ctx) => TextButton(
                onPressed: () => Navigator.of(ctx).pop('picked'),
                child: const Text('pick'),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets(
      'should wrap the body in a GlassSheet and return the popped value',
      (WidgetTester tester) async {
        final Future<String?> result = await open(tester, selfBacked: false);

        expect(find.byType(GlassSheet), findsOneWidget);
        await tester.tap(find.text('pick'));
        await tester.pumpAndSettle();
        expect(await result, 'picked');
      },
    );

    testWidgets('should leave the body unwrapped when selfBacked', (
      WidgetTester tester,
    ) async {
      await open(tester, selfBacked: true);

      expect(find.text('pick'), findsOneWidget);
      expect(find.byType(GlassSheet), findsNothing);
      expect(
        find.ancestor(of: find.text('pick'), matching: find.byType(GlassPanel)),
        findsNothing,
      );
    });
  });

  group('GlassDialogOption', () {
    testWidgets('should call onPressed when tapped', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await tester.pumpApp(
        GlassDialogOption(onPressed: () => taps++, child: const Text('opt')),
      );

      await tester.tap(find.text('opt'));

      expect(taps, 1);
    });
  });

  group('GlassAlertDialog', () {
    testWidgets('should render at phone size without overflow', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpApp(
        Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (BuildContext _) => GlassAlertDialog(
                title: const Text('title'),
                content: Text('line\n' * 40),
                actions: <Widget>[
                  TextButton(onPressed: () {}, child: const Text('ok')),
                ],
              ),
            ),
            child: const Text('open'),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('title'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
