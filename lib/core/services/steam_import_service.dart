// Сервис импорта библиотеки Steam → IGDB игры.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../shared/models/collection_item.dart';
import '../../shared/models/game.dart';
import '../../shared/models/item_status.dart';
import '../../shared/models/media_type.dart';
import '../api/igdb_api.dart';
import '../api/steam_api.dart';
import '../database/database_service.dart';

// ---------------------------------------------------------------------------
// Публичные модели
// ---------------------------------------------------------------------------

/// Этап импорта Steam библиотеки.
enum SteamImportStage {
  /// Загрузка библиотеки из Steam API.
  fetchingLibrary,

  /// Поиск игр в IGDB и добавление в коллекцию.
  matchingGames,

  /// Импорт завершён.
  completed,
}

/// Прогресс импорта Steam библиотеки.
class SteamImportProgress {
  /// Создаёт [SteamImportProgress].
  const SteamImportProgress({
    required this.stage,
    required this.current,
    required this.total,
    this.currentName,
    this.importedCount = 0,
    this.wishlistedCount = 0,
    this.skippedCount = 0,
  });

  /// Текущий этап.
  final SteamImportStage stage;

  /// Текущий прогресс.
  final int current;

  /// Общее количество.
  final int total;

  /// Название текущей обрабатываемой игры.
  final String? currentName;

  /// Количество импортированных игр.
  final int importedCount;

  /// Количество добавленных в вишлист (не найдены в IGDB).
  final int wishlistedCount;

  /// Количество пропущенных (дубликаты).
  final int skippedCount;

  /// Прогресс в долях (0.0 – 1.0).
  double get progress => total > 0 ? current / total : 0;
}

/// Результат импорта Steam библиотеки.
class SteamImportResult {
  /// Создаёт [SteamImportResult].
  const SteamImportResult({
    required this.imported,
    required this.wishlisted,
    required this.skipped,
    required this.total,
    required this.collectionId,
  });

  /// Количество импортированных игр.
  final int imported;

  /// Количество добавленных в вишлист (не найдены в IGDB).
  final int wishlisted;

  /// Количество пропущенных (дубликаты).
  final int skipped;

  /// Общее количество игр в библиотеке (после фильтрации DLC).
  final int total;

  /// ID созданной коллекции.
  final int collectionId;
}

// ---------------------------------------------------------------------------
// Провайдер
// ---------------------------------------------------------------------------

/// Провайдер для [SteamImportService].
final Provider<SteamImportService> steamImportServiceProvider =
    Provider<SteamImportService>((Ref ref) {
  return SteamImportService(
    steamApi: ref.watch(steamApiProvider),
    igdbApi: ref.watch(igdbApiProvider),
    database: ref.watch(databaseServiceProvider),
  );
});

// ---------------------------------------------------------------------------
// Сервис
// ---------------------------------------------------------------------------

/// Сервис импорта библиотеки Steam в коллекцию IGDB-игр.
class SteamImportService {
  /// Создаёт [SteamImportService].
  SteamImportService({
    required SteamApi steamApi,
    required IgdbApi igdbApi,
    required DatabaseService database,
  })  : _steamApi = steamApi,
        _igdbApi = igdbApi,
        _db = database;

  static final Logger _log = Logger('SteamImportService');

  /// IGDB platform ID для "PC (Microsoft Windows)".
  static const int _pcPlatformId = 6;

  final SteamApi _steamApi;
  final IgdbApi _igdbApi;
  final DatabaseService _db;

  /// Импортирует библиотеку Steam в коллекцию IGDB-игр.
  ///
  /// [apiKey] — Steam Web API ключ.
  /// [steamId] — 64-битный Steam ID пользователя.
  /// [authorName] — имя автора для коллекции (из Settings).
  /// [onProgress] — callback прогресса.
  Future<SteamImportResult> importLibrary({
    required String apiKey,
    required String steamId,
    required String authorName,
    required void Function(SteamImportProgress) onProgress,
  }) async {
    // 1. Получить библиотеку Steam
    onProgress(const SteamImportProgress(
      stage: SteamImportStage.fetchingLibrary,
      current: 0,
      total: 0,
    ));

    final List<SteamOwnedGame> library = await _steamApi.getOwnedGames(
      apiKey: apiKey,
      steamId: steamId,
    );

    // 2. Фильтрация DLC/саундтреков
    final List<SteamOwnedGame> games = library
        .where((SteamOwnedGame g) => !g.shouldSkip)
        .toList();

    final int filteredCount = library.length - games.length;
    if (filteredCount > 0) {
      _log.info('Filtered $filteredCount DLC/soundtracks from '
          '${library.length} total');
    }

    if (games.isEmpty) {
      throw const SteamApiException('No games found in this Steam library');
    }

    // 3. Создать коллекцию
    final int collectionId = (await _db.createCollection(
      name: 'Steam Library',
      author: authorName,
    ))
        .id;

    // 4. Для каждой игры — поиск в IGDB + добавление
    int imported = 0;
    int wishlisted = 0;
    int skipped = 0;

    for (int i = 0; i < games.length; i++) {
      final SteamOwnedGame steamGame = games[i];

      onProgress(SteamImportProgress(
        stage: SteamImportStage.matchingGames,
        current: i + 1,
        total: games.length,
        currentName: steamGame.name,
        importedCount: imported,
        wishlistedCount: wishlisted,
        skippedCount: skipped,
      ));

      try {
        final List<Game> results = await _igdbApi.searchGames(
          query: steamGame.name,
          limit: 5,
        );

        final Game? match = _findBestMatch(results, steamGame.name);

        if (match == null) {
          await _addToWishlist(steamGame);
          wishlisted++;
          _log.fine('Not found in IGDB, added to wishlist: ${steamGame.name}');
          continue;
        }

        // Проверка дубликата
        final CollectionItem? existing = await _db.findCollectionItem(
          collectionId: collectionId,
          mediaType: MediaType.game,
          externalId: match.id,
        );
        if (existing != null) {
          skipped++;
          continue;
        }

        // Кэшировать IGDB игру
        await _db.upsertGame(match);

        // Добавить в коллекцию
        final ItemStatus status = steamGame.playtimeMinutes > 0
            ? ItemStatus.inProgress
            : ItemStatus.notStarted;

        final int? itemId = await _db.addItemToCollection(
          collectionId: collectionId,
          mediaType: MediaType.game,
          externalId: match.id,
          platformId: _pcPlatformId,
          status: status,
        );

        // Обновить userComment и startedAt (если есть playtime)
        if (itemId != null && steamGame.playtimeMinutes > 0) {
          final String playtimeText = _formatPlaytime(steamGame);
          await _db.updateItemUserComment(itemId, 'Steam: $playtimeText');

          if (steamGame.lastPlayed != null) {
            await _db.updateItemActivityDates(
              itemId,
              startedAt: steamGame.lastPlayed,
            );
          }
        }

        imported++;
      } on IgdbApiException catch (e) {
        _log.warning('IGDB error for ${steamGame.name}', e);
        await _addToWishlist(steamGame);
        wishlisted++;
      }

      // Rate limiting: IGDB 4 req/sec
      if (i % 4 == 3) {
        await Future<void>.delayed(const Duration(milliseconds: 1100));
      }
    }

    _log.info('Steam import complete: $imported imported, '
        '$wishlisted wishlisted, $skipped skipped');

    onProgress(SteamImportProgress(
      stage: SteamImportStage.completed,
      current: games.length,
      total: games.length,
      importedCount: imported,
      wishlistedCount: wishlisted,
      skippedCount: skipped,
    ));

    return SteamImportResult(
      imported: imported,
      wishlisted: wishlisted,
      skipped: skipped,
      total: games.length,
      collectionId: collectionId,
    );
  }

  /// Добавляет ненайденную Steam игру в вишлист.
  Future<void> _addToWishlist(SteamOwnedGame steamGame) async {
    final String? note = steamGame.playtimeMinutes > 0
        ? 'Steam: ${_formatPlaytime(steamGame)}'
        : null;

    await _db.addWishlistItem(
      text: steamGame.name,
      mediaTypeHint: MediaType.game,
      note: note,
    );
  }

  /// Ищет лучшее совпадение IGDB результата с именем Steam игры.
  Game? _findBestMatch(List<Game> results, String steamName) {
    if (results.isEmpty) return null;

    final String normalized = steamName.toLowerCase().trim();

    // Точное совпадение
    for (final Game game in results) {
      if (game.name.toLowerCase().trim() == normalized) {
        return game;
      }
    }

    // Первый результат содержит имя как подстроку
    for (final Game game in results) {
      final String gameLower = game.name.toLowerCase().trim();
      if (gameLower.contains(normalized) || normalized.contains(gameLower)) {
        return game;
      }
    }

    // Первый результат (IGDB сортирует по релевантности)
    return results.first;
  }

  /// Форматирует время в игре.
  String _formatPlaytime(SteamOwnedGame game) {
    if (game.playtimeMinutes >= 60) {
      return '${game.playtimeHours.toStringAsFixed(1)}h';
    }
    return '${game.playtimeMinutes}min';
  }
}
