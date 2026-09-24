import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/widgets/focusable_surface.dart';

import '../../helpers/test_helpers.dart';

bool _ringShown(WidgetTester tester) {
  final DecoratedBox box = tester.widget<DecoratedBox>(find.descendant(
    of: find.byType(FocusableSurface),
    matching: find.byWidgetPredicate((Widget w) =>
        w is DecoratedBox && w.position == DecorationPosition.foreground),
  ));
  final BoxDecoration decoration = box.decoration as BoxDecoration;
  return decoration.border != null;
}

void main() {
  group('FocusableSurface', () {
    testWidgets('shows the ring only while focused', (WidgetTester tester) async {
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpApp(FocusableSurface(
        focusNode: node,
        onTap: () {},
        child: const Text('pill'),
      ));

      expect(_ringShown(tester), isFalse);

      node.requestFocus();
      await tester.pumpAndSettle();
      expect(_ringShown(tester), isTrue);

      node.unfocus();
      await tester.pumpAndSettle();
      expect(_ringShown(tester), isFalse);
    });

    testWidgets('a tap runs onTap', (WidgetTester tester) async {
      int taps = 0;
      await tester.pumpApp(FocusableSurface(
        onTap: () => taps++,
        child: const Text('pill'),
      ));

      await tester.tap(find.text('pill'));
      expect(taps, 1);
    });

    testWidgets('Enter on the focused surface activates it (gamepad A too)',
        (WidgetTester tester) async {
      int taps = 0;
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpApp(FocusableSurface(
        focusNode: node,
        onTap: () => taps++,
        child: const Text('pill'),
      ));
      node.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('without onTap the ring follows the focusable child',
        (WidgetTester tester) async {
      final FocusNode inner = FocusNode();
      addTearDown(inner.dispose);
      await tester.pumpApp(FocusableSurface(
        child: InkWell(focusNode: inner, onTap: () {}, child: const Text('x')),
      ));

      inner.requestFocus();
      await tester.pumpAndSettle();
      expect(_ringShown(tester), isTrue);
    });
  });
}
