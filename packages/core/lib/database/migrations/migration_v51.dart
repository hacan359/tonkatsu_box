import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

/// Custom items can carry a `display_type` that makes them masquerade as a real
/// media type. This adds the two fields that make those masquerades filterable:
/// `platform_id` (a `platforms` FK value, for custom games) and `format` (a
/// manga/anime format code, e.g. MANHWA / OVA). Both are chosen from the
/// existing reference lists; free-text platform stays in `platform_name`.
class MigrationV51 extends Migration {
  @override
  int get version => 51;

  @override
  String get description =>
      'Custom items: platform_id and format for filtering';

  @override
  Future<void> migrate(Database db) async {
    await Migration.addColumnIfAbsent(
      db,
      'custom_items',
      'platform_id',
      'platform_id INTEGER',
    );
    await Migration.addColumnIfAbsent(
      db,
      'custom_items',
      'format',
      'format TEXT',
    );
  }
}
