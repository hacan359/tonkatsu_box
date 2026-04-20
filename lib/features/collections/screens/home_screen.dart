import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/import_service.dart';
import '../../../core/services/xcoll_file.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/keyboard/keyboard_shortcuts.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/models/collection_list_sort_mode.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/navigation/search_providers.dart';
import '../../../shared/widgets/draggable_fab.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../home/providers/all_items_provider.dart';
import '../providers/canvas_provider.dart';
import '../providers/collection_covers_provider.dart';
import '../providers/collections_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../widgets/collection_card.dart';
import '../widgets/collection_list_tile.dart';
import '../widgets/create_collection_dialog.dart';
import '../widgets/import_progress_dialog.dart';
import 'collection_screen.dart';

/// Главный экран приложения.
///
/// Показывает список коллекций пользователя с группировкой по типу.
class HomeScreen extends ConsumerStatefulWidget {
  /// Создаёт [HomeScreen].
  const HomeScreen({super.key});

  /// Группа хоткеев этого экрана для легенды F1.
  static const ShortcutGroup shortcutGroup = ShortcutGroup(
    title: 'Коллекции',
    entries: <ShortcutEntry>[
      ShortcutEntry(keys: 'Ctrl+N', description: 'Создать коллекцию'),
      ShortcutEntry(keys: 'Ctrl+I', description: 'Импорт коллекции'),
      ShortcutEntry(keys: 'Ctrl+Shift+V', description: 'Переключить вид'),
      ShortcutEntry(keys: 'Delete', description: 'Удалить коллекцию'),
      ShortcutEntry(keys: 'F2', description: 'Переименовать коллекцию'),
      ShortcutEntry(keys: 'Enter', description: 'Открыть коллекцию'),
    ],
  );

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Collection? _focusedCollection;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Collection>> collectionsAsync =
        ref.watch(collectionsProvider);
    final S l = S.of(context);

    final CollectionListSortMode sortMode =
        ref.watch(collectionListSortProvider);
    final bool sortDesc = ref.watch(collectionListSortDescProvider);
    final bool isGridView = ref.watch(collectionListViewModeProvider);

    final String searchQuery = ref.watch(collectionsSearchQueryProvider);

    return CallbackShortcuts(
      bindings: _buildScreenShortcuts(ref),
      child: Stack(
        children: <Widget>[
          collectionsAsync.when(
            data: (List<Collection> collections) =>
                _buildCollectionsList(
                  context, ref, collections,
                  sortMode: sortMode,
                  sortDesc: sortDesc,
                  isGridView: isGridView,
                  searchQuery: searchQuery,
                ),
            loading: () => _buildLoadingState(),
            error: (Object error, StackTrace stack) =>
                _buildErrorState(context, ref, error),
          ),
          DraggableFab(
            primaryItems: <DraggableFabItem>[
              DraggableFabItem(
                icon: Icons.add,
                label: l.collectionsNewCollection,
                onTap: () => _createCollection(context, ref),
              ),
              DraggableFabItem(
                icon: Icons.file_download_outlined,
                label: l.collectionsImportCollection,
                onTap: () => _importCollection(context, ref),
              ),
              DraggableFabItem(
                icon: isGridView ? Icons.view_list : Icons.grid_view,
                label: isGridView
                    ? l.collectionListViewList
                    : l.collectionListViewGrid,
                onTap: () =>
                    ref.read(collectionListViewModeProvider.notifier).toggle(),
              ),
              DraggableFabItem(
                icon: sortDesc ? Icons.arrow_upward : Icons.arrow_downward,
                label: sortMode.localizedDisplayLabel(l),
                onTap: () =>
                    ref.read(collectionListSortDescProvider.notifier).toggle(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<ShortcutActivator, VoidCallback> _buildScreenShortcuts(WidgetRef ref) {
    if (kIsMobile) return <ShortcutActivator, VoidCallback>{};
    return <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.keyN, control: true):
          () => _createCollection(context, ref),
      const SingleActivator(LogicalKeyboardKey.keyI, control: true):
          () => _importCollection(context, ref),
      const SingleActivator(
        LogicalKeyboardKey.keyV,
        control: true,
        shift: true,
      ): () => ref.read(collectionListViewModeProvider.notifier).toggle(),
      const SingleActivator(LogicalKeyboardKey.delete):
          () {
            if (_focusedCollection == null) return;
            _deleteCollection(context, ref, _focusedCollection!);
          },
      const SingleActivator(LogicalKeyboardKey.f2):
          () {
            if (_focusedCollection == null) return;
            _renameCollection(context, ref, _focusedCollection!);
          },
      const SingleActivator(LogicalKeyboardKey.enter):
          () {
            if (_focusedCollection == null) return;
            _navigateToCollection(context, _focusedCollection!);
          },
    };
  }

  Widget _buildCollectionsList(
    BuildContext context,
    WidgetRef ref,
    List<Collection> collections, {
    required CollectionListSortMode sortMode,
    required bool sortDesc,
    required bool isGridView,
    required String searchQuery,
  }) {
    final int uncategorizedCount =
        ref.watch(uncategorizedItemCountProvider).valueOrNull ?? 0;

    if (collections.isEmpty && uncategorizedCount == 0) {
      return _buildEmptyState(context);
    }

    // Фильтрация коллекций по имени (глобальный поиск).
    List<Collection> filteredCollections = collections;
    if (searchQuery.isNotEmpty) {
      final String query = searchQuery.toLowerCase();
      filteredCollections = collections
          .where((Collection c) => c.name.toLowerCase().contains(query))
          .toList();
    }

    // Сортировка
    filteredCollections = _sortCollections(filteredCollections, sortMode, sortDesc);

    if (isGridView) {
      return _buildGrid(context, ref, filteredCollections, uncategorizedCount);
    }
    return _buildList(context, ref, filteredCollections, uncategorizedCount);
  }

  List<Collection> _sortCollections(
    List<Collection> collections,
    CollectionListSortMode mode,
    bool descending,
  ) {
    final List<Collection> sorted = List<Collection>.of(collections);
    switch (mode) {
      case CollectionListSortMode.createdDate:
        sorted.sort((Collection a, Collection b) => descending
            ? a.createdAt.compareTo(b.createdAt)
            : b.createdAt.compareTo(a.createdAt));
      case CollectionListSortMode.alphabetical:
        sorted.sort((Collection a, Collection b) => descending
            ? b.name.toLowerCase().compareTo(a.name.toLowerCase())
            : a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    return sorted;
  }

  Widget _buildGrid(
    BuildContext context,
    WidgetRef ref,
    List<Collection> collections,
    int uncategorizedCount,
  ) {
    final List<Widget> gridItems = <Widget>[
      if (uncategorizedCount > 0 && ref.read(collectionsSearchQueryProvider).isEmpty)
        UncategorizedCard(
          count: uncategorizedCount,
          onTap: () => _navigateToUncategorized(context),
        ),
      ...collections.map((Collection c) => CollectionCard(
            collection: c,
            onTap: () => _navigateToCollection(context, c),
            onLongPress: () => _showCollectionOptions(context, ref, c),
            onSecondaryTap: (Offset pos) =>
                _showCollectionContextMenu(context, ref, c, pos),
            onFocusChanged: (bool hasFocus) {
              setState(() => _focusedCollection = hasFocus ? c : null);
            },
          )),
    ];

    return FocusTraversalGroup(
      policy: WidgetOrderTraversalPolicy(),
      child: RefreshIndicator(
        onRefresh: () => ref.read(collectionsProvider.notifier).refresh(),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onSecondaryTapUp: (TapUpDetails details) =>
              _showEmptyAreaContextMenu(context, ref, details.globalPosition),
          onLongPressStart: (LongPressStartDetails details) =>
              _showEmptyAreaContextMenu(context, ref, details.globalPosition),
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
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    List<Collection> collections,
    int uncategorizedCount,
  ) {
    final int offset =
        (uncategorizedCount > 0 && ref.read(collectionsSearchQueryProvider).isEmpty) ? 1 : 0;

    return RefreshIndicator(
      onRefresh: () => ref.read(collectionsProvider.notifier).refresh(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onSecondaryTapUp: (TapUpDetails details) =>
            _showEmptyAreaContextMenu(context, ref, details.globalPosition),
        onLongPressStart: (LongPressStartDetails details) =>
            _showEmptyAreaContextMenu(context, ref, details.globalPosition),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          itemCount: collections.length + offset,
          itemBuilder: (BuildContext context, int index) {
            if (index == 0 && offset == 1) {
              return UncategorizedListTile(
                count: uncategorizedCount,
                onTap: () => _navigateToUncategorized(context),
              );
            }
            final Collection c = collections[index - offset];
            return CollectionListTile(
              collection: c,
              onTap: () => _navigateToCollection(context, c),
              onLongPress: () => _showCollectionOptions(context, ref, c),
              onSecondaryTap: (Offset pos) =>
                  _showCollectionContextMenu(context, ref, c, pos),
            );
          },
        ),
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
              size: 64,
              color: AppColors.textTertiary.withAlpha(120),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l.collectionsNoCollectionsYet,
              style: AppTypography.h2.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
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

  /// Контекстное меню ПКМ на пустом месте экрана — действия из FAB.
  Future<void> _showEmptyAreaContextMenu(
    BuildContext context,
    WidgetRef ref,
    Offset position,
  ) async {
    final S l = S.of(context);
    final bool isGridView = ref.read(collectionListViewModeProvider);
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;

    final String? value = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'create',
          child: ListTile(
            leading: const Icon(Icons.add),
            title: Text(l.collectionsNewCollection),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem<String>(
          value: 'import',
          child: ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: Text(l.collectionsImportCollection),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'toggle_view',
          child: ListTile(
            leading: Icon(isGridView ? Icons.view_list : Icons.grid_view),
            title: Text(
              isGridView ? l.collectionListViewList : l.collectionListViewGrid,
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );

    if (value == null || !context.mounted) return;
    switch (value) {
      case 'create':
        await _createCollection(context, ref);
      case 'import':
        await _importCollection(context, ref);
      case 'toggle_view':
        ref.read(collectionListViewModeProvider.notifier).toggle();
    }
  }

  /// Контекстное меню ПКМ для коллекции (десктоп).
  Future<void> _showCollectionContextMenu(
    BuildContext context,
    WidgetRef ref,
    Collection collection,
    Offset position,
  ) async {
    final S l = S.of(context);
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;

    final String? value = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'open',
          child: ListTile(
            leading: const Icon(Icons.open_in_new),
            title: Text(l.open),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        if (collection.isEditable)
          PopupMenuItem<String>(
            value: 'rename',
            child: ListTile(
              leading: const Icon(Icons.edit),
              title: Text(l.rename),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'delete',
          child: ListTile(
            leading: const Icon(
              Icons.delete,
              color: AppColors.error,
            ),
            title: Text(
              l.delete,
              style: const TextStyle(color: AppColors.error),
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );

    if (value == null || !context.mounted) return;
    switch (value) {
      case 'open':
        _navigateToCollection(context, collection);
      case 'rename':
        await _renameCollection(context, ref, collection);
      case 'delete':
        await _deleteCollection(context, ref, collection);
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

    // 1. Выбираем и парсим файл
    final XcollFile? xcoll;
    try {
      xcoll = await importService.pickAndParseFile();
    } on FormatException catch (e) {
      if (!context.mounted) return;
      context.showSnack(
        '${S.of(context).settingsError}: ${e.message}',
        type: SnackType.error,
      );
      return;
    }
    if (xcoll == null) return; // Отменено

    if (!context.mounted) return;

    // 2. Спрашиваем: создать новую или использовать существующую
    final int? targetCollectionId = await showDialog<int>(
      context: context,
      builder: (BuildContext dialogContext) =>
          _ImportTargetDialog(collections: ref.read(collectionsProvider)),
    );
    // null = отменено, 0 = создать новую, >0 = ID существующей
    if (targetCollectionId == null || !context.mounted) return;

    final int? collectionId =
        targetCollectionId == 0 ? null : targetCollectionId;

    // 3. Импорт с прогрессом
    final ValueNotifier<ImportProgress?> progressNotifier =
        ValueNotifier<ImportProgress?>(null);

    ImportResult? importResult;

    final Future<ImportResult> importFuture = importService.importFromXcoll(
      xcoll,
      collectionId: collectionId,
      onProgress: (ImportProgress progress) {
        progressNotifier.value = progress;
      },
    ).then((ImportResult result) {
      importResult = result;
      return result;
    });

    final bool? dialogResult = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => ImportProgressDialog(
        progressNotifier: progressNotifier,
        importFuture: importFuture,
      ),
    );

    progressNotifier.dispose();

    if (dialogResult == null || importResult == null) return;

    final ImportResult result = importResult!;

    if (!context.mounted) return;

    if (result.success && result.collection != null) {
      final int cid = result.collection!.id;
      ref.invalidate(collectionsProvider);
      ref.invalidate(collectionStatsProvider(cid));
      ref.invalidate(collectionCoversProvider(cid));
      ref.invalidate(collectionItemsNotifierProvider(cid));
      ref.invalidate(canvasNotifierProvider(cid));
      ref.invalidate(allItemsNotifierProvider);

      final StringBuffer message = StringBuffer(
        S.of(context).collectionsImported(
          result.collection!.name,
          result.itemsImported ?? 0,
        ),
      );
      if (result.itemsUpdated > 0) {
        message.write(', ${S.of(context).steamImportUpdated(result.itemsUpdated)}');
      }

      context.showSnack(message.toString(), type: SnackType.success);
      _navigateToCollection(context, result.collection!);
    } else if (!result.isCancelled && result.error != null) {
      context.showSnack(result.error!, type: SnackType.error);
    }
  }
}

/// Кнопка сортировки списка коллекций с popup menu.

/// Диалог выбора целевой коллекции для импорта.
///
/// Возвращает 0 для "Создать новую", ID для существующей, null для отмены.
class _ImportTargetDialog extends StatefulWidget {
  const _ImportTargetDialog({required this.collections});

  final AsyncValue<List<Collection>> collections;

  @override
  State<_ImportTargetDialog> createState() => _ImportTargetDialogState();
}

class _ImportTargetDialogState extends State<_ImportTargetDialog> {
  bool _createNew = true;
  int? _selectedId;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);

    return AlertDialog(
      scrollable: true,
      title: Text(l.importTargetTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          RadioGroup<bool>(
            groupValue: _createNew,
            onChanged: (bool? value) {
              if (value == null) return;
              setState(() {
                _createNew = value;
                if (value) _selectedId = null;
              });
            },
            child: Column(
              children: <Widget>[
                ListTile(
                  title: Text(l.importCreateNew),
                  leading: const Radio<bool>(value: true),
                  dense: true,
                  onTap: () => setState(() {
                    _createNew = true;
                    _selectedId = null;
                  }),
                ),
                ListTile(
                  title: Text(l.importUseExisting),
                  leading: const Radio<bool>(value: false),
                  dense: true,
                  onTap: () => setState(() {
                    _createNew = false;
                  }),
                ),
              ],
            ),
          ),
          if (!_createNew)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
              ),
              child: widget.collections.when(
                data: (List<Collection> collections) {
                  if (collections.isEmpty) {
                    return Text(
                      l.importNoCollections,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    );
                  }
                  return DropdownButtonFormField<int>(
                    initialValue: _selectedId,
                    hint: Text(l.importSelectCollection),
                    isExpanded: true,
                    items: collections.map((Collection c) {
                      return DropdownMenuItem<int>(
                        value: c.id,
                        child: Text(
                          c.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (int? value) {
                      setState(() => _selectedId = value);
                    },
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (Object e, StackTrace s) => Text(
                  l.importErrorLoadingCollections,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.statusDropped,
                  ),
                ),
              ),
            ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: _createNew || _selectedId != null
              ? () => Navigator.of(context).pop(
                    _createNew ? 0 : _selectedId,
                  )
              : null,
          child: Text(l.importStartButton),
        ),
      ],
    );
  }
}
