// Панель фильтров, поиска и сортировки для CollectionScreen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/collection_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/collection_sort_mode.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/platform.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../providers/collections_provider.dart';

/// Панель фильтров, поиска и сортировки для CollectionScreen.
///
/// Состоит из строки фильтров (тип медиа, поиск, сортировка, grid/list toggle)
/// и опциональной строки чипсов платформ (при фильтре Games).
class CollectionFilterBar extends ConsumerWidget {
  /// Создаёт [CollectionFilterBar].
  const CollectionFilterBar({
    required this.collectionId,
    required this.statsAsync,
    required this.itemsAsync,
    required this.filterType,
    required this.filterPlatformId,
    required this.searchController,
    required this.searchQuery,
    required this.isGridMode,
    required this.onFilterTypeChanged,
    required this.onPlatformFilterChanged,
    required this.onGridModeChanged,
    super.key,
  });

  /// ID коллекции.
  final int? collectionId;

  /// Статистика коллекции.
  final AsyncValue<CollectionStats> statsAsync;

  /// Элементы коллекции (для платформенных чипсов).
  final AsyncValue<List<CollectionItem>> itemsAsync;

  /// Текущий фильтр по типу медиа.
  final MediaType? filterType;

  /// Текущий фильтр по платформе.
  final int? filterPlatformId;

  /// Контроллер поиска.
  final TextEditingController searchController;

  /// Текущий текст поиска.
  final String searchQuery;

  /// Режим отображения (grid/list).
  final bool isGridMode;

  /// Callback изменения фильтра по типу.
  final ValueChanged<MediaType?> onFilterTypeChanged;

  /// Callback изменения фильтра по платформе.
  final ValueChanged<int?> onPlatformFilterChanged;

  /// Callback переключения grid/list.
  final VoidCallback onGridModeChanged;

  /// Ключ для "All" фильтра (без типа медиа).
  static const String _filterAllKey = 'all';

  /// Высота компактных элементов FilterRow.
  static const double _filterRowHeight = 32;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _buildFilterRow(context, ref),
        if (filterType == MediaType.game)
          _buildPlatformChipsRow(context),
      ],
    );
  }

  Widget _buildFilterRow(BuildContext context, WidgetRef ref) {
    final CollectionStats? stats = statsAsync.valueOrNull;
    final CollectionSortMode currentSort =
        ref.watch(collectionSortProvider(collectionId));
    final bool isDescending =
        ref.watch(collectionSortDescProvider(collectionId));

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: <Widget>[
          // Фильтр по типу медиа
          _buildMediaTypeDropdown(context, stats),

          const SizedBox(width: AppSpacing.xs),

          // Поиск
          Expanded(child: _buildCompactSearch(context)),

          const SizedBox(width: AppSpacing.xs),

          // Сортировка
          _buildSortDropdown(context, ref, currentSort, isDescending),

          const SizedBox(width: AppSpacing.xs),

          // Grid ⇄ List
          _buildViewToggle(context),
        ],
      ),
    );
  }

  Widget _buildMediaTypeDropdown(BuildContext context, CollectionStats? stats) {
    final S l = S.of(context);
    String label;
    if (filterType == null) {
      label = l.collectionFilterAll;
    } else {
      final int? count = switch (filterType!) {
        MediaType.game => stats?.gameCount,
        MediaType.movie => stats?.movieCount,
        MediaType.tvShow => stats?.tvShowCount,
        MediaType.animation => stats?.animationCount,
        MediaType.visualNovel => stats?.visualNovelCount,
        MediaType.manga => stats?.mangaCount,
      };
      label = '${filterType!.localizedLabel(l)}${count != null ? ' ($count)' : ''}';
    }

    return PopupMenuButton<String>(
      tooltip: l.collectionFilterByType,
      onSelected: (String value) {
        onFilterTypeChanged(
          value == _filterAllKey ? null : MediaType.fromString(value),
        );
      },
      constraints: const BoxConstraints(),
      padding: EdgeInsets.zero,
      position: PopupMenuPosition.under,
      child: Container(
        height: _filterRowHeight,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: filterType != null
              ? AppColors.brand.withAlpha(30)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: filterType != null
              ? Border.all(color: AppColors.brand.withAlpha(100))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.filter_list,
              size: 16,
              color: filterType != null
                  ? AppColors.brand
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: filterType != null
                    ? AppColors.brand
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: filterType != null
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
          _buildMediaTypeMenuItem(
              MediaType.visualNovel.value, ml.collectionFilterVisualNovels, stats?.visualNovelCount),
          _buildMediaTypeMenuItem(
              MediaType.manga.value, ml.collectionFilterManga, stats?.mangaCount),
        ];
      },
    );
  }

  PopupMenuItem<String> _buildMediaTypeMenuItem(
    String value,
    String label,
    int? count,
  ) {
    final bool selected = (value == _filterAllKey && filterType == null) ||
        (filterType != null && filterType!.value == value);
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

  Widget _buildCompactSearch(BuildContext context) {
    return SizedBox(
      height: _filterRowHeight,
      child: TextField(
        controller: searchController,
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
          suffixIcon: searchQuery.isNotEmpty
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
                  onPressed: () => searchController.clear(),
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
    BuildContext context,
    WidgetRef ref,
    CollectionSortMode currentSort,
    bool isDescending,
  ) {
    return PopupMenuButton<String>(
      tooltip: 'Sort',
      onSelected: (String value) {
        if (value == 'toggle_direction') {
          ref
              .read(collectionSortDescProvider(collectionId).notifier)
              .toggle();
        } else {
          final CollectionSortMode mode =
              CollectionSortMode.fromString(value);
          ref
              .read(collectionSortProvider(collectionId).notifier)
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

  Widget _buildViewToggle(BuildContext context) {
    return SizedBox(
      width: _filterRowHeight,
      height: _filterRowHeight,
      child: IconButton(
        icon: Icon(
          isGridMode ? Icons.view_list : Icons.grid_view,
          size: 18,
          color: AppColors.textSecondary,
        ),
        tooltip: isGridMode ? 'List view' : 'Grid view',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        visualDensity: VisualDensity.compact,
        onPressed: onGridModeChanged,
      ),
    );
  }

  Widget _buildPlatformChipsRow(BuildContext context) {
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
    final bool selected = filterPlatformId == platformId;
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
        onPlatformFilterChanged(value ? platformId : null);
      },
    );
  }
}
