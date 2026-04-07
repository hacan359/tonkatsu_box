// Экран всех элементов из всех коллекций (Home tab).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/image_cache_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/media_type_theme.dart';
import '../../settings/providers/settings_provider.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/item_status.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/platform.dart';
import '../../../shared/navigation/navigation_shell.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/media_poster_card.dart';
import '../../../shared/widgets/screen_app_bar.dart';
import '../../../shared/widgets/type_to_filter_overlay.dart';
import '../../collections/providers/collections_provider.dart';
import '../../collections/screens/item_detail_screen.dart';
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
  String _typeToFilterQuery = '';
  /// Максимальная ширина карточки на десктопе.
  static const double _desktopMaxCardWidth = 150;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<CollectionItem>> itemsAsync =
        ref.watch(allItemsNotifierProvider);
    final Map<int, String> collectionNames =
        ref.watch(collectionNamesProvider);
    final ItemStatus? filterStatus = ref.watch(homeStatusFilterProvider);

    return Scaffold(
      appBar: ScreenAppBar(title: S.of(context).navMain),
      body: TypeToFilterOverlay(
        onFilterChanged: (String query) {
          setState(() => _typeToFilterQuery = query);
        },
        child: Column(
          children: <Widget>[
            _buildChipsRow(itemsAsync, filterStatus),
            if (_filterType == MediaType.game) _buildPlatformChipsRow(),
            Expanded(
              child: itemsAsync.when(
                data: (List<CollectionItem> items) {
                  final List<CollectionItem> filtered =
                      _applyFilter(items, filterStatus);
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
      ),
    );
  }

  List<CollectionItem> _applyFilter(
    List<CollectionItem> items,
    ItemStatus? filterStatus,
  ) {
    List<CollectionItem> result = items;
    if (_filterType != null) {
      result = result
          .where((CollectionItem item) => item.mediaType == _filterType)
          .toList();
    }
    if (filterStatus != null) {
      result = result
          .where((CollectionItem item) => item.status == filterStatus)
          .toList();
    }
    if (_filterPlatformId != null) {
      result = result
          .where((CollectionItem item) => item.platformId == _filterPlatformId)
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

  Widget _buildChipsRow(
    AsyncValue<List<CollectionItem>> itemsAsync,
    ItemStatus? filterStatus,
  ) {
    final List<CollectionItem>? items = itemsAsync.valueOrNull;
    final Map<MediaType, int> counts = _countByMediaType(items);
    final int total = items?.length ?? 0;
    final S l = S.of(context);

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
            _buildMediaChip(null, l.allItemsAll, total),
            const SizedBox(width: AppSpacing.xs),
            _buildMediaChip(MediaType.game, l.allItemsGames, counts[MediaType.game]),
            const SizedBox(width: AppSpacing.xs),
            _buildMediaChip(MediaType.movie, l.allItemsMovies, counts[MediaType.movie]),
            const SizedBox(width: AppSpacing.xs),
            _buildMediaChip(MediaType.tvShow, l.allItemsTvShows, counts[MediaType.tvShow]),
            const SizedBox(width: AppSpacing.xs),
            _buildMediaChip(MediaType.animation, l.allItemsAnimation, counts[MediaType.animation]),
            const SizedBox(width: AppSpacing.xs),
            _buildMediaChip(MediaType.visualNovel, l.allItemsVisualNovels, counts[MediaType.visualNovel]),
            const SizedBox(width: AppSpacing.xs),
            _buildMediaChip(MediaType.manga, l.allItemsManga, counts[MediaType.manga]),
            _buildMediaChip(MediaType.custom, l.allItemsCustom, counts[MediaType.custom]),

            const SizedBox(width: AppSpacing.md),

            // Status filter dropdown chip
            _buildStatusDropdownChip(l, filterStatus),
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

  Widget _buildStatusDropdownChip(S l, ItemStatus? filterStatus) {
    final bool isActive = filterStatus != null;
    final Color chipColor =
        isActive ? filterStatus.color : AppColors.textSecondary;
    final String label = isActive
        ? _statusLabel(filterStatus, l)
        : l.homeFilterAll;

    return PopupMenuButton<String>(
      onSelected: (String value) {
        final ItemStatus? status =
            value == 'all' ? null : ItemStatus.fromString(value);
        ref.read(homeStatusFilterProvider.notifier).setFilter(status);
      },
      offset: const Offset(0, 36),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      color: AppColors.surface,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        // "All" option
        PopupMenuItem<String>(
          value: 'all',
          height: 36,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.filter_list_off,
                size: 16,
                color: filterStatus == null
                    ? AppColors.brand
                    : AppColors.textTertiary,
              ),
              const SizedBox(width: 8),
              Text(
                l.homeFilterAll,
                style: AppTypography.body.copyWith(
                  color: filterStatus == null
                      ? AppColors.brand
                      : AppColors.textPrimary,
                  fontWeight: filterStatus == null
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 8),
        // Status options
        for (final ItemStatus status in _statusOrder)
          PopupMenuItem<String>(
            value: status.value,
            height: 36,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  status.materialIcon,
                  size: 16,
                  color: filterStatus == status
                      ? status.color
                      : AppColors.textTertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  _statusLabel(status, l),
                  style: AppTypography.body.copyWith(
                    color: filterStatus == status
                        ? status.color
                        : AppColors.textPrimary,
                    fontWeight: filterStatus == status
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
      ],
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isActive ? chipColor.withAlpha(25) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? chipColor.withAlpha(80) : AppColors.surfaceBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              isActive ? filterStatus.materialIcon : Icons.filter_list,
              size: 14,
              color: isActive ? chipColor : AppColors.textTertiary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: isActive ? chipColor : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down,
              size: 14,
              color: isActive ? chipColor : AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  /// Порядок статусов в chips.
  static const List<ItemStatus> _statusOrder = <ItemStatus>[
    ItemStatus.inProgress,
    ItemStatus.planned,
    ItemStatus.notStarted,
    ItemStatus.completed,
    ItemStatus.dropped,
  ];

  /// Универсальная метка статуса (не привязана к MediaType).
  static String _statusLabel(ItemStatus status, S l) {
    return switch (status) {
      ItemStatus.notStarted => l.statusNotStarted,
      ItemStatus.inProgress => l.statusInProgress,
      ItemStatus.completed => l.statusCompleted,
      ItemStatus.dropped => l.statusDropped,
      ItemStatus.planned => l.statusPlanned,
    };
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

  Widget _buildGridView(
    List<CollectionItem> items,
    Map<int, String> collectionNames,
  ) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool isLandscape = isLandscapeMobile(context);
    final bool isDesktop = screenWidth >= navigationBreakpoint && !kIsMobile;

    final double gridPadding = isLandscape ? AppSpacing.sm : AppSpacing.screenPadding;
    final double crossSpacing = isLandscape ? AppSpacing.sm : AppSpacing.gridGap;
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
        _groupByCollection(items, collectionNames, S.of(context).collectionsUncategorized);

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
                      variant: isLandscape ||
                              isCompactScreen(context)
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
                      platformColor: item.platform?.familyColor,
                      platformOverlayAsset:
                          ref.watch(settingsNotifierProvider).resolveOverlay(
                            platformOverlay: item.platform?.overlayAsset,
                            mediaTypeOverlay: item.mediaType.overlayAsset,
                          ),
                      mediaType: item.mediaType,
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
    String uncategorizedLabel,
  ) {
    final Map<int?, _CollectionGroup> map = <int?, _CollectionGroup>{};
    final List<int?> order = <int?>[];
    for (final CollectionItem item in items) {
      final int? colId = item.collectionId;
      if (!map.containsKey(colId)) {
        final String name = colId != null
            ? (collectionNames[colId] ?? 'Unknown')
            : uncategorizedLabel;
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
            color: AppColors.textTertiary.withAlpha(120),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            noItemsAtAll
                ? S.of(context).allItemsNoItems
                : S.of(context).allItemsNoMatch,
            style: AppTypography.h2.copyWith(color: AppColors.textTertiary),
          ),
          if (noItemsAtAll) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(
              S.of(context).allItemsAddViaCollections,
              textAlign: TextAlign.center,
              style: AppTypography.body
                  .copyWith(color: AppColors.textSecondary),
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
            S.of(context).allItemsFailedToLoad,
            style: AppTypography.h2.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: () =>
                ref.read(allItemsNotifierProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
            label: Text(S.of(context).retry),
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
    if (item.isUncategorized) {
      isEditable = true;
    } else {
      final List<Collection>? collections =
          ref.read(collectionsProvider).valueOrNull;
      final Collection? collection =
          collections?.cast<Collection?>().firstWhere(
        (Collection? c) => c?.id == item.collectionId,
        orElse: () => null,
      );
      isEditable = collection?.isEditable ?? false;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ItemDetailScreen(
          collectionId: item.collectionId,
          itemId: item.id,
          isEditable: isEditable,
        ),
      ),
    );
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
      case MediaType.visualNovel:
        return item.visualNovel?.releaseYear;
      case MediaType.manga:
        return item.manga?.releaseYear;
      case MediaType.custom:
        return item.customMedia?.year;
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
      case MediaType.visualNovel:
        return ImageType.vnCover;
      case MediaType.manga:
        return ImageType.mangaCover;
      case MediaType.custom:
        return ImageType.customCover;
    }
  }
}

/// Группа элементов одной коллекции для отображения секции.
class _CollectionGroup {
  _CollectionGroup({required this.name, required this.items});
  final String name;
  final List<CollectionItem> items;
}
