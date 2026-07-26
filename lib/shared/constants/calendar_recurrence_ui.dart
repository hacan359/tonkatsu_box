import '../../l10n/app_localizations.dart';
import '../models/calendar_recurrence.dart';

/// Presentation extras for [CalendarRecurrence].
extension CalendarRecurrenceUi on CalendarRecurrence {
  String localizedLabel(S l) => switch (this) {
        CalendarRecurrence.once => l.recurrenceOnce,
        CalendarRecurrence.weekly => l.recurrenceWeekly,
        CalendarRecurrence.monthly => l.recurrenceMonthly,
      };
}
