import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../schema.dart';
import 'migration.dart';

/// Migration v36: mood grid tables.
class MigrationV36 extends Migration {
  @override
  int get version => 36;

  @override
  String get description => 'Add mood_grids and mood_grid_cells tables';

  @override
  Future<void> migrate(Database db) async {
    await DatabaseSchema.createMoodGridsTable(db);
    await DatabaseSchema.createMoodGridCellsTable(db);
  }
}
