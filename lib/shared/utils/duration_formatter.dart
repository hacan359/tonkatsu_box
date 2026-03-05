// Утилиты для форматирования Duration в человекочитаемые строки.

import '../../l10n/app_localizations.dart';

/// Константы для расчёта периодов.
class _DurationConstants {
  static const int daysInWeek = 7;
  static const int daysInMonth = 30;
  static const int daysInYear = 365;
}

/// Форматирует [Duration] в человекочитаемую локализованную строку.
///
/// Примеры:
/// - 0 дней -> "менее дня"
/// - 1 день -> "1 день"
/// - 5 дней -> "5 дней"
/// - 14 дней -> "2 недели"
/// - 60 дней -> "2 месяца"
/// - 400 дней -> "1.1 года"
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

/// Форматирует completion time с префиксом.
///
/// Возвращает строку вида "Completed in 2 weeks".
String formatCompletionTime(Duration duration, S localizations) {
  final String formattedDuration = formatDuration(duration, localizations);
  return localizations.activityDatesCompletionTime(formattedDuration);
}
