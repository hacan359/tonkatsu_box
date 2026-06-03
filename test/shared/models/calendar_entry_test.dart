import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/models/calendar_entry.dart';
import 'package:tonkatsu_box/shared/models/calendar_recurrence.dart';
import 'package:tonkatsu_box/shared/models/data_source.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';

void main() {
  group('CalendarRecurrence', () {
    test('should parse from value and fall back to once', () {
      expect(CalendarRecurrence.fromValue('weekly'), CalendarRecurrence.weekly);
      expect(CalendarRecurrence.fromValue('monthly'),
          CalendarRecurrence.monthly);
      expect(CalendarRecurrence.fromValue('bogus'), CalendarRecurrence.once);
      expect(CalendarRecurrence.fromValue(null), CalendarRecurrence.once);
    });
  });

  group('CalendarEntry', () {
    test('formatDate pads to YYYY-MM-DD', () {
      expect(CalendarEntry.formatDate(DateTime(2026, 7, 5)), '2026-07-05');
    });

    test('should round-trip through toDb / fromDb', () {
      final CalendarEntry entry = CalendarEntry(
        externalId: 42,
        source: DataSource.mangabaka,
        mediaType: MediaType.manga,
        startDate: DateTime(2026, 7, 5),
        recurrence: CalendarRecurrence.monthly,
        createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );

      final CalendarEntry restored = CalendarEntry.fromDb(entry.toDb());

      expect(restored.externalId, 42);
      expect(restored.source, DataSource.mangabaka);
      expect(restored.mediaType, MediaType.manga);
      expect(restored.startDate, DateTime(2026, 7, 5));
      expect(restored.recurrence, CalendarRecurrence.monthly);
      expect(restored.createdAt,
          DateTime.fromMillisecondsSinceEpoch(1700000000000));
    });
  });
}
