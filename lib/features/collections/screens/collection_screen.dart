import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/export_service.dart';
import '../../../core/services/image_cache_service.dart';
import '../../../core/services/xcoll_file.dart';
import '../../../shared/widgets/breadcrumb_app_bar.dart';
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
import 'anime_detail_screen.dart';
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
  bool _isGridMode = false;
  bool _isViewModeLocked = false;
  MediaType? _filterType;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  /// Реальная возможность редактирования с учётом режима просмотра.
  bool get _effectiveIsEditable =>
      _collection != null && _collection!.isEditable && !_isViewModeLocked;

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
    final CollectionRepository repo = ref.read(collectionRepositoryProvider);
    final Collection? collection = await repo.getById(widget.collectionId);
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
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: BreadcrumbAppBar(
          crumbs: <BreadcrumbItem>[
            BreadcrumbItem(
              label: 'Collections',
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_collection == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: BreadcrumbAppBar(
          crumbs: <BreadcrumbItem>[
            BreadcrumbItem(
              label: 'Collections',
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        body: Center(
          child: Text(
            'Collection not found',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final AsyncValue<List<CollectionItem>> itemsAsync =
        ref.watch(collectionItemsNotifierProvider(widget.collectionId));
    final AsyncValue<CollectionStats> statsAsync =
        ref.watch(collectionStatsProvider(widget.collectionId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BreadcrumbAppBar(
        crumbs: <BreadcrumbItem>[
          BreadcrumbItem(
            label: 'Collections',
            onTap: () => Navigator.of(context).pop(),
          ),
          BreadcrumbItem(label: _collection!.name),
        ],
        actions: <Widget>[
          if (_collection!.isEditable && !_isCanvasMode)
            IconButton(
              icon: const Icon(Icons.add),
              color: AppColors.textSecondary,
              tooltip: 'Add Items',
              onPressed: () => _addItems(context),
            ),
          if (kCanvasEnabled)
            IconButton(
              icon: Icon(
                _isCanvasMode ? Icons.list : Icons.dashboard,
              ),
              color: AppColors.textSecondary,
              tooltip: _isCanvasMode ? 'Switch to List' : 'Switch to Board',
              onPressed: () {
                setState(() {
                  _isCanvasMode = !_isCanvasMode;
                });
              },
            ),
          if (_collection!.isEditable && _isCanvasMode && kCanvasEnabled)
            IconButton(
              icon: Icon(
                _isViewModeLocked ? Icons.lock : Icons.lock_open,
              ),
              color: _isViewModeLocked
                  ? AppColors.warning
                  : AppColors.textSecondary,
              tooltip: _isViewModeLocked ? 'Unlock board' : 'Lock board',
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
          PopupMenuButton<String>(
            iconColor: AppColors.textSecondary,
            onSelected: (String value) => _handleMenuAction(value),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              if (_collection!.isEditable)
                const PopupMenuItem<String>(
                  value: 'rename',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Rename'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              const PopupMenuItem<String>(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.file_upload_outlined),
                  title: Text('Export'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (_collection!.isFork)
                const PopupMenuItem<String>(
                  value: 'revert',
                  child: ListTile(
                    leading: Icon(Icons.restore),
                    title: Text('Revert to Original'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: AppColors.error),
                  title: Text(
                    'Delete',
                    style: TextStyle(color: AppColors.error),
                  ),
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
    String label;
    if (_filterType == null) {
      label = 'All';
    } else {
      final int? count = switch (_filterType!) {
        MediaType.game => stats?.gameCount,
        MediaType.movie => stats?.movieCount,
        MediaType.tvShow => stats?.tvShowCount,
        MediaType.animation => stats?.animationCount,
      };
      label = '${_filterType!.displayLabel}${count != null ? ' ($count)' : ''}';
    }

    return PopupMenuButton<String>(
      tooltip: 'Filter by type',
      onSelected: (String value) {
        setState(() {
          _filterType =
              value == _filterAllKey ? null : MediaType.fromString(value);
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
              ? AppColors.gameAccent.withAlpha(30)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: _filterType != null
              ? Border.all(color: AppColors.gameAccent.withAlpha(100))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.filter_list,
              size: 16,
              color: _filterType != null
                  ? AppColors.gameAccent
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: _filterType != null
                    ? AppColors.gameAccent
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: _filterType != null
                  ? AppColors.gameAccent
                  : AppColors.textSecondary,
            ),
          ],
        ),
      ),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        _buildMediaTypeMenuItem(_filterAllKey, 'All', stats?.total),
        _buildMediaTypeMenuItem(
            MediaType.game.value, 'Games', stats?.gameCount),
        _buildMediaTypeMenuItem(
            MediaType.movie.value, 'Movies', stats?.movieCount),
        _buildMediaTypeMenuItem(
            MediaType.tvShow.value, 'TV Shows', stats?.tvShowCount),
        _buildMediaTypeMenuItem(
            MediaType.animation.value, 'Animation', stats?.animationCount),
      ],
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
            const Icon(Icons.check, size: 18, color: AppColors.gameAccent)
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
              currentSort.shortLabel,
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
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        ...CollectionSortMode.values.map(
          (CollectionSortMode mode) => PopupMenuItem<String>(
            value: mode.value,
            child: Row(
              children: <Widget>[
                if (mode == currentSort)
                  const Icon(
                    Icons.check,
                    size: 18,
                    color: AppColors.gameAccent,
                  )
                else
                  const SizedBox(width: 18),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(mode.displayLabel),
                    Text(
                      mode.description,
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
      ],
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
                '${SettingsKeys.collectionViewModePrefix}${widget.collectionId}',
                _isGridMode,
              );
        },
      ),
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
        sortMode == CollectionSortMode.manual && _collection!.isEditable;

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
            isEditable: _collection!.isEditable,
            onRemove: _collection!.isEditable
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
        return item.platform?.displayName;
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
          isEditable: _collection!.isEditable,
          showDragHandle: true,
          dragIndex: index,
          onRemove: _collection!.isEditable
              ? () => _removeItem(item)
              : null,
          onTap: () => _showItemDetails(item),
        );
      },
    );
  }

  Widget _buildEmptyState() {
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
            const Text('No Items Yet', style: AppTypography.h2),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _collection!.isEditable
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
              'Failed to load items',
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

  Future<void> _removeItem(CollectionItem item) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        scrollable: true,
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
    final String colName = _collection!.name;
    switch (item.mediaType) {
      case MediaType.game:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) => GameDetailScreen(
              collectionId: widget.collectionId,
              itemId: item.id,
              isEditable: _collection!.isEditable,
              collectionName: colName,
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
              collectionName: colName,
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
              collectionName: colName,
            ),
          ),
        );
      case MediaType.animation:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) => AnimeDetailScreen(
              collectionId: widget.collectionId,
              itemId: item.id,
              isEditable: _collection!.isEditable,
              collectionName: colName,
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
      case 'rename':
        _renameCollection(context);
      case 'export':
        _exportCollection();
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
        scrollable: true,
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
          content: Text('Image added to board'),
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
          content: Text('Map added to board'),
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

    // Выбор формата экспорта
    if (!mounted) return;
    final ExportFormat? chosen = await _showExportFormatDialog();
    if (chosen == null) return; // Отмена
    final ExportFormat format = chosen;

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
        scrollable: true,
        title: const Text('Export Format'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('Choose export format:'),
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
              subtitle: const Text(
                'Items + board + covers + media (offline)',
              ),
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
    this.showDragHandle = false,
    this.dragIndex = 0,
    this.onRemove,
    this.onTap,
  });

  final CollectionItem item;
  final bool isEditable;
  final bool showDragHandle;
  final int dragIndex;
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

                  // Удалить (если редактируемый)
                  if (onRemove != null)
                    IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: AppColors.error,
                      ),
                      tooltip: 'Remove',
                      onPressed: onRemove,
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
