import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/theme/app_surface.dart';
import 'package:tonkatsu_box/shared/widgets/poster_look.dart';

void main() {
  Future<PosterLook> resolve(WidgetTester tester, {PosterLook? scoped}) async {
    late PosterLook result;
    final Widget probe = Builder(
      builder: (BuildContext context) {
        result = PosterLookScope.of(context);
        return const SizedBox.shrink();
      },
    );
    await tester.pumpWidget(
      scoped == null ? probe : PosterLookScope(look: scoped, child: probe),
    );
    return result;
  }

  group('PosterLook', () {
    group('fromId', () {
      test('should resolve every look from its own id', () {
        for (final PosterLook look in PosterLook.values) {
          expect(PosterLook.fromId(look.id), look);
        }
      });

      test('should fall back to classic when the id is unknown', () {
        expect(PosterLook.fromId('no-such-look'), PosterLook.classic);
      });

      test('should fall back to classic when the id is null', () {
        expect(PosterLook.fromId(null), PosterLook.classic);
      });
    });
  });

  group('PosterLookScope', () {
    group('of', () {
      tearDown(() => AppSurface.skin = AppSkin.glass);

      testWidgets('should return classic when no scope is above', (
        WidgetTester tester,
      ) async {
        expect(await resolve(tester), PosterLook.classic);
      });

      testWidgets('should return the scoped look on the glass skin', (
        WidgetTester tester,
      ) async {
        AppSurface.skin = AppSkin.glass;

        expect(
          await resolve(tester, scoped: PosterLook.shelf),
          PosterLook.shelf,
        );
      });

      testWidgets('should return classic on a skin without glass', (
        WidgetTester tester,
      ) async {
        AppSurface.skin = AppSkin.classic;

        expect(
          await resolve(tester, scoped: PosterLook.shelf),
          PosterLook.classic,
        );
      });
    });
  });
}
