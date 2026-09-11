import '../models/showcase_item.dart';

/// Soonest first; items with no date keep their feed order at the end.
List<ShowcaseItem> sortByNextDate(List<ShowcaseItem> items) {
  final List<ShowcaseItem> dated =
      items.where((ShowcaseItem i) => i.nextDate != null).toList()
        ..sort((ShowcaseItem a, ShowcaseItem b) =>
            (a.nextDate ?? DateTime(0)).compareTo(b.nextDate ?? DateTime(0)));
  return <ShowcaseItem>[
    ...dated,
    ...items.where((ShowcaseItem i) => i.nextDate == null),
  ];
}

/// One calendar day of releases; [day] is null for the undated tail.
class ReleaseDayGroup {
  const ReleaseDayGroup({required this.day, required this.items});

  final DateTime? day;
  final List<ShowcaseItem> items;
}

/// Buckets by local calendar day, soonest day first, undated items last.
List<ReleaseDayGroup> groupByDay(List<ShowcaseItem> items) {
  final Map<DateTime, List<ShowcaseItem>> byDay = <DateTime, List<ShowcaseItem>>{};
  final List<ShowcaseItem> undated = <ShowcaseItem>[];
  for (final ShowcaseItem item in sortByNextDate(items)) {
    final DateTime? date = item.nextDate;
    if (date == null) {
      undated.add(item);
      continue;
    }
    byDay
        .putIfAbsent(
          DateTime(date.year, date.month, date.day),
          () => <ShowcaseItem>[],
        )
        .add(item);
  }
  return <ReleaseDayGroup>[
    for (final MapEntry<DateTime, List<ShowcaseItem>> e in byDay.entries)
      ReleaseDayGroup(day: e.key, items: e.value),
    if (undated.isNotEmpty) ReleaseDayGroup(day: null, items: undated),
  ];
}

/// Remaining time bucketed the way the card prints it. [wholeDays] is for
/// date-only releases, where hours since midnight would be noise.
sealed class Countdown {
  const Countdown();
}

class CountdownPassed extends Countdown {
  const CountdownPassed();
}

class CountdownToday extends Countdown {
  const CountdownToday();
}

class CountdownDays extends Countdown {
  const CountdownDays(this.days);

  final int days;
}

class CountdownDaysHours extends Countdown {
  const CountdownDaysHours(this.days, this.hours);

  final int days;
  final int hours;
}

class CountdownHoursMinutes extends Countdown {
  const CountdownHoursMinutes(this.hours, this.minutes);

  final int hours;
  final int minutes;
}

class CountdownMinutes extends Countdown {
  const CountdownMinutes(this.minutes);

  final int minutes;
}

Countdown countdownTo(
  DateTime target,
  DateTime now, {
  required bool wholeDays,
}) {
  if (wholeDays) {
    final DateTime targetDay = DateTime(target.year, target.month, target.day);
    final DateTime today = DateTime(now.year, now.month, now.day);
    final int days = targetDay.difference(today).inDays;
    if (days < 0) return const CountdownPassed();
    if (days == 0) return const CountdownToday();
    return CountdownDays(days);
  }
  final Duration left = target.difference(now);
  if (left.isNegative) return const CountdownPassed();
  if (left.inDays >= 1) {
    return CountdownDaysHours(left.inDays, left.inHours % 24);
  }
  if (left.inHours >= 1) {
    return CountdownHoursMinutes(left.inHours, left.inMinutes % 60);
  }
  return CountdownMinutes(left.inMinutes);
}
