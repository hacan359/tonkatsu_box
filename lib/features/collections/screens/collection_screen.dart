import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/export_service.dart';
import '../../../data/repositories/collection_repository.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/models/collection_game.dart';
import '../../../shared/models/game.dart';
import '../../search/screens/search_screen.dart';
import '../providers/collections_provider.dart';
import '../widgets/create_collection_dialog.dart';
import '../widgets/status_dropdown.dart';
import 'game_detail_screen.dart';

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

    final AsyncValue<List<CollectionGame>> gamesAsync =
        ref.watch(collectionGamesNotifierProvider(widget.collectionId));
    final AsyncValue<CollectionStats> statsAsync =
        ref.watch(collectionStatsProvider(widget.collectionId));

    return Scaffold(
      appBar: AppBar(
        title: Text(_collection!.name),
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
      body: Column(
        children: <Widget>[
          // Заголовок со статистикой
          _buildHeader(statsAsync),

          // Список игр
          Expanded(
            child: gamesAsync.when(
              data: (List<CollectionGame> games) =>
                  _buildGamesList(context, games),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object error, StackTrace stack) =>
                  _buildErrorState(context, error),
            ),
          ),
        ],
      ),
      floatingActionButton: _collection!.isEditable
          ? FloatingActionButton.extended(
              onPressed: () => _addGame(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Game'),
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
          '${stats.total} game${stats.total != 1 ? 's' : ''} • ${stats.completed} completed',
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

  Widget _buildGamesList(BuildContext context, List<CollectionGame> games) {
    if (games.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => ref
          .read(collectionGamesNotifierProvider(widget.collectionId).notifier)
          .refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: games.length,
        itemBuilder: (BuildContext context, int index) {
          final CollectionGame collectionGame = games[index];
          return _CollectionGameTile(
            collectionGame: collectionGame,
            isEditable: _collection!.isEditable,
            onStatusChanged: (GameStatus status) =>
                _updateStatus(collectionGame.id, status),
            onRemove: _collection!.isEditable
                ? () => _removeGame(collectionGame)
                : null,
            onTap: () => _showGameDetails(collectionGame),
          );
        },
      ),
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
              Icons.videogame_asset_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Games Yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _collection!.isEditable
                  ? 'Add games to start building your collection.'
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
              'Failed to load games',
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
                  .read(collectionGamesNotifierProvider(widget.collectionId)
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

  Future<void> _addGame(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => SearchScreen(
          collectionId: widget.collectionId,
        ),
      ),
    );
    // Обновляем список игр после возврата из SearchScreen
    if (mounted) {
      ref
          .read(collectionGamesNotifierProvider(widget.collectionId).notifier)
          .refresh();
    }
  }

  Future<void> _updateStatus(int id, GameStatus status) async {
    await ref
        .read(collectionGamesNotifierProvider(widget.collectionId).notifier)
        .updateStatus(id, status);
  }

  Future<void> _removeGame(CollectionGame game) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Remove Game?'),
        content: Text('Remove ${game.gameName} from this collection?'),
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
        .read(collectionGamesNotifierProvider(widget.collectionId).notifier)
        .removeGame(game.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${game.gameName} removed')),
      );
    }
  }

  void _showGameDetails(CollectionGame game) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => GameDetailScreen(
          collectionId: widget.collectionId,
          gameId: game.id,
          isEditable: _collection!.isEditable,
        ),
      ),
    );
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

      // Обновляем список игр после revert
      if (mounted) {
        await ref
            .read(collectionGamesNotifierProvider(widget.collectionId).notifier)
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

  Future<void> _exportCollection() async {
    if (_collection == null) return;

    // Получаем список игр
    final AsyncValue<List<CollectionGame>> gamesAsync =
        ref.read(collectionGamesNotifierProvider(widget.collectionId));

    final List<CollectionGame>? games = gamesAsync.valueOrNull;
    if (games == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Games not loaded yet')),
        );
      }
      return;
    }

    // Показываем индикатор
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: <Widget>[
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Preparing export...'),
            ],
          ),
          duration: Duration(seconds: 1),
        ),
      );
    }

    final ExportService exportService = ref.read(exportServiceProvider);
    final ExportResult result =
        await exportService.exportToFile(_collection!, games);

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
}

/// Плитка игры в коллекции.
class _CollectionGameTile extends StatelessWidget {
  const _CollectionGameTile({
    required this.collectionGame,
    required this.isEditable,
    required this.onStatusChanged,
    this.onRemove,
    this.onTap,
  });

  final CollectionGame collectionGame;
  final bool isEditable;
  final void Function(GameStatus) onStatusChanged;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Game? game = collectionGame.game;
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              // Обложка
              _buildCover(game?.coverUrl, colorScheme),
              const SizedBox(width: 12),

              // Информация
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Название
                    Text(
                      collectionGame.gameName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Платформа
                    Text(
                      collectionGame.platformName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),

                    // Комментарий автора
                    if (collectionGame.hasAuthorComment) ...<Widget>[
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
                              collectionGame.authorComment!,
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
              StatusDropdown(
                status: collectionGame.status,
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
    );
  }

  Widget _buildCover(String? coverUrl, ColorScheme colorScheme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 48,
        height: 64,
        child: coverUrl != null
            ? CachedNetworkImage(
                imageUrl: coverUrl,
                fit: BoxFit.cover,
                placeholder: (BuildContext context, String url) => Container(
                  color: colorScheme.surfaceContainerHighest,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget:
                    (BuildContext context, String url, Object error) =>
                        _buildPlaceholder(colorScheme),
              )
            : _buildPlaceholder(colorScheme),
      ),
    );
  }

  Widget _buildPlaceholder(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.videogame_asset,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}

