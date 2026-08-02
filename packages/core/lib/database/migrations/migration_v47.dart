import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../schema.dart';
import 'migration.dart';

/// Adds `books_cache` for `MediaType.book`. Identity mirrors manga: the
/// composite PK `(id, source)` lets two providers share a numeric id.
class MigrationV47 extends Migration {
  @override
  int get version => 47;

  @override
  String get description => 'Books: books_cache table (id, source) PK';

  @override
  Future<void> migrate(Database db) async {
    await DatabaseSchema.createBooksCacheTable(db);
  }
}
