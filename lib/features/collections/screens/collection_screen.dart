import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/import_service.dart';
import '../../../core/services/xcoll_file.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/widgets/auto_breadcrumb_app_bar.dart';
import '../../../shared/widgets/breadcrumb_scope.dart';
import '../../../data/repositories/collection_repository.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/steamgriddb_image.dart';
import '../../settings/providers/settings_provider.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/widgets/type_to_filter_overlay.dart';
import '../../home/providers/all_items_provider.dart';
import '../widgets/import_progress_dialog.dart';
import '../helpers/collection_actions.dart';
import '../providers/collection_covers_provider.dart';
import '../providers/collections_provider.dart';
import '../providers/steamgriddb_panel_provider.dart';
import '../providers/vgmaps_panel_provider.dart';
import '../widgets/collection_canvas_layout.dart';
import '../widgets/collection_filter_bar.dart';
import '../widgets/collection_items_view.dart';
import '../../../shared/models/tier_list.dart';
import '../../tier_lists/screens/tier_list_detail_screen.dart';
import '../../tier_lists/screens/tier_lists_screen.dart';
import '../../tier_lists/providers/tier_lists_provider.dart';
import 'item_detail_screen.dart';

/// Экран детального просмотра коллекции.
class CollectionScreen extends ConsumerStatefulWidget {
  /// Создаёт [CollectionScreen].
  const CollectionScreen({
    required this.collectionId,
    super.key,
  });

  /// ID коллекции (null для uncategorized).
  final int? collectionId;

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  Collection? _collection;
  bool _collectionLoading = true;
  bool _isCanvasMode = false;
  bool _isGridMode = false;
  bool _isViewModeLocked = false;
  MediaType? _filterType;
  int? _filterPlatformId;
  String _searchQuery = '';
  String _typeToFilterQuery = '';
  final TextEditingController _searchController = TextEditingController();

  /// Реальная возможность редактирования с учётом режима просмотра.
  bool get _effectiveIsEditable =>
      (_isUncategorized || (_collection != null && _collection!.isEditable)) &&
      !_isViewModeLocked;

  /// Может ли пользователь редактировать элементы.
  bool get _canEdit =>
      _isUncategorized || (_collection != null && _collection!.isEditable);

  /// Название для хлебных крошек и заголовка.
  ///
  /// Примечание: для uncategorized используется нелокализованная строка,
  /// так как контекст недоступен в getter. Локализация применяется в UI.
  String get _displayName =>
      _isUncategorized ? 'Uncategorized' : (_collection?.name ?? '');

  /// Локализованное название для UI-элементов.
  String _localizedDisplayName(BuildContext context) =>
      _isUncategorized ? S.of(context).collectionsUncategorized : (_collection?.name ?? '');

  /// Является ли это экраном uncategorized элементов.
  bool get _isUncategorized => widget.collectionId == null;

  @override
  void initState() {
    super.initState();
    _loadCollection();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCollection() async {
    if (_isUncategorized) {
      final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
      final bool savedGridMode = prefs.getBool(
            '${SettingsKeys.collectionViewModePrefix}uncategorized',
          ) ??
          true;
      if (mounted) {
        setState(() {
          _isGridMode = savedGridMode;
          _collectionLoading = false;
        });
      }
      return;
    }

    final CollectionRepository repo = ref.read(collectionRepositoryProvider);
    final Collection? collection = await repo.getById(widget.collectionId!);
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    final bool savedGridMode = prefs.getBool(
          '${SettingsKeys.collectionViewModePrefix}${widget.collectionId}',
        ) ??
        true;
    if (mounted) {
      setState(() {
        _collection = collection;
        _isGridMode = savedGridMode;
        _collectionLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_collectionLoading) {
      return const BreadcrumbScope(
        label: '...',
        child: Scaffold(
          appBar: AutoBreadcrumbAppBar(),
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (!_isUncategorized && _collection == null) {
      return BreadcrumbScope(
        label: S.of(context).collectionNotFound,
        child: Scaffold(
          appBar: const AutoBreadcrumbAppBar(),
          body: Center(
            child: Text(
              S.of(context).collectionNotFound,
              style: AppTypography.body.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ),
      );
    }

    final AsyncValue<List<CollectionItem>> itemsAsync =
        ref.watch(collectionItemsNotifierProvider(widget.collectionId));
    final AsyncValue<CollectionStats> statsAsync =
        ref.watch(collectionStatsProvider(widget.collectionId));

    final S l = S.of(context);
    return BreadcrumbScope(
      label: _localizedDisplayName(context),
      child: Scaffold(
        appBar: AutoBreadcrumbAppBar(
          actions: _buildAppBarActions(l),
        ),
        body: _isCanvasMode
            ? CollectionCanvasLayout(
                collectionId: widget.collectionId,
                isEditable: _effectiveIsEditable,
                collectionName: _collection!.name,
                onAddSteamGridDbImage: (SteamGridDbImage image) {
                  CollectionActions.addSteamGridDbImage(
                    context: context,
                    ref: ref,
                    collectionId: widget.collectionId,
                    image: image,
                  );
                },
                onAddVgMapsImage: (String url, int? width, int? height) {
                  CollectionActions.addVgMapsImage(
                    context: context,
                    ref: ref,
                    collectionId: widget.collectionId,
                    url: url,
                    width: width,
                    height: height,
                  );
                },
              )
            : TypeToFilterOverlay(
                onFilterChanged: (String query) {
                  setState(() => _typeToFilterQuery = query);
                },
                child: _buildListLayout(itemsAsync, statsAsync),
              ),
      ),
    );
  }

  List<Widget> _buildAppBarActions(S l) {
    return <Widget>[
      if (_canEdit && !_isCanvasMode)
        IconButton(
          icon: const Icon(Icons.add),
          color: AppColors.textSecondary,
          tooltip: l.collectionAddItems,
          onPressed: () => CollectionActions.addItems(
            context: context,
            ref: ref,
            collectionId: widget.collectionId,
          ),
        ),
      if (!_isCanvasMode && !_isUncategorized)
        IconButton(
          icon: const Icon(Icons.leaderboard),
          color: AppColors.textSecondary,
          tooltip: l.tierListTitle,
          onPressed: _navigateToTierLists,
        ),
      if (kCanvasEnabled && !_isUncategorized)
        IconButton(
          icon: Icon(
            _isCanvasMode ? Icons.list : Icons.dashboard,
          ),
          color: AppColors.textSecondary,
          tooltip: _isCanvasMode ? l.collectionSwitchToList : l.collectionSwitchToBoard,
          onPressed: () {
            setState(() {
              _isCanvasMode = !_isCanvasMode;
            });
          },
        ),
      if (_canEdit && _isCanvasMode && kCanvasEnabled && !_isUncategorized)
        IconButton(
          icon: Icon(
            _isViewModeLocked ? Icons.lock : Icons.lock_open,
          ),
          color: _isViewModeLocked
              ? AppColors.warning
              : AppColors.textSecondary,
          tooltip: _isViewModeLocked ? l.collectionUnlockBoard : l.collectionLockBoard,
          onPressed: () {
            setState(() {
              _isViewModeLocked = !_isViewModeLocked;
            });
            if (_isViewModeLocked) {
              ref
                  .read(steamGridDbPanelProvider(widget.collectionId)
                      .notifier)
                  .closePanel();
              ref
                  .read(
                      vgMapsPanelProvider(widget.collectionId).notifier)
                  .closePanel();
            }
          },
        ),
      if (!_isUncategorized)
        PopupMenuButton<String>(
          iconColor: AppColors.textSecondary,
          onSelected: _handleMenuAction,
          itemBuilder: (BuildContext context) {
            final S ml = S.of(context);
            return <PopupMenuEntry<String>>[
              if (_collection!.isEditable)
                PopupMenuItem<String>(
                  value: 'rename',
                  child: ListTile(
                    leading: const Icon(Icons.edit),
                    title: Text(ml.rename),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              PopupMenuItem<String>(
                value: 'tier_list',
                child: ListTile(
                  leading: const Icon(Icons.leaderboard),
                  title: Text(ml.tierListCreateFromCollection),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem<String>(
                value: 'export',
                child: ListTile(
                  leading: const Icon(Icons.file_upload_outlined),
                  title: Text(ml.collectionExport),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (_collection!.isEditable)
                PopupMenuItem<String>(
                  value: 'import',
                  child: ListTile(
                    leading: const Icon(Icons.file_download_outlined),
                    title: Text(ml.collectionsImportCollection),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'delete',
                child: ListTile(
                  leading: const Icon(Icons.delete, color: AppColors.error),
                  title: Text(
                    ml.delete,
                    style: const TextStyle(color: AppColors.error),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ];
          },
        ),
    ];
  }

  Widget _buildListLayout(
    AsyncValue<List<CollectionItem>> itemsAsync,
    AsyncValue<CollectionStats> statsAsync,
  ) {
    return Column(
      children: <Widget>[
        // Фильтры — только если есть элементы
        if ((statsAsync.valueOrNull?.total ?? 0) > 0)
          CollectionFilterBar(
            collectionId: widget.collectionId,
            statsAsync: statsAsync,
            itemsAsync: itemsAsync,
            filterType: _filterType,
            filterPlatformId: _filterPlatformId,
            searchController: _searchController,
            searchQuery: _searchQuery,
            isGridMode: _isGridMode,
            onFilterTypeChanged: (MediaType? type) {
              setState(() {
                _filterType = type;
                _filterPlatformId = null;
              });
            },
            onPlatformFilterChanged: (int? id) {
              setState(() => _filterPlatformId = id);
            },
            onGridModeChanged: () {
              setState(() => _isGridMode = !_isGridMode);
              ref
                  .read(sharedPreferencesProvider)
                  .setBool(
                    '${SettingsKeys.collectionViewModePrefix}${widget.collectionId ?? "uncategorized"}',
                    _isGridMode,
                  );
            },
          ),

        // Список элементов
        Expanded(
          child: itemsAsync.when(
            data: (List<CollectionItem> items) => CollectionItemsView(
              collectionId: widget.collectionId,
              items: _applyFilters(items),
              isGridMode: _isGridMode,
              canEdit: _canEdit,
              onItemTap: _showItemDetails,
              onItemMove: _canEdit
                  ? (CollectionItem item) => _handleMoveItem(item)
                  : null,
              onItemRemove: _canEdit
                  ? (CollectionItem item) => _handleRemoveItem(item)
                  : null,
            ),
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (Object error, StackTrace stack) =>
                _buildErrorState(context, error),
          ),
        ),
      ],
    );
  }

  /// Применяет фильтры по типу и поисковой строке.
  List<CollectionItem> _applyFilters(List<CollectionItem> items) {
    List<CollectionItem> result = items;

    if (_filterType != null) {
      result = result
          .where((CollectionItem item) => item.mediaType == _filterType)
          .toList();
    }

    if (_filterPlatformId != null) {
      result = result
          .where(
            (CollectionItem item) => item.platformId == _filterPlatformId,
          )
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      final String query = _searchQuery.toLowerCase();
      result = result
          .where(
            (CollectionItem item) =>
                item.itemName.toLowerCase().contains(query),
          )
          .toList();
    }

    if (_typeToFilterQuery.isNotEmpty) {
      final String query = _typeToFilterQuery.toLowerCase();
      result = result
          .where(
            (CollectionItem item) =>
                item.itemName.toLowerCase().contains(query),
          )
          .toList();
    }

    return result;
  }

  // =========================================================================
  // Навигация и обработчики действий
  // =========================================================================

  void _showItemDetails(CollectionItem item) {
    final String colName = _displayName;
    final bool isEditable = _canEdit;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => BreadcrumbScope(
          label: colName,
          child: ItemDetailScreen(
            collectionId: widget.collectionId,
            itemId: item.id,
            isEditable: isEditable,
          ),
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'rename':
        _handleRename();
      case 'tier_list':
        _handleCreateTierList();
      case 'export':
        _handleExport();
      case 'import':
        _handleImportIntoCollection();
      case 'delete':
        _handleDelete();
    }
  }

  Future<void> _handleRename() async {
    if (_collection == null) return;
    final String? newName = await CollectionActions.renameCollection(
      context: context,
      ref: ref,
      collection: _collection!,
    );
    if (newName != null && mounted) {
      setState(() {
        _collection = _collection!.copyWith(name: newName);
      });
    }
  }

  void _navigateToTierLists() {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (BuildContext context) =>
          TierListsScreen(collectionId: widget.collectionId),
    ));
  }

  Future<void> _handleCreateTierList() async {
    if (_collection == null) return;
    final S l = S.of(context);
    final TextEditingController controller =
        TextEditingController(text: '${_collection!.name} Tier List');
    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l.tierListCreateFromCollection),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l.tierListNameHint),
          onSubmitted: (String value) =>
              Navigator.of(ctx).pop(value.trim()),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(l.create),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty || !mounted) return;

    if (widget.collectionId == null) return;
    final TierList tierList = await ref
        .read(collectionTierListsProvider(widget.collectionId!).notifier)
        .create(name);

    if (mounted) {
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            TierListDetailScreen(tierListId: tierList.id),
      ));
    }
  }

  Future<void> _handleDelete() async {
    if (_collection == null) return;
    final bool deleted = await CollectionActions.deleteCollection(
      context: context,
      ref: ref,
      collection: _collection!,
    );
    if (deleted && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleExport() async {
    if (_collection == null) return;
    await CollectionActions.exportCollection(
      context: context,
      ref: ref,
      collectionId: widget.collectionId,
      collection: _collection!,
    );
  }

  Future<void> _handleImportIntoCollection() async {
    final ImportService importService = ref.read(importServiceProvider);

    final XcollFile? xcoll;
    try {
      xcoll = await importService.pickAndParseFile();
    } on FormatException catch (e) {
      if (!mounted) return;
      context.showSnack(
        '${S.of(context).settingsError}: ${e.message}',
        type: SnackType.error,
      );
      return;
    }
    if (xcoll == null || !mounted) return;

    final ValueNotifier<ImportProgress?> progressNotifier =
        ValueNotifier<ImportProgress?>(null);

    ImportResult? importResult;

    final Future<ImportResult> importFuture = importService.importFromXcoll(
      xcoll,
      collectionId: widget.collectionId,
      onProgress: (ImportProgress progress) {
        progressNotifier.value = progress;
      },
    ).then((ImportResult result) {
      importResult = result;
      return result;
    });

    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => ImportProgressDialog(
        progressNotifier: progressNotifier,
        importFuture: importFuture,
      ),
    );

    progressNotifier.dispose();

    if (importResult == null || !mounted) return;

    final ImportResult result = importResult!;

    if (result.success) {
      // Обновляем элементы коллекции и статистику
      ref.invalidate(
        collectionItemsNotifierProvider(widget.collectionId),
      );
      ref.invalidate(collectionStatsProvider(widget.collectionId));
      ref.invalidate(collectionCoversProvider(widget.collectionId));
      ref.invalidate(allItemsNotifierProvider);

      final S l = S.of(context);
      final StringBuffer message = StringBuffer(
        l.collectionsImported(
          _collection?.name ?? '',
          result.itemsImported ?? 0,
        ),
      );
      if (result.itemsUpdated > 0) {
        message.write(', ${l.steamImportUpdated(result.itemsUpdated)}');
      }
      context.showSnack(message.toString(), type: SnackType.success);
    } else if (!result.isCancelled && result.error != null) {
      context.showSnack(result.error!, type: SnackType.error);
    }
  }

  Future<void> _handleMoveItem(CollectionItem item) async {
    final bool sourceEmpty = await CollectionActions.moveItem(
      context: context,
      ref: ref,
      collectionId: widget.collectionId,
      item: item,
    );
    if (sourceEmpty && widget.collectionId != null && mounted) {
      await CollectionActions.promptDeleteEmptyCollection(
        context: context,
        ref: ref,
        collectionId: widget.collectionId!,
      );
    }
  }

  Future<void> _handleRemoveItem(CollectionItem item) async {
    await CollectionActions.removeItem(
      context: context,
      ref: ref,
      collectionId: widget.collectionId,
      item: item,
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    final S l = S.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              onPressed: () => ref
                  .read(collectionItemsNotifierProvider(widget.collectionId)
                      .notifier)
                  .refresh(),
              icon: const Icon(Icons.refresh),
              label: Text(l.retry),
            ),
          ],
        ),
      ),
    );
  }
}
