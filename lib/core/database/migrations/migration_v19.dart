// Миграция v19: создание таблицы wishlist.
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../schema.dart';
import 'migration.dart';

/// Миграция v19 — создание таблицы wishlist.
class MigrationV19 extends Migration {
  @override
  int get version => 19;

  @override
  String get description => 'Create wishlist table';

  @override
  Future<void> migrate(Database db) async {
    await DatabaseSchema.createWishlistTable(db);
  }
}
