import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/widgets/media_type_icon_strip.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('MediaTypeIconTile', () {
    Widget tile({required VoidCallback onTap, int count = 0}) =>
        MediaTypeIconStrip(
          children: <Widget>[
            MediaTypeIconTile(
              label: 'Games',
              icon: Icons.videogame_asset,
              accent: const Color(0xFF00FF00),
              selected: false,
              onTap: onTap,
              count: count,
            ),
          ],
        );

    testWidgets('should call onTap when tapped', (WidgetTester tester) async {
      int taps = 0;
      await tester.pumpApp(tile(onTap: () => taps++));

      await tester.tap(find.byIcon(Icons.videogame_asset));

      expect(taps, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should show the count badge only when count is positive', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(tile(onTap: () {}, count: 7));
      expect(find.text('7'), findsOneWidget);

      await tester.pumpApp(tile(onTap: () {}));
      expect(find.text('0'), findsNothing);
    });
  });
}
