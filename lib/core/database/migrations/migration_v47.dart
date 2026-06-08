import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../schema.dart';
import 'migration.dart';

/// Adds the `books_cache` table backing the `MediaType.book` media type
/// (OpenLibrary + Fantlab). Identity mirrors manga: the composite primary key
/// `(id, source)` lets an OpenLibrary and a Fantlab entry that share a numeric
/// id coexist.
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
