import 'package:core/models/collection.dart';
import 'package:core/models/collection_item.dart';
import 'package:core/models/custom_media.dart';
import 'package:core/models/item_status.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/steamgriddb_image.dart';
import 'package:core/models/tag.dart';
import 'package:core/models/tag_sort_mode.dart';
import 'package:core/models/tier_list.dart';
import 'package:core/models/xcoll_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/collection_hero_service.dart';
import '../../../core/services/import_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../widgets/create_custom_item_dialog.dart';
import '../../../shared/keyboard/keyboard_shortcuts.dart';
import '../../../data/repositories/collection_repository.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/navigation/search_providers.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/sub_screen_title_bar.dart';
import '../../../shared/theme/app_typography.dart';
import '../../settings/providers/settings_provider.dart';
import '../../../shared/constants/platform_features.dart';
import '../../home/providers/all_items_provider.dart';
import '../widgets/import_progress_dialog.dart';
import '../helpers/collection_actions.dart';
import '../helpers/collection_filters.dart';
import '../providers/collection_covers_provider.dart';
import '../providers/global_tags_provider.dart';
import '../providers/item_tags_provider.dart';
import '../providers/tag_sort_provider.dart';
import '../providers/collections_provider.dart';
import '../widgets/collection_screen/collection_bulk_action_bar.dart';
import '../widgets/collection_screen/collection_error_state.dart';
import '../widgets/collection_screen/collection_screen_fab.dart';
import '../widgets/dialogs/create_tier_list_dialog.dart';
import '../providers/steamgriddb_panel_provider.dart';
import '../providers/vgmaps_panel_provider.dart';
import '../widgets/collection_canvas_layout.dart';
import '../widgets/collection_filter_bar.dart';
import '../widgets/collection_items_view.dart';
import '../widgets/rich/rich_hero_styles.dart';
import '../providers/rich_collections_provider.dart';
import '../widgets/tag_top_bar.dart';
import '../widgets/tag_management_dialog.dart';
import '../../tier_lists/screens/tier_list_detail_screen.dart';
import '../../tier_lists/providers/tier_lists_provider.dart';
import 'item_detail_screen.dart';

class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({
    required this.collectionId,
    super.key,
  });

  final int? collectionId;

  static ShortcutGroup shortcutGroup(S l) => ShortcutGroup(
        title: l.collection,
        entries: <ShortcutEntry>[
          ShortcutEntry(keys: 'Ctrl+N', description: l.shortcutAddItems),
          ShortcutEntry(keys: 'Ctrl+E', description: l.shortcutExportCollection),
          ShortcutEntry(
              keys: 'Ctrl+I', description: l.shortcutImportIntoCollection),
          ShortcutEntry(keys: 'Ctrl+Shift+V', description: l.shortcutToggleView),
          ShortcutEntry(keys: 'Ctrl+B', description: l.shortcutToggleBoard),
          ShortcutEntry(keys: 'Delete', description: l.shortcutDeleteItem),
          ShortcutEntry(keys: 'Ctrl+M', description: l.shortcutMoveItem),
          ShortcutEntry(
              keys: 'Ctrl+Delete', description: l.shortcutDeleteCollection),
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
  Set<String> _filterMangaFormats = <String>{};
  Set<String> _filterAnimeFormats = <String>{};
  Set<int> _filterTagIds = <int>{};
  bool _groupByTags = false;
  Set<ItemStatus> _filterStatuses = <ItemStatus>{};
  bool _filterFavoriteOnly = false;
  ItemStatus? _tableFilterStatus;
  CollectionItem? _focusedItem;
  List<CollectionItem>? _tagCountsItemsSource;
  Map<int, List<int>>? _tagCountsTagsSource;
  Map<int, int> _tagCounts = const <int, int>{};

  Set<ItemStatus>? get _effectiveStatusesForChevrons {
    if (_filterStatuses.isNotEmpty) return _filterStatuses;
    final ItemStatus? tableStatus = _isTableMode ? _tableFilterStatus : null;
    return tableStatus == null ? null : <ItemStatus>{tableStatus};
  }

  // Effective editability considering view mode.
  bool get _effectiveIsEditable =>
      (_isUncategorized || (_collection != null && _collection!.isEditable)) &&
      !_isViewModeLocked;

  bool get _canEdit =>
      _isUncategorized || (_collection != null && _collection!.isEditable);

  bool get _isUncategorized => widget.collectionId == null;

  @override
  void initState() {
    super.initState();
    _loadCollection();
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
      return const Center(child: CircularProgressIndicator());
    }

    if (!_isUncategorized && _collection == null) {
      return Center(
        child: Text(
          S.of(context).collectionNotFound,
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    final AsyncValue<List<CollectionItem>> itemsAsync =
        ref.watch(collectionItemsNotifierProvider(widget.collectionId));
    final AsyncValue<CollectionStats> statsAsync =
        ref.watch(collectionStatsProvider(widget.collectionId));

    final String searchQuery = ref.watch(collectionsSearchQueryProvider);
    final List<Tag> tags = _visibleTags(itemsAsync);
    final Map<int, List<int>> itemTags =
        ref.watch(itemTagsProvider).valueOrNull ?? <int, List<int>>{};
    final CollectionFilters activeFilters = CollectionFilters(
      mediaTypes: _filterTypes,
      platformIds: _filterPlatformIds,
      mangaFormats: _filterMangaFormats,
      animeFormats: _filterAnimeFormats,
      tagIds: _filterTagIds,
      statuses: _filterStatuses,
      favoriteOnly: _filterFavoriteOnly,
      searchQuery: searchQuery,
    );
    final S l = S.of(context);
    // The rich banner carries the back arrow and title itself; the plain
    // title bar would duplicate both and waste a row.
    final bool heroCarriesTitle = _isRich(ref) && !_isCanvasMode;
    return CallbackShortcuts(
      bindings: _buildScreenShortcuts(l),
      child: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              if (!_isCanvasMode)
                _buildFilterBar(itemsAsync, statsAsync, searchQuery, tags),
              if (!heroCarriesTitle)
                SubScreenTitleBar(
                  title: _isUncategorized
                      ? l.collectionsUncategorized
                      : _collection!.name,
                ),
              if (_canEdit && !_isCanvasMode)
                CollectionBulkActionBar(
                  collectionId: widget.collectionId,
                  collectionName: _isUncategorized
                      ? l.collectionsUncategorized
                      : _collection?.name,
                  filters: activeFilters,
                  tags: tags,
                ),
              Expanded(
                child: _isCanvasMode
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
                        onAddVgMapsImage:
                            (String url, int? width, int? height) {
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
                    : _buildListLayout(
                        itemsAsync, activeFilters, tags, itemTags),
              ),
            ],
          ),
          CollectionScreenFab(
            canEdit: _canEdit,
            isUncategorized: _isUncategorized,
            isCollectionEditable: _collection?.isEditable ?? false,
            isCanvasMode: _isCanvasMode,
            isTableMode: _isTableMode,
            isViewModeLocked: _isViewModeLocked,
            onAddItems: () => CollectionActions.addItems(
              ref: ref,
              collectionId: widget.collectionId,
            ),
            onCycleViewMode: _handleCycleViewMode,
            onToggleLock: _toggleLock,
            onToggleCanvas: () =>
                setState(() => _isCanvasMode = !_isCanvasMode),
            onMenuAction: _handleMenuAction,
          ),
        ],
      ),
    );
  }

  Map<ShortcutActivator, VoidCallback> _buildScreenShortcuts(S l) {
    if (kIsMobile) return <ShortcutActivator, VoidCallback>{};
    return <ShortcutActivator, VoidCallback>{
      if (_canEdit && !_isUncategorized)
        const SingleActivator(LogicalKeyboardKey.keyN, control: true):
            () => CollectionActions.addItems(ref: ref, collectionId: widget.collectionId),
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
    };
  }

  void _toggleLock() {
    setState(() => _isViewModeLocked = !_isViewModeLocked);
    if (_isViewModeLocked) {
      ref
          .read(steamGridDbPanelProvider(widget.collectionId).notifier)
          .closePanel();
      ref.read(vgMapsPanelProvider(widget.collectionId).notifier).closePanel();
    }
  }

  /// Global tags actually used by this collection's items, in the display
  /// order the tag dialogs share (manual or alphabetical).
  List<Tag> _visibleTags(AsyncValue<List<CollectionItem>> itemsAsync) {
    final List<Tag> all = ref.watch(globalTagsProvider).valueOrNull ?? <Tag>[];
    final TagSortMode sortMode = ref.watch(tagSortModeProvider);
    final Map<int, List<int>> itemTags =
        ref.watch(itemTagsProvider).valueOrNull ?? <int, List<int>>{};
    final List<CollectionItem> items =
        itemsAsync.valueOrNull ?? <CollectionItem>[];
    final Set<int> used = <int>{
      for (final CollectionItem item in items) ...?itemTags[item.id],
    };
    return sortMode.apply(all.where((Tag t) => used.contains(t.id)).toList());
  }

  Widget _buildFilterBar(
    AsyncValue<List<CollectionItem>> itemsAsync,
    AsyncValue<CollectionStats> statsAsync,
    String searchQuery,
    List<Tag> tags,
  ) {
    if ((statsAsync.valueOrNull?.total ?? 0) == 0) {
      return const SizedBox.shrink();
    }

    return CollectionFilterBar(
      collectionId: widget.collectionId,
      statsAsync: statsAsync,
      itemsAsync: itemsAsync,
      filterTypes: _filterTypes,
      filterPlatformIds: _filterPlatformIds,
      filterMangaFormats: _filterMangaFormats,
      filterAnimeFormats: _filterAnimeFormats,
      filterTagIds: _filterTagIds,
      filterStatuses: _filterStatuses,
      filterFavoriteOnly: _filterFavoriteOnly,
      effectiveStatusesForCounts: _effectiveStatusesForChevrons,
      tags: tags,
      searchQuery: searchQuery,
      groupByTags: _groupByTags,
      onFavoriteToggled: () =>
          setState(() => _filterFavoriteOnly = !_filterFavoriteOnly),
      onGroupToggled: _handleGroupToggled,
      onTypeToggled: (MediaType? type) {
        setState(() {
          if (type == null) {
            _filterTypes = <MediaType>{};
          } else if (_filterTypes.contains(type)) {
            _filterTypes = Set<MediaType>.from(_filterTypes)..remove(type);
          } else {
            _filterTypes = Set<MediaType>.from(_filterTypes)..add(type);
          }
          _filterPlatformIds = <int>{};
          // Drop a type's subfilter when that type is no longer selected.
          if (!_filterTypes.contains(MediaType.manga)) {
            _filterMangaFormats = <String>{};
          }
          if (!_filterTypes.contains(MediaType.anime)) {
            _filterAnimeFormats = <String>{};
          }
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
            _filterPlatformIds = Set<int>.from(_filterPlatformIds)..add(id);
          }
        });
      },
      onMangaFormatToggled: (String? code) {
        setState(() {
          if (code == null) {
            _filterMangaFormats = <String>{};
          } else if (_filterMangaFormats.contains(code)) {
            _filterMangaFormats = Set<String>.from(_filterMangaFormats)
              ..remove(code);
          } else {
            _filterMangaFormats = Set<String>.from(_filterMangaFormats)
              ..add(code);
          }
        });
      },
      onAnimeFormatToggled: (String? code) {
        setState(() {
          if (code == null) {
            _filterAnimeFormats = <String>{};
          } else if (_filterAnimeFormats.contains(code)) {
            _filterAnimeFormats = Set<String>.from(_filterAnimeFormats)
              ..remove(code);
          } else {
            _filterAnimeFormats = Set<String>.from(_filterAnimeFormats)
              ..add(code);
          }
        });
      },
      onTagToggled: _handleTagToggled,
      onStatusChanged: (Set<ItemStatus> statuses) {
        setState(() => _filterStatuses = statuses);
      },
    );
  }

  void _handleGroupToggled() {
    setState(() {
      _groupByTags = !_groupByTags;
      _filterTagIds = <int>{};
    });
  }

  /// `null` clears the whole tag filter; an id toggles that tag.
  void _handleTagToggled(int? tagId) {
    setState(() {
      if (tagId == null) {
        _filterTagIds = <int>{};
      } else if (_filterTagIds.contains(tagId)) {
        _filterTagIds = Set<int>.from(_filterTagIds)..remove(tagId);
      } else {
        _filterTagIds = Set<int>.from(_filterTagIds)..add(tagId);
      }
    });
  }

  /// Rich banner applies to any collection except uncategorized when the
  /// toggle is on, giving a stable template regardless of whether a hero exists.
  bool _isRich(WidgetRef ref) =>
      ref.watch(richCollectionsEnabledProvider) && !_isUncategorized;

  Widget _buildListLayout(
    AsyncValue<List<CollectionItem>> itemsAsync,
    CollectionFilters filters,
    List<Tag> tags,
    Map<int, List<int>> itemTags,
  ) {
    final Set<int> validTagIds = <int>{
      for (final Tag tag in tags) tag.id,
    };
    if (_filterTagIds.isNotEmpty &&
        !_filterTagIds.every(validTagIds.contains)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _filterTagIds = _filterTagIds.intersection(validTagIds);
        });
      });
    }

    final bool isRich = _isRich(ref);
    final String? heroFile = _collection?.heroImagePath;
    final String? heroAbsPath = (isRich && heroFile != null)
        ? ref.watch(collectionHeroServiceProvider).resolve(heroFile)
        : null;

    Widget? heroHeader(List<CollectionItem> items) => isRich
        ? RichCollectionHero(
            collection: _collection!,
            items: items,
            heroAbsolutePath: heroAbsPath,
            onBack: () => Navigator.of(context).pop(),
          )
        : null;

    // The banner replaces the title bar, so it must stay up (with its back
    // arrow) while the items are still loading or failed to load.
    Widget underHero(Widget body) {
      final Widget? banner = heroHeader(const <CollectionItem>[]);
      if (banner == null) return body;
      return Column(
        children: <Widget>[banner, Expanded(child: body)],
      );
    }

    final String anilistLang =
        ref.read(sharedPreferencesProvider).animeMangaTitleLanguage;
    final Widget itemsView = itemsAsync.when(
      data: (List<CollectionItem> items) => CollectionItemsView(
        collectionId: widget.collectionId,
        items: filters.apply(
          items,
          tags,
          itemTags,
          animeMangaTitleLanguage: anilistLang,
        ),
        tags: tags,
        itemTags: itemTags,
        filterTagIds: _filterTagIds,
        groupByTags: _groupByTags,
        isTableMode: _isTableMode,
        canEdit: _canEdit,
        header: heroHeader(items),
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
        onTableFilterStatusChanged: (ItemStatus? status) {
          setState(() => _tableFilterStatus = status);
        },
      ),
      loading: () => underHero(const ShimmerPosterGrid()),
      error: (Object error, StackTrace stack) => underHero(
        CollectionErrorState(
          error: error,
          onRetry: () => ref
              .read(
                  collectionItemsNotifierProvider(widget.collectionId).notifier)
              .refresh(),
        ),
      ),
    );

    // On narrow screens tags live in the filter-bar sheet instead.
    final Widget? tagTopBar = (tags.isNotEmpty && !isCompactScreen(context))
        ? TagTopBar(
            tags: tags,
            counts: _countItemTags(itemsAsync, itemTags),
            selectedTagIds: _filterTagIds,
            groupByTags: _groupByTags,
            onGroupToggled: _handleGroupToggled,
            onTagToggled: _handleTagToggled,
          )
        : null;

    // Rich vs classic now differ only by the presence of heroHeader inside
    // CollectionItemsView; the layout is identical.
    return Column(
      children: <Widget>[
        ?tagTopBar,
        Expanded(child: itemsView),
      ],
    );
  }

  /// Per-tag item counts within this collection, shown on the bar's chips.
  /// Memoized by source identity: rebuilds fire on every search keystroke.
  Map<int, int> _countItemTags(
    AsyncValue<List<CollectionItem>> itemsAsync,
    Map<int, List<int>> itemTags,
  ) {
    final List<CollectionItem> items =
        itemsAsync.valueOrNull ?? const <CollectionItem>[];
    if (identical(items, _tagCountsItemsSource) &&
        identical(itemTags, _tagCountsTagsSource)) {
      return _tagCounts;
    }
    final Map<int, int> counts = <int, int>{};
    for (final CollectionItem item in items) {
      for (final int tagId in itemTags[item.id] ?? const <int>[]) {
        counts[tagId] = (counts[tagId] ?? 0) + 1;
      }
    }
    _tagCountsItemsSource = items;
    _tagCountsTagsSource = itemTags;
    _tagCounts = counts;
    return counts;
  }

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

  void _handleMenuAction(CollectionMenuAction action) {
    switch (action) {
      case CollectionMenuAction.customItem:
        _handleCreateCustomItem();
      case CollectionMenuAction.rename:
        _handleRename();
      case CollectionMenuAction.tierList:
        _handleCreateTierList();
      case CollectionMenuAction.manageTags:
        TagManagementDialog.show(context);
      case CollectionMenuAction.copyAsText:
        _handleCopyAsText();
      case CollectionMenuAction.export:
        _handleExport();
      case CollectionMenuAction.import:
        _handleImportIntoCollection();
      case CollectionMenuAction.delete:
        _handleDelete();
    }
  }

  Future<void> _handleCreateCustomItem() async {
    final CustomItemData? data = await CreateCustomItemDialog.show(context);
    if (data == null || !mounted) return;

    // For local files coverUrl stays null; the file is copied into the cache
    // via addCustomItem.
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
      platformId: data.platformId,
      format: data.format,
      unitTotal: data.unitTotal,
      unitGroupTotal: data.unitGroupTotal,
      externalUrl: data.externalUrl,
    );

    final bool success = await ref
        .read(collectionItemsNotifierProvider(widget.collectionId).notifier)
        .addCustomItem(
          customMedia,
          coverBytes: data.coverBytes,
          userComment: data.comment,
          tags: data.tags,
        );

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
    final bool changed = await CollectionActions.renameCollection(
      context: context,
      ref: ref,
      collection: _collection!,
    );
    if (changed && mounted) {
      final Collection? updated = await ref
          .read(collectionRepositoryProvider)
          .getById(widget.collectionId!);
      if (updated != null && mounted) {
        setState(() {
          _collection = updated;
        });
      }
    }
  }

  Future<void> _handleCreateTierList() async {
    if (_collection == null) return;
    final String? name = await CreateTierListDialog.show(
      context,
      initialName: '${_collection!.name} Tier List',
    );
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
      ref.invalidate(
        collectionItemsNotifierProvider(widget.collectionId),
      );
      ref.invalidate(collectionStatsProvider(widget.collectionId));
      ref.invalidate(collectionCoversProvider(widget.collectionId));
      ref.invalidate(allItemsNotifierProvider);
      // Import writes tags straight through the DAO, so the in-memory tag
      // state must be rebuilt.
      ref.invalidate(globalTagsProvider);
      ref.invalidate(itemTagsProvider);

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

}
