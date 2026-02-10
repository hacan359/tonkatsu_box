import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/export_service.dart';
import '../../../core/services/image_cache_service.dart';
import '../../../core/services/xcoll_file.dart';
import '../../../shared/widgets/cached_image.dart';
import '../../../data/repositories/collection_repository.dart';
import '../../../shared/constants/media_type_theme.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/collection_sort_mode.dart';
import '../../../shared/models/item_status.dart';
import '../../../shared/models/media_type.dart';
import '../../search/screens/search_screen.dart';
import '../../../data/repositories/canvas_repository.dart';
import '../../../shared/models/steamgriddb_image.dart';
import '../providers/canvas_provider.dart';
import '../providers/collections_provider.dart';
import '../providers/steamgriddb_panel_provider.dart';
import '../providers/vgmaps_panel_provider.dart';
import '../widgets/canvas_view.dart';
import '../widgets/create_collection_dialog.dart';
import '../widgets/item_status_dropdown.dart';
import '../widgets/steamgriddb_panel.dart';
import '../widgets/vgmaps_panel.dart';
import 'game_detail_screen.dart';
import 'movie_detail_screen.dart';
import 'tv_show_detail_screen.dart';

/// Экран детального просмотра коллекции.
class CollectionScreen extends ConsumerStatefulWidget {
  /// Создаёт [CollectionScreen].
  const CollectionScreen({
    required this.collectionId,
    super.key,
  });

  /// ID коллекции.
  final int collectionId;

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  Collection? _collection;
  bool _collectionLoading = true;
  bool _isCanvasMode = false;

  @override
  void initState() {
    super.initState();
    _loadCollection();
  }

  Future<void> _loadCollection() async {
    final CollectionRepository repo = ref.read(collectionRepositoryProvider);
    final Collection? collection = await repo.getById(widget.collectionId);
    if (mounted) {
      setState(() {
        _collection = collection;
        _collectionLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_collectionLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_collection == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Collection not found')),
      );
    }

    final AsyncValue<List<CollectionItem>> itemsAsync =
        ref.watch(collectionItemsNotifierProvider(widget.collectionId));
    final AsyncValue<CollectionStats> statsAsync =
        ref.watch(collectionStatsProvider(widget.collectionId));

    return Scaffold(
      appBar: AppBar(
        title: Text(_collection!.name),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SegmentedButton<bool>(
              segments: const <ButtonSegment<bool>>[
                ButtonSegment<bool>(
                  value: false,
                  label: Text('List'),
                  icon: Icon(Icons.list),
                ),
                ButtonSegment<bool>(
                  value: true,
                  label: Text('Canvas'),
                  icon: Icon(Icons.dashboard),
                ),
              ],
              selected: <bool>{_isCanvasMode},
              onSelectionChanged: (Set<bool> selection) {
                setState(() {
                  _isCanvasMode = selection.first;
                });
              },
            ),
          ),
        ),
        actions: <Widget>[
          if (_collection!.isEditable)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Rename',
              onPressed: () => _renameCollection(context),
            ),
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'Export',
            onPressed: () => _exportCollection(),
          ),
          PopupMenuButton<String>(
            onSelected: (String value) => _handleMenuAction(value),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              if (_collection!.isFork)
                const PopupMenuItem<String>(
                  value: 'revert',
                  child: ListTile(
                    leading: Icon(Icons.restore),
                    title: Text('Revert to Original'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isCanvasMode
          ? Row(
              children: <Widget>[
                Expanded(
                  child: CanvasView(
                    collectionId: widget.collectionId,
                    isEditable: _collection!.isEditable,
                  ),
                ),
                // Боковая панель SteamGridDB
                Consumer(
                  builder:
                      (BuildContext context, WidgetRef ref, Widget? child) {
                    final bool isPanelOpen = ref.watch(
                      steamGridDbPanelProvider(widget.collectionId)
                          .select(
                              (SteamGridDbPanelState s) => s.isOpen),
                    );
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isPanelOpen ? 320 : 0,
                      curve: Curves.easeInOut,
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        border: isPanelOpen
                            ? Border(
                                left: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant,
                                ),
                              )
                            : null,
                      ),
                      child: isPanelOpen
                          ? OverflowBox(
                              maxWidth: 320,
                              alignment: Alignment.centerLeft,
                              child: SteamGridDbPanel(
                                collectionId: widget.collectionId,
                                collectionName: _collection!.name,
                                onAddImage: _addSteamGridDbImage,
                              ),
                            )
                          : const SizedBox.shrink(),
                    );
                  },
                ),
                // Боковая панель VGMaps Browser
                Consumer(
                  builder:
                      (BuildContext context, WidgetRef ref, Widget? child) {
                    final bool isPanelOpen = ref.watch(
                      vgMapsPanelProvider(widget.collectionId)
                          .select((VgMapsPanelState s) => s.isOpen),
                    );
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isPanelOpen ? 500 : 0,
                      curve: Curves.easeInOut,
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        border: isPanelOpen
                            ? Border(
                                left: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant,
                                ),
                              )
                            : null,
                      ),
                      child: isPanelOpen
                          ? OverflowBox(
                              maxWidth: 500,
                              alignment: Alignment.centerLeft,
                              child: VgMapsPanel(
                                collectionId: widget.collectionId,
                                onAddImage: _addVgMapsImage,
                              ),
                            )
                          : const SizedBox.shrink(),
                    );
                  },
                ),
              ],
            )
          : Column(
              children: <Widget>[
                // Заголовок со статистикой
                _buildHeader(statsAsync),

                // Селектор сортировки
                _buildSortSelector(),

                // Список элементов
                Expanded(
                  child: itemsAsync.when(
                    data: (List<CollectionItem> items) =>
                        _buildItemsList(context, items),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (Object error, StackTrace stack) =>
                        _buildErrorState(context, error),
                  ),
                ),
              ],
            ),
      floatingActionButton: _collection!.isEditable && !_isCanvasMode
          ? FloatingActionButton.extended(
              onPressed: () => _addItems(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Items'),
            )
          : null,
    );
  }

  Widget _buildHeader(AsyncValue<CollectionStats> statsAsync) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Информация о форке
          if (_collection!.isFork && _collection!.forkedFromAuthor != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.fork_right,
                    size: 16,
                    color: colorScheme.tertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Forked from ${_collection!.forkedFromAuthor} / ${_collection!.forkedFromName}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
            ),

          // Статистика
          statsAsync.when(
            data: (CollectionStats stats) => _buildStatsContent(stats),
            loading: () => const SizedBox(
              height: 40,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (Object error, StackTrace stack) => Text(
              'Error loading stats',
              style: TextStyle(color: colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsContent(CollectionStats stats) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Основная статистика
        Text(
          '${stats.total} item${stats.total != 1 ? 's' : ''} \u2022 ${stats.completed} completed',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),

        const SizedBox(height: 8),

        // Прогресс-бар
        if (stats.total > 0) ...<Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: stats.completionPercent / 100,
                    minHeight: 8,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                stats.completionPercentFormatted,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSortSelector() {
    final CollectionSortMode currentSort =
        ref.watch(collectionSortProvider(widget.collectionId));
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.sort,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            currentSort.displayLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(width: 2),
          PopupMenuButton<CollectionSortMode>(
            icon: Icon(
              Icons.arrow_drop_down,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            style: const ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            tooltip: 'Sort mode',
            onSelected: (CollectionSortMode mode) {
              ref
                  .read(collectionSortProvider(widget.collectionId).notifier)
                  .setSortMode(mode);
            },
            itemBuilder: (BuildContext context) {
              return CollectionSortMode.values
                  .map(
                    (CollectionSortMode mode) =>
                        PopupMenuItem<CollectionSortMode>(
                      value: mode,
                      child: Row(
                        children: <Widget>[
                          if (mode == currentSort)
                            Icon(
                              Icons.check,
                              size: 18,
                              color: colorScheme.primary,
                            )
                          else
                            const SizedBox(width: 18),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(mode.displayLabel),
                              Text(
                                mode.description,
                                style:
                                    Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(BuildContext context, List<CollectionItem> items) {
    if (items.isEmpty) {
      return _buildEmptyState();
    }

    final CollectionSortMode sortMode =
        ref.watch(collectionSortProvider(widget.collectionId));
    final bool isManualSort =
        sortMode == CollectionSortMode.manual && _collection!.isEditable;

    if (isManualSort) {
      return _buildReorderableList(items);
    }

    return RefreshIndicator(
      onRefresh: () => ref
          .read(collectionItemsNotifierProvider(widget.collectionId).notifier)
          .refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: items.length,
        itemBuilder: (BuildContext context, int index) {
          final CollectionItem item = items[index];
          return _CollectionItemTile(
            key: ValueKey<int>(item.id),
            item: item,
            isEditable: _collection!.isEditable,
            onStatusChanged: (ItemStatus status) =>
                _updateStatus(item.id, status, item.mediaType),
            onRemove: _collection!.isEditable
                ? () => _removeItem(item)
                : null,
            onTap: () => _showItemDetails(item),
          );
        },
      ),
    );
  }

  Widget _buildReorderableList(List<CollectionItem> items) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      buildDefaultDragHandles: false,
      itemCount: items.length,
      proxyDecorator:
          (Widget child, int index, Animation<double> animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (BuildContext context, Widget? child) {
            final double elevation = lerpDouble(0, 6, animation.value) ?? 0;
            return Material(
              elevation: elevation,
              color: Colors.transparent,
              shadowColor: Colors.black26,
              child: child,
            );
          },
          child: child,
        );
      },
      onReorder: (int oldIndex, int newIndex) {
        // ReorderableListView даёт newIndex ПОСЛЕ удаления элемента
        if (newIndex > oldIndex) {
          newIndex -= 1;
        }
        ref
            .read(collectionItemsNotifierProvider(widget.collectionId).notifier)
            .reorderItem(oldIndex, newIndex);
      },
      itemBuilder: (BuildContext context, int index) {
        final CollectionItem item = items[index];
        return _CollectionItemTile(
          key: ValueKey<int>(item.id),
          item: item,
          isEditable: _collection!.isEditable,
          showDragHandle: true,
          dragIndex: index,
          onStatusChanged: (ItemStatus status) =>
              _updateStatus(item.id, status, item.mediaType),
          onRemove: _collection!.isEditable
              ? () => _removeItem(item)
              : null,
          onTap: () => _showItemDetails(item),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.collections_bookmark_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Items Yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _collection!.isEditable
                  ? 'Add items to start building your collection.'
                  : 'This collection is empty.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load items',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.error,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => ref
                  .read(collectionItemsNotifierProvider(widget.collectionId)
                      .notifier)
                  .refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addItems(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => SearchScreen(
          collectionId: widget.collectionId,
        ),
      ),
    );
    // Обновляем список элементов после возврата из SearchScreen
    if (mounted) {
      ref
          .read(collectionItemsNotifierProvider(widget.collectionId).notifier)
          .refresh();
    }
  }

  Future<void> _updateStatus(
    int id,
    ItemStatus status,
    MediaType mediaType,
  ) async {
    await ref
        .read(collectionItemsNotifierProvider(widget.collectionId).notifier)
        .updateStatus(id, status, mediaType);
  }

  Future<void> _removeItem(CollectionItem item) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Remove Item?'),
        content: Text('Remove ${item.itemName} from this collection?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await ref
        .read(collectionItemsNotifierProvider(widget.collectionId).notifier)
        .removeItem(item.id);

    // Синхронизация канваса — удалить элемент
    ref
        .read(canvasNotifierProvider(widget.collectionId).notifier)
        .removeMediaItem(item.mediaType, item.externalId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.itemName} removed')),
      );
    }
  }

  void _showItemDetails(CollectionItem item) {
    switch (item.mediaType) {
      case MediaType.game:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) => GameDetailScreen(
              collectionId: widget.collectionId,
              gameId: item.id,
              isEditable: _collection!.isEditable,
            ),
          ),
        );
      case MediaType.movie:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) => MovieDetailScreen(
              collectionId: widget.collectionId,
              itemId: item.id,
              isEditable: _collection!.isEditable,
            ),
          ),
        );
      case MediaType.tvShow:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) => TvShowDetailScreen(
              collectionId: widget.collectionId,
              itemId: item.id,
              isEditable: _collection!.isEditable,
            ),
          ),
        );
    }
  }

  Future<void> _renameCollection(BuildContext context) async {
    if (_collection == null) return;

    // Сохраняем ScaffoldMessenger и colorScheme до async операции
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final Color errorColor = Theme.of(context).colorScheme.error;

    final String? newName =
        await RenameCollectionDialog.show(context, _collection!.name);

    if (newName == null || newName == _collection!.name || !mounted) return;

    try {
      await ref
          .read(collectionsProvider.notifier)
          .rename(_collection!.id, newName);

      setState(() {
        _collection = _collection!.copyWith(name: newName);
      });

      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Collection renamed')),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to rename: $e'),
            backgroundColor: errorColor,
          ),
        );
      }
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'revert':
        _revertToOriginal();
      case 'delete':
        _deleteCollection();
    }
  }

  Future<void> _revertToOriginal() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Revert to Original?'),
        content: const Text(
          'This will restore the collection to its original state. '
          'All your changes will be lost.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Revert'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Сохраняем ссылки до async операций
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final Color errorColor = Theme.of(context).colorScheme.error;

    try {
      await ref
          .read(collectionsProvider.notifier)
          .revertToOriginal(widget.collectionId);

      // Обновляем список элементов после revert
      if (mounted) {
        await ref
            .read(collectionItemsNotifierProvider(widget.collectionId).notifier)
            .refresh();
      }

      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Reverted to original')),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to revert: $e'),
            backgroundColor: errorColor,
          ),
        );
      }
    }
  }

  Future<void> _deleteCollection() async {
    if (_collection == null) return;

    final bool confirmed =
        await DeleteCollectionDialog.show(context, _collection!.name);

    if (!confirmed || !mounted) return;

    try {
      await ref.read(collectionsProvider.notifier).delete(_collection!.id);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Collection deleted')),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _addSteamGridDbImage(SteamGridDbImage image) {
    // Масштабируем до max 300px по ширине, сохраняя пропорции
    const double maxWidth = 300;
    const double defaultSize = 200;
    double targetWidth = defaultSize;
    double targetHeight = defaultSize;

    if (image.width > 0 && image.height > 0) {
      final double aspectRatio = image.width / image.height;
      targetWidth =
          image.width.toDouble() > maxWidth ? maxWidth : image.width.toDouble();
      targetHeight = targetWidth / aspectRatio;
    }

    // Добавляем в центр канваса
    final double centerX =
        CanvasRepository.initialCenterX - targetWidth / 2;
    final double centerY =
        CanvasRepository.initialCenterY - targetHeight / 2;

    ref
        .read(canvasNotifierProvider(widget.collectionId).notifier)
        .addImageItem(
          centerX,
          centerY,
          <String, dynamic>{'url': image.url},
          width: targetWidth,
          height: targetHeight,
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image added to canvas'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _addVgMapsImage(String url, int? width, int? height) {
    // Масштабируем до max 400px по ширине (карты больше обычных изображений)
    const double maxWidth = 400;
    double targetWidth = maxWidth;
    double targetHeight = maxWidth;

    if (width != null && height != null && width > 0 && height > 0) {
      final double aspectRatio = width / height;
      targetWidth =
          width.toDouble() > maxWidth ? maxWidth : width.toDouble();
      targetHeight = targetWidth / aspectRatio;
    }

    // Добавляем в центр канваса
    final double centerX =
        CanvasRepository.initialCenterX - targetWidth / 2;
    final double centerY =
        CanvasRepository.initialCenterY - targetHeight / 2;

    ref
        .read(canvasNotifierProvider(widget.collectionId).notifier)
        .addImageItem(
          centerX,
          centerY,
          <String, dynamic>{'url': url},
          width: targetWidth,
          height: targetHeight,
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Map added to canvas'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _exportCollection() async {
    if (_collection == null) return;

    // Получаем список элементов
    final AsyncValue<List<CollectionItem>> itemsAsync =
        ref.read(collectionItemsNotifierProvider(widget.collectionId));

    final List<CollectionItem>? items = itemsAsync.valueOrNull;
    if (items == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Items not loaded yet')),
        );
      }
      return;
    }

    // Проверяем наличие canvas данных для выбора формата
    final CanvasRepository canvasRepo = ref.read(canvasRepositoryProvider);
    final bool hasCanvas =
        await canvasRepo.hasCanvasItems(widget.collectionId);

    ExportFormat format = ExportFormat.light;

    if (hasCanvas && mounted) {
      final ExportFormat? chosen = await _showExportFormatDialog();
      if (chosen == null) return; // Отмена
      format = chosen;
    }

    // Показываем индикатор
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: <Widget>[
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(format == ExportFormat.full
                  ? 'Preparing full export...'
                  : 'Preparing export...'),
            ],
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }

    final ExportService exportService = ref.read(exportServiceProvider);
    final ExportResult result =
        await exportService.exportToFile(_collection!, items, format: format);

    if (!mounted) return;

    // Скрываем предыдущий snackbar
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported to ${result.filePath}'),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
    } else if (!result.isCancelled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Export failed'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<ExportFormat?> _showExportFormatDialog() {
    return showDialog<ExportFormat>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Export Format'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              'This collection has canvas data. Choose export format:',
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Light (.xcoll)'),
              subtitle: const Text('Items only, smaller file'),
              onTap: () =>
                  Navigator.of(dialogContext).pop(ExportFormat.light),
            ),
            ListTile(
              leading: const Icon(Icons.folder_zip_outlined),
              title: const Text('Full (.xcollx)'),
              subtitle: const Text('Items + canvas + images'),
              onTap: () =>
                  Navigator.of(dialogContext).pop(ExportFormat.full),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

/// Плитка элемента в коллекции.
class _CollectionItemTile extends StatelessWidget {
  const _CollectionItemTile({
    super.key,
    required this.item,
    required this.isEditable,
    required this.onStatusChanged,
    this.showDragHandle = false,
    this.dragIndex = 0,
    this.onRemove,
    this.onTap,
  });

  final CollectionItem item;
  final bool isEditable;
  final void Function(ItemStatus) onStatusChanged;
  final bool showDragHandle;
  final int dragIndex;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: <Widget>[
          // Фоновая иконка типа медиа (наклонённая, обрезается Card)
          Positioned.fill(
            child: Align(
              alignment: const Alignment(0.0, -7.2),
              child: Transform.rotate(
                angle: -0.3,
                child: Icon(
                  MediaTypeTheme.iconFor(item.mediaType),
                  size: 200,
                  color: MediaTypeTheme.colorFor(item.mediaType)
                      .withValues(alpha: 0.06),
                ),
              ),
            ),
          ),
          // Основное содержимое
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: <Widget>[
                  // Drag handle (только в manual sort mode)
                  if (showDragHandle)
                    ReorderableDragStartListener(
                      index: dragIndex,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.drag_handle,
                          size: 20,
                          color: colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  // Обложка
                  _buildCover(colorScheme),
                  const SizedBox(width: 12),

                  // Информация
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // Название
                        Text(
                          item.itemName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 4),

                        // Подзаголовок (зависит от типа медиа)
                        Text(
                          _getSubtitle(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),

                        // Комментарий автора
                        if (item.hasAuthorComment) ...<Widget>[
                          const SizedBox(height: 4),
                          Row(
                            children: <Widget>[
                              Icon(
                                Icons.format_quote,
                                size: 14,
                                color: colorScheme.tertiary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item.authorComment!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.tertiary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Статус
                  ItemStatusDropdown(
                    status: item.status,
                    mediaType: item.mediaType,
                    onChanged: onStatusChanged,
                    compact: true,
                  ),

                  // Удалить (если редактируемый)
                  if (onRemove != null)
                    IconButton(
                      icon: Icon(
                        Icons.remove_circle_outline,
                        color: colorScheme.error,
                      ),
                      tooltip: 'Remove',
                      onPressed: onRemove,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSubtitle() {
    switch (item.mediaType) {
      case MediaType.game:
        return item.platformName;
      case MediaType.movie:
        final List<String> parts = <String>[];
        if (item.movie?.releaseYear != null) {
          parts.add(item.movie!.releaseYear.toString());
        }
        if (item.movie?.runtime != null) {
          final int hours = item.movie!.runtime! ~/ 60;
          final int mins = item.movie!.runtime! % 60;
          if (hours > 0 && mins > 0) {
            parts.add('${hours}h ${mins}m');
          } else if (hours > 0) {
            parts.add('${hours}h');
          } else {
            parts.add('${mins}m');
          }
        }
        return parts.isNotEmpty ? parts.join(' \u2022 ') : 'Movie';
      case MediaType.tvShow:
        final List<String> parts = <String>[];
        if (item.tvShow?.firstAirYear != null) {
          parts.add(item.tvShow!.firstAirYear.toString());
        }
        if (item.tvShow?.totalSeasons != null) {
          parts.add(
            '${item.tvShow!.totalSeasons} season${item.tvShow!.totalSeasons != 1 ? 's' : ''}',
          );
        }
        return parts.isNotEmpty ? parts.join(' \u2022 ') : 'TV Show';
    }
  }

  IconData _getMediaTypeIcon() {
    switch (item.mediaType) {
      case MediaType.game:
        return Icons.videogame_asset;
      case MediaType.movie:
        return Icons.movie_outlined;
      case MediaType.tvShow:
        return Icons.tv_outlined;
    }
  }

  ImageType _getImageTypeForCache() {
    switch (item.mediaType) {
      case MediaType.game:
        return ImageType.gameCover;
      case MediaType.movie:
        return ImageType.moviePoster;
      case MediaType.tvShow:
        return ImageType.tvShowPoster;
    }
  }

  Widget _buildCover(ColorScheme colorScheme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 48,
        height: 64,
        child: item.thumbnailUrl != null
            ? CachedImage(
                imageType: _getImageTypeForCache(),
                imageId: item.externalId.toString(),
                remoteUrl: item.thumbnailUrl!,
                fit: BoxFit.cover,
                memCacheWidth: 96,
                memCacheHeight: 128,
                placeholder: Container(
                  color: colorScheme.surfaceContainerHighest,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: _buildPlaceholder(colorScheme),
              )
            : _buildPlaceholder(colorScheme),
      ),
    );
  }

  Widget _buildPlaceholder(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(
        _getMediaTypeIcon(),
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
