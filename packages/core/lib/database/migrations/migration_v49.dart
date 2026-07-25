import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

/// Adds the `kind` discriminator to `books_cache` so comics (ComicVine,
/// `BookKind.comic`) and prose books (OpenLibrary / Fantlab, `BookKind.book`)
/// share the `book` media type while staying separable. Existing rows default
/// to `'book'`.
class MigrationV49 extends Migration {
  @override
  int get version => 49;

  @override
  String get description => 'Books: books_cache.kind discriminator (book/comic)';

  @override
  Future<void> migrate(Database db) async {
    await Migration.addColumnIfAbsent(
      db,
      'books_cache',
      'kind',
      "kind TEXT NOT NULL DEFAULT 'book'",
    );
  }
}
