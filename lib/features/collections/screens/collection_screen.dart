import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/import_service.dart';
import '../../../core/services/xcoll_file.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/models/custom_media.dart';
import '../widgets/create_custom_item_dialog.dart';
import '../../../shared/keyboard/keyboard_shortcuts.dart';
import '../../../data/repositories/collection_repository.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/screen_app_bar.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/collection_tag.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/steamgriddb_image.dart';
import '../../settings/providers/settings_provider.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/widgets/type_to_filter_overlay.dart';
import '../../home/providers/all_items_provider.dart';
import '../widgets/import_progress_dialog.dart';
import '../helpers/collection_actions.dart';
import '../providers/collection_covers_provider.dart';
import '../providers/collection_tags_provider.dart';
import '../providers/collections_provider.dart';
import '../providers/steamgriddb_panel_provider.dart';
import '../providers/vgmaps_panel_provider.dart';
import '../widgets/collection_canvas_layout.dart';
import '../widgets/collection_filter_bar.dart';
import '../widgets/collection_items_view.dart';
import '../widgets/tag_sidebar.dart';
import '../widgets/tag_management_dialog.dart';
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

  /// Группа хоткеев этого экрана для легенды F1.
  static const ShortcutGroup shortcutGroup = ShortcutGroup(
    title: 'Коллекция',
    entries: <ShortcutEntry>[
      ShortcutEntry(keys: 'Ctrl+N', description: 'Добавить элементы'),
      ShortcutEntry(keys: 'Ctrl+E', description: 'Экспорт коллекции'),
      ShortcutEntry(keys: 'Ctrl+I', description: 'Импорт в коллекцию'),
      ShortcutEntry(keys: 'Ctrl+Shift+V', description: 'Переключить вид'),
      ShortcutEntry(keys: 'Ctrl+B', description: 'Переключить Board/Canvas'),
      ShortcutEntry(keys: 'Delete', description: 'Удалить элемент'),
      ShortcutEntry(keys: 'Ctrl+M', description: 'Переместить элемент'),
      ShortcutEntry(keys: 'Ctrl+Delete', description: 'Удалить коллекцию'),
      ShortcutEntry(keys: 'F2', description: 'Переименовать коллекцию'),
    ],
  );

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  Collection? _collection;
  bool _collectionLoading = true;
  bool _isCanvasMode = false;
  bool _isGridMode = false;
  bool _isTableMode = false;
  bool _isViewModeLocked = false;
  Set<MediaType> _filterTypes = <MediaType>{};
  Set<int> _filterPlatformIds = <int>{};
  Set<int> _filterTagIds = <int>{};
  String _searchQuery = '';
  String _typeToFilterQuery = '';
  CollectionItem? _focusedItem;
  final TextEditingController _searchController = TextEditingController();

  /// Реальная возможность редактирования с учётом режима просмотра.
  bool get _effectiveIsEditable =>
      (_isUncategorized || (_collection != null && _collection!.isEditable)) &&
      !_isViewModeLocked;

  /// Может ли пользователь редактировать элементы.
  bool get _canEdit =>
      _isUncategorized || (_collection != null && _collection!.isEditable);

  /// Название для хлебных крошек и заголовка.
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
      const String viewKey =
          '${SettingsKeys.collectionViewModePrefix}uncategorized';
      const String tableKey =
          '${SettingsKeys.collectionTableModePrefix}uncategorized';
      final bool savedGridMode = prefs.getBool(viewKey) ?? true;
      final bool savedTableMode = prefs.getBool(tableKey) ?? false;
      if (mounted) {
        setState(() {
          _isGridMode = savedGridMode;
          _isTableMode = savedTableMode;
          _collectionLoading = false;
        });
      }
      return;
    }

    final CollectionRepository repo = ref.read(collectionRepositoryProvider);
    final Collection? collection = await repo.getById(widget.collectionId!);
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    final String viewKey =
        '${SettingsKeys.collectionViewModePrefix}${widget.collectionId}';
    final String tableKey =
        '${SettingsKeys.collectionTableModePrefix}${widget.collectionId}';
    final bool savedGridMode = prefs.getBool(viewKey) ?? true;
    final bool savedTableMode = prefs.getBool(tableKey) ?? false;
    if (mounted) {
      setState(() {
        _collection = collection;
        _isGridMode = savedGridMode;
        _isTableMode = savedTableMode;
        _collectionLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_collectionLoading) {
      return const Scaffold(
        appBar: ScreenAppBar(),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isUncategorized && _collection == null) {
      return Scaffold(
        appBar: const ScreenAppBar(),
        body: Center(
          child: Text(
            S.of(context).collectionNotFound,
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final AsyncValue<List<CollectionItem>> itemsAsync =
        ref.watch(collectionItemsNotifierProvider(widget.collectionId));
    final AsyncValue<CollectionStats> statsAsync =
        ref.watch(collectionStatsProvider(widget.collectionId));

    final S l = S.of(context);
    return CallbackShortcuts(
      bindings: _buildScreenShortcuts(l),
      child: Scaffold(
        appBar: ScreenAppBar(
          title: _isUncategorized
              ? l.collectionsUncategorized
              : _collection!.name,
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

  Map<ShortcutActivator, VoidCallback> _buildScreenShortcuts(S l) {
    if (kIsMobile) return <ShortcutActivator, VoidCallback>{};
    return <ShortcutActivator, VoidCallback>{
      if (_canEdit)
        const SingleActivator(LogicalKeyboardKey.keyN, control: true):
            () => CollectionActions.addItems(context: context, ref: ref, collectionId: widget.collectionId),
      if (!_isUncategorized && _collection != null)
        const SingleActivator(LogicalKeyboardKey.keyE, control: true):
            () => CollectionActions.exportCollection(context: context, ref: ref, collectionId: widget.collectionId, collection: _collection!),
      if (_canEdit && !_isUncategorized)
        const SingleActivator(LogicalKeyboardKey.keyI, control: true):
            _handleImportIntoCollection,
      const SingleActivator(
        LogicalKeyboardKey.keyV,
        control: true,
        shift: true,
      ): _handleCycleViewMode,
      if (kCanvasEnabled && !_isUncategorized)
        const SingleActivator(LogicalKeyboardKey.keyB, control: true):
            () => setState(() => _isCanvasMode = !_isCanvasMode),
      if (_canEdit)
        const SingleActivator(LogicalKeyboardKey.delete):
            () { if (_focusedItem != null) _handleRemoveItem(_focusedItem!); },
      if (_canEdit)
        const SingleActivator(LogicalKeyboardKey.keyM, control: true):
            () { if (_focusedItem != null) _handleMoveItem(_focusedItem!); },
      if (!_isUncategorized)
        const SingleActivator(LogicalKeyboardKey.delete, control: true):
            _handleDelete,
      if (!_isUncategorized && _collection != null && _collection!.isEditable)
        const SingleActivator(LogicalKeyboardKey.f2):
            _handleRename,
    };
  }

  List<Widget> _buildAppBarActions(S l) {
    return <Widget>[
      if (_canEdit && !_isCanvasMode)
        IconButton(
          icon: const Icon(Icons.add),
          color: AppColors.textSecondary,
          tooltip: kIsMobile
              ? l.collectionAddItems
              : '${l.collectionAddItems} (Ctrl+N)',
          onPressed: () => CollectionActions.addItems(
            context: context,
            ref: ref,
            collectionId: widget.collectionId,
          ),
        ),
      if (!_isCanvasMode)
        IconButton(
          icon: Icon(
            _isTableMode ? Icons.grid_view : Icons.table_chart_outlined,
          ),
          color: AppColors.textSecondary,
          tooltip: _isTableMode
              ? l.collectionListViewGrid
              : l.collectionListViewTable,
          onPressed: _handleCycleViewMode,
        ),
      if (!_isCanvasMode && !_isUncategorized)
        IconButton(
          icon: const Icon(Icons.leaderboard),
          color: AppColors.textSecondary,
          tooltip: l.tierListTitle,
          onPressed: _navigateToTierLists,
        ),
      if (_canEdit && _isCanvasMode && kCanvasEnabled && !_isUncategorized)
        IconButton(
          icon: Icon(
            _isViewModeLocked ? Icons.lock : Icons.lock_open,
          ),
          color: _isViewModeLocked
              ? AppColors.warning
              : AppColors.textSecondary,
          tooltip: _isViewModeLocked
              ? (kIsMobile
                  ? l.collectionUnlockBoard
                  : '${l.collectionUnlockBoard} (Ctrl+L)')
              : (kIsMobile
                  ? l.collectionLockBoard
                  : '${l.collectionLockBoard} (Ctrl+L)'),
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
      if (kCanvasEnabled && !_isUncategorized)
        IconButton(
          icon: Icon(
            _isCanvasMode ? Icons.list : Icons.dashboard,
          ),
          color: AppColors.textSecondary,
          tooltip: kIsMobile
              ? (_isCanvasMode ? l.collectionSwitchToList : l.collectionSwitchToBoard)
              : (_isCanvasMode
                  ? '${l.collectionSwitchToList} (Ctrl+B)'
                  : '${l.collectionSwitchToBoard} (Ctrl+B)'),
          onPressed: () {
            setState(() {
              _isCanvasMode = !_isCanvasMode;
            });
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
                  value: 'custom_item',
                  child: ListTile(
                    leading: const Icon(Icons.add_box_outlined,
                        color: AppColors.brand),
                    title: Text(ml.customItemCreate),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
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
                value: 'manage_tags',
                child: ListTile(
                  leading: const Icon(Icons.label_outlined),
                  title: Text(ml.tagManage),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem<String>(
                value: 'copy_as_list',
                child: ListTile(
                  leading: const Icon(Icons.content_copy),
                  title: Text(ml.copyAsList),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem<String>(
                value: 'copy_as_text',
                child: ListTile(
                  leading: const Icon(Icons.text_snippet_outlined),
                  title: Text(ml.copyAsText),
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
    final List<CollectionTag> tags = widget.collectionId != null
        ? (ref.watch(collectionTagsProvider(widget.collectionId!))
                .valueOrNull ??
            <CollectionTag>[])
        : <CollectionTag>[];

    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            children: <Widget>[
              // Фильтры — только если есть элементы
              if ((statsAsync.valueOrNull?.total ?? 0) > 0)
                CollectionFilterBar(
                  collectionId: widget.collectionId,
                  statsAsync: statsAsync,
                  itemsAsync: itemsAsync,
                  filterTypes: _filterTypes,
                  filterPlatformIds: _filterPlatformIds,
                  filterTagIds: _filterTagIds,
                  tags: tags,
                  searchController: _searchController,
                  searchQuery: _searchQuery,
                  onTypeToggled: (MediaType? type) {
                    setState(() {
                      if (type == null) {
                        _filterTypes = <MediaType>{};
                      } else if (_filterTypes.contains(type)) {
                        _filterTypes = Set<MediaType>.from(_filterTypes)
                          ..remove(type);
                      } else {
                        _filterTypes = Set<MediaType>.from(_filterTypes)
                          ..add(type);
                      }
                      _filterPlatformIds = <int>{};
                    });
                  },
                  onPlatformToggled: (int? id) {
                    setState(() {
                      if (id == null) {
                        _filterPlatformIds = <int>{};
                      } else if (_filterPlatformIds.contains(id)) {
                        _filterPlatformIds = Set<int>.from(_filterPlatformIds)
                          ..remove(id);
                      } else {
                        _filterPlatformIds = Set<int>.from(_filterPlatformIds)
                          ..add(id);
                      }
                    });
                  },
                  onTagToggled: (int? tagId) {
                    setState(() {
                      if (tagId == null) {
                        _filterTagIds = <int>{};
                      } else if (_filterTagIds.contains(tagId)) {
                        _filterTagIds = Set<int>.from(_filterTagIds)
                          ..remove(tagId);
                      } else {
                        _filterTagIds = Set<int>.from(_filterTagIds)
                          ..add(tagId);
                      }
                    });
                  },
                ),

              // Список элементов
              Expanded(
                child: itemsAsync.when(
                  data: (List<CollectionItem> items) => CollectionItemsView(
                    collectionId: widget.collectionId,
                    items: _applyFilters(items),
                    tags: tags,
                    filterTagIds: _filterTagIds,
                    isGridMode: _isGridMode,
                    isTableMode: _isTableMode,
                    canEdit: _canEdit,
                    onItemTap: _showItemDetails,
                    onItemMove: _canEdit
                        ? (CollectionItem item) => _handleMoveItem(item)
                        : null,
                    onItemClone: _canEdit
                        ? (CollectionItem item) => _handleCloneItem(item)
                        : null,
                    onItemRemove: _canEdit
                        ? (CollectionItem item) => _handleRemoveItem(item)
                        : null,
                    onItemFocusChanged: (CollectionItem item, bool hasFocus) {
                      setState(() => _focusedItem = hasFocus ? item : null);
                    },
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (Object error, StackTrace stack) =>
                      _buildErrorState(context, error),
                ),
              ),
            ],
          ),
        ),

        // Боковая панель тегов
        if (tags.length >= 2 && !kIsMobile)
          TagSidebar(
            tags: tags,
            selectedTagIds: _filterTagIds,
            onTagToggled: (int? tagId) {
              setState(() {
                if (tagId == null) {
                  _filterTagIds = <int>{};
                } else if (_filterTagIds.contains(tagId)) {
                  _filterTagIds = Set<int>.from(_filterTagIds)
                    ..remove(tagId);
                } else {
                  _filterTagIds = Set<int>.from(_filterTagIds)
                    ..add(tagId);
                }
              });
            },
          ),
      ],
    );
  }

  /// Применяет фильтры по типу, платформе, тегу и поисковой строке.
  List<CollectionItem> _applyFilters(List<CollectionItem> items) {
    List<CollectionItem> result = items;

    if (_filterTypes.isNotEmpty) {
      result = result
          .where((CollectionItem item) =>
              _filterTypes.contains(item.mediaType))
          .toList();
    }

    if (_filterPlatformIds.isNotEmpty) {
      result = result
          .where((CollectionItem item) =>
              item.platformId != null &&
              _filterPlatformIds.contains(item.platformId))
          .toList();
    }

    if (_filterTagIds.isNotEmpty) {
      result = result
          .where((CollectionItem item) =>
              item.tagId != null && _filterTagIds.contains(item.tagId))
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
    final bool isEditable = _canEdit;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ItemDetailScreen(
          collectionId: widget.collectionId,
          itemId: item.id,
          isEditable: isEditable,
        ),
      ),
    );
  }

  /// Переключает режим отображения: grid → table → grid.
  void _handleCycleViewMode() {
    setState(() {
      if (_isGridMode) {
        _isGridMode = false;
        _isTableMode = true;
      } else {
        _isGridMode = true;
        _isTableMode = false;
      }
    });
    final String colKey =
        widget.collectionId?.toString() ?? 'uncategorized';
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    prefs.setBool(
      '${SettingsKeys.collectionViewModePrefix}$colKey',
      _isGridMode,
    );
    prefs.setBool(
      '${SettingsKeys.collectionTableModePrefix}$colKey',
      _isTableMode,
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'custom_item':
        _handleCreateCustomItem();
      case 'rename':
        _handleRename();
      case 'tier_list':
        _handleCreateTierList();
      case 'manage_tags':
        TagManagementDialog.show(context, widget.collectionId!);
      case 'copy_as_list':
        _handleCopyAsList();
      case 'copy_as_text':
        _handleCopyAsText();
      case 'export':
        _handleExport();
      case 'import':
        _handleImportIntoCollection();
      case 'delete':
        _handleDelete();
    }
  }

  Future<void> _handleCreateCustomItem() async {
    final CustomItemData? data = await CreateCustomItemDialog.show(context);
    if (data == null || !mounted) return;

    // Для локальных файлов coverUrl оставляем null —
    // файл будет скопирован в кэш через addCustomItem.
    final CustomMedia customMedia = CustomMedia(
      id: 0,
      title: data.title,
      displayType: data.mediaType != MediaType.custom ? data.mediaType : null,
      altTitle: data.altTitle,
      description: data.description,
      coverUrl: data.coverUrl,
      year: data.year,
      genres: data.genres,
      platformName: data.platform,
      externalUrl: data.externalUrl,
    );

    final bool success = await ref
        .read(collectionItemsNotifierProvider(widget.collectionId).notifier)
        .addCustomItem(customMedia, localCoverPath: data.localCoverPath);

    if (!mounted) return;

    if (success) {
      context.showSnack(
        '${S.of(context).customItemCreated}: ${data.title}',
        type: SnackType.success,
      );
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

  Future<void> _handleCopyAsList() async {
    await CollectionActions.copyAsList(
      context: context,
      ref: ref,
      collectionId: widget.collectionId,
    );
  }

  Future<void> _handleCopyAsText() async {
    await CollectionActions.copyAsText(
      context: context,
      ref: ref,
      collectionId: widget.collectionId,
    );
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

  Future<void> _handleCloneItem(CollectionItem item) async {
    await CollectionActions.cloneItem(
      context: context,
      ref: ref,
      collectionId: widget.collectionId,
      item: item,
    );
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
