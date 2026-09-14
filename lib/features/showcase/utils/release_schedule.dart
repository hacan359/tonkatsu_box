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

/// How a board buckets its cards. [weekday] is the seasonal schedule — a show
/// airing every Friday stays under Friday for the whole season.
enum ReleaseGrouping { list, weekday, day, week }

/// One bucket of releases; [date] is null for the undated tail. It is the
/// bucket's own anchor, not any item's date — the title formatter reads it.
class ReleaseGroup {
  const ReleaseGroup({required this.date, required this.items});

  final DateTime? date;
  final List<ShowcaseItem> items;
}

/// Buckets by [grouping], undated items last. Bucket order follows first
/// appearance in date order, so the nearest release always leads.
List<ReleaseGroup> groupReleases(
  List<ShowcaseItem> items,
  ReleaseGrouping grouping,
) {
  final Map<DateTime, List<ShowcaseItem>> buckets =
      <DateTime, List<ShowcaseItem>>{};
  final List<ShowcaseItem> undated = <ShowcaseItem>[];
  for (final ShowcaseItem item in sortByNextDate(items)) {
    final DateTime? date = item.nextDate;
    if (date == null) {
      undated.add(item);
      continue;
    }
    buckets
        .putIfAbsent(releaseBucketKey(date, grouping), () => <ShowcaseItem>[])
        .add(item);
  }
  return <ReleaseGroup>[
    for (final MapEntry<DateTime, List<ShowcaseItem>> e in buckets.entries)
      ReleaseGroup(date: e.key, items: e.value),
    if (undated.isNotEmpty) ReleaseGroup(date: null, items: undated),
  ];
}

/// The day a [ReleaseGrouping.week] bucket starts on.
DateTime startOfWeek(DateTime date) =>
    DateTime(date.year, date.month, date.day - (date.weekday - 1));

DateTime releaseBucketKey(DateTime date, ReleaseGrouping grouping) =>
    switch (grouping) {
      ReleaseGrouping.week => startOfWeek(date),
      // A weekday bucket spans months, so it is anchored on a reference week:
      // 1 Jan 2001 was a Monday, making a weekday its own day of that month.
      ReleaseGrouping.weekday => DateTime(2001, 1, date.weekday),
      ReleaseGrouping.list ||
      ReleaseGrouping.day =>
        DateTime(date.year, date.month, date.day),
    };

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
