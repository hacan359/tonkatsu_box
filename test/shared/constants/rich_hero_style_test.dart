import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/constants/rich_hero_style.dart';

void main() {
  group('RichHeroStyle', () {
    group('fromId', () {
      test('should resolve every style by its own id', () {
        for (final RichHeroStyle style in RichHeroStyle.values) {
          expect(RichHeroStyle.fromId(style.id), style);
        }
      });

      test('should fall back to classic when id is unknown', () {
        expect(RichHeroStyle.fromId('vaporwave'), RichHeroStyle.classic);
      });

      test('should fall back to classic when id is null', () {
        expect(RichHeroStyle.fromId(null), RichHeroStyle.classic);
      });
    });

    test('ids are unique', () {
      final Set<String> ids =
          RichHeroStyle.values.map((RichHeroStyle v) => v.id).toSet();
      expect(ids.length, RichHeroStyle.values.length);
    });
  });
}
