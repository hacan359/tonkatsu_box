import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/database/database_service.dart';
import '../../../data/repositories/collection_repository.dart';
import '../../../shared/models/collected_item_info.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/collection_sort_mode.dart';
import '../../../shared/models/game.dart';
import '../../../shared/models/item_status.dart';
import '../../../shared/models/media_type.dart';
import '../../../data/repositories/game_repository.dart';
import '../../home/providers/all_items_provider.dart';
import 'sort_utils.dart';

/// Провайдер для списка коллекций.
final AsyncNotifierProvider<CollectionsNotifier, List<Collection>>
    collectionsProvider =
    AsyncNotifierProvider<CollectionsNotifier, List<Collection>>(
  CollectionsNotifier.new,
);

/// Notifier для управления коллекциями.
class CollectionsNotifier extends AsyncNotifier<List<Collection>> {
  late CollectionRepository _repository;

  @override
  Future<List<Collection>> build() async {
    _repository = ref.watch(collectionRepositoryProvider);
    return _repository.getAll();
  }

  /// Обновляет список коллекций.
  Future<void> refresh() async {
    state = const AsyncLoading<List<Collection>>();
    state = await AsyncValue.guard(() => _repository.getAll());
  }

  /// Создаёт новую коллекцию.
  Future<Collection> create({
    required String name,
    required String author,
  }) async {
    final Collection collection = await _repository.create(
      name: name,
      author: author,
    );

    // Обновляем список
    final List<Collection> current = state.valueOrNull ?? <Collection>[];
    state = AsyncData<List<Collection>>(<Collection>[collection, ...current]);

    return collection;
  }

  /// Переименовывает коллекцию.
  Future<void> rename(int id, String newName) async {
    await _repository.updateName(id, newName);

    // Обновляем список
    final List<Collection> current = state.valueOrNull ?? <Collection>[];
    state = AsyncData<List<Collection>>(
      current.map((Collection c) {
        if (c.id == id) {
          return c.copyWith(name: newName);
        }
        return c;
      }).toList(),
    );
  }

  /// Удаляет коллекцию.
  Future<void> delete(int id) async {
    await _repository.delete(id);

    // Обновляем список
    final List<Collection> current = state.valueOrNull ?? <Collection>[];
    state = AsyncData<List<Collection>>(
      current.where((Collection c) => c.id != id).toList(),
    );

    // Инвалидируем связанные провайдеры
    ref.invalidate(collectionStatsProvider(id));
    ref.invalidate(allItemsNotifierProvider);
  }

}

/// Провайдер для статистики коллекции.
///
/// Если ключ == null, возвращает статистику uncategorized элементов.
final FutureProviderFamily<CollectionStats, int?> collectionStatsProvider =
    FutureProvider.family<CollectionStats, int?>(
  (Ref ref, int? collectionId) async {
    final CollectionRepository repository =
        ref.watch(collectionRepositoryProvider);
    return repository.getStats(collectionId);
  },
);

// ==================== Collection Sort ====================

/// Ключ SharedPreferences для режима сортировки коллекции.
String _sortModeKey(int? collectionId) =>
    'collection_sort_mode_${collectionId ?? "uncategorized"}';

/// Ключ SharedPreferences для направления сортировки.
String _sortDescKey(int? collectionId) =>
    'collection_sort_desc_${collectionId ?? "uncategorized"}';

/// Провайдер режима сортировки для конкретной коллекции.
///
/// Если ключ == null, используется для uncategorized элементов.
final NotifierProviderFamily<CollectionSortNotifier, CollectionSortMode, int?>
    collectionSortProvider =
    NotifierProvider.family<CollectionSortNotifier, CollectionSortMode, int?>(
  CollectionSortNotifier.new,
);

/// Notifier для режима сортировки коллекции.
class CollectionSortNotifier extends FamilyNotifier<CollectionSortMode, int?> {
  @override
  CollectionSortMode build(int? arg) {
    _loadFromPrefs(arg);
    return CollectionSortMode.addedDate;
  }

  Future<void> _loadFromPrefs(int? collectionId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? value = prefs.getString(_sortModeKey(collectionId));
    if (value != null) {
      state = CollectionSortMode.fromString(value);
    }
  }

  /// Устанавливает режим сортировки и сохраняет в SharedPreferences.
  ///
  /// Пересортировка происходит автоматически: `CollectionItemsNotifier`
  /// подписан на этот провайдер через `ref.watch`.
  Future<void> setSortMode(CollectionSortMode mode) async {
    state = mode;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sortModeKey(arg), mode.value);
  }
}

/// Провайдер направления сортировки (descending) для конкретной коллекции.
///
/// Если ключ == null, используется для uncategorized элементов.
final NotifierProviderFamily<CollectionSortDescNotifier, bool, int?>
    collectionSortDescProvider =
    NotifierProvider.family<CollectionSortDescNotifier, bool, int?>(
  CollectionSortDescNotifier.new,
);

/// Notifier для направления сортировки (ascending/descending).
class CollectionSortDescNotifier extends FamilyNotifier<bool, int?> {
  @override
  bool build(int? arg) {
    _loadFromPrefs(arg);
    return false;
  }

  Future<void> _loadFromPrefs(int? collectionId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool? value = prefs.getBool(_sortDescKey(collectionId));
    if (value != null) {
      state = value;
    }
  }

  /// Переключает направление сортировки.
  Future<void> toggle() async {
    state = !state;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sortDescKey(arg), state);
  }

  /// Устанавливает направление сортировки.
  Future<void> setDescending({required bool descending}) async {
    state = descending;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sortDescKey(arg), descending);
  }
}

// ==================== Collection Items ====================

/// Провайдер для управления элементами в конкретной коллекции.
///
/// Если ключ == null, управляет uncategorized элементами.
final NotifierProviderFamily<CollectionItemsNotifier,
        AsyncValue<List<CollectionItem>>, int?>
    collectionItemsNotifierProvider = NotifierProvider.family<
        CollectionItemsNotifier, AsyncValue<List<CollectionItem>>, int?>(
  CollectionItemsNotifier.new,
);

/// Notifier для управления элементами коллекции (универсальный).
class CollectionItemsNotifier
    extends FamilyNotifier<AsyncValue<List<CollectionItem>>, int?> {
  late CollectionRepository _repository;
  late int? _collectionId;

  @override
  AsyncValue<List<CollectionItem>> build(int? arg) {
    _collectionId = arg;
    _repository = ref.watch(collectionRepositoryProvider);

    // Подписываемся на режим и направление сортировки
    final CollectionSortMode sortMode =
        ref.watch(collectionSortProvider(_collectionId));
    final bool isDescending =
        ref.watch(collectionSortDescProvider(_collectionId));

    _loadItems(sortMode, isDescending: isDescending);

    return const AsyncLoading<List<CollectionItem>>();
  }

  Future<void> _loadItems(
    CollectionSortMode sortMode, {
    bool isDescending = false,
  }) async {
    state = const AsyncLoading<List<CollectionItem>>();
    state = await AsyncValue.guard(() async {
      List<CollectionItem> items =
          await _repository.getItemsWithData(_collectionId);

      // Дозагрузка платформ: если есть game-элементы с platformId, но без platform
      final bool hasMissingPlatforms = items.any(
        (CollectionItem item) =>
            item.mediaType == MediaType.game &&
            item.platformId != null &&
            item.platform == null,
      );
      if (hasMissingPlatforms) {
        final List<Game> gamesWithPlatforms = items
            .where(
              (CollectionItem item) =>
                  item.mediaType == MediaType.game && item.game != null,
            )
            .map((CollectionItem item) => item.game!)
            .toList();
        if (gamesWithPlatforms.isNotEmpty) {
          await ref
              .read(gameRepositoryProvider)
              .ensurePlatformsCached(gamesWithPlatforms);
          // Перезагружаем items с подгруженными платформами
          items = await _repository.getItemsWithData(_collectionId);
        }
      }

      return _applySortMode(items, sortMode, isDescending: isDescending);
    });
  }

  /// Применяет режим сортировки к списку элементов.
  List<CollectionItem> _applySortMode(
    List<CollectionItem> items,
    CollectionSortMode sortMode, {
    bool isDescending = false,
  }) {
    return applySortMode(items, sortMode, isDescending: isDescending);
  }

  /// Обновляет список элементов.
  Future<void> refresh() async {
    final CollectionSortMode sortMode =
        ref.read(collectionSortProvider(_collectionId));
    final bool isDescending =
        ref.read(collectionSortDescProvider(_collectionId));
    await _loadItems(sortMode, isDescending: isDescending);
    ref.invalidate(collectionStatsProvider(_collectionId));
  }

  /// Перемещает элемент с позиции [oldIndex] на [newIndex].
  ///
  /// Оптимистичное обновление UI + batch update sort_order в БД.
  Future<void> reorderItem(int oldIndex, int newIndex) async {
    final List<CollectionItem>? items = state.valueOrNull;
    if (items == null) return;

    // Оптимистичное обновление: переставляем в списке
    final List<CollectionItem> reordered = List<CollectionItem>.of(items);
    final CollectionItem moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);

    // Обновляем sortOrder
    final List<CollectionItem> updated = <CollectionItem>[];
    for (int i = 0; i < reordered.length; i++) {
      updated.add(reordered[i].copyWith(sortOrder: i));
    }
    state = AsyncData<List<CollectionItem>>(updated);

    // Сохраняем в БД
    final DatabaseService db = ref.read(databaseServiceProvider);
    final List<int> orderedIds =
        updated.map((CollectionItem item) => item.id).toList();
    await db.reorderItems(_collectionId, orderedIds);
  }

  /// Добавляет элемент в коллекцию.
  ///
  /// Возвращает true при успехе, false если элемент уже в коллекции.
  Future<bool> addItem({
    required MediaType mediaType,
    required int externalId,
    int? platformId,
    String? authorComment,
  }) async {
    final int? id = await _repository.addItem(
      collectionId: _collectionId,
      mediaType: mediaType,
      externalId: externalId,
      platformId: platformId,
      authorComment: authorComment,
    );

    if (id == null) return false;

    await refresh();
    _invalidateCollectedIds(mediaType);
    ref.invalidate(uncategorizedItemCountProvider);
    ref.invalidate(allItemsNotifierProvider);
    return true;
  }

  /// Перемещает элемент в другую коллекцию.
  ///
  /// Возвращает `({success: true, sourceEmpty: ...})` при успехе,
  /// `({success: false, sourceEmpty: false})` если элемент уже есть
  /// в целевой коллекции (дубликат).
  Future<({bool success, bool sourceEmpty})> moveItem(
    int itemId, {
    required int? targetCollectionId,
    required MediaType mediaType,
  }) async {
    final bool success = await _repository.moveItemToCollection(
      itemId,
      targetCollectionId,
    );
    if (!success) return (success: false, sourceEmpty: false);

    // Обновляем текущую коллекцию (элемент исчез).
    await refresh();

    // Проверяем, пуста ли исходная коллекция после переноса.
    final bool sourceEmpty = _collectionId != null &&
        (state.valueOrNull?.isEmpty ?? false);

    // Инвалидируем целевую коллекцию и статистики.
    ref.invalidate(collectionItemsNotifierProvider(targetCollectionId));
    ref.invalidate(collectionStatsProvider(targetCollectionId));
    ref.invalidate(collectionStatsProvider(_collectionId));
    ref.invalidate(uncategorizedItemCountProvider);
    _invalidateCollectedIds(mediaType);
    ref.invalidate(allItemsNotifierProvider);

    return (success: true, sourceEmpty: sourceEmpty);
  }

  /// Удаляет элемент из коллекции.
  Future<void> removeItem(int id, {MediaType? mediaType}) async {
    await _repository.removeItem(id);
    await refresh();
    if (mediaType != null) {
      _invalidateCollectedIds(mediaType);
    }
    ref.invalidate(uncategorizedItemCountProvider);
    ref.invalidate(allItemsNotifierProvider);
  }

  void _invalidateCollectedIds(MediaType mediaType) {
    switch (mediaType) {
      case MediaType.game:
        ref.invalidate(collectedGameIdsProvider);
      case MediaType.movie:
        ref.invalidate(collectedMovieIdsProvider);
      case MediaType.tvShow:
        ref.invalidate(collectedTvShowIdsProvider);
      case MediaType.animation:
        ref.invalidate(collectedAnimationIdsProvider);
      case MediaType.visualNovel:
        ref.invalidate(collectedVisualNovelIdsProvider);
    }
  }

  /// Обновляет статус элемента.
  ///
  /// Автоматически обновляет даты активности в локальном state:
  /// last_activity_at, started_at (при inProgress), completed_at (при completed).
  Future<void> updateStatus(int id, ItemStatus status, MediaType mediaType) async {
    await _repository.updateItemStatus(id, status, mediaType: mediaType);

    // Локальное обновление с датами
    final List<CollectionItem>? items = state.valueOrNull;
    if (items != null) {
      final DateTime now = DateTime.now();
      state = AsyncData<List<CollectionItem>>(
        items.map((CollectionItem i) {
          if (i.id == id) {
            if (status == ItemStatus.notStarted) {
              return i.copyWith(
                status: status,
                clearStartedAt: true,
                clearCompletedAt: true,
                lastActivityAt: now,
              );
            }
            if (status == ItemStatus.inProgress) {
              return i.copyWith(
                status: status,
                startedAt: i.startedAt ?? now,
                clearCompletedAt: true,
                lastActivityAt: now,
              );
            }
            // completed и другие статусы
            DateTime? newStartedAt = i.startedAt;
            DateTime? newCompletedAt = i.completedAt;
            if (status == ItemStatus.completed) {
              newCompletedAt = now;
              newStartedAt ??= now;
            }
            return i.copyWith(
              status: status,
              startedAt: newStartedAt,
              completedAt: newCompletedAt,
              lastActivityAt: now,
            );
          }
          return i;
        }).toList(),
      );
    }

    ref.invalidate(collectionStatsProvider(_collectionId));
    ref.invalidate(allItemsNotifierProvider);
  }

  /// Обновляет даты активности элемента вручную.
  ///
  /// Автоматически синхронизирует статус:
  /// - Установка [completedAt] → статус `completed` (с любого статуса).
  /// - Установка [startedAt] → статус `inProgress` (если был `notStarted`
  ///   или `planned`; `dropped`, `completed` и `inProgress` не меняются).
  Future<void> updateActivityDates(
    int id, {
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? lastActivityAt,
  }) async {
    await _repository.updateItemActivityDates(
      id,
      startedAt: startedAt,
      completedAt: completedAt,
      lastActivityAt: lastActivityAt,
    );

    // Локальное обновление
    final List<CollectionItem>? items = state.valueOrNull;
    if (items != null) {
      // Определяем новый статус на основе устанавливаемых дат.
      ItemStatus? newStatus;
      MediaType? mediaType;

      if (completedAt != null || startedAt != null) {
        final CollectionItem? target =
            items.where((CollectionItem i) => i.id == id).firstOrNull;
        if (target != null) {
          final ItemStatus currentStatus = target.status;
          mediaType = target.mediaType;

          if (completedAt != null && currentStatus != ItemStatus.completed) {
            newStatus = ItemStatus.completed;
          } else if (startedAt != null &&
              completedAt == null &&
              (currentStatus == ItemStatus.notStarted ||
                  currentStatus == ItemStatus.planned)) {
            newStatus = ItemStatus.inProgress;
          }
        }
      }

      // Сохраняем новый статус в БД.
      if (newStatus != null && mediaType != null) {
        await _repository.updateItemStatus(id, newStatus, mediaType: mediaType);
      }

      state = AsyncData<List<CollectionItem>>(
        items.map((CollectionItem i) {
          if (i.id == id) {
            return i.copyWith(
              startedAt: startedAt ?? i.startedAt,
              completedAt: completedAt ?? i.completedAt,
              lastActivityAt: lastActivityAt ?? i.lastActivityAt,
              status: newStatus ?? i.status,
            );
          }
          return i;
        }).toList(),
      );

      if (newStatus != null) {
        ref.invalidate(collectionStatsProvider(_collectionId));
        ref.invalidate(allItemsNotifierProvider);
      }
    }
  }

  /// Обновляет прогресс просмотра сериала.
  Future<void> updateProgress(
    int id, {
    int? currentSeason,
    int? currentEpisode,
  }) async {
    await _repository.updateItemProgress(
      id,
      currentSeason: currentSeason,
      currentEpisode: currentEpisode,
    );

    // Локальное обновление
    final List<CollectionItem>? items = state.valueOrNull;
    if (items != null) {
      state = AsyncData<List<CollectionItem>>(
        items.map((CollectionItem i) {
          if (i.id == id) {
            return i.copyWith(
              currentSeason: currentSeason ?? i.currentSeason,
              currentEpisode: currentEpisode ?? i.currentEpisode,
            );
          }
          return i;
        }).toList(),
      );
    }
  }

  /// Обновляет комментарий автора.
  Future<void> updateAuthorComment(int id, String? comment) async {
    await _repository.updateItemAuthorComment(id, comment);

    final List<CollectionItem>? items = state.valueOrNull;
    if (items != null) {
      state = AsyncData<List<CollectionItem>>(
        items.map((CollectionItem i) {
          if (i.id == id) {
            return comment == null
                ? i.copyWith(clearAuthorComment: true)
                : i.copyWith(authorComment: comment);
          }
          return i;
        }).toList(),
      );
    }
  }

  /// Обновляет личный комментарий.
  Future<void> updateUserComment(int id, String? comment) async {
    await _repository.updateItemUserComment(id, comment);

    final List<CollectionItem>? items = state.valueOrNull;
    if (items != null) {
      state = AsyncData<List<CollectionItem>>(
        items.map((CollectionItem i) {
          if (i.id == id) {
            return comment == null
                ? i.copyWith(clearUserComment: true)
                : i.copyWith(userComment: comment);
          }
          return i;
        }).toList(),
      );
    }
  }

  /// Обновляет пользовательский рейтинг (1-10 или null для сброса).
  Future<void> updateUserRating(int id, int? rating) async {
    assert(
      rating == null || (rating >= 1 && rating <= 10),
      'Rating must be 1-10 or null, got $rating',
    );
    await _repository.updateItemUserRating(id, rating);

    final List<CollectionItem>? items = state.valueOrNull;
    if (items != null) {
      state = AsyncData<List<CollectionItem>>(
        items.map((CollectionItem i) {
          if (i.id == id) {
            return rating == null
                ? i.copyWith(clearUserRating: true)
                : i.copyWith(userRating: rating);
          }
          return i;
        }).toList(),
      );
    }
    ref.invalidate(allItemsNotifierProvider);
  }
}

// ==================== Collected IDs ====================

/// Провайдер для информации о нахождении игр в коллекциях.
///
/// Возвращает `Map` igdb_id -> список записей в коллекциях.
final FutureProvider<Map<int, List<CollectedItemInfo>>>
    collectedGameIdsProvider =
    FutureProvider<Map<int, List<CollectedItemInfo>>>((Ref ref) async {
  final DatabaseService db = ref.watch(databaseServiceProvider);
  return db.getCollectedItemInfos(MediaType.game);
});

/// Провайдер для информации о нахождении фильмов в коллекциях.
///
/// Возвращает `Map` tmdb_id -> список записей в коллекциях.
final FutureProvider<Map<int, List<CollectedItemInfo>>>
    collectedMovieIdsProvider =
    FutureProvider<Map<int, List<CollectedItemInfo>>>((Ref ref) async {
  final DatabaseService db = ref.watch(databaseServiceProvider);
  return db.getCollectedItemInfos(MediaType.movie);
});

/// Провайдер для информации о нахождении сериалов в коллекциях.
///
/// Возвращает `Map` tmdb_id -> список записей в коллекциях.
final FutureProvider<Map<int, List<CollectedItemInfo>>>
    collectedTvShowIdsProvider =
    FutureProvider<Map<int, List<CollectedItemInfo>>>((Ref ref) async {
  final DatabaseService db = ref.watch(databaseServiceProvider);
  return db.getCollectedItemInfos(MediaType.tvShow);
});

/// Провайдер для информации о нахождении анимации в коллекциях.
///
/// Возвращает `Map` tmdb_id -> список записей в коллекциях.
final FutureProvider<Map<int, List<CollectedItemInfo>>>
    collectedAnimationIdsProvider =
    FutureProvider<Map<int, List<CollectedItemInfo>>>((Ref ref) async {
  final DatabaseService db = ref.watch(databaseServiceProvider);
  return db.getCollectedItemInfos(MediaType.animation);
});

/// Провайдер для информации о нахождении визуальных новелл в коллекциях.
///
/// Возвращает `Map` numeric_id -> список записей в коллекциях.
final FutureProvider<Map<int, List<CollectedItemInfo>>>
    collectedVisualNovelIdsProvider =
    FutureProvider<Map<int, List<CollectedItemInfo>>>((Ref ref) async {
  final DatabaseService db = ref.watch(databaseServiceProvider);
  return db.getCollectedItemInfos(MediaType.visualNovel);
});

/// Провайдер для количества uncategorized элементов.
final FutureProvider<int> uncategorizedItemCountProvider =
    FutureProvider<int>((Ref ref) async {
  final CollectionRepository repository =
      ref.watch(collectionRepositoryProvider);
  return repository.getUncategorizedCount();
});

/// Провайдер для собственных коллекций.
final Provider<List<Collection>> ownCollectionsProvider =
    Provider<List<Collection>>((Ref ref) {
  final AsyncValue<List<Collection>> allCollections =
      ref.watch(collectionsProvider);
  return allCollections.valueOrNull
          ?.where((Collection c) => c.type == CollectionType.own)
          .toList() ??
      <Collection>[];
});

