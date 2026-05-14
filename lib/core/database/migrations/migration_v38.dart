import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

/// Migration v38: backfill `platform_id` on legacy tracker_game_data rows.
///
/// v37 added the `platform_id` column but left every existing row with
/// NULL — the value isn't recoverable from RA without an API round-trip.
/// We can do better locally: the user's own `collection_items` already
/// carry the IGDB platform id for the same game. For each NULL tracker
/// row we look at the matching `collection_items` rows and:
///
///   * exactly one distinct platform → set `platform_id` to that;
///   * zero or >1 distinct platforms → delete the NULL tracker row, since
///     it can't be unambiguously attributed and would otherwise bleed
///     across platform installs via the legacy fallback lookup.
///
/// Trivial cost (single in-process SQL run) and idempotent — only NULL
/// rows are touched, so re-running the migration is a no-op.
class MigrationV38 extends Migration {
  @override
  int get version => 38;

  @override
  String get description =>
      'Backfill platform_id on legacy tracker_game_data NULL rows';

  @override
  Future<void> migrate(Database db) async {
    // Resolve unambiguous platforms in a single statement: an UPDATE that
    // joins via subquery and only fires when COUNT(DISTINCT platform_id)
    // is exactly 1.
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

    // Anything still NULL is ambiguous (no matching items, or multiple
    // platforms). Drop the row so the legacy fallback lookup can't leak
    // it across platform installs of the same IGDB game.
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

    // Drop the orphan achievements rows too — they're keyed by
    // `(tracker_type, tracker_game_id)` and have no parent left.
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
