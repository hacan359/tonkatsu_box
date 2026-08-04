import 'package:core/models/canvas_connection.dart';
import 'package:core/models/canvas_item.dart';
import 'package:core/models/canvas_viewport.dart';
import 'package:core/models/collection_item.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../data/repositories/canvas_repository.dart';
import '../../../data/repositories/collection_repository.dart';
import 'canvas_operations_mixin.dart';
import 'canvas_state.dart';
import 'canvas_timer_mixin.dart';
import 'collections_provider.dart';
export 'canvas_operations_mixin.dart';
export 'canvas_state.dart';
export 'canvas_timer_mixin.dart';
export 'game_canvas_provider.dart';

final NotifierProviderFamily<CanvasNotifier, CanvasState, int?>
    canvasNotifierProvider =
    NotifierProvider.family<CanvasNotifier, CanvasState, int?>(
  CanvasNotifier.new,
);

/// Reactively syncs canvas items with the collection: when items are
/// added or removed in the collection, matching canvas items are
/// created or deleted automatically.
class CanvasNotifier extends FamilyNotifier<CanvasState, int?>
    with CanvasTimerMixin, CanvasOperationsMixin
    implements BaseCanvasController {
  static final Logger _log = Logger('CanvasNotifier');

  late CanvasRepository _repository;
  late int? _collectionId;
  bool _isSyncing = false;

  /// Bumped on every `_loadCanvas` so async hydration tasks started by an
  /// earlier load know to drop their result instead of overwriting fresh
  /// state — see the phase-2 enrichment in [_loadCanvas].
  int _loadGeneration = 0;

  // CanvasTimerMixin
  @override
  CanvasRepository get timerRepository => _repository;

  @override
  int get viewportId => _collectionId!;

  @override
  void persistViewport(CanvasViewport viewport) {
    _repository.saveViewport(viewport);
  }

  // CanvasOperationsMixin
  @override
  CanvasRepository get operationsRepository => _repository;

  @override
  int get collectionId => _collectionId!;

  @override
  int? get itemCollectionItemId => null;

  @override
  CanvasState build(int? arg) {
    _collectionId = arg;
    _repository = ref.watch(canvasRepositoryProvider);

    // Canvas is not supported for the uncategorized bucket.
    if (_collectionId == null) {
      return const CanvasState(isLoading: false, isInitialized: true);
    }

    ref.onDispose(cancelTimers);

    ref.listen<AsyncValue<List<CollectionItem>>>(
      collectionItemsNotifierProvider(_collectionId),
      (AsyncValue<List<CollectionItem>>? previous,
          AsyncValue<List<CollectionItem>> next) {
        final List<CollectionItem>? items = next.valueOrNull;
        if (items != null) {
          // Patch override_name into existing canvas items eagerly: this
          // covers the rename-while-loading window where the structural
          // _syncAndReload below skips because state.isLoading is true.
          _syncOverrideNames(items);
        }
        if (state.isInitialized && !state.isLoading && next.hasValue) {
          _syncAndReload();
        }
      },
    );

    Future<void>.microtask(_loadCanvas);

    return const CanvasState();
  }

  Future<void> _loadCanvas() async {
    if (_collectionId == null) return;
    final int cId = _collectionId!;
    final int gen = ++_loadGeneration;
    try {
      final bool hasItems = await _repository.hasCanvasItems(cId);

      if (!hasItems) {
        await _initializeFromItems();
        return;
      }

      await _syncCanvasWithItems();

      // Phase 1: paint a skeleton canvas with positions and types as soon
      // as the bare item rows are loaded — the media-table joins for
      // covers/titles run in phase 2 below.
      final (
        List<CanvasItem> rawItems,
        CanvasViewport? viewport,
        List<CanvasConnection> connections,
      ) = await (
        _repository.getItems(cId),
        _repository.getViewport(cId),
        _repository.getConnections(cId),
      ).wait;
      if (gen != _loadGeneration) return;

      state = state.copyWith(
        items: rawItems,
        connections: connections,
        viewport: viewport ?? CanvasViewport(collectionId: cId),
        isLoading: false,
        isInitialized: true,
      );

      // Phase 2: hydrate cover images and titles. A concurrent reload
      // (gen mismatch) discards this result, since its state is stale.
      final List<CanvasItem> enriched =
          await _repository.enrichItems(rawItems);
      if (gen != _loadGeneration) return;
      state = state.copyWith(items: enriched);
    } catch (e) {
      if (gen != _loadGeneration) return;
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> _initializeFromItems() async {
    if (_collectionId == null) return;
    final int cId = _collectionId!;
    try {
      // Provider value if available, otherwise read straight from DB.
      final AsyncValue<List<CollectionItem>> itemsAsync =
          ref.read(collectionItemsNotifierProvider(cId));
      final List<CollectionItem> allItems = itemsAsync.valueOrNull ??
          await ref.read(collectionRepositoryProvider).getItemsWithData(cId);

      final List<CanvasItem> items =
          await _repository.initializeCanvas(cId, allItems);

      state = state.copyWith(
        items: items,
        viewport: CanvasViewport(collectionId: cId),
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

  /// Triggered reactively when the collection items change. Guarded
  /// by [_isSyncing] against concurrent re-entry.
  Future<void> _syncAndReload() async {
    if (_collectionId == null || _isSyncing) return;
    _isSyncing = true;
    final int cId = _collectionId!;
    try {
      await _syncCanvasWithItems();
    } catch (e) {
      _log.warning('Canvas sync failed, proceeding to reload', e);
    }
    try {
      // Reload items even when the sync step failed.
      final List<CanvasItem> items =
          await _repository.getItemsWithData(cId);
      state = state.copyWith(items: items);
    } catch (e) {
      _log.warning('Canvas reload failed, keeping current state', e);
    } finally {
      _isSyncing = false;
    }
  }

  /// Two-way sync: removes canvas items that no longer exist in the
  /// collection, and creates canvas items for new collection entries.
  /// Matching uses `(itemType, itemRefId)` because collection-canvas
  /// rows carry `collection_item_id = NULL` — unlike game-canvas rows,
  /// which point at a specific `collection_item_id`.
  Future<void> _syncCanvasWithItems() async {
    if (_collectionId == null) return;
    final int cId = _collectionId!;
    final AsyncValue<List<CollectionItem>> itemsAsync =
        ref.read(collectionItemsNotifierProvider(cId));
    final List<CollectionItem> allItems = itemsAsync.valueOrNull ??
        await ref.read(collectionRepositoryProvider).getItemsWithData(cId);

    final List<CanvasItem> canvasItems =
        await _repository.getItems(cId);

    // Count copies of each (type, refId) on both sides; canvas surplus
    // over the collection count is removed.
    final Map<(String, int), int> collMediaCounts =
        <(String, int), int>{};
    for (final CollectionItem ci in allItems) {
      final (String, int) key =
          (CanvasItemType.fromMediaType(ci.mediaType).value, ci.externalId);
      collMediaCounts[key] = (collMediaCounts[key] ?? 0) + 1;
    }

    // Keep at most as many canvas items per key as the collection has.
    final Map<(String, int), int> seenCounts = <(String, int), int>{};
    final List<int> orphanIds = <int>[];
    for (final CanvasItem item in canvasItems) {
      if (item.itemType.isMediaItem && item.itemRefId != null) {
        final (String, int) key = (item.itemType.value, item.itemRefId!);
        final int allowed = collMediaCounts[key] ?? 0;
        final int seen = seenCounts[key] ?? 0;
        if (seen >= allowed) {
          orphanIds.add(item.id);
        } else {
          seenCounts[key] = seen + 1;
        }
      }
    }
    if (orphanIds.isNotEmpty) {
      await _repository.deleteItemsBatch(orphanIds);
    }

    // After the orphan pass, seenCounts holds the surviving canvas
    // count per key; here we find collection items still missing a
    // matching canvas item.
    final List<CollectionItem> missingItems = <CollectionItem>[];
    final Map<(String, int), int> addedCounts = <(String, int), int>{};
    for (final CollectionItem i in allItems) {
      final String typeValue =
          CanvasItemType.fromMediaType(i.mediaType).value;
      final (String, int) key = (typeValue, i.externalId);
      final int onCanvas = seenCounts[key] ?? 0;
      final int alreadyAdded = addedCounts[key] ?? 0;
      if (onCanvas + alreadyAdded < collMediaCounts[key]!) {
        missingItems.add(i);
        addedCounts[key] = alreadyAdded + 1;
      }
    }

    if (missingItems.isEmpty) return;

    double maxY = CanvasRepository.initialCenterY;
    for (final CanvasItem item in canvasItems) {
      final double bottom =
          item.y + (item.height ?? CanvasRepository.defaultCardHeight);
      if (bottom > maxY) maxY = bottom;
    }

    final double startY = canvasItems.isEmpty
        ? CanvasRepository.initialCenterY -
            CanvasRepository.defaultCardHeight / 2
        : maxY + CanvasRepository.gridGap;

    final int cols = missingItems.length < CanvasRepository.gridColumns
        ? missingItems.length
        : CanvasRepository.gridColumns;
    final double gridWidth =
        cols * (CanvasRepository.defaultCardWidth + CanvasRepository.gridGap) -
            CanvasRepository.gridGap;
    final double startX = CanvasRepository.initialCenterX - gridWidth / 2;

    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final int baseZIndex = canvasItems.isEmpty
        ? 0
        : canvasItems
                .map((CanvasItem item) => item.zIndex)
                .reduce((int a, int b) => a > b ? a : b) +
            1;

    // collectionItemId is intentionally null: collection-canvas rows
    // are stored with collection_item_id = NULL (getCanvasItems
    // filters by that).
    final List<CanvasItem> newItems = <CanvasItem>[
      for (int i = 0; i < missingItems.length; i++)
        CanvasItem(
          id: 0,
          collectionId: cId,
          itemType: CanvasItemType.fromMediaType(missingItems[i].mediaType),
          itemRefId: missingItems[i].externalId,
          x: startX +
              (i % cols) *
                  (CanvasRepository.defaultCardWidth +
                      CanvasRepository.gridGap),
          y: startY +
              (i ~/ cols) *
                  (CanvasRepository.defaultCardHeight +
                      CanvasRepository.gridGap),
          width: CanvasRepository.defaultCardWidth,
          height: CanvasRepository.defaultCardHeight,
          zIndex: baseZIndex + i,
          createdAt: DateTime.fromMillisecondsSinceEpoch(now * 1000),
        ),
    ];
    await _repository.createItemsBatch(newItems);
  }

  /// Collection-canvas items carry `collection_item_id = NULL`, so we match
  /// them to `collection_items` by `(itemType, itemRefId)` — same join key
  /// as `canvas_dao.getCanvasItems`. Multi-platform games produce several
  /// rows for one `(type, externalId)`; we take the first override, again
  /// mirroring the SQL `LIMIT 1`.
  void _syncOverrideNames(List<CollectionItem> collectionItems) {
    if (state.items.isEmpty) return;
    final Map<(String, int), String?> overridesByRef =
        <(String, int), String?>{};
    for (final CollectionItem ci in collectionItems) {
      final (String, int) key = (
        CanvasItemType.fromMediaType(ci.mediaType).value,
        ci.externalId,
      );
      overridesByRef.putIfAbsent(key, () => ci.overrideName);
    }

    bool changed = false;
    final List<CanvasItem> updated = state.items.map((CanvasItem item) {
      if (item.itemRefId == null || !item.itemType.isMediaItem) return item;
      final (String, int) key = (item.itemType.value, item.itemRefId!);
      if (!overridesByRef.containsKey(key)) return item;
      final String? fresh = overridesByRef[key];
      if (item.overrideName == fresh) return item;
      changed = true;
      return fresh == null
          ? item.copyWith(clearOverrideName: true)
          : item.copyWith(overrideName: fresh);
    }).toList();

    if (changed) {
      state = state.copyWith(items: updated);
    }
  }

  void removeByCollectionItemId(int collectionItemId) {
    if (_collectionId == null) return;
    final int cId = _collectionId!;
    state = state.copyWith(
      items: state.items
          .where((CanvasItem item) =>
              item.collectionItemId != collectionItemId)
          .toList(),
    );
    _repository.deleteByCollectionItemId(cId, collectionItemId);
  }

  void removeMediaItem(MediaType mediaType, int externalId) {
    if (_collectionId == null) return;
    final int cId = _collectionId!;
    final CanvasItemType canvasType =
        CanvasItemType.fromMediaType(mediaType);
    state = state.copyWith(
      items: state.items
          .where((CanvasItem item) =>
              !(item.itemType == canvasType &&
                  item.itemRefId == externalId))
          .toList(),
    );
    _repository.deleteMediaItem(cId, canvasType, externalId);
  }

  void removeGameItem(int igdbId) {
    removeMediaItem(MediaType.game, igdbId);
  }

  @override
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    await _loadCanvas();
  }
}
