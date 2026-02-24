import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/export_service.dart';
import '../../../core/services/image_cache_service.dart';
import '../../../core/services/xcoll_file.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/widgets/auto_breadcrumb_app_bar.dart';
import '../../../shared/widgets/breadcrumb_scope.dart';
import '../../../shared/widgets/collection_picker_dialog.dart';
import '../../../shared/widgets/cached_image.dart';
import '../../../data/repositories/collection_repository.dart';
import '../../../shared/constants/media_type_theme.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/collection_sort_mode.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/platform.dart';
import '../../../shared/navigation/navigation_shell.dart';
import '../../../shared/widgets/dual_rating_badge.dart';
import '../../../shared/widgets/media_poster_card.dart';
import '../../search/screens/search_screen.dart';
import '../../settings/providers/settings_provider.dart';
import '../../../data/repositories/canvas_repository.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/models/steamgriddb_image.dart';
import '../providers/canvas_provider.dart';
import '../providers/collections_provider.dart';
import '../providers/steamgriddb_panel_provider.dart';
import '../providers/vgmaps_panel_provider.dart';
import '../widgets/canvas_view.dart';
import '../widgets/create_collection_dialog.dart';
import '../widgets/status_ribbon.dart';
import '../widgets/steamgriddb_panel.dart';
import '../widgets/vgmaps_panel.dart';
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

  /// Является ли это экраном uncategorized элементов.
  bool get _isUncategorized => widget.collectionId == null;

  Future<void> _loadCollection() async {
    if (_isUncategorized) {
      // Uncategorized — нет коллекции в БД
      final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
      final bool savedGridMode = prefs.getBool(
            '${SettingsKeys.collectionViewModePrefix}uncategorized',
          ) ??
          false;
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
    // Загружаем сохранённый режим отображения
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    final bool savedGridMode = prefs.getBool(
          '${SettingsKeys.collectionViewModePrefix}${widget.collectionId}',
        ) ??
        false;
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
        actions: <Widget>[
          if (_canEdit && !_isCanvasMode)
            IconButton(
              icon: const Icon(Icons.add),
              color: AppColors.textSecondary,
              tooltip: l.collectionAddItems,
              onPressed: () => _addItems(context),
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
              onSelected: (String value) => _handleMenuAction(value),
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
                  value: 'export',
                  child: ListTile(
                    leading: const Icon(Icons.file_upload_outlined),
                    title: Text(ml.collectionExport),
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
        ],
      ),
      body: _isCanvasMode
          ? Row(
              children: <Widget>[
                Expanded(
                  child: CanvasView(
                    collectionId: widget.collectionId,
                    isEditable: _effectiveIsEditable,
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
                            ? const Border(
                                left: BorderSide(
                                  color: AppColors.surfaceBorder,
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
                // Боковая панель VGMaps Browser (Windows only)
                if (kVgMapsEnabled)
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
                              ? const Border(
                                  left: BorderSide(
                                    color: AppColors.surfaceBorder,
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
                // Единая строка фильтров — только если есть элементы
                if ((statsAsync.valueOrNull?.total ?? 0) > 0)
                  _buildFilterRow(statsAsync),

                // Чипсы платформ (только при фильтре Games)
                if (_filterType == MediaType.game)
                  _buildPlatformChipsRow(itemsAsync),

                // Список элементов
                Expanded(
                  child: itemsAsync.when(
                    data: (List<CollectionItem> items) =>
                        _buildItemsList(context, _applyFilters(items)),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (Object error, StackTrace stack) =>
                        _buildErrorState(context, error),
                  ),
                ),
              ],
            ),
    ),
    );
  }

  Widget _buildFilterRow(AsyncValue<CollectionStats> statsAsync) {
    final CollectionStats? stats = statsAsync.valueOrNull;
    final CollectionSortMode currentSort =
        ref.watch(collectionSortProvider(widget.collectionId));
    final bool isDescending =
        ref.watch(collectionSortDescProvider(widget.collectionId));

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: <Widget>[
          // Фильтр по типу медиа
          _buildMediaTypeDropdown(stats),

          const SizedBox(width: AppSpacing.xs),

          // Поиск
          Expanded(child: _buildCompactSearch()),

          const SizedBox(width: AppSpacing.xs),

          // Сортировка
          _buildSortDropdown(currentSort, isDescending),

          const SizedBox(width: AppSpacing.xs),

          // Grid ⇄ List
          _buildViewToggle(),
        ],
      ),
    );
  }

  /// Ключ для "All" фильтра (без типа медиа).
  static const String _filterAllKey = 'all';

  /// Высота компактных элементов FilterRow.
  static const double _filterRowHeight = 32;

  Widget _buildMediaTypeDropdown(CollectionStats? stats) {
    final S l = S.of(context);
    String label;
    if (_filterType == null) {
      label = l.collectionFilterAll;
    } else {
      final int? count = switch (_filterType!) {
        MediaType.game => stats?.gameCount,
        MediaType.movie => stats?.movieCount,
        MediaType.tvShow => stats?.tvShowCount,
        MediaType.animation => stats?.animationCount,
      };
      label = '${_filterType!.localizedLabel(l)}${count != null ? ' ($count)' : ''}';
    }

    return PopupMenuButton<String>(
      tooltip: l.collectionFilterByType,
      onSelected: (String value) {
        setState(() {
          _filterType =
              value == _filterAllKey ? null : MediaType.fromString(value);
          _filterPlatformId = null;
        });
      },
      constraints: const BoxConstraints(),
      padding: EdgeInsets.zero,
      position: PopupMenuPosition.under,
      child: Container(
        height: _filterRowHeight,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: _filterType != null
              ? AppColors.brand.withAlpha(30)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: _filterType != null
              ? Border.all(color: AppColors.brand.withAlpha(100))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.filter_list,
              size: 16,
              color: _filterType != null
                  ? AppColors.brand
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: _filterType != null
                    ? AppColors.brand
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: _filterType != null
                  ? AppColors.brand
                  : AppColors.textSecondary,
            ),
          ],
        ),
      ),
      itemBuilder: (BuildContext context) {
        final S ml = S.of(context);
        return <PopupMenuEntry<String>>[
          _buildMediaTypeMenuItem(_filterAllKey, ml.collectionFilterAll, stats?.total),
          _buildMediaTypeMenuItem(
              MediaType.game.value, ml.collectionFilterGames, stats?.gameCount),
          _buildMediaTypeMenuItem(
              MediaType.movie.value, ml.collectionFilterMovies, stats?.movieCount),
          _buildMediaTypeMenuItem(
              MediaType.tvShow.value, ml.collectionFilterTvShows, stats?.tvShowCount),
          _buildMediaTypeMenuItem(
              MediaType.animation.value, ml.collectionFilterAnimation, stats?.animationCount),
        ];
      },
    );
  }

  PopupMenuItem<String> _buildMediaTypeMenuItem(
    String value,
    String label,
    int? count,
  ) {
    final bool selected = (value == _filterAllKey && _filterType == null) ||
        (_filterType != null && _filterType!.value == value);
    final String displayLabel =
        count != null && count > 0 ? '$label ($count)' : label;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: <Widget>[
          if (selected)
            const Icon(Icons.check, size: 18, color: AppColors.brand)
          else
            const SizedBox(width: 18),
          const SizedBox(width: AppSpacing.sm),
          Text(displayLabel),
        ],
      ),
    );
  }

  Widget _buildCompactSearch() {
    return SizedBox(
      height: _filterRowHeight,
      child: TextField(
        controller: _searchController,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Search...',
          hintStyle: AppTypography.bodySmall.copyWith(
            color: AppColors.textTertiary,
          ),
          prefixIcon: const Icon(
            Icons.search,
            size: 16,
            color: AppColors.textTertiary,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 14,
                    color: AppColors.textTertiary,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  onPressed: () => _searchController.clear(),
                )
              : null,
          filled: true,
          fillColor: AppColors.surfaceLight,
          contentPadding: const EdgeInsets.symmetric(
            vertical: AppSpacing.xs,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildSortDropdown(
    CollectionSortMode currentSort,
    bool isDescending,
  ) {
    return PopupMenuButton<String>(
      tooltip: 'Sort',
      onSelected: (String value) {
        if (value == 'toggle_direction') {
          ref
              .read(collectionSortDescProvider(widget.collectionId).notifier)
              .toggle();
        } else {
          final CollectionSortMode mode =
              CollectionSortMode.fromString(value);
          ref
              .read(collectionSortProvider(widget.collectionId).notifier)
              .setSortMode(mode);
        }
      },
      constraints: const BoxConstraints(),
      padding: EdgeInsets.zero,
      position: PopupMenuPosition.under,
      child: Container(
        height: _filterRowHeight,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              currentSort.localizedShortLabel(S.of(context)),
              style: AppTypography.bodySmall,
            ),
            const SizedBox(width: 2),
            Icon(
              isDescending ? Icons.arrow_downward : Icons.arrow_upward,
              size: 14,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
      itemBuilder: (BuildContext context) {
        final S sl = S.of(context);
        return <PopupMenuEntry<String>>[
          ...CollectionSortMode.values.map(
            (CollectionSortMode mode) => PopupMenuItem<String>(
              value: mode.value,
              child: Row(
                children: <Widget>[
                  if (mode == currentSort)
                    const Icon(
                      Icons.check,
                      size: 18,
                      color: AppColors.brand,
                    )
                  else
                    const SizedBox(width: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(mode.localizedDisplayLabel(sl)),
                      Text(
                        mode.localizedDescription(sl),
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<String>(
            value: 'toggle_direction',
            child: Row(
              children: <Widget>[
                Icon(
                  isDescending ? Icons.arrow_downward : Icons.arrow_upward,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(isDescending ? 'Descending' : 'Ascending'),
              ],
            ),
          ),
        ];
      },
    );
  }

  Widget _buildViewToggle() {
    return SizedBox(
      width: _filterRowHeight,
      height: _filterRowHeight,
      child: IconButton(
        icon: Icon(
          _isGridMode ? Icons.view_list : Icons.grid_view,
          size: 18,
          color: AppColors.textSecondary,
        ),
        tooltip: _isGridMode ? 'List view' : 'Grid view',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        visualDensity: VisualDensity.compact,
        onPressed: () {
          setState(() => _isGridMode = !_isGridMode);
          ref
              .read(sharedPreferencesProvider)
              .setBool(
                '${SettingsKeys.collectionViewModePrefix}${widget.collectionId ?? "uncategorized"}',
                _isGridMode,
              );
        },
      ),
    );
  }

  Widget _buildPlatformChipsRow(
    AsyncValue<List<CollectionItem>> itemsAsync,
  ) {
    final List<CollectionItem>? items = itemsAsync.valueOrNull;
    if (items == null) return const SizedBox.shrink();

    // Уникальные платформы из игр в этой коллекции
    final Map<int, Platform> platformMap = <int, Platform>{};
    for (final CollectionItem item in items) {
      if (item.mediaType == MediaType.game &&
          item.platformId != null &&
          item.platformId != -1 &&
          item.platform != null) {
        platformMap[item.platformId!] = item.platform!;
      }
    }
    if (platformMap.isEmpty) return const SizedBox.shrink();

    final List<Platform> platforms = platformMap.values.toList()
      ..sort((Platform a, Platform b) => a.name.compareTo(b.name));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            _buildPlatformChip(null, S.of(context).collectionFilterAll),
            for (final Platform platform in platforms) ...<Widget>[
              const SizedBox(width: AppSpacing.xs),
              _buildPlatformChip(platform.id, platform.displayName),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformChip(int? platformId, String label) {
    final bool selected = _filterPlatformId == platformId;
    const Color accentColor = AppColors.brand;

    return ChoiceChip(
      label: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: selected ? AppColors.background : AppColors.textTertiary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: selected,
      selectedColor: accentColor,
      backgroundColor: AppColors.surface,
      side: BorderSide(
        color: selected
            ? Colors.transparent
            : accentColor.withAlpha(50),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      onSelected: (bool value) {
        setState(() => _filterPlatformId = value ? platformId : null);
      },
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

    return result;
  }

  Widget _buildItemsList(BuildContext context, List<CollectionItem> items) {
    if (items.isEmpty) {
      return _buildEmptyState();
    }

    if (_isGridMode) {
      return _buildGridView(items);
    }

    final CollectionSortMode sortMode =
        ref.watch(collectionSortProvider(widget.collectionId));
    final bool isManualSort =
        sortMode == CollectionSortMode.manual && _canEdit;

    if (isManualSort) {
      return _buildReorderableList(items);
    }

    return RefreshIndicator(
      onRefresh: () => ref
          .read(collectionItemsNotifierProvider(widget.collectionId).notifier)
          .refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        itemCount: items.length,
        itemBuilder: (BuildContext context, int index) {
          final CollectionItem item = items[index];
          return _CollectionItemTile(
            key: ValueKey<int>(item.id),
            item: item,
            isEditable: _canEdit,
            onMove: _canEdit ? () => _moveItem(item) : null,
            onRemove: _canEdit
                ? () => _removeItem(item)
                : null,
            onTap: () => _showItemDetails(item),
          );
        },
      ),
    );
  }

  /// Максимальная ширина карточки на десктопе.
  static const double _desktopMaxCardWidth = 150;

  Widget _buildGridView(List<CollectionItem> items) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool isLandscape = isLandscapeMobile(context);
    final bool isDesktop = screenWidth >= navigationBreakpoint && !kIsMobile;

    final double gridPadding = isLandscape ? AppSpacing.sm : AppSpacing.md;
    final double crossSpacing = isLandscape ? AppSpacing.sm : AppSpacing.md;
    final double mainSpacing = isLandscape ? AppSpacing.sm : AppSpacing.lg;

    final SliverGridDelegate gridDelegate;
    if (isDesktop) {
      // На десктопе ограничиваем максимальный размер карточки
      gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: _desktopMaxCardWidth,
        crossAxisSpacing: crossSpacing,
        mainAxisSpacing: mainSpacing,
        childAspectRatio: 0.55,
      );
    } else {
      final int crossAxisCount;
      if (isLandscape) {
        crossAxisCount = AppSpacing.gridColumnsDesktop;
      } else if (screenWidth >= 500) {
        crossAxisCount = AppSpacing.gridColumnsTablet;
      } else {
        crossAxisCount = AppSpacing.gridColumnsMobile;
      }
      gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossSpacing,
        mainAxisSpacing: mainSpacing,
        childAspectRatio: 0.55,
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref
          .read(collectionItemsNotifierProvider(widget.collectionId).notifier)
          .refresh(),
      child: GridView.builder(
        padding: EdgeInsets.all(gridPadding),
        gridDelegate: gridDelegate,
        itemCount: items.length,
        itemBuilder: (BuildContext context, int index) {
          final CollectionItem item = items[index];
          return MediaPosterCard(
            key: ValueKey<int>(item.id),
            variant: isLandscape ? CardVariant.compact : CardVariant.grid,
            title: item.itemName,
            imageUrl: item.thumbnailUrl ?? '',
            cacheImageType: _imageTypeFor(item.mediaType, item.platformId),
            cacheImageId: item.externalId.toString(),
            userRating: item.userRating,
            apiRating: item.apiRating,
            year: _yearFor(item),
            platformLabel: item.platform?.displayName,
            subtitle: _subtitleFor(item),
            status: item.status,
            onTap: () => _showItemDetails(item),
          );
        },
      ),
    );
  }

  /// Год выпуска элемента.
  static int? _yearFor(CollectionItem item) {
    switch (item.mediaType) {
      case MediaType.game:
        return item.game?.releaseYear;
      case MediaType.movie:
        return item.movie?.releaseYear;
      case MediaType.tvShow:
        return item.tvShow?.firstAirYear;
      case MediaType.animation:
        if (item.platformId == AnimationSource.tvShow) {
          return item.tvShow?.firstAirYear;
        }
        return item.movie?.releaseYear;
    }
  }

  /// Подзаголовок для grid-карточки.
  static String? _subtitleFor(CollectionItem item) {
    switch (item.mediaType) {
      case MediaType.game:
        return item.game?.genresString;
      case MediaType.movie:
        return item.movie?.genresString;
      case MediaType.tvShow:
        return item.tvShow?.genresString;
      case MediaType.animation:
        if (item.platformId == AnimationSource.tvShow) {
          return item.tvShow?.genresString;
        }
        return item.movie?.genresString;
    }
  }

  /// ImageType для кэширования по типу медиа.
  ///
  /// Для [MediaType.animation] использует [platformId] для определения
  /// источника: [AnimationSource.tvShow] → tvShowPoster, иначе moviePoster.
  static ImageType _imageTypeFor(MediaType mediaType, int? platformId) {
    switch (mediaType) {
      case MediaType.game:
        return ImageType.gameCover;
      case MediaType.movie:
        return ImageType.moviePoster;
      case MediaType.tvShow:
        return ImageType.tvShowPoster;
      case MediaType.animation:
        if (platformId == AnimationSource.tvShow) {
          return ImageType.tvShowPoster;
        }
        return ImageType.moviePoster;
    }
  }

  Widget _buildReorderableList(List<CollectionItem> items) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
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
          isEditable: _canEdit,
          showDragHandle: true,
          dragIndex: index,
          onMove: _canEdit ? () => _moveItem(item) : null,
          onRemove: _canEdit
              ? () => _removeItem(item)
              : null,
          onTap: () => _showItemDetails(item),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final S l = S.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.collections_bookmark_outlined,
              size: 64,
              color: AppColors.textTertiary.withAlpha(120),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(l.collectionNoItemsYet, style: AppTypography.h2),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _canEdit
                  ? 'Add items to start building your collection.'
                  : 'This collection is empty.',
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

  Future<void> _moveItem(CollectionItem item) async {
    final bool isUncategorized = widget.collectionId == null;
    final S l = S.of(context);

    final CollectionChoice? choice = await showCollectionPickerDialog(
      context: context,
      ref: ref,
      excludeCollectionId: widget.collectionId,
      showUncategorized: !isUncategorized,
      title: l.collectionMoveToCollection,
    );
    if (choice == null || !mounted) return;

    final int? targetCollectionId;
    final String targetName;
    switch (choice) {
      case ChosenCollection(:final Collection collection):
        targetCollectionId = collection.id;
        targetName = collection.name;
      case WithoutCollection():
        targetCollectionId = null;
        targetName = S.of(context).collectionsUncategorized;
    }

    final ({bool success, bool sourceEmpty}) result = await ref
        .read(
          collectionItemsNotifierProvider(widget.collectionId).notifier,
        )
        .moveItem(
          item.id,
          targetCollectionId: targetCollectionId,
          mediaType: item.mediaType,
        );

    if (!mounted) return;

    if (result.success) {
      context.showSnack(
        S.of(context).collectionItemMovedTo(item.itemName, targetName),
        type: SnackType.success,
      );

      if (result.sourceEmpty && widget.collectionId != null) {
        await _promptDeleteEmptyCollection();
      }
    } else {
      context.showSnack(S.of(context).collectionItemAlreadyExists(item.itemName, targetName));
    }
  }

  Future<void> _promptDeleteEmptyCollection() async {
    if (!mounted) return;
    final NavigatorState navigator = Navigator.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final S dl = S.of(context);
        return AlertDialog(
          title: Text(dl.collectionEmpty),
          content: Text(dl.collectionDeleteEmptyPrompt),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(dl.keep),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(dl.delete),
            ),
          ],
        );
      },
    );
    if (confirmed == true && mounted) {
      await ref
          .read(collectionsProvider.notifier)
          .delete(widget.collectionId!);
      if (mounted) {
        navigator.pop();
      }
    }
  }

  Future<void> _removeItem(CollectionItem item) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final S dl = S.of(context);
        return AlertDialog(
          scrollable: true,
          title: Text(dl.collectionRemoveItemTitle),
          content: Text(dl.collectionRemoveItemMessage(item.itemName)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(dl.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(dl.remove),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    await ref
        .read(collectionItemsNotifierProvider(widget.collectionId).notifier)
        .removeItem(item.id);

    // Синхронизация канваса — удалить элемент
    ref
        .read(canvasNotifierProvider(widget.collectionId).notifier)
        .removeByCollectionItemId(item.id);

    if (mounted) {
      context.showSnack(S.of(context).collectionItemRemoved(item.itemName), type: SnackType.success);
    }
  }

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

  Future<void> _renameCollection(BuildContext context) async {
    if (_collection == null) return;

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

      if (context.mounted) {
        context.showSnack(S.of(context).collectionsRenamed, type: SnackType.success);
      }
    } on Exception catch (e) {
      if (context.mounted) {
        context.showSnack(S.of(context).collectionsFailedToRename('$e'), type: SnackType.error);
      }
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'rename':
        _renameCollection(context);
      case 'export':
        _exportCollection();
      case 'delete':
        _deleteCollection();
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
        context.showSnack(S.of(context).collectionsDeleted, type: SnackType.success);
      }
    } on Exception catch (e) {
      if (mounted) {
        context.showSnack(S.of(context).collectionsFailedToDelete('$e'), type: SnackType.error);
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
      context.showSnack(S.of(context).imageAddedToBoard, type: SnackType.success);
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
      context.showSnack(S.of(context).mapAddedToBoard, type: SnackType.success);
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
        context.showSnack('Items not loaded yet', type: SnackType.error);
      }
      return;
    }

    // Выбор формата экспорта
    if (!mounted) return;
    final ExportFormat? chosen = await _showExportFormatDialog();
    if (chosen == null) return; // Отмена
    final ExportFormat format = chosen;

    // Показываем индикатор
    if (mounted) {
      context.showSnack(
        format == ExportFormat.full
            ? 'Preparing full export...'
            : 'Preparing export...',
        loading: true,
        duration: const Duration(seconds: 30),
      );
    }

    final ExportService exportService = ref.read(exportServiceProvider);
    final ExportResult result =
        await exportService.exportToFile(_collection!, items, format: format);

    if (!mounted) return;

    if (result.success) {
      context.showSnack(
        'Exported to ${result.filePath}',
        type: SnackType.success,
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      );
    } else if (!result.isCancelled) {
      context.showSnack(
        result.error ?? 'Export failed',
        type: SnackType.error,
      );
    } else {
      context.hideSnack();
    }
  }

  Future<ExportFormat?> _showExportFormatDialog() {
    return showDialog<ExportFormat>(
      context: context,
      builder: (BuildContext dialogContext) {
        final S dl = S.of(dialogContext);
        return AlertDialog(
          scrollable: true,
          title: Text(dl.collectionExportFormat),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(dl.collectionChooseExportFormat),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(dl.collectionExportLight),
                subtitle: Text(dl.collectionExportLightDesc),
                onTap: () =>
                    Navigator.of(dialogContext).pop(ExportFormat.light),
              ),
              ListTile(
                leading: const Icon(Icons.folder_zip_outlined),
                title: Text(dl.collectionExportFull),
                subtitle: Text(dl.collectionExportFullDesc),
                onTap: () =>
                    Navigator.of(dialogContext).pop(ExportFormat.full),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(dl.cancel),
            ),
          ],
        );
      },
    );
  }
}

/// Плитка элемента в коллекции.
class _CollectionItemTile extends StatelessWidget {
  const _CollectionItemTile({
    super.key,
    required this.item,
    required this.isEditable,
    this.showDragHandle = false,
    this.dragIndex = 0,
    this.onMove,
    this.onRemove,
    this.onTap,
  });

  final CollectionItem item;
  final bool isEditable;
  final bool showDragHandle;
  final int dragIndex;
  final VoidCallback? onMove;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: const BorderSide(color: AppColors.surfaceBorder),
      ),
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
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md - 4),
              child: Row(
                children: <Widget>[
                  // Drag handle (только в manual sort mode)
                  if (showDragHandle)
                    ReorderableDragStartListener(
                      index: dragIndex,
                      child: Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: Icon(
                          Icons.drag_handle,
                          size: 20,
                          color: AppColors.textTertiary.withAlpha(128),
                        ),
                      ),
                    ),
                  // Обложка
                  _buildCover(),
                  const SizedBox(width: AppSpacing.md - 4),

                  // Информация
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // Название
                        Text(
                          item.itemName,
                          style: AppTypography.h3,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: AppSpacing.xs),

                        // Подзаголовок (зависит от типа медиа)
                        Text(
                          _getSubtitle(),
                          style: AppTypography.bodySmall,
                        ),

                        // Рейтинги (пользовательский + API)
                        if (_hasAnyRating) ...<Widget>[
                          const SizedBox(height: AppSpacing.xs),
                          DualRatingBadge(
                            userRating: item.userRating,
                            apiRating: item.apiRating,
                            inline: true,
                          ),
                        ],

                        // Описание
                        if (item.itemDescription != null &&
                            item.itemDescription!.isNotEmpty) ...<Widget>[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            item.itemDescription!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],

                        // Комментарий автора (рецензия)
                        if (item.hasAuthorComment) ...<Widget>[
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: <Widget>[
                              const Icon(
                                Icons.format_quote,
                                size: 14,
                                color: AppColors.movieAccent,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  item.authorComment!,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.movieAccent,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],

                        // Личные заметки
                        if (item.hasUserComment) ...<Widget>[
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: <Widget>[
                              const Icon(
                                Icons.note_outlined,
                                size: 14,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  item.userComment!,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textTertiary,
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

                  // Move / Remove меню
                  if (onMove != null || onRemove != null)
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        color: AppColors.textSecondary,
                      ),
                      padding: EdgeInsets.zero,
                      onSelected: (String value) {
                        switch (value) {
                          case 'move':
                            onMove?.call();
                          case 'remove':
                            onRemove?.call();
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        final S ml = S.of(context);
                        return <PopupMenuEntry<String>>[
                          if (onMove != null)
                            PopupMenuItem<String>(
                              value: 'move',
                              child: ListTile(
                                leading:
                                    const Icon(Icons.drive_file_move_outlined),
                                title: Text(ml.collectionMoveToCollection),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          if (onMove != null && onRemove != null)
                            const PopupMenuDivider(),
                          if (onRemove != null)
                            PopupMenuItem<String>(
                              value: 'remove',
                              child: ListTile(
                                leading: Icon(
                                  Icons.remove_circle_outline,
                                  color:
                                      Theme.of(context).colorScheme.error,
                                ),
                                title: Text(
                                  ml.remove,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .error,
                                  ),
                                ),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                        ];
                      },
                    ),
                ],
              ),
            ),
          ),
          // Диагональная ленточка статуса (верхний левый угол, поверх контента)
          StatusRibbon(
            status: item.status,
            mediaType: item.mediaType,
          ),
        ],
      ),
    );
  }

  bool get _hasAnyRating =>
      item.userRating != null ||
      (item.apiRating != null && item.apiRating! > 0);

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
      case MediaType.animation:
        if (item.platformId == AnimationSource.tvShow) {
          final List<String> parts = <String>[];
          if (item.tvShow?.firstAirYear != null) {
            parts.add(item.tvShow!.firstAirYear.toString());
          }
          if (item.tvShow?.totalSeasons != null) {
            parts.add(
              '${item.tvShow!.totalSeasons} season${item.tvShow!.totalSeasons != 1 ? 's' : ''}',
            );
          }
          return parts.isNotEmpty ? parts.join(' \u2022 ') : 'Animated Series';
        }
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
        return parts.isNotEmpty ? parts.join(' \u2022 ') : 'Animated Movie';
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
      case MediaType.animation:
        return Icons.animation;
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
      case MediaType.animation:
        if (item.platformId == AnimationSource.tvShow) {
          return ImageType.tvShowPoster;
        }
        return ImageType.moviePoster;
    }
  }

  Widget _buildCover() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: SizedBox(
        width: 48,
        height: 72,
        child: item.thumbnailUrl != null
            ? CachedImage(
                imageType: _getImageTypeForCache(),
                imageId: item.externalId.toString(),
                remoteUrl: item.thumbnailUrl!,
                fit: BoxFit.cover,
                memCacheWidth: 96,
                memCacheHeight: 128,
                placeholder: Container(
                  color: AppColors.surfaceLight,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: _buildPlaceholder(),
              )
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.surfaceLight,
      child: Icon(
        _getMediaTypeIcon(),
        color: AppColors.textSecondary,
      ),
    );
  }
}
