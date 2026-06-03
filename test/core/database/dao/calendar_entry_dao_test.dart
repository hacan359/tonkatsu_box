import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tonkatsu_box/core/database/dao/calendar_entry_dao.dart';
import 'package:tonkatsu_box/core/database/schema.dart';
import 'package:tonkatsu_box/shared/models/calendar_entry.dart';
import 'package:tonkatsu_box/shared/models/calendar_recurrence.dart';
import 'package:tonkatsu_box/shared/models/data_source.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';

void main() {
  sqfliteFfiInit();
  final DatabaseFactory factory = databaseFactoryFfi;

  late Database db;
  late CalendarEntryDao dao;

  CalendarEntry entry({
    int externalId = 1,
    DataSource source = DataSource.tmdb,
    MediaType mediaType = MediaType.movie,
    required DateTime startDate,
    CalendarRecurrence recurrence = CalendarRecurrence.once,
  }) =>
      CalendarEntry(
        externalId: externalId,
        source: source,
        mediaType: mediaType,
        startDate: startDate,
        recurrence: recurrence,
        createdAt: DateTime(2024),
      );

  setUp(() async {
    db = await factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (Database db, int _) async {
          await DatabaseSchema.createCalendarEntriesTable(db);
          await DatabaseSchema.createCollectionItemsTable(db);
        },
      ),
    );
    dao = CalendarEntryDao(() async => db);
  });

  tearDown(() async => db.close());

  group('CalendarEntryDao', () {
    test('should report added after upsert', () async {
      await dao.upsert(entry(startDate: DateTime(2026, 6, 1)));

      expect(
        await dao.isAdded(1, DataSource.tmdb, MediaType.movie),
        isTrue,
      );
    });

    test('should not collide across providers sharing an id', () async {
      await dao.upsert(entry(
        externalId: 5,
        source: DataSource.anilist,
        mediaType: MediaType.manga,
        startDate: DateTime(2026, 6, 1),
      ));

      expect(
        await dao.isAdded(5, DataSource.mangabaka, MediaType.manga),
        isFalse,
      );
    });

    test('should remove an entry', () async {
      await dao.upsert(entry(startDate: DateTime(2026, 6, 1)));
      await dao.remove(1, DataSource.tmdb, MediaType.movie);

      expect(
        await dao.isAdded(1, DataSource.tmdb, MediaType.movie),
        isFalse,
      );
    });

    test('should round-trip recurrence and date through getAll', () async {
      await dao.upsert(entry(
        startDate: DateTime(2026, 7, 15),
        recurrence: CalendarRecurrence.weekly,
      ));

      final CalendarEntry stored = (await dao.getAll()).single;
      expect(stored.recurrence, CalendarRecurrence.weekly);
      expect(stored.startDate, DateTime(2026, 7, 15));
    });

    test('should delete past one-time entries but keep recurring ones',
        () async {
      final DateTime today = DateTime(2026, 6, 2);
      await dao.upsert(entry(
        externalId: 1,
        startDate: DateTime(2026, 5, 1), // past one-time → removed
      ));
      await dao.upsert(entry(
        externalId: 2,
        startDate: DateTime(2026, 5, 1), // past but weekly → kept
        recurrence: CalendarRecurrence.weekly,
      ));
      await dao.upsert(entry(
        externalId: 3,
        startDate: DateTime(2026, 7, 1), // future one-time → kept
      ));

      await dao.deletePastOnce(today);

      final Set<int> ids =
          (await dao.getAll()).map((CalendarEntry e) => e.externalId).toSet();
      expect(ids, <int>{2, 3});
    });

    test('deleteOrphaned drops entries whose item left all collections',
        () async {
      await dao.upsert(entry(externalId: 1, startDate: DateTime(2026, 6, 1)));
      await dao.upsert(entry(externalId: 2, startDate: DateTime(2026, 6, 1)));
      await db.insert('collection_items', <String, Object?>{
        'external_id': 1,
        'media_type': MediaType.movie.value,
        'added_at': 0,
        'sort_order': 0,
      });

      await dao.deleteOrphaned();

      final Set<int> ids =
          (await dao.getAll()).map((CalendarEntry e) => e.externalId).toSet();
      expect(ids, <int>{1});
    });
  });
}
