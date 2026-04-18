import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/database/dao/collection_dao.dart';
import '../../../core/database/database_service.dart';
import '../../../data/repositories/collection_repository.dart';
import '../../../core/services/image_cache_service.dart';
import '../../../shared/models/collected_item_info.dart';
import '../../../shared/models/custom_media.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/collection_list_sort_mode.dart';
import '../../../shared/models/collection_sort_mode.dart';
import '../../../shared/models/game.dart';
import '../../../shared/models/item_status.dart';
import '../../../shared/models/item_status_logic.dart';
import '../../../shared/models/media_type.dart';
import '../../../data/repositories/game_repository.dart';
import '../../home/providers/all_items_provider.dart';
import '../../../core/database/dao/tag_dao.dart';
import '../../../core/database/dao/tier_list_dao.dart';
import '../../tier_lists/providers/tier_list_detail_provider.dart';
import '../../settings/providers/profile_provider.dart';
import '../../settings/providers/settings_provider.dart';
import 'collection_covers_provider.dart';
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
    ref.invalidate(collectionCoversProvider(id));
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
    return CollectionSortMode.lastActivity;
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

// ==================== Collection List Sort & View ====================

/// Ключ SharedPreferences для режима сортировки списка коллекций.
const String _collectionListSortModeKey = 'collection_list_sort_mode';

/// Ключ SharedPreferences для направления сортировки списка коллекций.
const String _collectionListSortDescKey = 'collection_list_sort_desc';

/// Ключ SharedPreferences для режима отображения (grid/list).
const String _collectionListGridViewKey = 'collection_list_grid_view';

/// Провайдер режима сортировки списка коллекций.
final NotifierProvider<CollectionListSortNotifier, CollectionListSortMode>
    collectionListSortProvider =
    NotifierProvider<CollectionListSortNotifier, CollectionListSortMode>(
  CollectionListSortNotifier.new,
);

/// Notifier для режима сортировки списка коллекций.
class CollectionListSortNotifier extends Notifier<CollectionListSortMode> {
  @override
  CollectionListSortMode build() {
    _loadFromPrefs();
    return CollectionListSortMode.createdDate;
  }

  Future<void> _loadFromPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? value = prefs.getString(_collectionListSortModeKey);
    if (value != null) {
      state = CollectionListSortMode.fromString(value);
    }
  }

  /// Устанавливает режим сортировки и сохраняет в SharedPreferences.
  Future<void> setSortMode(CollectionListSortMode mode) async {
    state = mode;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_collectionListSortModeKey, mode.value);
  }
}

/// Провайдер направления сортировки списка коллекций.
final NotifierProvider<CollectionListSortDescNotifier, bool>
    collectionListSortDescProvider =
    NotifierProvider<CollectionListSortDescNotifier, bool>(
  CollectionListSortDescNotifier.new,
);

/// Notifier для направления сортировки списка коллекций.
class CollectionListSortDescNotifier extends Notifier<bool> {
  @override
  bool build() {
    _loadFromPrefs();
    return false;
  }

  Future<void> _loadFromPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool? value = prefs.getBool(_collectionListSortDescKey);
    if (value != null) {
      state = value;
    }
  }

  /// Переключает направление сортировки.
  Future<void> toggle() async {
    state = !state;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_collectionListSortDescKey, state);
  }

  /// Устанавливает направление сортировки.
  Future<void> setDescending({required bool descending}) async {
    state = descending;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_collectionListSortDescKey, descending);
  }
}

/// Провайдер режима отображения списка коллекций (grid/list).
final NotifierProvider<CollectionListViewModeNotifier, bool>
    collectionListViewModeProvider =
    NotifierProvider<CollectionListViewModeNotifier, bool>(
  CollectionListViewModeNotifier.new,
);

/// Notifier для режима отображения (true = grid, false = list).
class CollectionListViewModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    _loadFromPrefs();
    return true;
  }

  Future<void> _loadFromPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool? value = prefs.getBool(_collectionListGridViewKey);
    if (value != null) {
      state = value;
    }
  }

  /// Переключает режим отображения.
  Future<void> toggle() async {
    state = !state;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_collectionListGridViewKey, state);
  }
}

// ==================== Home Status Filter ====================

/// Ключ SharedPreferences для фильтра статуса на главной.
const String _homeStatusFilterKey = 'home_status_filter';

/// Провайдер фильтра статуса на главном экране.
///
/// `null` означает "Все" (без фильтра).
/// По умолчанию: `null` (без фильтра).
final NotifierProvider<HomeStatusFilterNotifier, ItemStatus?>
    homeStatusFilterProvider =
    NotifierProvider<HomeStatusFilterNotifier, ItemStatus?>(
  HomeStatusFilterNotifier.new,
);

/// Notifier для фильтра статуса на главном экране.
///
/// Сохраняет выбор per-profile: ключ `home_status_filter_{profileId}`.
class HomeStatusFilterNotifier extends Notifier<ItemStatus?> {
  String get _prefsKey {
    final String profileId = ref.read(currentProfileProvider).id;
    return '${_homeStatusFilterKey}_$profileId';
  }

  @override
  ItemStatus? build() {
    final SharedPreferences prefs = ref.watch(sharedPreferencesProvider);
    final String? value = prefs.getString(_prefsKey);
    if (value == null) return null;
    if (value == 'all') return null;
    return ItemStatus.fromString(value);
  }

  /// Устанавливает фильтр статуса и сохраняет в SharedPreferences.
  void setFilter(ItemStatus? status) {
    state = status;
    ref.read(sharedPreferencesProvider).setString(
      _prefsKey,
      status?.value ?? 'all',
    );
  }
}

/// ID коллекций, содержащих элементы с указанным статусом.
///
/// Пересчитывается при изменении фильтра или обновлении коллекций.
final FutureProvider<Set<int?>> filteredCollectionIdsProvider =
    FutureProvider<Set<int?>>((Ref ref) async {
  final ItemStatus? status = ref.watch(homeStatusFilterProvider);
  if (status == null) return const <int?>{};

  // Зависимость от collectionsProvider гарантирует пересчёт при изменении данных
  ref.watch(collectionsProvider);

  final CollectionDao dao = ref.read(collectionDaoProvider);
  return dao.getCollectionIdsWithStatus(status);
});

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
  late CollectionSortMode _sortMode;
  late bool _isDescending;
  late DatabaseService _db;
  late GameRepository _gameRepository;

  @override
  AsyncValue<List<CollectionItem>> build(int? arg) {
    _collectionId = arg;
    _repository = ref.watch(collectionRepositoryProvider);
    _db = ref.watch(databaseServiceProvider);
    _gameRepository = ref.watch(gameRepositoryProvider);

    // Подписываемся на режим и направление сортировки
    _sortMode = ref.watch(collectionSortProvider(_collectionId));
    _isDescending = ref.watch(collectionSortDescProvider(_collectionId));

    _loadItems(_sortMode, isDescending: _isDescending);

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
          await _gameRepository
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

  /// Обновляет тег элемента без полной перезагрузки списка.
  /// Оптимистично обновляет даты активности и статус элемента в state.
  void updateItemDates(
    int itemId, {
    DateTime? startedAt,
    DateTime? lastActivityAt,
    DateTime? completedAt,
    ItemStatus? status,
  }) {
    final List<CollectionItem>? items = state.valueOrNull;
    if (items == null) return;

    state = AsyncData<List<CollectionItem>>(
      items.map((CollectionItem item) {
        if (item.id == itemId) {
          return item.copyWith(
            startedAt: startedAt,
            lastActivityAt: lastActivityAt,
            completedAt: completedAt,
            status: status ?? item.status,
          );
        }
        return item;
      }).toList(),
    );
  }

  void updateItemTag(int itemId, int? tagId) {
    final List<CollectionItem>? items = state.valueOrNull;
    if (items == null) return;

    state = AsyncData<List<CollectionItem>>(
      items.map((CollectionItem item) {
        if (item.id == itemId) {
          return item.copyWith(tagId: tagId, clearTagId: tagId == null);
        }
        return item;
      }).toList(),
    );
  }

  /// Обновляет список элементов.
  Future<void> refresh() async {
    await _loadItems(_sortMode, isDescending: _isDescending);
    ref.invalidate(collectionStatsProvider(_collectionId));
    ref.invalidate(collectionCoversProvider(_collectionId));
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
    final List<int> orderedIds =
        updated.map((CollectionItem item) => item.id).toList();
    await _db.reorderItems(_collectionId, orderedIds);
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

  /// Создаёт кастомный элемент и добавляет его в коллекцию.
  ///
  /// Создаёт запись в `custom_items`, затем добавляет `CollectionItem`
  /// с `mediaType = custom` и `externalId = customItem.id`.
  /// При [localCoverPath] != null — копирует файл в кэш изображений.
  Future<bool> addCustomItem(
    CustomMedia customMedia, {
    String? localCoverPath,
  }) async {
    try {
      final int customId = await _db.customMediaDao.create(customMedia);
      final ImageCacheService cache = ref.read(imageCacheServiceProvider);

      if (localCoverPath != null) {
        final File sourceFile = File(localCoverPath);
        if (sourceFile.existsSync()) {
          final Uint8List bytes = await sourceFile.readAsBytes();
          final bool saved = await cache.saveImageBytes(
            ImageType.customCover,
            customId.toString(),
            bytes,
          );
          // Маркер в cover_url — CachedImage получит непустой imageUrl
          // и найдёт файл в кэше, не обращаясь к сети.
          if (saved) {
            await _db.customMediaDao.update(
              customMedia.copyWith(id: customId, coverUrl: CustomMedia.localCoverMarker),
            );
          }
        }
      } else if (customMedia.coverUrl != null &&
          customMedia.coverUrl!.isNotEmpty) {
        await cache.downloadImage(
          type: ImageType.customCover,
          imageId: customId.toString(),
          remoteUrl: customMedia.coverUrl!,
        );
      }

      final int? itemId = await _repository.addItem(
        collectionId: _collectionId,
        mediaType: MediaType.custom,
        externalId: customId,
      );

      if (itemId == null) return false;

      await refresh();
      ref.invalidate(uncategorizedItemCountProvider);
      ref.invalidate(allItemsNotifierProvider);
      return true;
    } catch (e, stack) {
      debugPrint('addCustomItem error: $e\n$stack'); // TODO: remove after stabilization
      return false;
    }
  }

  /// Клонирует элемент в другую коллекцию (полная копия).
  ///
  /// Возвращает true при успехе, false если элемент уже в целевой коллекции.
  Future<bool> cloneItem(
    int itemId, {
    required int targetCollectionId,
    required MediaType mediaType,
  }) async {
    final int? newId = await _repository.cloneItemToCollection(
      itemId,
      targetCollectionId,
    );
    if (newId == null) return false;

    // Инвалидируем целевую коллекцию и статистики.
    ref.invalidate(collectionItemsNotifierProvider(targetCollectionId));
    ref.invalidate(collectionStatsProvider(targetCollectionId));
    ref.invalidate(collectionCoversProvider(targetCollectionId));
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
    // Удаляем элемент из тир-листов исходной коллекции до перемещения.
    final TierListDao tierDao = ref.read(tierListDaoProvider);
    final List<int> affectedTierListIds =
        await tierDao.getTierListIdsForItem(itemId);
    if (_collectionId != null) {
      await tierDao.removeItemFromCollectionTierLists(
        itemId,
        _collectionId!,
      );
    }

    // Обнуляем тег элемента (теги привязаны к коллекции).
    final TagDao tagDao = ref.read(tagDaoProvider);
    await tagDao.setItemTag(itemId, null);

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
    ref.invalidate(collectionCoversProvider(targetCollectionId));
    ref.invalidate(collectionStatsProvider(_collectionId));
    ref.invalidate(collectionCoversProvider(_collectionId));
    ref.invalidate(uncategorizedItemCountProvider);
    _invalidateCollectedIds(mediaType);
    ref.invalidate(allItemsNotifierProvider);

    // Инвалидируем тир-листы, содержавшие перемещённый элемент.
    for (final int tierListId in affectedTierListIds) {
      ref.invalidate(tierListDetailProvider(tierListId));
    }

    return (success: true, sourceEmpty: sourceEmpty);
  }

  /// Удаляет элемент из коллекции.
  Future<void> removeItem(int id, {MediaType? mediaType}) async {
    // Запоминаем тир-листы до удаления (CASCADE удалит entries из БД).
    final TierListDao tierDao = ref.read(tierListDaoProvider);
    final List<int> affectedTierListIds =
        await tierDao.getTierListIdsForItem(id);

    await _repository.removeItem(id);
    await refresh();
    if (mediaType != null) {
      _invalidateCollectedIds(mediaType);
    }
    ref.invalidate(uncategorizedItemCountProvider);
    ref.invalidate(allItemsNotifierProvider);

    // Инвалидируем тир-листы, содержавшие удалённый элемент.
    for (final int tierListId in affectedTierListIds) {
      ref.invalidate(tierListDetailProvider(tierListId));
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
      case MediaType.visualNovel:
        ref.invalidate(collectedVisualNovelIdsProvider);
      case MediaType.manga:
        ref.invalidate(collectedMangaIdsProvider);
      case MediaType.anime:
        ref.invalidate(collectedAnimeIdsProvider);
      case MediaType.custom:
        break; // Кастомные элементы не имеют collected IDs провайдера
    }
  }

  /// Обновляет статус элемента.
  ///
  /// Автоматически обновляет даты активности в локальном state:
  /// last_activity_at, started_at (при inProgress), completed_at (при completed).
  /// Логика дат вынесена в [computeDatesForStatus] — та же функция используется
  /// для внешнего sync (Kodi) с кастомным `now`.
  Future<void> updateStatus(int id, ItemStatus status, MediaType mediaType) async {
    await _repository.updateItemStatus(id, status, mediaType: mediaType);

    // Локальное обновление с датами
    final List<CollectionItem>? items = state.valueOrNull;
    if (items != null) {
      final DateTime now = DateTime.now();
      state = AsyncData<List<CollectionItem>>(
        items.map((CollectionItem i) {
          if (i.id != id) return i;
          final StatusDatesUpdate update = computeDatesForStatus(
            newStatus: status,
            currentStartedAt: i.startedAt,
            currentCompletedAt: i.completedAt,
            now: now,
          );
          return i.copyWith(
            status: update.status,
            startedAt: update.startedAt,
            completedAt: update.completedAt,
            lastActivityAt: update.lastActivityAt,
            clearStartedAt: update.clearStartedAt,
            clearCompletedAt: update.clearCompletedAt,
          );
        }).toList(),
      );
    }

    ref.invalidate(collectionStatsProvider(_collectionId));
    ref.invalidate(collectionCoversProvider(_collectionId));
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
          mediaType = target.mediaType;
          newStatus = computeStatusForDates(
            currentStatus: target.status,
            newCompletedAt: completedAt,
            newStartedAt: startedAt,
          );
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
        ref.invalidate(collectionCoversProvider(_collectionId));
        ref.invalidate(allItemsNotifierProvider);
      }
    }
  }

  /// Обновляет прогресс просмотра сериала или чтения манги.
  ///
  /// Для манги автоматически обновляет статус:
  /// - `notStarted`/`planned` → `inProgress` при начале чтения.
  /// - → `completed` при достижении последней главы.
  /// - → `notStarted` при сбросе прогресса до нуля.
  /// - `dropped` никогда не перезаписывается.
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

      // Авто-статус для манги и аниме
      await _autoUpdateMangaStatus(id, currentEpisode, currentSeason);
      await _autoUpdateAnimeStatus(id, currentEpisode);
    }
  }

  /// Автоматически обновляет статус манги на основе прогресса чтения.
  Future<void> _autoUpdateMangaStatus(
    int id,
    int? newChapterValue,
    int? newVolumeValue,
  ) async {
    final CollectionItem? item =
        state.valueOrNull?.where((CollectionItem i) => i.id == id).firstOrNull;
    if (item == null || item.mediaType != MediaType.manga) return;

    final int newChapter = newChapterValue ?? item.currentEpisode;
    final int newVolume = newVolumeValue ?? item.currentSeason;
    final int? totalChapters = item.manga?.chapters;

    final ItemStatus? targetStatus = computeStatusFromProgress(
      currentStatus: item.status,
      hasAnyProgress: newChapter > 0 || newVolume > 0,
      isFullyCompleted:
          totalChapters != null && newChapter >= totalChapters,
    );

    if (targetStatus != null) {
      await updateStatus(id, targetStatus, MediaType.manga);
    }
  }

  /// Автоматически обновляет статус аниме на основе прогресса просмотра.
  Future<void> _autoUpdateAnimeStatus(
    int id,
    int? newEpisodeValue,
  ) async {
    final CollectionItem? item =
        state.valueOrNull?.where((CollectionItem i) => i.id == id).firstOrNull;
    if (item == null || item.mediaType != MediaType.anime) return;

    final int newEpisode = newEpisodeValue ?? item.currentEpisode;
    final int? totalEpisodes = item.anime?.episodes;

    final ItemStatus? targetStatus = computeStatusFromProgress(
      currentStatus: item.status,
      hasAnyProgress: newEpisode > 0,
      isFullyCompleted:
          totalEpisodes != null && newEpisode >= totalEpisodes,
    );

    if (targetStatus != null) {
      await updateStatus(id, targetStatus, MediaType.anime);
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

  /// Добавляет время (в минутах) к потраченному на элемент.
  Future<void> addTimeSpent(int id, int minutesToAdd) async {
    final List<CollectionItem>? items = state.valueOrNull;
    final CollectionItem? item =
        items?.cast<CollectionItem?>().firstWhere(
              (CollectionItem? i) => i?.id == id,
              orElse: () => null,
            );
    final int current = item?.timeSpentMinutes ?? 0;
    final int total = current + minutesToAdd;
    await _repository.updateItemTimeSpent(id, total);

    if (items != null) {
      state = AsyncData<List<CollectionItem>>(
        items.map((CollectionItem i) {
          if (i.id == id) {
            return i.copyWith(timeSpentMinutes: total);
          }
          return i;
        }).toList(),
      );
    }
    ref.invalidate(allItemsNotifierProvider);
  }

  /// Устанавливает потраченное время (в минутах) вручную.
  Future<void> setTimeSpent(int id, int totalMinutes) async {
    await _repository.updateItemTimeSpent(id, totalMinutes);

    final List<CollectionItem>? items = state.valueOrNull;
    if (items != null) {
      state = AsyncData<List<CollectionItem>>(
        items.map((CollectionItem i) {
          if (i.id == id) {
            return i.copyWith(timeSpentMinutes: totalMinutes);
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

/// Провайдер для информации о нахождении манги в коллекциях.
///
/// Возвращает `Map` numeric_id -> список записей в коллекциях.
final FutureProvider<Map<int, List<CollectedItemInfo>>>
    collectedMangaIdsProvider =
    FutureProvider<Map<int, List<CollectedItemInfo>>>((Ref ref) async {
  final DatabaseService db = ref.watch(databaseServiceProvider);
  return db.getCollectedItemInfos(MediaType.manga);
});

/// Провайдер для информации о нахождении аниме в коллекциях.
///
/// Возвращает `Map` anilist_id -> список записей в коллекциях.
final FutureProvider<Map<int, List<CollectedItemInfo>>>
    collectedAnimeIdsProvider =
    FutureProvider<Map<int, List<CollectedItemInfo>>>((Ref ref) async {
  final DatabaseService db = ref.watch(databaseServiceProvider);
  return db.getCollectedItemInfos(MediaType.anime);
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

