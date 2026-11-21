import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/theme/app_skin.dart';
import 'package:tonkatsu_box/shared/theme/app_skin_id.dart';

void main() {
  group('AppSkinId', () {
    group('fromId', () {
      test('возвращает glass для "glass" и classic для "classic"', () {
        expect(AppSkinId.fromId('glass'), AppSkinId.glass);
        expect(AppSkinId.fromId('classic'), AppSkinId.classic);
      });

      test('возвращает glass для null и неизвестного значения', () {
        expect(AppSkinId.fromId(null), AppSkinId.glass);
        expect(AppSkinId.fromId('nope'), AppSkinId.glass);
      });
    });

    test('каждому стилю соответствует свой скин', () {
      expect(AppSkinId.glass.skin, same(AppSkin.glass));
      expect(AppSkinId.classic.skin, same(AppSkin.classic));
    });

    test('id уникален для каждого стиля', () {
      final Set<String> ids = AppSkinId.values
          .map((AppSkinId s) => s.id)
          .toSet();
      expect(ids.length, AppSkinId.values.length);
    });
  });

  group('AppSkin', () {
    test('классика без размытия, зазоров и фото', () {
      expect(classicSkin.wallpaperBlurSigma, 0);
      expect(classicSkin.modalBlurSigma, 0);
      expect(classicSkin.frameGap, 0);
      expect(classicSkin.wallpaper, SkinWallpaper.tile);
      expect(classicSkin.contentOnWallpaper, isTrue);
      expect(classicSkin.panelRadius, 0);
      expect(classicSkin.panelFill, SkinFill.surface);
      expect(classicSkin.detailBackdrop, isTrue);
    });

    test('стеклянный скин размывает и показывает картинку', () {
      expect(glassSkin.wallpaperBlurSigma, greaterThan(0));
      expect(glassSkin.modalBlurSigma, greaterThan(0));
      expect(glassSkin.frameGap, greaterThan(0));
      expect(glassSkin.wallpaper, SkinWallpaper.picture);
      expect(glassSkin.panelRadius, greaterThan(0));
      expect(glassSkin.detailBackdrop, isFalse);
    });
  });
}
