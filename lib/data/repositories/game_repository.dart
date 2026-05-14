import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/igdb_api.dart';
import '../../core/database/database_service.dart';
import '../../shared/models/game.dart';
import '../../shared/models/platform.dart';

final Provider<GameRepository> gameRepositoryProvider =
    Provider<GameRepository>((Ref ref) {
  return GameRepository(
    api: ref.watch(igdbApiProvider),
    db: ref.watch(databaseServiceProvider),
  );
});

/// Coordinates IGDB API calls with the local cache so callers don't have to
/// branch on cache state. Cache entries older than [cacheMaxAge] seconds are
/// treated as stale and refetched.
class GameRepository {
  GameRepository({
    required IgdbApi api,
    required DatabaseService db,
  })  : _api = api,
        _db = db;

  final IgdbApi _api;
  final DatabaseService _db;

  static const int cacheMaxAge = 86400 * 7;

  Future<List<Game>> searchGames({
    required String query,
    List<int>? platformIds,
    int limit = 50,
    int offset = 0,
  }) async {
    final List<Game> games = await _api.searchGames(
      query: query,
      platformIds: platformIds,
      limit: limit,
      offset: offset,
    );

    if (games.isNotEmpty) {
      await _db.upsertGames(games);
      await ensurePlatformsCached(games);
    }

    return games;
  }

  Future<Game?> getGameById(int gameId, {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final Game? cached = await _db.getGameById(gameId);
      if (cached != null && _isCacheValid(cached.cachedAt)) {
        return cached;
      }
    }

    final Game? game = await _api.getGameById(gameId);

    if (game != null) {
      await _db.upsertGame(game);
    }

    return game;
  }

  Future<List<Game>> getGamesByIds(
    List<int> gameIds, {
    bool forceRefresh = false,
  }) async {
    if (gameIds.isEmpty) return <Game>[];

    final List<Game> result = <Game>[];
    final List<int> idsToFetch = <int>[];

    if (!forceRefresh) {
      final List<Game> cached = await _db.getGamesByIds(gameIds);
      final Map<int, Game> cachedMap = <int, Game>{
        for (final Game g in cached) g.id: g,
      };

      for (final int id in gameIds) {
        final Game? game = cachedMap[id];
        if (game != null && _isCacheValid(game.cachedAt)) {
          result.add(game);
        } else {
          idsToFetch.add(id);
        }
      }
    } else {
      idsToFetch.addAll(gameIds);
    }

    if (idsToFetch.isNotEmpty) {
      final List<Game> fetched = await _api.getGamesByIds(idsToFetch);

      if (fetched.isNotEmpty) {
        await _db.upsertGames(fetched);
      }

      result.addAll(fetched);
    }

    return result;
  }

  Future<List<Game>> searchInCache(String query, {int limit = 20}) async {
    return _db.searchGamesInCache(query, limit: limit);
  }

  Future<int> getCacheSize() async {
    return _db.getGameCount();
  }

  /// Backfills the `platforms` table for every platform id mentioned by
  /// [games]. Missing rows are fetched from IGDB; failures are swallowed
  /// because the next request will pick them up.
  Future<void> ensurePlatformsCached(List<Game> games) async {
    final Set<int> allPlatformIds = <int>{};
    for (final Game game in games) {
      if (game.platformIds != null) {
        allPlatformIds.addAll(game.platformIds!);
      }
    }
    if (allPlatformIds.isEmpty) return;

    final List<Platform> cached =
        await _db.getPlatformsByIds(allPlatformIds.toList());
    final Set<int> cachedIds = <int>{
      for (final Platform p in cached) p.id,
    };

    final List<int> missingIds =
        allPlatformIds.where((int id) => !cachedIds.contains(id)).toList();
    if (missingIds.isEmpty) return;

    try {
      final List<Platform> fetched =
          await _api.fetchPlatformsByIds(missingIds);
      if (fetched.isNotEmpty) {
        await _db.upsertPlatforms(fetched);
      }
    } on Exception {
      // Best-effort: next call will retry.
    }
  }

  bool _isCacheValid(int? cachedAt) {
    if (cachedAt == null) return false;
    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now - cachedAt < cacheMaxAge;
  }
}
