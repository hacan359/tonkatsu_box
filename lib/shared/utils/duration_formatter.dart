import '../../l10n/app_localizations.dart';

class _DurationConstants {
  static const int daysInWeek = 7;
  static const int daysInMonth = 30;
  static const int daysInYear = 365;
}

/// Rounds up to the coarsest unit that fits: days, weeks, months, then years.
String formatDuration(Duration duration, S localizations) {
  final int days = duration.inDays;

  if (days == 0) return localizations.durationLessThanDay;
  if (days == 1) return localizations.durationOneDay;
  if (days < _DurationConstants.daysInWeek) {
    return localizations.durationDays(days);
  }
  if (days < _DurationConstants.daysInMonth) {
    final int weeks = (days / _DurationConstants.daysInWeek).round();
    return localizations.durationWeeks(weeks);
  }
  if (days < _DurationConstants.daysInYear) {
    final int months = (days / _DurationConstants.daysInMonth).round();
    return localizations.durationMonths(months);
  }

  final double years = days / _DurationConstants.daysInYear;
  return localizations.durationYears(years.toStringAsFixed(1));
}

/// Wraps [formatDuration] as `Completed in <duration>`.
String formatCompletionTime(Duration duration, S localizations) {
  final String formattedDuration = formatDuration(duration, localizations);
  return localizations.activityDatesCompletionTime(formattedDuration);
}

/// Exact to the minute: `22m`, `1h`, `1h 28m`.
String formatMinutes(int minutes, S localizations) {
  final int hours = minutes ~/ 60;
  final int rest = minutes % 60;
  if (hours > 0 && rest > 0) {
    return localizations.runtimeHoursMinutes(hours, rest);
  }
  if (hours > 0) return localizations.runtimeHours(hours);
  return localizations.runtimeMinutes(rest);
}
