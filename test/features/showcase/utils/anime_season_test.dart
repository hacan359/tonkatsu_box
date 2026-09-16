import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/showcase/utils/anime_season.dart';

void main() {
  group('animeSeasonFor', () {
    test('maps each month to its season', () {
      final Map<int, AnimeSeason> expected = <int, AnimeSeason>{
        1: AnimeSeason.winter,
        2: AnimeSeason.winter,
        3: AnimeSeason.winter,
        4: AnimeSeason.spring,
        5: AnimeSeason.spring,
        6: AnimeSeason.spring,
        7: AnimeSeason.summer,
        8: AnimeSeason.summer,
        9: AnimeSeason.summer,
        10: AnimeSeason.fall,
        11: AnimeSeason.fall,
        12: AnimeSeason.fall,
      };
      for (final MapEntry<int, AnimeSeason> e in expected.entries) {
        expect(
          animeSeasonFor(DateTime(2026, e.key, 15)).season,
          e.value,
          reason: 'month ${e.key}',
        );
      }
    });

    test('season boundaries fall on the first and last day of the month', () {
      expect(animeSeasonFor(DateTime(2026, 3, 31)).season, AnimeSeason.winter);
      expect(animeSeasonFor(DateTime(2026, 4, 1)).season, AnimeSeason.spring);
      expect(animeSeasonFor(DateTime(2026, 9, 30)).season, AnimeSeason.summer);
      expect(animeSeasonFor(DateTime(2026, 10, 1)).season, AnimeSeason.fall);
    });

    test('winter keeps the calendar year of January', () {
      expect(animeSeasonFor(DateTime(2027, 1, 5)).year, 2027);
      expect(animeSeasonFor(DateTime(2026, 12, 31)).year, 2026);
    });
  });

  group('nextAnimeSeason', () {
    test('advances within the year', () {
      expect(
        nextAnimeSeason((season: AnimeSeason.summer, year: 2026)),
        (season: AnimeSeason.fall, year: 2026),
      );
    });

    test('fall rolls into the next year\'s winter', () {
      expect(
        nextAnimeSeason((season: AnimeSeason.fall, year: 2026)),
        (season: AnimeSeason.winter, year: 2027),
      );
    });
  });

  group('AnimeSeason.aniListValue', () {
    test('matches the MediaSeason enum names', () {
      expect(
        AnimeSeason.values.map((AnimeSeason s) => s.aniListValue),
        <String>['WINTER', 'SPRING', 'SUMMER', 'FALL'],
      );
    });
  });
}
