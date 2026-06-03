import 'calendar_recurrence.dart';
import 'data_source.dart';
import 'media_type.dart';

/// A manual calendar entry the user added for any item: a start date and a
/// recurrence. Identity is `(externalId, source, mediaType)` — one entry per
/// item, independent of collections.
class CalendarEntry {
  const CalendarEntry({
    required this.externalId,
    required this.source,
    required this.mediaType,
    required this.startDate,
    required this.recurrence,
    required this.createdAt,
  });

  factory CalendarEntry.fromDb(Map<String, dynamic> row) {
    return CalendarEntry(
      externalId: row['external_id'] as int,
      source: DataSource.fromName(row['source'] as String?),
      mediaType: MediaType.fromString(row['media_type'] as String),
      startDate: DateTime.parse(row['start_date'] as String),
      recurrence: CalendarRecurrence.fromValue(row['recurrence'] as String?),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
    );
  }

  final int externalId;
  final DataSource source;
  final MediaType mediaType;

  /// First (or only) occurrence, date-only.
  final DateTime startDate;
  final CalendarRecurrence recurrence;
  final DateTime createdAt;

  /// `YYYY-MM-DD`, stable and lexicographically comparable for SQL.
  static String formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toDb() {
    return <String, dynamic>{
      'external_id': externalId,
      'source': source.name,
      'media_type': mediaType.value,
      'start_date': formatDate(startDate),
      'recurrence': recurrence.value,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }
}
