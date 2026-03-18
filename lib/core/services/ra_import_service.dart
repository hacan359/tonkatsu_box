// Сервис импорта RetroAchievements → IGDB игры.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../shared/models/collection.dart';
import '../../shared/models/collection_item.dart';
import '../../shared/models/game.dart';
import '../../shared/models/item_status.dart';
import '../../shared/models/media_type.dart';
import '../../shared/models/ra_game_progress.dart';
import '../../shared/models/universal_import_result.dart';
import '../../shared/models/wishlist_item.dart';
import '../api/igdb_api.dart';
import '../api/ra_api.dart';
import '../database/database_service.dart';
import 'ra_to_igdb_mapper.dart';

// ---------------------------------------------------------------------------
// Публичные модели
// ---------------------------------------------------------------------------

/// Этап импорта RetroAchievements.
enum RaImportStage {
  /// Загрузка библиотеки из RA API.
  fetchingLibrary,

  /// Поиск игр в IGDB и добавление в коллекцию.
  matchingGames,

  /// Импорт завершён.
  completed,
}

/// Прогресс импорта RetroAchievements.
class RaImportProgress {
  /// Создаёт [RaImportProgress].
  const RaImportProgress({
    required this.stage,
    this.current = 0,
    this.total = 0,
    this.currentName,
    this.addedCount = 0,
    this.updatedCount = 0,
    this.unmatchedCount = 0,
  });

  /// Текущий этап.
  final RaImportStage stage;

  /// Текущий прогресс.
  final int current;

  /// Общее количество.
  final int total;

  /// Название текущей обрабатываемой игры.
  final String? currentName;

  /// Количество добавленных игр.
  final int addedCount;

  /// Количество обновлённых игр.
  final int updatedCount;

  /// Количество ненайденных игр.
  final int unmatchedCount;
}

/// Результат импорта RetroAchievements.
class RaImportResult {
  /// Создаёт [RaImportResult].
  const RaImportResult({
    required this.totalGames,
    required this.added,
    required this.updated,
    required this.unmatched,
    required this.unmatchedTitles,
    required this.collectionId,
  });

  /// Общее количество игр в RA.
  final int totalGames;

  /// Новые элементы в коллекцию.
  final int added;

  /// Обновлена мета у существующих.
  final int updated;

  /// Не найдено в IGDB.
  final int unmatched;

  /// Названия ненайденных игр.
  final List<String> unmatchedTitles;

  /// ID целевой коллекции.
  final int collectionId;
}

/// Расширение для преобразования в [UniversalImportResult].
extension RaImportResultToUniversal on RaImportResult {
  /// Преобразует в [UniversalImportResult] для унифицированного экрана.
  UniversalImportResult toUniversal({Collection? collection}) {
    return UniversalImportResult(
      sourceName: 'RetroAchievements',
      success: true,
      collection: collection,
      collectionId: collectionId,
      importedByType: added > 0
          ? <MediaType, int>{MediaType.game: added}
          : <MediaType, int>{},
      updatedByType: updated > 0
          ? <MediaType, int>{MediaType.game: updated}
          : <MediaType, int>{},
      wishlistedByType: unmatched > 0
          ? <MediaType, int>{MediaType.game: unmatched}
          : <MediaType, int>{},
    );
  }
}

// ---------------------------------------------------------------------------
// Сервис
// ---------------------------------------------------------------------------

/// Провайдер для RA import service.
final Provider<RaImportService> raImportServiceProvider =
    Provider<RaImportService>((Ref ref) {
  return RaImportService(
    raApi: ref.watch(raApiProvider),
    igdbApi: ref.watch(igdbApiProvider),
    database: ref.watch(databaseServiceProvider),
  );
});

/// Сервис импорта игр из RetroAchievements.
///
/// Загружает список играных игр из RA, маппит на IGDB,
/// добавляет/обновляет в целевой коллекции.
class RaImportService {
  /// Создаёт [RaImportService].
  RaImportService({
    required RaApi raApi,
    required IgdbApi igdbApi,
    required DatabaseService database,
  })  : _raApi = raApi,
        _igdbApi = igdbApi,
        _db = database;

  final RaApi _raApi;
  final IgdbApi _igdbApi;
  final DatabaseService _db;
  static final Logger _log = Logger('RaImportService');

  /// Импортирует игры из RA профиля в коллекцию.
  Future<RaImportResult> importFromProfile({
    required String raUsername,
    required int collectionId,
    required bool addToWishlist,
    required void Function(RaImportProgress) onProgress,
  }) async {
    final RaToIgdbMapper mapper = RaToIgdbMapper(_igdbApi);

    onProgress(const RaImportProgress(
      stage: RaImportStage.fetchingLibrary,
    ));

    // Загружаем игры и даты наград параллельно.
    final (List<RaGameProgress> raGames, Map<int, DateTime> awardDates) =
        await (
      _raApi.getCompletedGames(raUsername),
      _raApi.getUserAwardDates(raUsername),
    ).wait;

    int added = 0;
    int updated = 0;
    int unmatched = 0;
    final List<String> unmatchedTitles = <String>[];

    // Фильтруем не-игровые записи (Hubs, Events, Standalone).
    final List<RaGameProgress> games =
        raGames.where((RaGameProgress g) => g.isRealGame).toList();

    for (int i = 0; i < games.length; i++) {
      final RaGameProgress raGame = games[i];

      onProgress(RaImportProgress(
        stage: RaImportStage.matchingGames,
        current: i + 1,
        total: games.length,
        currentName: raGame.title,
        addedCount: added,
        updatedCount: updated,
        unmatchedCount: unmatched,
      ));

      // Найти в IGDB.
      final Game? igdbGame = await mapper.findIgdbGame(raGame);

      if (igdbGame == null) {
        unmatched++;
        unmatchedTitles.add('${raGame.title} (${raGame.consoleName})');
        if (addToWishlist) {
          await _addToWishlistIfNotExists(raGame);
        }
        // Rate limit.
        await Future<void>.delayed(const Duration(milliseconds: 300));
        continue;
      }

      // Проверить дубликат ТОЛЬКО В ЦЕЛЕВОЙ КОЛЛЕКЦИИ.
      final CollectionItem? existing = await _db.findCollectionItem(
        collectionId: collectionId,
        mediaType: MediaType.game,
        externalId: igdbGame.id,
      );

      final DateTime? completedAt = awardDates[raGame.gameId];

      if (existing != null) {
        final bool wasUpdated = await _updateExistingItem(
          existing,
          raGame,
          completedAt: completedAt,
        );
        if (wasUpdated) updated++;
      } else {
        // Кэшировать игру и добавить в коллекцию.
        await _db.upsertGame(igdbGame);
        await _addToCollection(
          collectionId: collectionId,
          game: igdbGame,
          raGame: raGame,
          completedAt: completedAt,
        );
        added++;
      }

      // Rate limit: 300ms между IGDB запросами.
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }

    onProgress(RaImportProgress(
      stage: RaImportStage.completed,
      current: games.length,
      total: games.length,
      addedCount: added,
      updatedCount: updated,
      unmatchedCount: unmatched,
    ));

    _log.info(
      'RA import done: $added added, $updated updated, '
      '$unmatched unmatched out of ${games.length}',
    );

    return RaImportResult(
      totalGames: games.length,
      added: added,
      updated: updated,
      unmatched: unmatched,
      unmatchedTitles: unmatchedTitles,
      collectionId: collectionId,
    );
  }

  /// Обновляет мету существующего элемента. Не понижает статус.
  Future<bool> _updateExistingItem(
    CollectionItem existing,
    RaGameProgress raGame, {
    DateTime? completedAt,
  }) async {
    bool changed = false;

    // Статус: только повышение.
    final ItemStatus raStatus = raGame.itemStatus;
    if (_isHigherStatus(raStatus, existing.status)) {
      await _db.updateItemStatus(
        existing.id,
        raStatus,
        mediaType: MediaType.game,
      );
      changed = true;
    }

    // Author comment: обновляем RA строку в authorComment.
    final String? raComment = _buildRaComment(raGame);
    if (raComment != null && raComment != existing.authorComment) {
      await _db.updateItemAuthorComment(existing.id, raComment);
      changed = true;
    }

    // Activity dates: completedAt и lastActivityAt.
    final DateTime? lastActivity = raGame.lastPlayedAt;
    if (completedAt != null || lastActivity != null) {
      await _db.updateItemActivityDates(
        existing.id,
        completedAt: completedAt,
        lastActivityAt: lastActivity,
      );
      changed = true;
    }

    return changed;
  }

  /// Проверяет что новый статус выше текущего.
  ///
  /// completed и dropped не перезаписываются.
  static bool _isHigherStatus(ItemStatus newStatus, ItemStatus existing) {
    if (existing == ItemStatus.completed) return false;
    if (existing == ItemStatus.dropped) return false;
    const Map<ItemStatus, int> priority = <ItemStatus, int>{
      ItemStatus.planned: 0,
      ItemStatus.notStarted: 0,
      ItemStatus.inProgress: 1,
      ItemStatus.completed: 2,
    };
    return (priority[newStatus] ?? 0) > (priority[existing] ?? 0);
  }

  /// Формирует строку RA комментария.
  String? _buildRaComment(RaGameProgress raGame) {
    if (raGame.maxPossible <= 0) return null;
    final String pct = (raGame.completionRate * 100).toStringAsFixed(0);
    final StringBuffer sb = StringBuffer()
      ..write('RA: ${raGame.numAwarded}/${raGame.maxPossible} ')
      ..write('achievements ($pct%)');
    if (raGame.highestAwardKind != null) {
      sb.write(' \u2022 ${raGame.highestAwardKind}');
    }
    return sb.toString();
  }

  Future<void> _addToWishlistIfNotExists(RaGameProgress raGame) async {
    final String title = '${raGame.title} (${raGame.consoleName})';
    final WishlistItem? existing = await _db.findUnresolvedWishlistItem(title);
    if (existing != null) return;

    await _db.addWishlistItem(
      text: title,
      mediaTypeHint: MediaType.game,
      note: 'From RetroAchievements \u2022 '
          '${raGame.numAwarded}/${raGame.maxPossible} achievements'
          '${raGame.highestAwardKind != null ? ' \u2022 ${raGame.highestAwardKind}' : ''}',
    );
  }

  Future<void> _addToCollection({
    required int collectionId,
    required Game game,
    required RaGameProgress raGame,
    DateTime? completedAt,
  }) async {
    final int? platformId =
        RaToIgdbMapper.consolePlatformMap[raGame.consoleId];
    final int? itemId = await _db.addItemToCollection(
      collectionId: collectionId,
      mediaType: MediaType.game,
      externalId: game.id,
      platformId: platformId,
      status: raGame.itemStatus,
      authorComment: _buildRaComment(raGame),
    );

    // Устанавливаем activity dates.
    if (itemId != null) {
      final DateTime? lastActivity = raGame.lastPlayedAt;
      if (completedAt != null || lastActivity != null) {
        await _db.updateItemActivityDates(
          itemId,
          startedAt: lastActivity,
          completedAt: completedAt,
          lastActivityAt: lastActivity,
        );
      }
    }
  }
}
