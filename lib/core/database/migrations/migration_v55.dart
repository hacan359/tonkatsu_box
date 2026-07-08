import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

/// Adds `collection_items.rewatch_count` — how many times the item was
/// completed again after the first completion (MAL "times watched" /
/// AniList "repeat" semantics: 0 = completed once, no repeats).
///
/// Nullable on purpose: `NULL` means "never completed / not tracked", so
/// pre-existing rows stay unknown instead of pretending "completed once".
class MigrationV55 extends Migration {
  @override
  int get version => 55;

  @override
  String get description => 'Collection items: rewatch_count';

  @override
  Future<void> migrate(Database db) async {
    await Migration.addColumnIfAbsent(
      db,
      'collection_items',
      'rewatch_count',
      'rewatch_count INTEGER',
    );
  }
}
