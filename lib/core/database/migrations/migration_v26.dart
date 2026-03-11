// Миграция v26: добавление таблиц тир-листов.
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../schema.dart';
import 'migration.dart';

/// Миграция v26 — создание таблиц tier_lists, tier_definitions,
/// tier_list_entries.
class MigrationV26 extends Migration {
  @override
  int get version => 26;

  @override
  String get description => 'Add tier lists tables';

  @override
  Future<void> migrate(Database db) async {
    await DatabaseSchema.createTierListsTable(db);
    await DatabaseSchema.createTierDefinitionsTable(db);
    await DatabaseSchema.createTierListEntriesTable(db);
  }
}
