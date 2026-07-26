import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

/// Gives books the same source-aware collection identity as manga.
///
/// Books fell under the generic `idx_ci_*_other` unique indexes, keyed on
/// `(collection_id, media_type, external_id)` without `source`. Because an
/// OpenLibrary and a Fantlab work can share a numeric id, the second one hit a
/// false unique conflict ("already in collection"). This carves `book` out of
/// the `*_other` indexes into dedicated `*_book` indexes that include `source`,
/// mirroring the manga indexes added in v44.
class MigrationV48 extends Migration {
  @override
  int get version => 48;

  @override
  String get description =>
      'Books: source-aware collection_items unique index';

  @override
  Future<void> migrate(Database db) async {
    // OpenLibrary was the only book source before this change, so legacy
    // NULL-source book rows match the index default.
    await db.execute(
      "UPDATE collection_items SET source = 'openLibrary' "
      "WHERE media_type = 'book' AND source IS NULL",
    );

    await db.execute('DROP INDEX IF EXISTS idx_ci_coll_other');
    await db.execute('DROP INDEX IF EXISTS idx_ci_uncat_other');
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_ci_coll_book
      ON collection_items(collection_id, media_type, external_id, COALESCE(source, 'openLibrary'))
      WHERE collection_id IS NOT NULL AND media_type = 'book'
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_ci_uncat_book
      ON collection_items(media_type, external_id, COALESCE(source, 'openLibrary'))
      WHERE collection_id IS NULL AND media_type = 'book'
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_ci_coll_other
      ON collection_items(collection_id, media_type, external_id)
      WHERE collection_id IS NOT NULL AND media_type NOT IN ('game', 'manga', 'book')
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_ci_uncat_other
      ON collection_items(media_type, external_id)
      WHERE collection_id IS NULL AND media_type NOT IN ('game', 'manga', 'book')
    ''');
  }
}
