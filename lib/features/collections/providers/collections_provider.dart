import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/database/database_service.dart';
import '../../../data/repositories/collection_repository.dart';
import '../../../shared/models/collected_item_info.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/models/collection_game.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/collection_sort_mode.dart';
import '../../../shared/models/item_status.dart';
import '../../../shared/models/media_type.dart';

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
    ref.invalidate(collectionGamesProvider(id));
    ref.invalidate(collectionStatsProvider(id));
  }

  /// Создаёт форк коллекции.
  Future<Collection> fork(int collectionId, String author) async {
    final Collection forked = await _repository.fork(collectionId, author);

    // Обновляем список
    await refresh();

    return forked;
  }

  /// Откатывает форк к оригиналу.
  Future<void> revertToOriginal(int collectionId) async {
    await _repository.revertToOriginal(collectionId);

    // Инвалидируем связанные провайдеры
    ref.invalidate(collectionGamesProvider(collectionId));
    ref.invalidate(collectionStatsProvider(collectionId));
  }
}

/// Провайдер для игр в коллекции.
final FutureProviderFamily<List<CollectionGame>, int> collectionGamesProvider =
    FutureProvider.family<List<CollectionGame>, int>(
  (Ref ref, int collectionId) async {
    final CollectionRepository repository =
        ref.watch(collectionRepositoryProvider);
    return repository.getGamesWithData(collectionId);
  },
);

/// Провайдер для статистики коллекции.
final FutureProviderFamily<CollectionStats, int> collectionStatsProvider =
    FutureProvider.family<CollectionStats, int>(
  (Ref ref, int collectionId) async {
    final CollectionRepository repository =
        ref.watch(collectionRepositoryProvider);
    return repository.getStats(collectionId);
  },
);

/// Провайдер для управления играми в конкретной коллекции.
final NotifierProviderFamily<CollectionGamesNotifier, AsyncValue<List<CollectionGame>>, int>
    collectionGamesNotifierProvider =
    NotifierProvider.family<CollectionGamesNotifier, AsyncValue<List<CollectionGame>>, int>(
  CollectionGamesNotifier.new,
);

/// Notifier для управления играми в коллекции.
class CollectionGamesNotifier
    extends FamilyNotifier<AsyncValue<List<CollectionGame>>, int> {
  late CollectionRepository _repository;
  late int _collectionId;

  @override
  AsyncValue<List<CollectionGame>> build(int arg) {
    _collectionId = arg;
    _repository = ref.watch(collectionRepositoryProvider);

    // Подписываемся на изменения
    _loadGames();

    return const AsyncLoading<List<CollectionGame>>();
  }

  Future<void> _loadGames() async {
    state = const AsyncLoading<List<CollectionGame>>();
    state = await AsyncValue.guard(
      () => _repository.getGamesWithData(_collectionId),
    );
  }

  /// Обновляет список игр.
  Future<void> refresh() async {
    await _loadGames();
    // Инвалидируем статистику и универсальный провайдер элементов
    ref.invalidate(collectionStatsProvider(_collectionId));
    ref.invalidate(collectionItemsNotifierProvider(_collectionId));
  }

  /// Добавляет игру в коллекцию.
  ///
  /// Возвращает true при успехе, false если игра уже в коллекции.
  Future<bool> addGame({
    required int igdbId,
    required int platformId,
    String? authorComment,
  }) async {
    final int? id = await _repository.addGame(
      collectionId: _collectionId,
      igdbId: igdbId,
      platformId: platformId,
      authorComment: authorComment,
    );

    if (id == null) return false;

    await refresh();
    ref.invalidate(collectedGameIdsProvider);
    return true;
  }

  /// Удаляет игру из коллекции.
  Future<void> removeGame(int id) async {
    await _repository.removeGame(id);
    await refresh();
    ref.invalidate(collectedGameIdsProvider);
  }

  /// Обновляет статус игры.
  ///
  /// Автоматически обновляет даты активности в локальном state.
  Future<void> updateStatus(int id, GameStatus status) async {
    await _repository.updateGameStatus(id, status);

    // Локальное обновление с датами
    final List<CollectionGame>? games = state.valueOrNull;
    if (games != null) {
      final DateTime now = DateTime.now();
      state = AsyncData<List<CollectionGame>>(
        games.map((CollectionGame g) {
          if (g.id == id) {
            DateTime? newStartedAt = g.startedAt;
            DateTime? newCompletedAt = g.completedAt;
            if (status == GameStatus.playing && g.startedAt == null) {
              newStartedAt = now;
            }
            if (status == GameStatus.completed) {
              newCompletedAt = now;
              newStartedAt ??= now;
            }
            return g.copyWith(
              status: status,
              startedAt: newStartedAt,
              completedAt: newCompletedAt,
              lastActivityAt: now,
            );
          }
          return g;
        }).toList(),
      );
    }

    // Обновляем статистику и синхронизируем универсальный провайдер
    ref.invalidate(collectionStatsProvider(_collectionId));
    ref.invalidate(collectionItemsNotifierProvider(_collectionId));
  }

  /// Обновляет даты активности игры вручную.
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
    final List<CollectionGame>? games = state.valueOrNull;
    if (games != null) {
      state = AsyncData<List<CollectionGame>>(
        games.map((CollectionGame g) {
          if (g.id == id) {
            return g.copyWith(
              startedAt: startedAt ?? g.startedAt,
              completedAt: completedAt ?? g.completedAt,
              lastActivityAt: lastActivityAt ?? g.lastActivityAt,
            );
          }
          return g;
        }).toList(),
      );
    }

    // Синхронизируем универсальный провайдер
    ref.invalidate(collectionItemsNotifierProvider(_collectionId));
  }

  /// Обновляет комментарий автора.
  Future<void> updateAuthorComment(int id, String? comment) async {
    await _repository.updateAuthorComment(id, comment);

    // Локальное обновление
    final List<CollectionGame>? games = state.valueOrNull;
    if (games != null) {
      state = AsyncData<List<CollectionGame>>(
        games.map((CollectionGame g) {
          if (g.id == id) {
            return g.copyWith(authorComment: comment);
          }
          return g;
        }).toList(),
      );
    }

    // Синхронизируем универсальный провайдер
    ref.invalidate(collectionItemsNotifierProvider(_collectionId));
  }

  /// Обновляет личный комментарий.
  Future<void> updateUserComment(int id, String? comment) async {
    await _repository.updateUserComment(id, comment);

    // Локальное обновление
    final List<CollectionGame>? games = state.valueOrNull;
    if (games != null) {
      state = AsyncData<List<CollectionGame>>(
        games.map((CollectionGame g) {
          if (g.id == id) {
            return g.copyWith(userComment: comment);
          }
          return g;
        }).toList(),
      );
    }

    // Синхронизируем универсальный провайдер
    ref.invalidate(collectionItemsNotifierProvider(_collectionId));
  }
}

// ==================== Collection Sort ====================

/// Ключ SharedPreferences для режима сортировки коллекции.
String _sortModeKey(int collectionId) =>
    'collection_sort_mode_$collectionId';

/// Провайдер режима сортировки для конкретной коллекции.
final NotifierProviderFamily<CollectionSortNotifier, CollectionSortMode, int>
    collectionSortProvider =
    NotifierProvider.family<CollectionSortNotifier, CollectionSortMode, int>(
  CollectionSortNotifier.new,
);

/// Notifier для режима сортировки коллекции.
class CollectionSortNotifier extends FamilyNotifier<CollectionSortMode, int> {
  @override
  CollectionSortMode build(int arg) {
    _loadFromPrefs(arg);
    return CollectionSortMode.addedDate;
  }

  Future<void> _loadFromPrefs(int collectionId) async {
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

// ==================== Collection Items ====================

/// Провайдер для управления элементами в конкретной коллекции.
final NotifierProviderFamily<CollectionItemsNotifier,
        AsyncValue<List<CollectionItem>>, int>
    collectionItemsNotifierProvider = NotifierProvider.family<
        CollectionItemsNotifier, AsyncValue<List<CollectionItem>>, int>(
  CollectionItemsNotifier.new,
);

/// Notifier для управления элементами коллекции (универсальный).
class CollectionItemsNotifier
    extends FamilyNotifier<AsyncValue<List<CollectionItem>>, int> {
  late CollectionRepository _repository;
  late int _collectionId;

  @override
  AsyncValue<List<CollectionItem>> build(int arg) {
    _collectionId = arg;
    _repository = ref.watch(collectionRepositoryProvider);

    // Подписываемся на режим сортировки
    final CollectionSortMode sortMode =
        ref.watch(collectionSortProvider(_collectionId));

    _loadItems(sortMode);

    return const AsyncLoading<List<CollectionItem>>();
  }

  Future<void> _loadItems(CollectionSortMode sortMode) async {
    state = const AsyncLoading<List<CollectionItem>>();
    state = await AsyncValue.guard(() async {
      final List<CollectionItem> items =
          await _repository.getItemsWithData(_collectionId);
      return _applySortMode(items, sortMode);
    });
  }

  /// Применяет режим сортировки к списку элементов.
  List<CollectionItem> _applySortMode(
    List<CollectionItem> items,
    CollectionSortMode sortMode,
  ) {
    final List<CollectionItem> sorted = List<CollectionItem>.of(items);
    switch (sortMode) {
      case CollectionSortMode.manual:
        sorted.sort(
          (CollectionItem a, CollectionItem b) =>
              a.sortOrder.compareTo(b.sortOrder),
        );
      case CollectionSortMode.addedDate:
        sorted.sort(
          (CollectionItem a, CollectionItem b) =>
              b.addedAt.compareTo(a.addedAt),
        );
      case CollectionSortMode.status:
        sorted.sort((CollectionItem a, CollectionItem b) {
          final int cmp =
              a.status.statusSortPriority.compareTo(b.status.statusSortPriority);
          if (cmp != 0) return cmp;
          return a.itemName.toLowerCase().compareTo(b.itemName.toLowerCase());
        });
      case CollectionSortMode.name:
        sorted.sort(
          (CollectionItem a, CollectionItem b) =>
              a.itemName.toLowerCase().compareTo(b.itemName.toLowerCase()),
        );
    }
    return sorted;
  }

  /// Обновляет список элементов.
  Future<void> refresh() async {
    final CollectionSortMode sortMode =
        ref.read(collectionSortProvider(_collectionId));
    await _loadItems(sortMode);
    ref.invalidate(collectionStatsProvider(_collectionId));
    ref.invalidate(collectionGamesNotifierProvider(_collectionId));
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
    return true;
  }

  /// Удаляет элемент из коллекции.
  Future<void> removeItem(int id, {MediaType? mediaType}) async {
    await _repository.removeItem(id);
    await refresh();
    if (mediaType != null) {
      _invalidateCollectedIds(mediaType);
    }
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
            DateTime? newStartedAt = i.startedAt;
            DateTime? newCompletedAt = i.completedAt;
            if (status == ItemStatus.inProgress && i.startedAt == null) {
              newStartedAt = now;
            }
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
  }

  /// Обновляет даты активности элемента вручную.
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
      state = AsyncData<List<CollectionItem>>(
        items.map((CollectionItem i) {
          if (i.id == id) {
            return i.copyWith(
              startedAt: startedAt ?? i.startedAt,
              completedAt: completedAt ?? i.completedAt,
              lastActivityAt: lastActivityAt ?? i.lastActivityAt,
            );
          }
          return i;
        }).toList(),
      );
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
            return i.copyWith(authorComment: comment);
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
            return i.copyWith(userComment: comment);
          }
          return i;
        }).toList(),
      );
    }
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

/// Провайдер для импортированных коллекций.
final Provider<List<Collection>> importedCollectionsProvider =
    Provider<List<Collection>>((Ref ref) {
  final AsyncValue<List<Collection>> allCollections =
      ref.watch(collectionsProvider);
  return allCollections.valueOrNull
          ?.where((Collection c) => c.type == CollectionType.imported)
          .toList() ??
      <Collection>[];
});

/// Провайдер для форков.
final Provider<List<Collection>> forkedCollectionsProvider =
    Provider<List<Collection>>((Ref ref) {
  final AsyncValue<List<Collection>> allCollections =
      ref.watch(collectionsProvider);
  return allCollections.valueOrNull
          ?.where((Collection c) => c.type == CollectionType.fork)
          .toList() ??
      <Collection>[];
});
