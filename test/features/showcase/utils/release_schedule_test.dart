import 'package:core/models/data_source.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/showcase/models/showcase_item.dart';
import 'package:tonkatsu_box/features/showcase/utils/release_schedule.dart';

ShowcaseItem _item(int id, {DateTime? nextDate}) => ShowcaseItem(
      media: Object(),
      mediaType: MediaType.anime,
      source: DataSource.anilist,
      externalId: id,
      title: 'Item $id',
      nextDate: nextDate,
    );

void main() {
  final DateTime now = DateTime(2026, 9, 11, 12);

  group('sortByNextDate', () {
    test('soonest first, undated keep feed order at the end', () {
      final List<ShowcaseItem> sorted = sortByNextDate(<ShowcaseItem>[
        _item(1),
        _item(2, nextDate: DateTime(2026, 9, 20)),
        _item(3),
        _item(4, nextDate: DateTime(2026, 9, 12)),
      ]);

      expect(
        sorted.map((ShowcaseItem i) => i.externalId),
        <int>[4, 2, 1, 3],
      );
    });

    test('is stable for equal dates', () {
      final DateTime same = DateTime(2026, 9, 12);
      final List<ShowcaseItem> sorted = sortByNextDate(<ShowcaseItem>[
        _item(1, nextDate: same),
        _item(2, nextDate: same),
      ]);

      expect(sorted.map((ShowcaseItem i) => i.externalId), <int>[1, 2]);
    });

    test('empty input stays empty', () {
      expect(sortByNextDate(const <ShowcaseItem>[]), isEmpty);
    });
  });

  group('groupByDay', () {
    test('buckets by local calendar day, undated last', () {
      final List<ReleaseDayGroup> groups = groupByDay(<ShowcaseItem>[
        _item(1, nextDate: DateTime(2026, 9, 13, 23, 30)),
        _item(2),
        _item(3, nextDate: DateTime(2026, 9, 12, 1)),
        _item(4, nextDate: DateTime(2026, 9, 13, 2)),
      ]);

      expect(groups, hasLength(3));
      expect(groups[0].day, DateTime(2026, 9, 12));
      expect(groups[0].items.single.externalId, 3);
      expect(groups[1].day, DateTime(2026, 9, 13));
      expect(
        groups[1].items.map((ShowcaseItem i) => i.externalId),
        <int>[4, 1],
      );
      expect(groups[2].day, isNull);
      expect(groups[2].items.single.externalId, 2);
    });

    test('no undated group when every item has a date', () {
      final List<ReleaseDayGroup> groups = groupByDay(<ShowcaseItem>[
        _item(1, nextDate: DateTime(2026, 9, 12)),
      ]);

      expect(groups.single.day, isNotNull);
    });
  });

  group('countdownTo', () {
    group('with time of day', () {
      test('more than a day away gives days and leftover hours', () {
        final Countdown c = countdownTo(
          now.add(const Duration(days: 2, hours: 4, minutes: 30)),
          now,
          wholeDays: false,
        );
        expect(c, isA<CountdownDaysHours>());
        expect((c as CountdownDaysHours).days, 2);
        expect(c.hours, 4);
      });

      test('under a day gives hours and minutes', () {
        final Countdown c = countdownTo(
          now.add(const Duration(hours: 4, minutes: 12)),
          now,
          wholeDays: false,
        );
        expect(c, isA<CountdownHoursMinutes>());
        expect((c as CountdownHoursMinutes).hours, 4);
        expect(c.minutes, 12);
      });

      test('under an hour gives minutes', () {
        final Countdown c = countdownTo(
          now.add(const Duration(minutes: 59)),
          now,
          wholeDays: false,
        );
        expect(c, isA<CountdownMinutes>());
        expect((c as CountdownMinutes).minutes, 59);
      });

      test('exactly 24 hours is one day, zero hours', () {
        final Countdown c = countdownTo(
          now.add(const Duration(hours: 24)),
          now,
          wholeDays: false,
        );
        expect(c, isA<CountdownDaysHours>());
        expect((c as CountdownDaysHours).days, 1);
        expect(c.hours, 0);
      });

      test('a past moment has passed', () {
        expect(
          countdownTo(
            now.subtract(const Duration(minutes: 1)),
            now,
            wholeDays: false,
          ),
          isA<CountdownPassed>(),
        );
      });
    });

    group('whole days', () {
      test('same calendar day is today even later in the day', () {
        expect(
          countdownTo(DateTime(2026, 9, 11), now, wholeDays: true),
          isA<CountdownToday>(),
        );
      });

      test('tomorrow is one day regardless of the hour', () {
        final Countdown c =
            countdownTo(DateTime(2026, 9, 12), now, wholeDays: true);
        expect(c, isA<CountdownDays>());
        expect((c as CountdownDays).days, 1);
      });

      test('yesterday has passed', () {
        expect(
          countdownTo(DateTime(2026, 9, 10), now, wholeDays: true),
          isA<CountdownPassed>(),
        );
      });
    });
  });
}
