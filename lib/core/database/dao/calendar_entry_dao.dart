import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../shared/models/calendar_entry.dart';
import '../../../shared/models/calendar_recurrence.dart';
import '../../../shared/models/data_source.dart';
import '../../../shared/models/media_type.dart';

/// DAO for `calendar_entries` — manual calendar entries keyed by
/// `(external_id, source, media_type)`.
class CalendarEntryDao {
  const CalendarEntryDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  static const String _where =
      'external_id = ? AND source = ? AND media_type = ?';

  List<Object?> _key(int externalId, DataSource source, MediaType mediaType) =>
      <Object?>[externalId, source.name, mediaType.value];

  Future<bool> isAdded(
    int externalId,
    DataSource source,
    MediaType mediaType,
  ) async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query(
      'calendar_entries',
      columns: <String>['external_id'],
      where: _where,
      whereArgs: _key(externalId, source, mediaType),
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  /// Inserts or replaces the entry for its identity.
  Future<void> upsert(CalendarEntry entry) async {
    final Database db = await _getDatabase();
    await db.insert(
      'calendar_entries',
      entry.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> remove(
    int externalId,
    DataSource source,
    MediaType mediaType,
  ) async {
    final Database db = await _getDatabase();
    await db.delete(
      'calendar_entries',
      where: _where,
      whereArgs: _key(externalId, source, mediaType),
    );
  }

  Future<List<CalendarEntry>> getAll() async {
    final Database db = await _getDatabase();
    final List<Map<String, dynamic>> rows = await db.query('calendar_entries');
    return rows.map(CalendarEntry.fromDb).toList();
  }

  /// Removes one-time entries whose date is before [today] — past single
  /// entries clutter the calendar. Recurring entries roll forward and stay.
  Future<void> deletePastOnce(DateTime today) async {
    final Database db = await _getDatabase();
    await db.delete(
      'calendar_entries',
      where: 'recurrence = ? AND start_date < ?',
      whereArgs: <Object?>[
        CalendarRecurrence.once.value,
        CalendarEntry.formatDate(today),
      ],
    );
  }

  /// Drops entries whose item no longer exists in any collection. Matched by
  /// `(external_id, media_type)` — a still-collected copy keeps it.
  Future<void> deleteOrphaned() async {
    final Database db = await _getDatabase();
    await db.delete(
      'calendar_entries',
      where: 'NOT EXISTS (SELECT 1 FROM collection_items ci '
          'WHERE ci.external_id = calendar_entries.external_id '
          'AND ci.media_type = calendar_entries.media_type)',
    );
  }
}
