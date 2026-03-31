// Миграция v30: unique индексы collection_items с platform_id для игр.
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

/// Миграция v30 — разрешить одну игру на разных платформах в одной коллекции.
///
/// Разделяет единый unique index на условные: для игр — с platform_id,
/// для остальных типов — без. Аналогично для uncategorized.
class MigrationV30 extends Migration {
  @override
  int get version => 30;

  @override
  String get description =>
      'Split unique indexes to allow same game on different platforms';

  @override
  Future<void> migrate(Database db) async {
    // Удаляем старые индексы.
    await db.execute('DROP INDEX IF EXISTS idx_ci_coll');
    await db.execute('DROP INDEX IF EXISTS idx_ci_uncat');

    // Для игр: unique по (collection, type, external_id, platform_id).
    await db.execute('''
      CREATE UNIQUE INDEX idx_ci_coll_game
      ON collection_items(collection_id, media_type, external_id, platform_id)
      WHERE collection_id IS NOT NULL AND media_type = 'game'
    ''');

    // Для остальных типов: unique по (collection, type, external_id) как раньше.
    await db.execute('''
      CREATE UNIQUE INDEX idx_ci_coll_other
      ON collection_items(collection_id, media_type, external_id)
      WHERE collection_id IS NOT NULL AND media_type != 'game'
    ''');

    // Uncategorized игры: с platform_id.
    await db.execute('''
      CREATE UNIQUE INDEX idx_ci_uncat_game
      ON collection_items(media_type, external_id, platform_id)
      WHERE collection_id IS NULL AND media_type = 'game'
    ''');

    // Uncategorized остальные: как раньше.
    await db.execute('''
      CREATE UNIQUE INDEX idx_ci_uncat_other
      ON collection_items(media_type, external_id)
      WHERE collection_id IS NULL AND media_type != 'game'
    ''');
  }
}
