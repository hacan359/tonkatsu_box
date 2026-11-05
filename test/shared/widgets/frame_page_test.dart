import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/navigation/frame_chrome.dart';
import 'package:tonkatsu_box/shared/widgets/frame_page.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('FramePage', () {
    testWidgets('вне рамки рисует заголовок, кнопку назад и действия', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        const FramePage(
          title: 'Sub screen',
          actions: <Widget>[Icon(Icons.star)],
          child: Text('body'),
        ),
      );

      expect(find.text('Sub screen'), findsOneWidget);
      expect(find.byTooltip('Back'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.text('body'), findsOneWidget);
    });

    testWidgets('без заголовка и действий строки нет', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(const FramePage(child: Text('body')));

      expect(find.byTooltip('Back'), findsNothing);
    });

    testWidgets('кнопка назад зовёт onBack', (WidgetTester tester) async {
      int taps = 0;
      await tester.pumpApp(
        FramePage(
          title: 'T',
          onBack: () => taps++,
          child: const SizedBox(),
        ),
      );

      await tester.tap(find.byTooltip('Back'));
      expect(taps, 1);
    });

    testWidgets('внутри рамки одалживает заголовок контроллеру', (
      WidgetTester tester,
    ) async {
      final FrameChromeController controller = FrameChromeController();
      addTearDown(controller.dispose);

      await tester.pumpApp(
        FrameChromeScope(
          controller: controller,
          child: const FramePage(title: 'Lent', child: Text('body')),
        ),
      );
      await tester.pump();

      expect(find.text('Lent'), findsNothing);
      expect(find.byTooltip('Back'), findsNothing);
      expect(controller.current?.title, 'Lent');
      expect(controller.current?.onBack, isNotNull);
      expect(controller.current?.priority, 1);
    });

    testWidgets('header встаёт над телом', (WidgetTester tester) async {
      await tester.pumpApp(
        const FramePage(header: Text('header'), child: Text('body')),
      );

      expect(
        tester.getTopLeft(find.text('header')).dy,
        lessThan(tester.getTopLeft(find.text('body')).dy),
      );
    });
  });
}
