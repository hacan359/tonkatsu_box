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
import '../../../shared/navigation/navigation_shell.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 40,
        title: Text(
          'Main',
          style: AppTypography.body.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          _buildChipsRow(currentSort, isDescending),
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
    if (_filterType == null) return items;
    return items
        .where((CollectionItem item) => item.mediaType == _filterType)
        .toList();
  }

  Widget _buildChipsRow(CollectionSortMode currentSort, bool isDescending) {
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
            _buildMediaChip(null, 'All'),
            const SizedBox(width: AppSpacing.xs),
            _buildMediaChip(MediaType.game, 'Games'),
            const SizedBox(width: AppSpacing.xs),
            _buildMediaChip(MediaType.movie, 'Movies'),
            const SizedBox(width: AppSpacing.xs),
            _buildMediaChip(MediaType.tvShow, 'TV Shows'),
            const SizedBox(width: AppSpacing.xs),
            _buildMediaChip(MediaType.animation, 'Animation'),

            const SizedBox(width: AppSpacing.md),

            // Sort by rating chip
            _buildSortChip(currentSort, isDescending),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaChip(MediaType? type, String label) {
    final bool selected = _filterType == type;
    final Color? accentColor =
        type != null ? MediaTypeTheme.colorFor(type) : null;

    return ChoiceChip(
      label: Text(
        label,
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
        setState(() => _filterType = value ? type : null);
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

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(allItemsNotifierProvider.notifier).refresh(),
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
            subtitle: collectionNames[item.collectionId],
            status: item.status,
            onTap: () => _showItemDetails(item),
          );
        },
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

  void _showItemDetails(CollectionItem item) {
    // Определяем isEditable из коллекции
    final List<Collection>? collections =
        ref.read(collectionsProvider).valueOrNull;
    final Collection? collection = collections?.cast<Collection?>().firstWhere(
      (Collection? c) => c?.id == item.collectionId,
      orElse: () => null,
    );
    final bool isEditable = collection?.isEditable ?? false;

    switch (item.mediaType) {
      case MediaType.game:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) => GameDetailScreen(
              collectionId: item.collectionId,
              itemId: item.id,
              isEditable: isEditable,
            ),
          ),
        );
      case MediaType.movie:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) => MovieDetailScreen(
              collectionId: item.collectionId,
              itemId: item.id,
              isEditable: isEditable,
            ),
          ),
        );
      case MediaType.tvShow:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) => TvShowDetailScreen(
              collectionId: item.collectionId,
              itemId: item.id,
              isEditable: isEditable,
            ),
          ),
        );
      case MediaType.animation:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) => AnimeDetailScreen(
              collectionId: item.collectionId,
              itemId: item.id,
              isEditable: isEditable,
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
