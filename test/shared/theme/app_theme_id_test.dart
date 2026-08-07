import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/theme/app_palette.dart';
import 'package:tonkatsu_box/shared/theme/app_theme_id.dart';

void main() {
  group('AppThemeId', () {
    group('fromId', () {
      test('возвращает dark для "dark"', () {
        expect(AppThemeId.fromId('dark'), AppThemeId.dark);
      });

      test('возвращает sakura для "sakura"', () {
        expect(AppThemeId.fromId('sakura'), AppThemeId.sakura);
      });

      test('возвращает dark для null', () {
        expect(AppThemeId.fromId(null), AppThemeId.dark);
      });

      test('возвращает dark для неизвестного значения', () {
        expect(AppThemeId.fromId('neon'), AppThemeId.dark);
      });
    });

    group('palette', () {
      test('каждой теме соответствует своя палитра', () {
        expect(AppThemeId.dark.palette, same(AppPalette.dark));
        expect(AppThemeId.sakura.palette, same(AppPalette.sakura));
      });
    });

    group('id', () {
      test('id уникален для каждой темы', () {
        final Set<String> ids =
            AppThemeId.values.map((AppThemeId t) => t.id).toSet();
        expect(ids.length, AppThemeId.values.length);
      });
    });
  });
}
