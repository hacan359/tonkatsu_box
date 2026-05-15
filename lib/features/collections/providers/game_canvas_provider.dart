import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/canvas_repository.dart';
import '../../../shared/models/canvas_connection.dart';
import '../../../shared/models/canvas_item.dart';
import '../../../shared/models/canvas_viewport.dart';
import '../../../shared/models/collection_item.dart';
import 'canvas_operations_mixin.dart';
import 'canvas_state.dart';
import 'canvas_timer_mixin.dart';
import 'collections_provider.dart';

/// Провайдер для управления per-item canvas.
///
/// Ключ — `({collectionId, collectionItemId})`.
/// В отличие от [canvasNotifierProvider], per-item canvas:
/// - Не синхронизируется реактивно с элементами коллекции
/// - Автоинициализируется одним медиа-элементом (игра/фильм/сериал)
/// - Поддерживает game/movie/tvShow/text/image/link элементы
final NotifierProviderFamily<GameCanvasNotifier, CanvasState,
        ({int? collectionId, int collectionItemId})>
    gameCanvasNotifierProvider = NotifierProvider.family<GameCanvasNotifier,
        CanvasState, ({int? collectionId, int collectionItemId})>(
  GameCanvasNotifier.new,
);

/// Notifier для управления per-item canvas.
///
/// Упрощённая версия [CanvasNotifier] без реактивной синхронизации
/// с элементами коллекции. Каждый элемент коллекции имеет свой canvas.
class GameCanvasNotifier
    extends FamilyNotifier<CanvasState,
        ({int? collectionId, int collectionItemId})>
    with CanvasTimerMixin, CanvasOperationsMixin
    implements BaseCanvasController {
  late CanvasRepository _repository;
  late int? _collectionId;
  late int _collectionItemId;

  // CanvasTimerMixin
  @override
  CanvasRepository get timerRepository => _repository;

  @override
  int get viewportId => _collectionItemId;

  @override
  void persistViewport(CanvasViewport viewport) {
    _repository.saveGameCanvasViewport(_collectionItemId, viewport);
  }

  // CanvasOperationsMixin
  @override
  CanvasRepository get operationsRepository => _repository;

  @override
  int get collectionId => _collectionId!;

  @override
  int? get itemCollectionItemId => _collectionItemId;

  @override
  CanvasState build(({int? collectionId, int collectionItemId}) arg) {
    _collectionId = arg.collectionId;
    _collectionItemId = arg.collectionItemId;
    _repository = ref.watch(canvasRepositoryProvider);

    ref.onDispose(cancelTimers);

    // Per-item canvas has no structural sync loop; without this listener
    // a rename in collection_items would not propagate to the live state.
    ref.listen<AsyncValue<List<CollectionItem>>>(
      collectionItemsNotifierProvider(_collectionId),
      (AsyncValue<List<CollectionItem>>? previous,
          AsyncValue<List<CollectionItem>> next) {
        final List<CollectionItem>? items = next.valueOrNull;
        if (items == null) return;
        CollectionItem? match;
        for (final CollectionItem ci in items) {
          if (ci.id == _collectionItemId) {
            match = ci;
            break;
          }
        }
        if (match == null) return;
        _syncOverrideName(match.overrideName);
      },
    );

    // Загружаем canvas после инициализации state
    Future<void>.microtask(_loadCanvas);

    return const CanvasState();
  }

  /// In-memory patch only — `override_name` lives on `collection_items` and
  /// is rejoined on the next canvas reload, so no DB write here.
  void _syncOverrideName(String? overrideName) {
    if (!state.isInitialized) return;
    bool changed = false;
    final List<CanvasItem> updated = state.items.map((CanvasItem item) {
      if (item.collectionItemId != _collectionItemId) return item;
      if (item.overrideName == overrideName) return item;
      changed = true;
      return overrideName == null
          ? item.copyWith(clearOverrideName: true)
          : item.copyWith(overrideName: overrideName);
    }).toList();
    if (changed) {
      state = state.copyWith(items: updated);
    }
  }

  Future<void> _loadCanvas() async {
    try {
      final bool hasItems =
          await _repository.hasGameCanvasItems(_collectionItemId);

      if (!hasItems) {
        await _initializeWithCollectionItem();
        return;
      }

      final (
        List<CanvasItem> items,
        CanvasViewport? viewport,
        List<CanvasConnection> connections,
      ) = await (
        _repository.getGameCanvasItemsWithData(_collectionItemId),
        _repository.getGameCanvasViewport(_collectionItemId),
        _repository.getGameCanvasConnections(_collectionItemId),
      ).wait;

      state = state.copyWith(
        items: items,
        connections: connections,
        viewport: viewport ??
            CanvasViewport(collectionId: _collectionItemId),
        isLoading: false,
        isInitialized: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Инициализирует per-item canvas с одним медиа-элементом.
  Future<void> _initializeWithCollectionItem() async {
    final AsyncValue<List<CollectionItem>> itemsAsync =
        ref.read(collectionItemsNotifierProvider(_collectionId));
    final List<CollectionItem> allItems =
        itemsAsync.valueOrNull ?? <CollectionItem>[];

    CollectionItem? collectionItem;
    for (final CollectionItem item in allItems) {
      if (item.id == _collectionItemId) {
        collectionItem = item;
        break;
      }
    }

    if (collectionItem == null) {
      state = state.copyWith(
        viewport: CanvasViewport(collectionId: _collectionItemId),
        isLoading: false,
        isInitialized: true,
      );
      return;
    }

    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final CanvasItemType canvasType =
        CanvasItemType.fromMediaType(collectionItem.mediaType);

    // Размещаем единственный элемент по центру canvas
    const double x = CanvasRepository.initialCenterX -
        CanvasRepository.defaultCardWidth / 2;
    const double y = CanvasRepository.initialCenterY -
        CanvasRepository.defaultCardHeight / 2;

    final CanvasItem item = CanvasItem(
      id: 0,
      collectionId: _collectionId!,
      collectionItemId: _collectionItemId,
      itemType: canvasType,
      itemRefId: collectionItem.externalId,
      x: x,
      y: y,
      width: CanvasRepository.defaultCardWidth,
      height: CanvasRepository.defaultCardHeight,
      zIndex: 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(now * 1000),
    );

    final CanvasItem created = await _repository.createItem(item);
    final CanvasItem enriched = created.copyWith(
      game: collectionItem.game,
      movie: collectionItem.movie,
      tvShow: collectionItem.tvShow,
      visualNovel: collectionItem.visualNovel,
      manga: collectionItem.manga,
      customMedia: collectionItem.customMedia,
    );

    await _repository.saveGameCanvasViewport(
      _collectionItemId,
      CanvasViewport(collectionId: _collectionItemId),
    );

    state = state.copyWith(
      items: <CanvasItem>[enriched],
      viewport: CanvasViewport(collectionId: _collectionItemId),
      isLoading: false,
      isInitialized: true,
    );
  }

  /// Перезагрузка canvas из БД.
  @override
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    await _loadCanvas();
  }
}
