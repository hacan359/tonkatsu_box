import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/import_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/auto_breadcrumb_app_bar.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/type_to_filter_overlay.dart';
import '../../home/providers/all_items_provider.dart';
import '../providers/collections_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../widgets/collection_card.dart';
import '../widgets/create_collection_dialog.dart';
import 'collection_screen.dart';

/// Главный экран приложения.
///
/// Показывает список коллекций пользователя с группировкой по типу.
class HomeScreen extends ConsumerStatefulWidget {
  /// Создаёт [HomeScreen].
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _typeToFilterQuery = '';

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Collection>> collectionsAsync =
        ref.watch(collectionsProvider);
    final bool isLandscape = isLandscapeMobile(context);
    final S l = S.of(context);

    return Scaffold(
      appBar: AutoBreadcrumbAppBar(
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add, size: isLandscape ? 20 : null),
            color: AppColors.textSecondary,
            tooltip: l.collectionsNewCollection,
            onPressed: () => _createCollection(context, ref),
          ),
          IconButton(
            icon: Icon(Icons.file_download_outlined, size: isLandscape ? 20 : null),
            color: AppColors.textSecondary,
            tooltip: l.collectionsImportCollection,
            onPressed: () => _importCollection(context, ref),
          ),
        ],
      ),
      body: TypeToFilterOverlay(
        onFilterChanged: (String query) {
          setState(() => _typeToFilterQuery = query);
        },
        child: collectionsAsync.when(
          data: (List<Collection> collections) =>
              _buildCollectionsList(context, ref, collections),
          loading: () => _buildLoadingState(),
          error: (Object error, StackTrace stack) =>
              _buildErrorState(context, ref, error),
        ),
      ),
    );
  }

  Widget _buildCollectionsList(
    BuildContext context,
    WidgetRef ref,
    List<Collection> collections,
  ) {
    final int uncategorizedCount =
        ref.watch(uncategorizedItemCountProvider).valueOrNull ?? 0;

    if (collections.isEmpty && uncategorizedCount == 0) {
      return _buildEmptyState(context);
    }

    // Фильтрация коллекций по имени
    List<Collection> filteredCollections = collections;
    if (_typeToFilterQuery.isNotEmpty) {
      final String query = _typeToFilterQuery.toLowerCase();
      filteredCollections = collections
          .where((Collection c) => c.name.toLowerCase().contains(query))
          .toList();
    }

    // Все элементы грида: uncategorized (опционально) + отфильтрованные коллекции
    final List<Widget> gridItems = <Widget>[
      if (uncategorizedCount > 0 && _typeToFilterQuery.isEmpty)
        UncategorizedCard(
          count: uncategorizedCount,
          onTap: () => _navigateToUncategorized(context),
        ),
      ...filteredCollections.map((Collection c) => CollectionCard(
            collection: c,
            onTap: () => _navigateToCollection(context, c),
            onLongPress: () => _showCollectionOptions(context, ref, c),
          )),
    ];

    return RefreshIndicator(
      onRefresh: () => ref.read(collectionsProvider.notifier).refresh(),
      child: GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 273,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemCount: gridItems.length,
        itemBuilder: (BuildContext context, int index) => gridItems[index],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: const <Widget>[
        ShimmerListTile(),
        ShimmerListTile(),
        ShimmerListTile(),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final S l = S.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.shelves,
              size: 80,
              color: AppColors.textTertiary.withAlpha(120),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(l.collectionsNoCollectionsYet, style: AppTypography.h2),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l.collectionsNoCollectionsHint,
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    final S l = S.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l.collectionsFailedToLoad,
              style: AppTypography.h3.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () => ref.invalidate(collectionsProvider),
              icon: const Icon(Icons.refresh),
              label: Text(l.retry),
            ),
          ],
        ),
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

  void _navigateToUncategorized(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const CollectionScreen(
          collectionId: null,
        ),
      ),
    );
  }

  Future<void> _createCollection(BuildContext context, WidgetRef ref) async {
    final String? name = await CreateCollectionDialog.show(context);

    if (name == null) return;

    try {
      final String author = ref.read(settingsNotifierProvider).authorName;
      final Collection collection =
          await ref.read(collectionsProvider.notifier).create(
                name: name,
                author: author,
              );

      if (context.mounted) {
        // Переходим к созданной коллекции
        _navigateToCollection(context, collection);
      }
    } on Exception catch (e) {
      if (context.mounted) {
        context.showSnack(S.of(context).collectionsFailedToCreate('$e'), type: SnackType.error);
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
      builder: (BuildContext context) {
        final S l = S.of(context);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.open_in_new),
                title: Text(l.open),
                onTap: () {
                  Navigator.of(context).pop();
                  _navigateToCollection(context, collection);
                },
              ),
              if (collection.isEditable)
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: Text(l.rename),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _renameCollection(context, ref, collection);
                  },
                ),
              ListTile(
                leading: Icon(
                  Icons.delete,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  l.delete,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _deleteCollection(context, ref, collection);
                },
              ),
            ],
          ),
        );
      },
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
        context.showSnack(S.of(context).collectionsRenamed, type: SnackType.success);
      }
    } on Exception catch (e) {
      if (context.mounted) {
        context.showSnack(S.of(context).collectionsFailedToRename('$e'), type: SnackType.error);
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
        context.showSnack(S.of(context).collectionsDeleted, type: SnackType.success);
      }
    } on Exception catch (e) {
      if (context.mounted) {
        context.showSnack(S.of(context).collectionsFailedToDelete('$e'), type: SnackType.error);
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
      // Обновляем список коллекций и All Items
      ref.invalidate(collectionsProvider);
      ref.invalidate(allItemsNotifierProvider);

      context.showSnack(
        S.of(context).collectionsImported(result.collection!.name, result.itemsImported ?? 0),
        type: SnackType.success,
      );

      // Переходим к импортированной коллекции
      _navigateToCollection(context, result.collection!);
    } else if (!result.isCancelled && result.error != null) {
      context.showSnack(result.error!, type: SnackType.error);
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
      scrollable: true,
      title: Text(S.of(context).collectionsImporting),
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
                child: Text(S.of(context).done),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}
