import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

class MigrationV38 extends Migration {
  @override
  int get version => 38;

  @override
  String get description =>
      'Backfill platform_id on legacy tracker_game_data NULL rows';

  @override
  Future<void> migrate(Database db) async {
    // Only backfill when collection_items has exactly one platform for the game;
    // multiple platforms would bleed RA progress across installs.
    await db.execute('''
      UPDATE tracker_game_data
      SET platform_id = (
        SELECT MIN(ci.platform_id)
        FROM collection_items ci
        WHERE ci.external_id = tracker_game_data.game_id
          AND ci.media_type = 'game'
          AND ci.platform_id IS NOT NULL
      )
      WHERE platform_id IS NULL
        AND (
          SELECT COUNT(DISTINCT ci.platform_id)
          FROM collection_items ci
          WHERE ci.external_id = tracker_game_data.game_id
            AND ci.media_type = 'game'
            AND ci.platform_id IS NOT NULL
        ) = 1
    ''');

    // Ambiguous rows get dropped — keeping them would let the legacy fallback
    // leak progress across platform installs of the same IGDB game.
    final List<Map<String, Object?>> orphans = await db.query(
      'tracker_game_data',
      columns: <String>['tracker_type', 'tracker_game_id'],
      where: 'platform_id IS NULL',
    );
    final Set<String> orphanKeys = <String>{
      for (final Map<String, Object?> r in orphans)
        '${r['tracker_type']}|${r['tracker_game_id']}',
    };

    await db.delete(
      'tracker_game_data',
      where: 'platform_id IS NULL',
    );

    // tracker_achievements has no FK to tracker_game_data, so cascade by hand.
    for (final String key in orphanKeys) {
      final List<String> parts = key.split('|');
      final String type = parts[0];
      final String trackerGameId = parts[1];
      final List<Map<String, Object?>> stillReferenced = await db.query(
        'tracker_game_data',
        columns: <String>['id'],
        where: 'tracker_type = ? AND tracker_game_id = ?',
        whereArgs: <Object?>[type, trackerGameId],
        limit: 1,
      );
      if (stillReferenced.isEmpty) {
        await db.delete(
          'tracker_achievements',
          where: 'tracker_type = ? AND tracker_game_id = ?',
          whereArgs: <Object?>[type, trackerGameId],
        );
      }
    }
  }
}
