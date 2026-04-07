// Миграция v31: таблицы трекеров (tracker_profiles, tracker_game_data, tracker_achievements).
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../schema.dart';
import 'migration.dart';

/// Миграция v31: создаёт таблицы для универсальной системы трекеров.
///
/// - `tracker_profiles` — профили подключённых аккаунтов (RA, Steam, Trakt)
/// - `tracker_game_data` — прогресс per-game (ачивки, awards, playtime)
/// - `tracker_achievements` — конкретные достижения per-game
class MigrationV31 extends Migration {
  @override
  int get version => 31;

  @override
  String get description =>
      'Create tracker tables (profiles, game data, achievements)';

  @override
  Future<void> migrate(Database db) async {
    await DatabaseSchema.createTrackerProfilesTable(db);
    await DatabaseSchema.createTrackerGameDataTable(db);
    await DatabaseSchema.createTrackerAchievementsTable(db);
  }
}
