import 'package:core/models/media_type.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../models/showcase_item.dart';
import 'release_schedule.dart';

String countdownText(S l, Countdown countdown) => switch (countdown) {
      CountdownPassed() => l.showcaseOutNow,
      CountdownToday() => l.releasesToday,
      CountdownDays(:final int days) =>
        l.showcaseCountdownIn(l.showcaseCountdownDays(days)),
      CountdownDaysHours(:final int days, :final int hours) =>
        l.showcaseCountdownIn(l.showcaseCountdownDaysHours(days, hours)),
      CountdownHoursMinutes(:final int hours, :final int minutes) =>
        l.showcaseCountdownIn(l.showcaseCountdownHoursMinutes(hours, minutes)),
      CountdownMinutes(:final int minutes) =>
        l.showcaseCountdownIn(l.showcaseCountdownMinutes(minutes)),
    };

/// `Ep 5 · in 2d 4h`, `S4E8 · in 5d`, `Premiere · Today`, `Release · Out now`;
/// null when the item has no date at all.
String? releaseHeadline(S l, ShowcaseItem item, DateTime now) {
  final DateTime? date = item.nextDate;
  if (date == null) return null;
  final Countdown countdown =
      countdownTo(date, now, wholeDays: !item.hasTimeOfDay);
  return '${_whatAirs(l, item)} · ${countdownText(l, countdown)}';
}

String _whatAirs(S l, ShowcaseItem item) {
  final int? episode = item.nextEpisode;
  final int? season = item.nextSeason;
  if (episode != null && season != null) {
    return l.showcaseSeasonEpisodeShort(season, episode);
  }
  if (episode != null) return l.showcaseEpisodeShort(episode);
  return switch (item.mediaType) {
    MediaType.game || MediaType.audio => l.showcaseRelease,
    _ => l.showcasePremiere,
  };
}

// Twenty cards re-render every minute; parsing a locale pattern each time
// is the one avoidable cost in that tick.
final Map<String, DateFormat> _dayFormats = <String, DateFormat>{};
final Map<String, DateFormat> _timeFormats = <String, DateFormat>{};
final Map<String, DateFormat> _dayTitleFormats = <String, DateFormat>{};
final Map<String, DateFormat> _weekdayFormats = <String, DateFormat>{};
final Map<String, DateFormat> _monthDayFormats = <String, DateFormat>{};

/// `Fri, Sep 13` for a date-only item, with ` · 21:00` when the time is known.
String releaseDateText(ShowcaseItem item, String locale) {
  final DateTime? date = item.nextDate;
  if (date == null) return '';
  final DateFormat day =
      _dayFormats.putIfAbsent(locale, () => DateFormat.MMMEd(locale));
  if (!item.hasTimeOfDay) return day.format(date);
  final DateFormat time =
      _timeFormats.putIfAbsent(locale, () => DateFormat.Hm(locale));
  return '${day.format(date)} · ${time.format(date)}';
}

/// `Friday` for a weekday bucket, `29 Sep - 5 Oct` for a week, and
/// `Friday, 3 Oct` for a single day.
String releaseGroupTitle(
  DateTime date,
  ReleaseGrouping grouping,
  String locale,
) {
  switch (grouping) {
    case ReleaseGrouping.weekday:
      return _weekdayFormats
          .putIfAbsent(locale, () => DateFormat('EEEE', locale))
          .format(date);
    case ReleaseGrouping.week:
      final DateFormat monthDay =
          _monthDayFormats.putIfAbsent(locale, () => DateFormat.MMMd(locale));
      final DateTime end = DateTime(date.year, date.month, date.day + 6);
      return '${monthDay.format(date)} - ${monthDay.format(end)}';
    case ReleaseGrouping.list:
    case ReleaseGrouping.day:
      return _dayTitleFormats
          .putIfAbsent(locale, () => DateFormat('EEEE, d MMM', locale))
          .format(date);
  }
}

/// `TV · 12 ep · 24m · MAPPA` — whichever parts the source gave.
String releaseMeta(S l, ShowcaseItem item) {
  final int? episodes = item.episodes;
  final int? minutes = item.durationMinutes;
  return <String?>[
    item.formatLabel,
    if (episodes != null) l.showcaseEpisodesCount(episodes),
    if (minutes != null) l.runtimeMinutes(minutes),
    item.creator,
  ].whereType<String>().where((String s) => s.isNotEmpty).join(' · ');
}
