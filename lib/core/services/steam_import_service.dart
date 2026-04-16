// Сервис импорта библиотеки Steam → IGDB игры.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../shared/models/collection_item.dart';
import '../../shared/models/collection.dart';
import '../../shared/models/game.dart';
import '../../shared/models/item_status.dart';
import '../../shared/models/item_status_logic.dart';
import '../../shared/models/media_type.dart';
import '../../shared/models/universal_import_result.dart';
import '../../shared/models/wishlist_item.dart';
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
    this.updatedCount = 0,
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

  /// Количество обновлённых (дубликаты с обновлёнными данными).
  final int updatedCount;

  /// Прогресс в долях (0.0 – 1.0).
  double get progress => total > 0 ? current / total : 0;
}

/// Результат импорта Steam библиотеки.
class SteamImportResult {
  /// Создаёт [SteamImportResult].
  const SteamImportResult({
    required this.imported,
    required this.wishlisted,
    required this.updated,
    required this.total,
    required this.collectionId,
  });

  /// Количество импортированных игр.
  final int imported;

  /// Количество добавленных в вишлист (не найдены в IGDB).
  final int wishlisted;

  /// Количество обновлённых (дубликаты с обновлёнными данными).
  final int updated;

  /// Общее количество игр в библиотеке (после фильтрации DLC).
  final int total;

  /// ID коллекции импорта.
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
  /// [collectionId] — ID целевой коллекции (если уже создана).
  /// [createCollection] — callback для ленивого создания коллекции.
  ///   Вызывается только после успешной загрузки библиотеки Steam,
  ///   чтобы не создавать пустую коллекцию при ошибке API.
  ///   Должен быть указан либо [collectionId], либо [createCollection].
  /// [onProgress] — callback прогресса.
  Future<SteamImportResult> importLibrary({
    required String apiKey,
    required String steamId,
    int? collectionId,
    Future<int> Function()? createCollection,
    required void Function(SteamImportProgress) onProgress,
  }) async {
    if (collectionId == null && createCollection == null) {
      throw ArgumentError(
        'Either collectionId or createCollection must be provided',
      );
    }

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

    // 3. Создание коллекции (если нужно) — только после успешной загрузки.
    final int targetCollectionId =
        collectionId ?? await createCollection!();

    // 4. Batch-поиск всех игр в IGDB по Steam App ID (1-2 запроса).
    onProgress(SteamImportProgress(
      stage: SteamImportStage.matchingGames,
      current: 0,
      total: games.length,
    ));

    final Map<String, Game> igdbMatches = await _igdbApi.lookupSteamGames(
      games.map((SteamOwnedGame g) => g.appId.toString()).toList(),
    );

    _log.info('IGDB matched ${igdbMatches.length}/${games.length} games');

    // 5. Обработка каждой игры.
    int imported = 0;
    int wishlisted = 0;
    int updated = 0;

    for (int i = 0; i < games.length; i++) {
      final SteamOwnedGame steamGame = games[i];

      onProgress(SteamImportProgress(
        stage: SteamImportStage.matchingGames,
        current: i + 1,
        total: games.length,
        currentName: steamGame.name,
        importedCount: imported,
        wishlistedCount: wishlisted,
        updatedCount: updated,
      ));

      final Game? match = igdbMatches[steamGame.appId.toString()];

      if (match == null) {
        await _addToWishlist(steamGame);
        wishlisted++;
        _log.fine('Not found in IGDB, added to wishlist: ${steamGame.name}');
        continue;
      }

      // Проверка дубликата
      final CollectionItem? existing = await _db.findCollectionItem(
        collectionId: targetCollectionId,
        mediaType: MediaType.game,
        externalId: match.id,
      );
      if (existing != null) {
        await _updateExistingItem(existing, steamGame);
        updated++;
        continue;
      }

      // Кэшировать IGDB игру
      await _db.upsertGame(match);

      // Добавить в коллекцию
      final ItemStatus status = steamGame.playtimeMinutes > 0
          ? ItemStatus.inProgress
          : ItemStatus.notStarted;

      final int? itemId = await _db.addItemToCollection(
        collectionId: targetCollectionId,
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
            lastActivityAt: steamGame.lastPlayed,
          );
        }
      }

      imported++;
    }

    _log.info('Steam import complete: $imported imported, '
        '$wishlisted wishlisted, $updated updated');

    onProgress(SteamImportProgress(
      stage: SteamImportStage.completed,
      current: games.length,
      total: games.length,
      importedCount: imported,
      wishlistedCount: wishlisted,
      updatedCount: updated,
    ));

    return SteamImportResult(
      imported: imported,
      wishlisted: wishlisted,
      updated: updated,
      total: games.length,
      collectionId: targetCollectionId,
    );
  }

  /// Обновляет существующий элемент коллекции данными из Steam.
  ///
  /// Повышает статус через [mergeExternalStatus] (защищает от понижения
  /// и локальный `dropped`), обновляет playtime-комментарий и дату последней
  /// игры.
  Future<void> _updateExistingItem(
    CollectionItem existing,
    SteamOwnedGame steamGame,
  ) async {
    // Повышаем статус через общее правило: Steam означает "в процессе",
    // если есть playtime. mergeExternalStatus не понизит completed и не
    // тронет dropped.
    if (steamGame.playtimeMinutes > 0) {
      final ItemStatus? newStatus = mergeExternalStatus(
        currentStatus: existing.status,
        externalStatus: ItemStatus.inProgress,
      );
      if (newStatus != null) {
        await _db.updateItemStatus(
          existing.id,
          newStatus,
          mediaType: MediaType.game,
        );
      }
    }

    // Обновляем playtime комментарий
    if (steamGame.playtimeMinutes > 0) {
      final String playtimeText = _formatPlaytime(steamGame);
      await _db.updateItemUserComment(existing.id, 'Steam: $playtimeText');
    }

    // Обновляем lastActivityAt если есть данные
    if (steamGame.lastPlayed != null) {
      await _db.updateItemActivityDates(
        existing.id,
        lastActivityAt: steamGame.lastPlayed,
      );
    }
  }

  /// Добавляет ненайденную Steam игру в вишлист.
  ///
  /// Если в вишлисте уже есть активный элемент с таким же именем,
  /// обновляет его заметку вместо создания дубликата.
  Future<void> _addToWishlist(SteamOwnedGame steamGame) async {
    final String? note = steamGame.playtimeMinutes > 0
        ? 'Steam: ${_formatPlaytime(steamGame)}'
        : null;

    // Проверяем наличие дубликата в вишлисте
    final WishlistItem? existing =
        await _db.findUnresolvedWishlistItem(steamGame.name);

    if (existing != null) {
      // Обновляем заметку если есть новые данные о playtime
      if (note != null && note != existing.note) {
        await _db.updateWishlistItem(existing.id, note: note);
      }
      return;
    }

    await _db.addWishlistItem(
      text: steamGame.name,
      mediaTypeHint: MediaType.game,
      note: note,
    );
  }


  /// Форматирует время в игре.
  static String _formatPlaytime(SteamOwnedGame game) {
    if (game.playtimeMinutes >= 60) {
      return '${game.playtimeHours.toStringAsFixed(1)}h';
    }
    return '${game.playtimeMinutes}min';
  }
}

// ---------------------------------------------------------------------------
// Extension: toUniversal()
// ---------------------------------------------------------------------------

/// Конвертация [SteamImportResult] в [UniversalImportResult].
extension SteamImportResultToUniversal on SteamImportResult {
  /// Преобразует в универсальный результат.
  UniversalImportResult toUniversal({Collection? collection}) {
    final Map<MediaType, int> importedByType = <MediaType, int>{};
    final Map<MediaType, int> wishlistedByType = <MediaType, int>{};
    final Map<MediaType, int> updatedByType = <MediaType, int>{};

    if (imported > 0) {
      importedByType[MediaType.game] = imported;
    }
    if (wishlisted > 0) {
      wishlistedByType[MediaType.game] = wishlisted;
    }
    if (updated > 0) {
      updatedByType[MediaType.game] = updated;
    }

    return UniversalImportResult(
      sourceName: 'Steam',
      success: true,
      collection: collection,
      collectionId: collectionId,
      importedByType: importedByType,
      wishlistedByType: wishlistedByType,
      updatedByType: updatedByType,
      skipped: (total - imported - wishlisted - updated).clamp(0, total),
    );
  }
}
