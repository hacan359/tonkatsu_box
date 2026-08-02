import 'package:core/models/calendar_recurrence.dart';

import '../../l10n/app_localizations.dart';

/// Presentation extras for [CalendarRecurrence].
extension CalendarRecurrenceUi on CalendarRecurrence {
  String localizedLabel(S l) => switch (this) {
        CalendarRecurrence.once => l.recurrenceOnce,
        CalendarRecurrence.weekly => l.recurrenceWeekly,
        CalendarRecurrence.monthly => l.recurrenceMonthly,
      };
}
