import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/widgets/glass_app_bar.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('GlassAppBar', () {
    testWidgets('root route gets no back pill and one pill per action set',
        (WidgetTester tester) async {
      await tester.pumpApp(
        Scaffold(
          extendBodyBehindAppBar: true,
          appBar: GlassAppBar(
            actions: <Widget>[
              IconButton(icon: const Icon(Icons.star), onPressed: () {}),
            ],
          ),
          body: const SizedBox.expand(),
        ),
      );

      expect(find.byIcon(Icons.arrow_back), findsNothing);
      expect(find.byType(GlassPill), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('hides the actions pill when there is nothing to show',
        (WidgetTester tester) async {
      await tester.pumpApp(
        const Scaffold(appBar: GlassAppBar(), body: SizedBox.expand()),
      );

      expect(find.byType(GlassPill), findsNothing);
    });

    testWidgets('pushed route shows a back pill that pops',
        (WidgetTester tester) async {
      await tester.pumpApp(
        Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const Scaffold(
                  extendBodyBehindAppBar: true,
                  appBar: GlassAppBar(),
                  body: Text('inner'),
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      // The body starts behind the bar: the inner text sits under the inset.
      expect(tester.getTopLeft(find.text('inner')).dy, 0);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('inner'), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('renders without exceptions at phone width',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpApp(
        Scaffold(
          extendBodyBehindAppBar: true,
          appBar: GlassAppBar(
            actions: <Widget>[
              for (int i = 0; i < 4; i++)
                IconButton(icon: const Icon(Icons.star), onPressed: () {}),
            ],
          ),
          body: const SizedBox.expand(),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
