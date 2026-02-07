import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/collection_repository.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/models/collection_game.dart';
import '../../../shared/models/collection_item.dart';
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
    // Инвалидируем статистику
    ref.invalidate(collectionStatsProvider(_collectionId));
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
    return true;
  }

  /// Удаляет игру из коллекции.
  Future<void> removeGame(int id) async {
    await _repository.removeGame(id);
    await refresh();
  }

  /// Обновляет статус игры.
  Future<void> updateStatus(int id, GameStatus status) async {
    await _repository.updateGameStatus(id, status);

    // Локальное обновление для быстрого UI
    final List<CollectionGame>? games = state.valueOrNull;
    if (games != null) {
      state = AsyncData<List<CollectionGame>>(
        games.map((CollectionGame g) {
          if (g.id == id) {
            return g.copyWith(status: status);
          }
          return g;
        }).toList(),
      );
    }

    // Обновляем статистику
    ref.invalidate(collectionStatsProvider(_collectionId));
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

    _loadItems();

    return const AsyncLoading<List<CollectionItem>>();
  }

  Future<void> _loadItems() async {
    state = const AsyncLoading<List<CollectionItem>>();
    state = await AsyncValue.guard(
      () => _repository.getItemsWithData(_collectionId),
    );
  }

  /// Обновляет список элементов.
  Future<void> refresh() async {
    await _loadItems();
    ref.invalidate(collectionStatsProvider(_collectionId));
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
    return true;
  }

  /// Удаляет элемент из коллекции.
  Future<void> removeItem(int id) async {
    await _repository.removeItem(id);
    await refresh();
  }

  /// Обновляет статус элемента.
  Future<void> updateStatus(int id, ItemStatus status, MediaType mediaType) async {
    await _repository.updateItemStatus(id, status, mediaType: mediaType);

    // Локальное обновление
    final List<CollectionItem>? items = state.valueOrNull;
    if (items != null) {
      state = AsyncData<List<CollectionItem>>(
        items.map((CollectionItem i) {
          if (i.id == id) {
            return i.copyWith(status: status);
          }
          return i;
        }).toList(),
      );
    }

    ref.invalidate(collectionStatsProvider(_collectionId));
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
