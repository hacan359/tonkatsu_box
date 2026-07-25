import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../schema.dart';
import 'migration.dart';

/// Adds release tracking: the `tracked_releases` table holds per-title
/// subscriptions keyed by `(external_id, source, media_type)`. Release dates
/// come from the existing `tv_episodes_cache`, so no other schema change.
class MigrationV45 extends Migration {
  @override
  int get version => 45;

  @override
  String get description => 'Release tracking: tracked_releases table';

  @override
  Future<void> migrate(Database db) async {
    await DatabaseSchema.createTrackedReleasesTable(db);
  }
}
