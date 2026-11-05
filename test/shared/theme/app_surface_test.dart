import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/theme/app_colors.dart';
import 'package:tonkatsu_box/shared/theme/app_surface.dart';

void main() {
  group('AppSurface', () {
    tearDown(() {
      AppSurface.skin = AppSkin.glass;
      AppColors.palette = AppPalette.dark;
    });

    test('классика на светлой палитре красит панель её surface', () {
      AppSurface.skin = AppSkin.classic;
      AppColors.palette = AppPalette.sakura;

      expect(AppSurface.panelFill(), AppPalette.sakura.surface);
      expect(AppSurface.tileFill(), AppPalette.sakura.surface);
      expect(AppSurface.panelEdge(), AppPalette.sakura.surfaceBorder);
    });

    test('стекло на тёмной палитре даёт чёрный фрост с альфой скина', () {
      AppSurface.skin = AppSkin.glass;
      AppColors.palette = AppPalette.dark;

      expect(
        AppSurface.panelFill(),
        Colors.black.withAlpha(glassSkin.panelFrost.dark),
      );
      expect(AppSurface.tileFill().a, lessThan(1));
    });

    test('стекло на светлой палитре даёт белый фрост', () {
      AppSurface.skin = AppSkin.glass;
      AppColors.palette = AppPalette.sakura;

      expect(
        AppSurface.panelFill(),
        Colors.white.withAlpha(glassSkin.panelFrost.light),
      );
    });

    test('явная палитра побеждает активную', () {
      AppSurface.skin = AppSkin.classic;
      AppColors.palette = AppPalette.dark;

      expect(
        AppSurface.panelFill(AppPalette.sakura),
        AppPalette.sakura.surface,
      );
    });

    test('плитка на картинке остаётся полупрозрачной в классике', () {
      AppSurface.skin = AppSkin.classic;
      AppColors.palette = AppPalette.dark;

      expect(AppSurface.tileFill().a, 1);
      expect(AppSurface.pictureTileFill().a, lessThan(1));
    });

    test('плитка на картинке в стекле совпадает с обычной плиткой', () {
      AppSurface.skin = AppSkin.glass;
      AppColors.palette = AppPalette.dark;

      expect(AppSurface.pictureTileFill(), AppSurface.tileFill());
    });

    test('шторка берёт глубину из скина, а оттенок из палитры', () {
      AppSurface.skin = AppSkin.classic;
      AppColors.palette = AppPalette.dark;
      final Color classic = AppSurface.barrier();
      expect(
        classic,
        AppPalette.dark.barrier.withAlpha(classicSkin.barrierAlpha.dark),
      );

      AppSurface.skin = AppSkin.glass;
      final Color glass = AppSurface.barrier();
      expect(
        glass,
        AppPalette.dark.barrier.withAlpha(glassSkin.barrierAlpha.dark),
      );
      expect(glass.a, lessThan(classic.a));
    });

    test('геттеры размеров читают активный скин', () {
      AppSurface.skin = AppSkin.classic;
      expect(AppSurface.frameGap, 0);
      expect(AppSurface.modalBlurSigma, 0);
      expect(AppSurface.tileShadow, isFalse);

      AppSurface.skin = AppSkin.glass;
      expect(AppSurface.frameGap, glassSkin.frameGap);
      expect(AppSurface.tileShadow, isTrue);
    });
  });
}
