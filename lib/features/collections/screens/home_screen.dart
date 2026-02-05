import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/import_service.dart';
import '../../../shared/models/collection.dart';
import '../../search/screens/search_screen.dart';
import '../../settings/providers/settings_provider.dart';
import '../../settings/screens/settings_screen.dart';
import '../providers/collections_provider.dart';
import '../widgets/collection_tile.dart';
import '../widgets/create_collection_dialog.dart';
import 'collection_screen.dart';

/// Главный экран приложения.
///
/// Показывает список коллекций пользователя с группировкой по типу.
class HomeScreen extends ConsumerWidget {
  /// Создаёт [HomeScreen].
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SettingsState settings = ref.watch(settingsNotifierProvider);
    final AsyncValue<List<Collection>> collectionsAsync =
        ref.watch(collectionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('xeRAbora'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search Games',
            onPressed: settings.isApiReady
                ? () => _navigateToSearch(context)
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Import Collection',
            onPressed: settings.isApiReady
                ? () => _importCollection(context, ref)
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => _navigateToSettings(context),
          ),
        ],
      ),
      body: collectionsAsync.when(
        data: (List<Collection> collections) =>
            _buildCollectionsList(context, ref, collections),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stack) =>
            _buildErrorState(context, ref, error),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createCollection(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Collection'),
      ),
    );
  }

  Widget _buildCollectionsList(
    BuildContext context,
    WidgetRef ref,
    List<Collection> collections,
  ) {
    if (collections.isEmpty) {
      return _buildEmptyState(context);
    }

    // Группируем по типу
    final List<Collection> ownCollections = collections
        .where((Collection c) => c.type == CollectionType.own)
        .toList();
    final List<Collection> forkCollections = collections
        .where((Collection c) => c.type == CollectionType.fork)
        .toList();
    final List<Collection> importedCollections = collections
        .where((Collection c) => c.type == CollectionType.imported)
        .toList();

    return RefreshIndicator(
      onRefresh: () => ref.read(collectionsProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 80),
        children: <Widget>[
          // Собственные коллекции
          if (ownCollections.isNotEmpty) ...<Widget>[
            CollectionSectionHeader(
              title: 'My Collections',
              count: ownCollections.length,
            ),
            ...ownCollections.map((Collection c) => CollectionTile(
                  collection: c,
                  onTap: () => _navigateToCollection(context, c),
                  onLongPress: () => _showCollectionOptions(context, ref, c),
                  onDelete: () => _deleteCollection(context, ref, c),
                )),
          ],

          // Форки
          if (forkCollections.isNotEmpty) ...<Widget>[
            CollectionSectionHeader(
              title: 'Forked Collections',
              count: forkCollections.length,
            ),
            ...forkCollections.map((Collection c) => CollectionTile(
                  collection: c,
                  onTap: () => _navigateToCollection(context, c),
                  onLongPress: () => _showCollectionOptions(context, ref, c),
                  onDelete: () => _deleteCollection(context, ref, c),
                )),
          ],

          // Импортированные
          if (importedCollections.isNotEmpty) ...<Widget>[
            CollectionSectionHeader(
              title: 'Imported',
              count: importedCollections.length,
            ),
            ...importedCollections.map((Collection c) => CollectionTile(
                  collection: c,
                  onTap: () => _navigateToCollection(context, c),
                  onLongPress: () => _showCollectionOptions(context, ref, c),
                  onDelete: () => _deleteCollection(context, ref, c),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.collections_bookmark_outlined,
              size: 80,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Collections Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first collection to start tracking\nyour gaming journey.',
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

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
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
              'Failed to load collections',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.error,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => ref.invalidate(collectionsProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToSearch(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const SearchScreen(),
      ),
    );
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const SettingsScreen(),
      ),
    );
  }

  void _navigateToCollection(BuildContext context, Collection collection) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => CollectionScreen(
          collectionId: collection.id,
        ),
      ),
    );
  }

  Future<void> _createCollection(BuildContext context, WidgetRef ref) async {
    final CreateCollectionResult? result = await CreateCollectionDialog.show(
      context,
      defaultAuthor: 'User', // TODO: Get from settings
    );

    if (result == null) return;

    try {
      final Collection collection =
          await ref.read(collectionsProvider.notifier).create(
                name: result.name,
                author: result.author,
              );

      if (context.mounted) {
        // Переходим к созданной коллекции
        _navigateToCollection(context, collection);
      }
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create collection: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showCollectionOptions(
    BuildContext context,
    WidgetRef ref,
    Collection collection,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('Open'),
              onTap: () {
                Navigator.of(context).pop();
                _navigateToCollection(context, collection);
              },
            ),
            if (collection.isEditable)
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Rename'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _renameCollection(context, ref, collection);
                },
              ),
            if (collection.type == CollectionType.imported)
              ListTile(
                leading: const Icon(Icons.fork_right),
                title: const Text('Create Copy'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _forkCollection(context, ref, collection);
                },
              ),
            ListTile(
              leading: Icon(
                Icons.delete,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () async {
                Navigator.of(context).pop();
                await _deleteCollection(context, ref, collection);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _renameCollection(
    BuildContext context,
    WidgetRef ref,
    Collection collection,
  ) async {
    final String? newName =
        await RenameCollectionDialog.show(context, collection.name);

    if (newName == null || newName == collection.name) return;

    try {
      await ref.read(collectionsProvider.notifier).rename(collection.id, newName);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Collection renamed')),
        );
      }
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to rename: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _forkCollection(
    BuildContext context,
    WidgetRef ref,
    Collection collection,
  ) async {
    try {
      final Collection fork = await ref
          .read(collectionsProvider.notifier)
          .fork(collection.id, 'User'); // TODO: Get from settings

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Collection copied')),
        );
        _navigateToCollection(context, fork);
      }
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteCollection(
    BuildContext context,
    WidgetRef ref,
    Collection collection,
  ) async {
    final bool confirmed =
        await DeleteCollectionDialog.show(context, collection.name);

    if (!confirmed) return;

    try {
      await ref.read(collectionsProvider.notifier).delete(collection.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Collection deleted')),
        );
      }
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _importCollection(BuildContext context, WidgetRef ref) async {
    final ImportService importService = ref.read(importServiceProvider);

    // Показываем диалог прогресса
    final ValueNotifier<ImportProgress?> progressNotifier =
        ValueNotifier<ImportProgress?>(null);

    ImportResult? importResult;

    // Запускаем импорт
    final Future<ImportResult> importFuture = importService.importFromFile(
      onProgress: (ImportProgress progress) {
        progressNotifier.value = progress;
      },
    ).then((ImportResult result) {
      importResult = result;
      return result;
    });

    // Показываем диалог с прогрессом
    final bool? dialogResult = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => _ImportProgressDialog(
        progressNotifier: progressNotifier,
        importFuture: importFuture,
      ),
    );

    // Очищаем ValueNotifier
    progressNotifier.dispose();

    // Если диалог был закрыт до завершения импорта или результат не получен
    if (dialogResult == null || importResult == null) return;

    final ImportResult result = importResult!;

    if (!context.mounted) return;

    if (result.success && result.collection != null) {
      // Обновляем список коллекций
      ref.invalidate(collectionsProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported "${result.collection!.name}" with ${result.gamesImported} games',
          ),
        ),
      );

      // Переходим к импортированной коллекции
      _navigateToCollection(context, result.collection!);
    } else if (!result.isCancelled && result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error!),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

/// Диалог прогресса импорта.
class _ImportProgressDialog extends StatelessWidget {
  const _ImportProgressDialog({
    required this.progressNotifier,
    required this.importFuture,
  });

  final ValueNotifier<ImportProgress?> progressNotifier;
  final Future<ImportResult> importFuture;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Importing Collection'),
      content: ValueListenableBuilder<ImportProgress?>(
        valueListenable: progressNotifier,
        builder: (BuildContext context, ImportProgress? progress, Widget? child) {
          if (progress == null) {
            return const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                progress.stage.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (progress.message != null) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  progress.message!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: progress.total > 0 ? progress.progress : null,
              ),
              if (progress.total > 0) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  '${progress.current} / ${progress.total}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          );
        },
      ),
      actions: <Widget>[
        FutureBuilder<ImportResult>(
          future: importFuture,
          builder: (BuildContext context, AsyncSnapshot<ImportResult> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Done'),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}
