import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/igdb_api.dart';
import '../../core/database/database_service.dart';
import '../../shared/models/game.dart';

/// Провайдер для репозитория игр.
final Provider<GameRepository> gameRepositoryProvider =
    Provider<GameRepository>((Ref ref) {
  return GameRepository(
    api: ref.watch(igdbApiProvider),
    db: ref.watch(databaseServiceProvider),
  );
});

/// Репозиторий для работы с играми.
///
/// Объединяет IGDB API и локальный кеш для оптимизации запросов.
class GameRepository {
  /// Создаёт экземпляр [GameRepository].
  GameRepository({
    required IgdbApi api,
    required DatabaseService db,
  })  : _api = api,
        _db = db;

  final IgdbApi _api;
  final DatabaseService _db;

  /// Максимальный возраст кеша в секундах (7 дней).
  static const int cacheMaxAge = 86400 * 7;

  /// Ищет игры по названию.
  ///
  /// Сначала запрашивает IGDB, затем кеширует результаты.
  /// [query] — строка поиска.
  /// [platformIds] — опциональный фильтр по платформам (несколько).
  /// [limit] — максимальное количество результатов.
  /// [offset] — смещение для пагинации (по умолчанию 0).
  ///
  /// Возвращает список найденных игр.
  Future<List<Game>> searchGames({
    required String query,
    List<int>? platformIds,
    int limit = 50,
    int offset = 0,
  }) async {
    // Поиск через IGDB API
    final List<Game> games = await _api.searchGames(
      query: query,
      platformIds: platformIds,
      limit: limit,
      offset: offset,
    );

    // Кешируем результаты
    if (games.isNotEmpty) {
      await _db.upsertGames(games);
    }

    return games;
  }

  /// Получает игру по ID.
  ///
  /// Сначала проверяет локальный кеш, затем запрашивает IGDB при необходимости.
  /// [gameId] — ID игры в IGDB.
  /// [forceRefresh] — принудительное обновление из API.
  ///
  /// Возвращает игру или null, если не найдена.
  Future<Game?> getGameById(int gameId, {bool forceRefresh = false}) async {
    // Проверяем кеш, если не требуется принудительное обновление
    if (!forceRefresh) {
      final Game? cached = await _db.getGameById(gameId);
      if (cached != null && _isCacheValid(cached.cachedAt)) {
        return cached;
      }
    }

    // Запрашиваем из API
    final Game? game = await _api.getGameById(gameId);

    // Кешируем результат
    if (game != null) {
      await _db.upsertGame(game);
    }

    return game;
  }

  /// Получает несколько игр по списку ID.
  ///
  /// Оптимизирует запросы: кешированные игры берёт из БД,
  /// остальные запрашивает из IGDB.
  ///
  /// [gameIds] — список ID игр.
  /// [forceRefresh] — принудительное обновление всех игр из API.
  ///
  /// Возвращает список найденных игр.
  Future<List<Game>> getGamesByIds(
    List<int> gameIds, {
    bool forceRefresh = false,
  }) async {
    if (gameIds.isEmpty) return <Game>[];

    final List<Game> result = <Game>[];
    final List<int> idsToFetch = <int>[];

    if (!forceRefresh) {
      // Проверяем кеш
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

    // Запрашиваем недостающие из API
    if (idsToFetch.isNotEmpty) {
      final List<Game> fetched = await _api.getGamesByIds(idsToFetch);

      // Кешируем
      if (fetched.isNotEmpty) {
        await _db.upsertGames(fetched);
      }

      result.addAll(fetched);
    }

    return result;
  }

  /// Ищет игры в локальном кеше.
  ///
  /// Используется для оффлайн-поиска или быстрого автодополнения.
  Future<List<Game>> searchInCache(String query, {int limit = 20}) async {
    return _db.searchGamesInCache(query, limit: limit);
  }

  /// Очищает устаревший кеш.
  ///
  /// Возвращает количество удалённых записей.
  Future<int> clearStaleCache() async {
    return _db.clearStaleGames(maxAgeSeconds: cacheMaxAge);
  }

  /// Возвращает количество игр в кеше.
  Future<int> getCacheSize() async {
    return _db.getGameCount();
  }

  /// Проверяет валидность кеша.
  bool _isCacheValid(int? cachedAt) {
    if (cachedAt == null) return false;
    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now - cachedAt < cacheMaxAge;
  }
}
