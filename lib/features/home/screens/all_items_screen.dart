// Экран всех элементов из всех коллекций (Home tab).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/image_cache_service.dart';
import '../../../shared/constants/media_type_theme.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/collection_sort_mode.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/platform.dart';
import '../../../shared/navigation/navigation_shell.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/auto_breadcrumb_app_bar.dart';
import '../../../shared/widgets/breadcrumb_scope.dart';
import '../../../shared/widgets/media_poster_card.dart';
import '../../collections/providers/collections_provider.dart';
import '../../collections/screens/anime_detail_screen.dart';
import '../../collections/screens/game_detail_screen.dart';
import '../../collections/screens/movie_detail_screen.dart';
import '../../collections/screens/tv_show_detail_screen.dart';
import '../providers/all_items_provider.dart';

/// Экран всех элементов из всех коллекций.
///
/// Показывает grid-вид всех элементов с чипсами фильтрации по типу медиа
/// и сортировкой по рейтингу.
class AllItemsScreen extends ConsumerStatefulWidget {
  /// Создаёт [AllItemsScreen].
  const AllItemsScreen({super.key});

  @override
  ConsumerState<AllItemsScreen> createState() => _AllItemsScreenState();
}

class _AllItemsScreenState extends ConsumerState<AllItemsScreen> {
  MediaType? _filterType;
  int? _filterPlatformId;

  /// Максимальная ширина карточки на десктопе.
  static const double _desktopMaxCardWidth = 150;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<CollectionItem>> itemsAsync =
        ref.watch(allItemsNotifierProvider);
    final Map<int, String> collectionNames =
        ref.watch(collectionNamesProvider);
    final CollectionSortMode currentSort =
        ref.watch(allItemsSortProvider);
    final bool isDescending = ref.watch(allItemsSortDescProvider);

    return Scaffold(
      appBar: const AutoBreadcrumbAppBar(),
      body: Column(
        children: <Widget>[
          _buildChipsRow(itemsAsync, currentSort, isDescending),
          if (_filterType == MediaType.game) _buildPlatformChipsRow(),
          Expanded(
            child: itemsAsync.when(
              data: (List<CollectionItem> items) {
                final List<CollectionItem> filtered = _applyFilter(items);
                if (filtered.isEmpty) {
                  return _buildEmptyState(items.isEmpty);
                }
                return _buildGridView(filtered, collectionNames);
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (Object error, StackTrace stack) =>
                  _buildErrorState(error),
            ),
          ),
        ],
      ),
    );
  }

  List<CollectionItem> _applyFilter(List<CollectionItem> items) {
    List<CollectionItem> result = items;
    if (_filterType != null) {
      result = result
          .where((CollectionItem item) => item.mediaType == _filterType)
          .toList();
    }
    if (_filterPlatformId != null) {
      result = result
          .where((CollectionItem item) => item.platformId == _filterPlatformId)
          .toList();
    }
    return result;
  }

  Widget _buildChipsRow(
    AsyncValue<List<CollectionItem>> itemsAsync,
    CollectionSortMode currentSort,
    bool isDescending,
  ) {
    final List<CollectionItem>? items = itemsAsync.valueOrNull;
    final Map<MediaType, int> counts = _countByMediaType(items);
    final int total = items?.length ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            // Media type chips
            _buildMediaChip(null, 'All', total),
            const SizedBox(width: AppSpacing.xs),
            _buildMediaChip(MediaType.game, 'Games', counts[MediaType.game]),
            const SizedBox(width: AppSpacing.xs),
            _buildMediaChip(
                MediaType.movie, 'Movies', counts[MediaType.movie]),
            const SizedBox(width: AppSpacing.xs),
            _buildMediaChip(
                MediaType.tvShow, 'TV Shows', counts[MediaType.tvShow]),
            const SizedBox(width: AppSpacing.xs),
            _buildMediaChip(
                MediaType.animation, 'Animation', counts[MediaType.animation]),

            const SizedBox(width: AppSpacing.md),

            // Sort by rating chip
            _buildSortChip(currentSort, isDescending),
          ],
        ),
      ),
    );
  }

  /// Считает количество элементов по типу медиа.
  static Map<MediaType, int> _countByMediaType(List<CollectionItem>? items) {
    if (items == null) return <MediaType, int>{};
    final Map<MediaType, int> counts = <MediaType, int>{};
    for (final CollectionItem item in items) {
      counts[item.mediaType] = (counts[item.mediaType] ?? 0) + 1;
    }
    return counts;
  }

  Widget _buildMediaChip(MediaType? type, String label, int? count) {
    final bool selected = _filterType == type;
    final Color? accentColor =
        type != null ? MediaTypeTheme.colorFor(type) : null;
    final String displayLabel =
        count != null && count > 0 ? '$label ($count)' : label;

    return ChoiceChip(
      label: Text(
        displayLabel,
        style: AppTypography.bodySmall.copyWith(
          color: selected
              ? AppColors.background
              : accentColor ?? AppColors.textSecondary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: selected,
      selectedColor: accentColor ?? AppColors.textPrimary,
      backgroundColor: AppColors.surface,
      side: BorderSide(
        color: selected
            ? Colors.transparent
            : accentColor?.withAlpha(80) ?? AppColors.surfaceBorder,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onSelected: (bool value) {
        setState(() {
          _filterType = value ? type : null;
          _filterPlatformId = null;
        });
      },
    );
  }

  Widget _buildSortChip(CollectionSortMode currentSort, bool isDescending) {
    final bool isRatingSort = currentSort == CollectionSortMode.rating;
    final IconData sortIcon = isRatingSort
        ? (isDescending ? Icons.arrow_upward : Icons.arrow_downward)
        : Icons.star_outline;

    return ActionChip(
      avatar: Icon(
        sortIcon,
        size: 16,
        color: isRatingSort ? AppColors.ratingStar : AppColors.textTertiary,
      ),
      label: Text(
        isRatingSort
            ? (isDescending ? 'Rating ↑' : 'Rating ↓')
            : 'Rating',
        style: AppTypography.bodySmall.copyWith(
          color: isRatingSort ? AppColors.ratingStar : AppColors.textSecondary,
          fontWeight: isRatingSort ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      backgroundColor: isRatingSort
          ? AppColors.ratingStar.withAlpha(25)
          : AppColors.surface,
      side: BorderSide(
        color: isRatingSort
            ? AppColors.ratingStar.withAlpha(80)
            : AppColors.surfaceBorder,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onPressed: () {
        if (isRatingSort) {
          // Переключаем направление
          ref.read(allItemsSortDescProvider.notifier).toggle();
        } else {
          // Включаем сортировку по рейтингу
          ref.read(allItemsSortProvider.notifier)
              .setSortMode(CollectionSortMode.rating);
        }
      },
    );
  }

  Widget _buildPlatformChipsRow() {
    final AsyncValue<List<Platform>> platformsAsync =
        ref.watch(allItemsPlatformsProvider);
    final List<Platform> platforms =
        platformsAsync.valueOrNull ?? <Platform>[];
    if (platforms.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            _buildPlatformChip(null, 'All'),
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
    const Color accentColor = AppColors.gameAccent;

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

  Widget _buildGridView(
    List<CollectionItem> items,
    Map<int, String> collectionNames,
  ) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool isLandscape = isLandscapeMobile(context);
    final bool isDesktop = screenWidth >= navigationBreakpoint && !kIsMobile;

    final double gridPadding = isLandscape ? AppSpacing.sm : AppSpacing.md;
    final double crossSpacing = isLandscape ? AppSpacing.sm : AppSpacing.md;
    final double mainSpacing = isLandscape ? AppSpacing.sm : AppSpacing.lg;

    final SliverGridDelegate gridDelegate;
    if (isDesktop) {
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

    // Группируем элементы по коллекциям (сохраняя порядок появления)
    final List<_CollectionGroup> groups =
        _groupByCollection(items, collectionNames);

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(allItemsNotifierProvider.notifier).refresh(),
      child: CustomScrollView(
        slivers: <Widget>[
          for (int i = 0; i < groups.length; i++) ...<Widget>[
            // Разделитель с названием коллекции
            SliverToBoxAdapter(
              child: _buildCollectionDivider(
                groups[i].name,
                groups[i].items.length,
                isFirst: i == 0,
              ),
            ),
            // Сетка элементов
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: gridPadding,
              ),
              sliver: SliverGrid(
                gridDelegate: gridDelegate,
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    final CollectionItem item = groups[i].items[index];
                    return MediaPosterCard(
                      key: ValueKey<int>(item.id),
                      variant: isLandscape
                          ? CardVariant.compact
                          : CardVariant.grid,
                      title: item.itemName,
                      imageUrl: item.thumbnailUrl ?? '',
                      cacheImageType:
                          _imageTypeFor(item.mediaType, item.platformId),
                      cacheImageId: item.externalId.toString(),
                      userRating: item.userRating,
                      apiRating: item.apiRating,
                      year: _yearFor(item),
                      platformLabel: item.platform?.displayName,
                      status: item.status,
                      onTap: () =>
                          _showItemDetails(item, collectionNames),
                    );
                  },
                  childCount: groups[i].items.length,
                ),
              ),
            ),
            // Отступ после секции (кроме последней)
            if (i < groups.length - 1)
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.sm),
              ),
          ],
          // Нижний отступ
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.md),
          ),
        ],
      ),
    );
  }

  /// Группирует элементы по коллекциям, сохраняя порядок появления.
  static List<_CollectionGroup> _groupByCollection(
    List<CollectionItem> items,
    Map<int, String> collectionNames,
  ) {
    final Map<int?, _CollectionGroup> map = <int?, _CollectionGroup>{};
    final List<int?> order = <int?>[];
    for (final CollectionItem item in items) {
      final int? colId = item.collectionId;
      if (!map.containsKey(colId)) {
        final String name = colId != null
            ? (collectionNames[colId] ?? 'Unknown')
            : 'Uncategorized';
        map[colId] = _CollectionGroup(name: name, items: <CollectionItem>[]);
        order.add(colId);
      }
      map[colId]!.items.add(item);
    }
    return order.map((int? id) => map[id]!).toList();
  }

  /// Разделитель коллекции — линия во всю ширину с названием.
  Widget _buildCollectionDivider(
    String name,
    int count, {
    required bool isFirst,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        top: isFirst ? AppSpacing.xs : AppSpacing.md,
        bottom: AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Container(
              height: 1,
              color: AppColors.surfaceBorder,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              '$name ($count)',
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: AppColors.surfaceBorder,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool noItemsAtAll) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            noItemsAtAll ? Icons.inbox_outlined : Icons.filter_list_off,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            noItemsAtAll
                ? 'No items yet'
                : 'No items match filter',
            style: AppTypography.h2.copyWith(color: AppColors.textTertiary),
          ),
          if (noItemsAtAll) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Add items via Collections tab',
              style: AppTypography.body
                  .copyWith(color: AppColors.textTertiary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Failed to load items',
            style: AppTypography.h2.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: () =>
                ref.read(allItemsNotifierProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showItemDetails(
    CollectionItem item,
    Map<int, String> collectionNames,
  ) {
    // Определяем isEditable из коллекции
    final bool isEditable;
    final String colName;
    if (item.isUncategorized) {
      isEditable = true;
      colName = 'Uncategorized';
    } else {
      final List<Collection>? collections =
          ref.read(collectionsProvider).valueOrNull;
      final Collection? collection =
          collections?.cast<Collection?>().firstWhere(
        (Collection? c) => c?.id == item.collectionId,
        orElse: () => null,
      );
      isEditable = collection?.isEditable ?? false;
      colName = collectionNames[item.collectionId!] ?? '';
    }

    switch (item.mediaType) {
      case MediaType.game:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) => BreadcrumbScope(
              label: colName,
              child: GameDetailScreen(
                collectionId: item.collectionId,
                itemId: item.id,
                isEditable: isEditable,
              ),
            ),
          ),
        );
      case MediaType.movie:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) => BreadcrumbScope(
              label: colName,
              child: MovieDetailScreen(
                collectionId: item.collectionId,
                itemId: item.id,
                isEditable: isEditable,
              ),
            ),
          ),
        );
      case MediaType.tvShow:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) => BreadcrumbScope(
              label: colName,
              child: TvShowDetailScreen(
                collectionId: item.collectionId,
                itemId: item.id,
                isEditable: isEditable,
              ),
            ),
          ),
        );
      case MediaType.animation:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) => BreadcrumbScope(
              label: colName,
              child: AnimeDetailScreen(
                collectionId: item.collectionId,
                itemId: item.id,
                isEditable: isEditable,
              ),
            ),
          ),
        );
    }
  }

  // ==================== Helpers ====================

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
}

/// Группа элементов одной коллекции для отображения секции.
class _CollectionGroup {
  _CollectionGroup({required this.name, required this.items});
  final String name;
  final List<CollectionItem> items;
}
