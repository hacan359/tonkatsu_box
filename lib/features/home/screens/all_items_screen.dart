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
import '../../../shared/models/collection_tag.dart';
import '../../../shared/models/item_status.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/platform.dart';
import '../../../shared/navigation/search_providers.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/media_poster_card.dart';
import '../../collections/providers/collections_provider.dart';
import '../../collections/screens/item_detail_screen.dart';
import '../providers/all_items_provider.dart';

/// Экран всех элементов из всех коллекций.
///
/// Показывает grid-вид всех элементов. Фильтры: media type (segmented
/// control на всю ширину), status (pill), platforms (pill с multi-select,
/// появляется только при выборе Games).
class AllItemsScreen extends ConsumerStatefulWidget {
  /// Создаёт [AllItemsScreen].
  const AllItemsScreen({super.key});

  @override
  ConsumerState<AllItemsScreen> createState() => _AllItemsScreenState();
}

class _AllItemsScreenState extends ConsumerState<AllItemsScreen> {
  final Set<MediaType> _selectedTypes = <MediaType>{};
  final Set<int> _selectedPlatformIds = <int>{};

  /// Максимальная ширина карточки на десктопе.
  static const double _desktopMaxCardWidth = 150;

  /// Ширина, ниже которой сегменты показывают иконки вместо текста.
  static const double _compactBreakpoint = 700;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<CollectionItem>> itemsAsync =
        ref.watch(allItemsNotifierProvider);
    final Map<int, String> collectionNames =
        ref.watch(collectionNamesProvider);
    final Map<int, CollectionTag> tagsMap =
        ref.watch(allTagsMapProvider).valueOrNull ?? <int, CollectionTag>{};
    final ItemStatus? filterStatus = ref.watch(homeStatusFilterProvider);
    final String searchQuery = ref.watch(homeSearchQueryProvider);

    return Column(
      children: <Widget>[
        _buildMediaTypeBar(itemsAsync, filterStatus),
        _buildPlatformsRow(),
        Expanded(
          child: itemsAsync.when(
            data: (List<CollectionItem> items) {
              final List<CollectionItem> filtered =
                  _applyFilter(items, filterStatus, tagsMap, searchQuery);
              if (filtered.isEmpty) {
                return _buildEmptyState(items.isEmpty);
              }
              return _buildGridView(filtered, collectionNames, tagsMap);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (Object error, StackTrace stack) =>
                _buildErrorState(error),
          ),
        ),
      ],
    );
  }

  List<CollectionItem> _applyFilter(
    List<CollectionItem> items,
    ItemStatus? filterStatus,
    Map<int, CollectionTag> tagsMap,
    String searchQuery,
  ) {
    List<CollectionItem> result = items;
    if (_selectedTypes.isNotEmpty) {
      result = result
          .where((CollectionItem item) => _selectedTypes.contains(item.mediaType))
          .toList();
    }
    if (filterStatus != null) {
      result = result
          .where((CollectionItem item) => item.status == filterStatus)
          .toList();
    }
    if (_selectedPlatformIds.isNotEmpty) {
      result = result
          .where(
            (CollectionItem item) =>
                item.platformId != null &&
                _selectedPlatformIds.contains(item.platformId),
          )
          .toList();
    }
    if (searchQuery.isNotEmpty) {
      final String query = searchQuery.toLowerCase();
      result = result
          .where(
            (CollectionItem item) =>
                item.itemName.toLowerCase().contains(query) ||
                (item.tagId != null &&
                    (tagsMap[item.tagId]?.name.toLowerCase().contains(query) ??
                        false)),
          )
          .toList();
    }
    return result;
  }

  // ==================== Filter UI ====================

  /// Chevron-бар: типы медиа (multi-select) + dropdown статуса (последний
  /// сегмент).
  ///
  /// В compact-режиме (< [_compactBreakpoint]) показывает иконки вместо текста.
  Widget _buildMediaTypeBar(
    AsyncValue<List<CollectionItem>> itemsAsync,
    ItemStatus? filterStatus,
  ) {
    final List<CollectionItem>? items = itemsAsync.valueOrNull;
    final Map<MediaType, int> counts = _countByMediaType(items);
    final S l = S.of(context);

    final List<_MediaTypeEntry> entries = <_MediaTypeEntry>[
      _MediaTypeEntry(
        type: MediaType.game,
        label: l.allItemsGames,
        count: counts[MediaType.game] ?? 0,
      ),
      _MediaTypeEntry(
        type: MediaType.movie,
        label: l.allItemsMovies,
        count: counts[MediaType.movie] ?? 0,
      ),
      _MediaTypeEntry(
        type: MediaType.tvShow,
        label: l.allItemsTvShows,
        count: counts[MediaType.tvShow] ?? 0,
      ),
      _MediaTypeEntry(
        type: MediaType.animation,
        label: l.allItemsAnimation,
        count: counts[MediaType.animation] ?? 0,
      ),
      _MediaTypeEntry(
        type: MediaType.visualNovel,
        label: l.allItemsVisualNovels,
        count: counts[MediaType.visualNovel] ?? 0,
      ),
      _MediaTypeEntry(
        type: MediaType.manga,
        label: l.allItemsManga,
        count: counts[MediaType.manga] ?? 0,
      ),
      _MediaTypeEntry(
        type: MediaType.anime,
        label: l.mediaTypeAnime,
        count: counts[MediaType.anime] ?? 0,
      ),
      _MediaTypeEntry(
        type: MediaType.custom,
        label: l.allItemsCustom,
        count: counts[MediaType.custom] ?? 0,
      ),
    ];

    final bool compact =
        MediaQuery.sizeOf(context).width < _compactBreakpoint;

    return ColoredBox(
      color: AppColors.surface,
      child: SizedBox(
        height: 40,
        child: Row(
          children: <Widget>[
            for (int i = 0; i < entries.length; i++)
              Expanded(
                child: _ChevronSegment(
                  label: entries[i].displayLabel,
                  icon: MediaTypeTheme.iconFor(entries[i].type),
                  selected: _selectedTypes.contains(entries[i].type),
                  accentColor: MediaTypeTheme.colorFor(entries[i].type),
                  isFirst: i == 0,
                  isLast: false,
                  onTap: () => _toggleMediaType(entries[i].type),
                  compact: compact,
                ),
              ),
            Expanded(
              child: _StatusDropdownSegment(
                status: filterStatus,
                compact: compact,
                onChanged: (ItemStatus? s) =>
                    ref.read(homeStatusFilterProvider.notifier).setFilter(s),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Полоска ChoiceChip платформ — видна только при выбранном Games.
  ///
  /// Горизонтальный скролл. Стиль как в main, но с цветом семейства.
  Widget _buildPlatformsRow() {
    if (!_selectedTypes.contains(MediaType.game)) {
      return const SizedBox.shrink();
    }
    final AsyncValue<List<Platform>> platformsAsync =
        ref.watch(allItemsPlatformsProvider);
    final List<Platform> platforms =
        platformsAsync.valueOrNull ?? <Platform>[];
    if (platforms.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            for (final Platform p in platforms) ...<Widget>[
              _buildPlatformChip(p),
              const SizedBox(width: AppSpacing.xs),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformChip(Platform platform) {
    final bool selected = _selectedPlatformIds.contains(platform.id);
    const Color accentColor = AppColors.brand;

    return ChoiceChip(
      label: Text(
        platform.displayName,
        style: AppTypography.caption.copyWith(
          color: selected ? AppColors.background : AppColors.textTertiary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: selected,
      selectedColor: accentColor,
      backgroundColor: AppColors.surface,
      side: BorderSide(
        color: selected ? Colors.transparent : accentColor.withAlpha(50),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      onSelected: (bool value) {
        setState(() {
          if (value) {
            _selectedPlatformIds.add(platform.id);
          } else {
            _selectedPlatformIds.remove(platform.id);
          }
        });
      },
    );
  }

  void _toggleMediaType(MediaType type) {
    setState(() {
      if (_selectedTypes.contains(type)) {
        _selectedTypes.remove(type);
      } else {
        _selectedTypes.add(type);
      }
      if (!_selectedTypes.contains(MediaType.game)) {
        _selectedPlatformIds.clear();
      }
    });
  }

  // ==================== Helpers ====================

  /// Считает количество элементов по типу медиа.
  static Map<MediaType, int> _countByMediaType(List<CollectionItem>? items) {
    if (items == null) return <MediaType, int>{};
    final Map<MediaType, int> counts = <MediaType, int>{};
    for (final CollectionItem item in items) {
      counts[item.mediaType] = (counts[item.mediaType] ?? 0) + 1;
    }
    return counts;
  }

  // ==================== Grid ====================

  Widget _buildGridView(
    List<CollectionItem> items,
    Map<int, String> collectionNames,
    Map<int, CollectionTag> tagsMap,
  ) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool isLandscape = isLandscapeMobile(context);
    final bool isDesktop = screenWidth >= kDesktopContentBreakpoint && !kIsMobile;

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

    final List<_CollectionGroup> groups =
        _groupByCollection(items, collectionNames, S.of(context).collectionsUncategorized);

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(allItemsNotifierProvider.notifier).refresh(),
      child: CustomScrollView(
        slivers: <Widget>[
          for (int i = 0; i < groups.length; i++) ...<Widget>[
            SliverToBoxAdapter(
              child: _buildCollectionDivider(
                groups[i].name,
                groups[i].items.length,
                isFirst: i == 0,
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: gridPadding,
              ),
              sliver: SliverGrid(
                gridDelegate: gridDelegate,
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    final CollectionItem item = groups[i].items[index];
                    final CollectionTag? tag = item.tagId != null
                        ? tagsMap[item.tagId]
                        : null;
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
                      tagName: tag?.name,
                      tagColor: tag?.color,
                      onTap: () =>
                          _showItemDetails(item, collectionNames),
                    );
                  },
                  childCount: groups[i].items.length,
                ),
              ),
            ),
            if (i < groups.length - 1)
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.sm),
              ),
          ],
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.md),
          ),
        ],
      ),
    );
  }

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
      case MediaType.anime:
        return item.anime?.releaseYear;
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
      case MediaType.anime:
        return ImageType.animeCover;
      case MediaType.custom:
        return ImageType.customCover;
    }
  }
}

// ==================== Сегменты media type ====================

class _MediaTypeEntry {
  const _MediaTypeEntry({
    required this.type,
    required this.label,
    required this.count,
  });

  final MediaType type;
  final String label;
  final int count;

  String get displayLabel => count > 0 ? '$label ($count)' : label;
}

/// Универсальный chevron-сегмент для filter-баров.
///
/// V-вырез слева (кроме первого) и V-конец справа (кроме последнего).
/// В режиме [compact] показывает [Tooltip] + иконку вместо текста.
class _ChevronSegment extends StatelessWidget {
  const _ChevronSegment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.accentColor,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color accentColor;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;
  final bool compact;

  static const double _chevronWidth = 6;

  @override
  Widget build(BuildContext context) {
    final Color bg = selected ? accentColor : AppColors.surface;
    final Color contentColor =
        selected ? AppColors.background : AppColors.textSecondary;

    return ClipPath(
      clipper: _ChevronClipper(
        chevronWidth: _chevronWidth,
        hasLeftNotch: !isFirst,
        hasRightPoint: !isLast,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        color: bg,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.only(
                left: isFirst ? 4 : _chevronWidth + 1,
                right: isLast ? 4 : _chevronWidth + 1,
              ),
              child: Center(
                child: compact
                    ? Tooltip(
                        message: label,
                        child: Icon(icon, size: 18, color: contentColor),
                      )
                    : Text(
                        label,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: AppTypography.bodySmall.copyWith(
                          color: contentColor,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// CustomClipper, вырезающий из прямоугольника форму стрелочки.
class _ChevronClipper extends CustomClipper<Path> {
  const _ChevronClipper({
    required this.chevronWidth,
    required this.hasLeftNotch,
    required this.hasRightPoint,
  });

  final double chevronWidth;
  final bool hasLeftNotch;
  final bool hasRightPoint;

  @override
  Path getClip(Size size) {
    final Path path = Path();
    final double mid = size.height / 2;

    // Левая грань: либо V-вырез внутрь, либо прямой край.
    if (hasLeftNotch) {
      path.moveTo(0, 0);
      path.lineTo(chevronWidth, mid);
      path.lineTo(0, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
    }

    // Правая грань: либо остриё вправо, либо прямой край.
    if (hasRightPoint) {
      path.lineTo(size.width - chevronWidth, size.height);
      path.lineTo(size.width, mid);
      path.lineTo(size.width - chevronWidth, 0);
    } else {
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0);
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _ChevronClipper old) {
    return chevronWidth != old.chevronWidth ||
        hasLeftNotch != old.hasLeftNotch ||
        hasRightPoint != old.hasRightPoint;
  }
}

// ==================== Status dropdown сегмент ====================

/// Chevron-сегмент в виде dropdown для выбора статуса.
///
/// Визуально идентичен [_ChevronSegment] (всегда `isLast: true`), но при
/// нажатии открывает [PopupMenuButton] со списком статусов. Каждый пункт
/// подсвечивается цветом соответствующего статуса.
class _StatusDropdownSegment extends StatelessWidget {
  const _StatusDropdownSegment({
    required this.status,
    required this.compact,
    required this.onChanged,
  });

  final ItemStatus? status;
  final bool compact;
  final ValueChanged<ItemStatus?> onChanged;

  static const double _chevronWidth = 6;

  static const List<ItemStatus> _order = <ItemStatus>[
    ItemStatus.inProgress,
    ItemStatus.planned,
    ItemStatus.notStarted,
    ItemStatus.completed,
    ItemStatus.dropped,
  ];

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final bool active = status != null;
    final Color accentColor = active ? status!.color : AppColors.surface;
    final Color contentColor =
        active ? AppColors.background : AppColors.textSecondary;
    final String label = active ? status!.genericLabel(l) : l.homeFilterAll;
    final IconData icon = active ? status!.materialIcon : Icons.filter_list;

    return PopupMenuButton<String>(
      onSelected: (String v) {
        onChanged(v == 'all' ? null : ItemStatus.fromString(v));
      },
      offset: const Offset(0, 40),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      itemBuilder: (BuildContext ctx) => <PopupMenuEntry<String>>[
        _menuItem('all', Icons.filter_list_off, l.homeFilterAll,
            status == null, null),
        const PopupMenuDivider(height: 8),
        for (final ItemStatus s in _order)
          _menuItem(s.value, s.materialIcon, s.genericLabel(l),
              status == s, s.color),
      ],
      child: ClipPath(
        clipper: const _ChevronClipper(
          chevronWidth: _chevronWidth,
          hasLeftNotch: true,
          hasRightPoint: false,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          color: accentColor,
          child: Padding(
            padding: const EdgeInsets.only(
              left: _chevronWidth + 1,
              right: 4,
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (compact)
                      Tooltip(
                        message: label,
                        child: Icon(icon, size: 18, color: contentColor),
                      )
                    else
                      Text(
                        label,
                        maxLines: 1,
                        style: AppTypography.bodySmall.copyWith(
                          color: contentColor,
                          fontWeight:
                              active ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 14,
                      color: contentColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static PopupMenuItem<String> _menuItem(
    String value,
    IconData icon,
    String label,
    bool selected,
    Color? statusColor,
  ) {
    final Color itemColor = selected
        ? (statusColor ?? AppColors.brand)
        : AppColors.textPrimary;
    final Color iconColor = selected
        ? (statusColor ?? AppColors.brand)
        : AppColors.textTertiary;

    return PopupMenuItem<String>(
      value: value,
      height: 36,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTypography.body.copyWith(
              color: itemColor,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}


/// Группа элементов одной коллекции для отображения секции.
class _CollectionGroup {
  _CollectionGroup({required this.name, required this.items});
  final String name;
  final List<CollectionItem> items;
}
