/// How a manual calendar entry repeats.
enum CalendarRecurrence {
  once('once'),
  weekly('weekly'),
  monthly('monthly');

  const CalendarRecurrence(this.value);

  /// Stored value (DB / serialization).
  final String value;

  static CalendarRecurrence fromValue(String? value) {
    for (final CalendarRecurrence r in CalendarRecurrence.values) {
      if (r.value == value) return r;
    }
    return CalendarRecurrence.once;
  }
}
