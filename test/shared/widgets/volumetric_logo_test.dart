import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/theme/app_assets.dart';
import 'package:tonkatsu_box/shared/widgets/volumetric_logo.dart';

void main() {
  Widget host(double lift) => MaterialApp(
    home: Center(
      child: VolumetricLogo(lift: AlwaysStoppedAnimation<double>(lift)),
    ),
  );

  final int lifting = 1 + AppAssets.logoPieces.length;

  group('VolumetricLogo', () {
    testWidgets('в покое рисует плоский логотип: только слои, без теней', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(host(0));

      expect(find.byType(Image), findsNWidgets(1 + lifting));
      expect(find.byType(ImageFiltered), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('после подъёма у каждой поднятой части есть тень и бок', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(host(1));

      expect(find.byType(ImageFiltered), findsNWidgets(lifting));
      expect(find.byType(Image).evaluate().length, greaterThan(3 * lifting));
      expect(tester.takeException(), isNull);
    });

    testWidgets('кусочки поднимаются позже хлопушки', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(host(0.2));

      expect(find.byType(ImageFiltered), findsOneWidget);
    });

    testWidgets('значение подъёма за пределами 0..1 не ломает отрисовку', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(host(1.5));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(host(-0.5));
      expect(find.byType(ImageFiltered), findsNothing);
    });
  });
}
