import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

/// Per-grid template for auto-filling the cell label when an item is picked.
/// Independent from `caption_template` (the right-column row captions).
class MigrationV58 extends Migration {
  @override
  int get version => 58;

  @override
  String get description => 'Add cell_label_template to mood_grids';

  @override
  Future<void> migrate(Database db) async {
    await Migration.addColumnIfAbsent(
      db,
      'mood_grids',
      'cell_label_template',
      'cell_label_template TEXT',
    );
  }
}
