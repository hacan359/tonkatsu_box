import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/image_cache_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/media_type_theme.dart';
import '../../settings/providers/settings_provider.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/tag.dart';
import '../../../shared/models/item_status.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/platform.dart';
import '../../../shared/navigation/search_providers.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/utils/item_card_progress.dart';
import '../../../shared/utils/media_format.dart';
import '../../../shared/widgets/chevron_filter_bar.dart';
import '../../../shared/widgets/filter_subfilter_bar.dart';
import '../../../shared/widgets/logo_loader.dart';
import '../../../shared/widgets/media_poster_card.dart';
import '../../../shared/widgets/uncategorized_deprecation_banner.dart';
import '../../collections/helpers/collection_actions.dart';
import '../../collections/helpers/tracker_card_progress.dart';
import '../../collections/providers/all_items_selection_provider.dart';
import '../../collections/providers/collections_provider.dart';
import '../../collections/extensions/item_display_name.dart';
import '../../collections/screens/item_detail_screen.dart';
import '../../collections/widgets/bulk_action_bar.dart';
import '../../collections/widgets/selectable_poster_card.dart';
import '../../collections/widgets/context_menu_item.dart';
import '../../collections/widgets/status_chip_row.dart';
import '../providers/all_items_provider.dart';
import '../../collections/providers/item_tags_provider.dart';
import '../../../shared/constants/platform_ui.dart';

/// Grid of all items across all collections (Home tab). The platforms
/// filter row appears only while Games is selected.
class AllItemsScreen extends ConsumerStatefulWidget {
  const AllItemsScreen({super.key});

  @override
  ConsumerState<AllItemsScreen> createState() => _AllItemsScreenState();
}

class _AllItemsScreenState extends ConsumerState<AllItemsScreen> {
  final Set<MediaType> _selectedTypes = <MediaType>{};
  final Set<int> _selectedPlatformIds = <int>{};
  final Set<String> _selectedMangaFormats = <String>{};
  final Set<String> _selectedAnimeFormats = <String>{};

  /// Below this width the segments show icons instead of text.
  static const double _compactBreakpoint = 700;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<CollectionItem>> itemsAsync =
        ref.watch(allItemsNotifierProvider);
    final Map<int, String> collectionNames =
        ref.watch(collectionNamesProvider);
    final Map<int, Tag> tagsMap = ref.watch(allTagsMapProvider);
    final Map<int, List<int>> itemTags =
        ref.watch(itemTagsProvider).valueOrNull ?? <int, List<int>>{};
    final ItemStatus? filterStatus = ref.watch(homeStatusFilterProvider);
    final bool favoriteOnly = ref.watch(homeFavoriteFilterProvider);
    final String searchQuery = ref.watch(homeSearchQueryProvider);

    final Set<int> selection = ref.watch(allItemsSelectionProvider);
    final List<CollectionItem> allItems =
        itemsAsync.valueOrNull ?? const <CollectionItem>[];
    final List<CollectionItem> visibleItems =
        _applyFilter(allItems, filterStatus, favoriteOnly, tagsMap, searchQuery);
    final List<CollectionItem> selectedItems = selection.isEmpty
        ? const <CollectionItem>[]
        : <CollectionItem>[
            for (final CollectionItem i in allItems)
              if (selection.contains(i.id)) i,
          ];

    return Column(
      children: <Widget>[
        _buildMediaTypeBar(
            itemsAsync, filterStatus, favoriteOnly, tagsMap, searchQuery),
        SubfilterBar(groups: _subfilterGroups(itemsAsync)),
        if (selectedItems.isNotEmpty)
          BulkActionBar(
            items: selectedItems,
            visibleCount: visibleItems.length,
            onSelectAllVisible: () => ref
                .read(allItemsSelectionProvider.notifier)
                .selectAll(visibleItems.map((CollectionItem i) => i.id)),
            onClearSelection: () => ref
                .read(allItemsSelectionProvider.notifier)
                .clear(),
          ),
        Expanded(
          child: itemsAsync.when(
            data: (List<CollectionItem> items) {
              if (visibleItems.isEmpty) {
                return _buildEmptyState(items.isEmpty);
              }
              return _buildGridView(
                  visibleItems, collectionNames, tagsMap, itemTags);
            },
            loading: () => const Center(child: LogoLoader()),
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
    bool favoriteOnly,
    Map<int, Tag> tagsMap,
    String searchQuery,
  ) {
    final String query = searchQuery.toLowerCase();
    final String lang =
        ref.read(sharedPreferencesProvider).animeMangaTitleLanguage;
    return items
        .where((CollectionItem item) =>
            (_selectedTypes.isEmpty ||
                item.matchesTypeFilter(_selectedTypes)) &&
            _matchesNonTypeFilters(
                item, filterStatus, favoriteOnly, tagsMap, query, lang))
        .toList();
  }

  bool _matchesNonTypeFilters(
    CollectionItem item,
    ItemStatus? filterStatus,
    bool favoriteOnly,
    Map<int, Tag> tagsMap,
    String lowerQuery,
    String animeMangaTitleLanguage,
  ) {
    if (favoriteOnly && !item.isFavorite) return false;
    if (filterStatus != null && item.status != filterStatus) return false;
    if (!MediaFormat.matchesSubfilters(
      item,
      platformIds: _selectedPlatformIds,
      mangaFormats: _selectedMangaFormats,
      animeFormats: _selectedAnimeFormats,
    )) {
      return false;
    }
    if (lowerQuery.isNotEmpty) {
      final bool match = item
              .displayName(animeMangaTitleLanguage)
              .toLowerCase()
              .contains(lowerQuery) ||
          _matchesTagName(item, tagsMap, lowerQuery) ||
          (item.userComment?.toLowerCase().contains(lowerQuery) ?? false) ||
          (item.authorComment?.toLowerCase().contains(lowerQuery) ?? false);
      if (!match) return false;
    }
    return true;
  }

  /// Chevron bar: media types (multi-select) plus the status dropdown as
  /// the last segment.
  Widget _buildMediaTypeBar(
    AsyncValue<List<CollectionItem>> itemsAsync,
    ItemStatus? filterStatus,
    bool favoriteOnly,
    Map<int, Tag> tagsMap,
    String searchQuery,
  ) {
    final List<CollectionItem>? items = itemsAsync.valueOrNull;
    final Map<MediaType, int> counts =
        _countByMediaType(items, filterStatus, favoriteOnly, tagsMap, searchQuery);
    final Map<MediaType, int> totals = _rawTotalsByMediaType(items);
    final S l = S.of(context);

    final List<_MediaTypeEntry> entries = <_MediaTypeEntry>[
      _MediaTypeEntry(
        type: MediaType.game,
        label: l.collectionFilterGames,
        count: counts[MediaType.game] ?? 0,
      ),
      _MediaTypeEntry(
        type: MediaType.movie,
        label: l.collectionFilterMovies,
        count: counts[MediaType.movie] ?? 0,
      ),
      _MediaTypeEntry(
        type: MediaType.tvShow,
        label: l.collectionFilterTvShows,
        count: counts[MediaType.tvShow] ?? 0,
      ),
      _MediaTypeEntry(
        type: MediaType.animation,
        label: l.mediaTypeAnimation,
        count: counts[MediaType.animation] ?? 0,
      ),
      _MediaTypeEntry(
        type: MediaType.visualNovel,
        label: l.collectionFilterVisualNovels,
        count: counts[MediaType.visualNovel] ?? 0,
      ),
      _MediaTypeEntry(
        type: MediaType.manga,
        label: l.mediaTypeManga,
        count: counts[MediaType.manga] ?? 0,
      ),
      _MediaTypeEntry(
        type: MediaType.anime,
        label: l.mediaTypeAnime,
        count: counts[MediaType.anime] ?? 0,
      ),
      _MediaTypeEntry(
        type: MediaType.book,
        label: l.collectionFilterBooks,
        count: counts[MediaType.book] ?? 0,
      ),
      _MediaTypeEntry(
        type: MediaType.custom,
        label: l.mediaTypeCustom,
        count: counts[MediaType.custom] ?? 0,
      ),
    ];

    final bool compact =
        MediaQuery.sizeOf(context).width < _compactBreakpoint;
    final bool hideEmpty = ref.watch(
      settingsNotifierProvider.select(
        (SettingsState s) => s.hideEmptyMediaTypeChevrons,
      ),
    );
    final List<_MediaTypeEntry> visibleEntries =
        (hideEmpty && items != null)
            ? entries
                .where((_MediaTypeEntry e) =>
                    (totals[e.type] ?? 0) > 0 ||
                    _selectedTypes.contains(e.type))
                .toList()
            : entries;

    return ColoredBox(
      color: AppColors.surface,
      child: SizedBox(
        height: 40,
        child: Row(
          children: <Widget>[
            for (int i = 0; i < visibleEntries.length; i++)
              Expanded(
                child: ChevronSegment(
                  label: visibleEntries[i].displayLabel,
                  icon: MediaTypeTheme.iconFor(visibleEntries[i].type),
                  selected: _selectedTypes.contains(visibleEntries[i].type),
                  accentColor:
                      MediaTypeTheme.colorFor(visibleEntries[i].type),
                  isFirst: i == 0,
                  isLast: false,
                  onTap: () => _toggleMediaType(visibleEntries[i].type),
                  compact: compact,
                  tintWhenInactive: true,
                ),
              ),
            Expanded(
              child: StatusDropdownSegment(
                status: filterStatus,
                compact: compact,
                subtitle: l.status,
                isLast: false,
                onChanged: (ItemStatus? s) =>
                    ref.read(homeStatusFilterProvider.notifier).setFilter(s),
              ),
            ),
            Expanded(
              child: ChevronSegment(
                label: l.favorite,
                icon: Icons.favorite,
                selected: favoriteOnly,
                accentColor: AppColors.favorite,
                isFirst: false,
                isLast: true,
                onTap: () =>
                    ref.read(homeFavoriteFilterProvider.notifier).toggle(),
                compact: compact,
                tintWhenInactive: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// One subfilter group per active type — game platforms, manga formats,
  /// anime formats — each tinted with its media-type accent, on one row.
  ///
  /// A group normally appears only once its media-type chevron is selected;
  /// with the "always show subcategories" setting every group whose type has
  /// items is shown upfront.
  List<List<SubfilterChipData>> _subfilterGroups(
    AsyncValue<List<CollectionItem>> itemsAsync,
  ) {
    final List<CollectionItem> items =
        itemsAsync.valueOrNull ?? const <CollectionItem>[];
    final bool alwaysShow = ref.watch(
      settingsNotifierProvider.select(
        (SettingsState s) => s.alwaysShowSubcategories,
      ),
    );
    return <List<SubfilterChipData>>[
      if (alwaysShow || _selectedTypes.contains(MediaType.game))
        <SubfilterChipData>[
          for (final Platform p
              in ref.watch(allItemsPlatformsProvider).valueOrNull ??
                  const <Platform>[])
            SubfilterChipData(
              label: p.displayName,
              accent: MediaTypeTheme.colorFor(MediaType.game),
              selected: _selectedPlatformIds.contains(p.id),
              onTap: () => setState(() {
                if (_selectedPlatformIds.contains(p.id)) {
                  _selectedPlatformIds.remove(p.id);
                } else {
                  _selectedPlatformIds.add(p.id);
                }
              }),
            ),
        ],
      _formatGroup(MediaType.manga, _selectedMangaFormats, items,
          alwaysShow: alwaysShow),
      _formatGroup(MediaType.anime, _selectedAnimeFormats, items,
          alwaysShow: alwaysShow),
    ];
  }

  List<SubfilterChipData> _formatGroup(
    MediaType type,
    Set<String> selected,
    List<CollectionItem> items, {
    required bool alwaysShow,
  }) {
    if (!alwaysShow && !_selectedTypes.contains(type)) {
      return const <SubfilterChipData>[];
    }
    return <SubfilterChipData>[
      for (final String code in MediaFormat.present(items, type))
        SubfilterChipData(
          label: MediaFormat.label(type, code),
          accent: MediaTypeTheme.colorFor(type),
          selected: selected.contains(code),
          onTap: () => setState(() {
            if (selected.contains(code)) {
              selected.remove(code);
            } else {
              selected.add(code);
            }
          }),
        ),
    ];
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
      if (!_selectedTypes.contains(MediaType.manga)) {
        _selectedMangaFormats.clear();
      }
      if (!_selectedTypes.contains(MediaType.anime)) {
        _selectedAnimeFormats.clear();
      }
    });
  }

  /// Raw item count per media type, ignoring every filter. Drives chevron
  /// visibility — search hits should change the chevron label, not make
  /// non-matching media types disappear when "Hide empty" is on.
  static Map<MediaType, int> _rawTotalsByMediaType(
    List<CollectionItem>? items,
  ) {
    if (items == null) return const <MediaType, int>{};
    final Map<MediaType, int> totals = <MediaType, int>{};
    for (final CollectionItem item in items) {
      for (final MediaType bucket in item.filterTypeBuckets) {
        totals[bucket] = (totals[bucket] ?? 0) + 1;
      }
    }
    return totals;
  }

  /// Counts items per media type after applying every active filter except
  /// the media-type one — so each chevron shows how many would be visible if
  /// the user picked it.
  /// True when any of the item's tags matches the search query.
  bool _matchesTagName(
    CollectionItem item,
    Map<int, Tag> tagsMap,
    String lowerQuery,
  ) {
    final List<int>? ids = ref.read(itemTagsProvider).valueOrNull?[item.id];
    if (ids == null) return false;
    return ids.any((int id) =>
        tagsMap[id]?.name.toLowerCase().contains(lowerQuery) ?? false);
  }

  Map<MediaType, int> _countByMediaType(
    List<CollectionItem>? items,
    ItemStatus? filterStatus,
    bool favoriteOnly,
    Map<int, Tag> tagsMap,
    String searchQuery,
  ) {
    if (items == null) return <MediaType, int>{};
    final String lower = searchQuery.toLowerCase();
    final String lang =
        ref.read(sharedPreferencesProvider).animeMangaTitleLanguage;
    final Map<MediaType, int> counts = <MediaType, int>{};
    for (final CollectionItem item in items) {
      if (!_matchesNonTypeFilters(
          item, filterStatus, favoriteOnly, tagsMap, lower, lang)) {
        continue;
      }
      for (final MediaType bucket in item.filterTypeBuckets) {
        counts[bucket] = (counts[bucket] ?? 0) + 1;
      }
    }
    return counts;
  }

  Widget _buildGridView(
    List<CollectionItem> items,
    Map<int, String> collectionNames,
    Map<int, Tag> tagsMap,
    Map<int, List<int>> itemTags,
  ) {
    // getAll() returns display order, and the map preserves insertion order.
    final List<Tag> orderedTags = tagsMap.values.toList();
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool isLandscape = isLandscapeMobile(context);
    final bool isDesktop = screenWidth >= kDesktopContentBreakpoint && !kIsMobile;

    final double gridPadding = isLandscape ? AppSpacing.sm : AppSpacing.screenPadding;
    final double crossSpacing = isLandscape ? AppSpacing.sm : AppSpacing.gridGap;
    final double mainSpacing = isLandscape ? AppSpacing.sm : AppSpacing.lg;

    final double cardScale = ref.watch(
      settingsNotifierProvider.select((SettingsState s) => s.cardScale),
    );

    final SliverGridDelegate gridDelegate;
    if (isDesktop) {
      gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: AppSpacing.desktopMaxCardWidth * cardScale,
        crossAxisSpacing: crossSpacing,
        mainAxisSpacing: mainSpacing,
        childAspectRatio: AppSpacing.posterAspectRatio,
      );
    } else {
      final int baseCount;
      if (isLandscape) {
        baseCount = AppSpacing.gridColumnsDesktop;
      } else if (screenWidth >= 500) {
        baseCount = AppSpacing.gridColumnsTablet;
      } else {
        baseCount = AppSpacing.gridColumnsMobile;
      }
      gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: AppSpacing.scaledColumns(baseCount, cardScale),
        crossAxisSpacing: crossSpacing,
        mainAxisSpacing: mainSpacing,
        childAspectRatio: AppSpacing.posterAspectRatio,
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
                groups[i],
                isFirst: i == 0,
              ),
            ),
            if (groups[i].isUncategorized)
              const SliverToBoxAdapter(
                child: UncategorizedDeprecationBanner(),
              ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                gridPadding,
                AppSpacing.sm,
                gridPadding,
                0,
              ),
              sliver: SliverGrid(
                gridDelegate: gridDelegate,
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    final CollectionItem item = groups[i].items[index];
                    final List<int>? tagIds = itemTags[item.id];
                    final Tag? tag = orderedTags.primaryFor(tagIds);
                    final int tagCount = tagIds?.length ?? 0;
                    final Set<int> selection =
                        ref.watch(allItemsSelectionProvider);
                    final bool isSelected = selection.contains(item.id);
                    final ItemCardProgress? progress =
                        itemCardProgress(item) ?? trackerCardProgress(ref, item);
                    final MediaPosterCard card = MediaPosterCard(
                      key: ValueKey<int>(item.id),
                      variant: isLandscape ||
                              isCompactScreen(context)
                          ? CardVariant.compact
                          : CardVariant.grid,
                      title: ref.displayNameOf(item),
                      imageUrl: item.thumbnailUrl ?? '',
                      cacheImageType:
                          _imageTypeFor(item.mediaType, item.platformId),
                      cacheImageId: item.coverImageId,
                      userRating: item.userRating,
                      apiRating: item.apiRating,
                      splitRatings: true,
                      year: _yearFor(item),
                      platformLabel: item.platform?.displayName,
                      platformColor: item.platform?.familyColor,
                      platformOverlayAsset:
                          ref.watch(settingsNotifierProvider).resolveOverlay(
                            platformOverlay: item.platform?.overlayAsset,
                            mediaTypeOverlay: item.mediaType.overlayAsset,
                          ),
                      mediaType: item.displayMediaType,
                      typeLabelOverride: item.formatLabel,
                      status: item.status,
                      progress: progress,
                      isFavorite: item.isFavorite,
                      showFavorite: true,
                      enableHoverScale: !isSelected,
                      onToggleFavorite: selection.isEmpty
                          ? () => ref
                              .read(allItemsNotifierProvider.notifier)
                              .toggleFavorite(item.id)
                          : null,
                      tagName: tag?.name,
                      tagColor: tag?.color,
                      tagTextColor: tag?.textColor,
                      tagMoreCount: tagCount > 1 ? tagCount - 1 : 0,
                      onTap: selection.isEmpty
                          ? () => _showItemDetails(item, collectionNames)
                          : () => ref
                              .read(allItemsSelectionProvider.notifier)
                              .toggle(item.id),
                      onSecondaryTap: (Offset pos) =>
                          _showItemContextMenu(pos, item),
                      onLongPress: () => ref
                          .read(allItemsSelectionProvider.notifier)
                          .toggle(item.id),
                    );
                    return SelectablePosterCard(
                      key: ValueKey<int>(item.id),
                      isSelected: isSelected,
                      selectionActive: selection.isNotEmpty,
                      onToggleSelect: () => ref
                          .read(allItemsSelectionProvider.notifier)
                          .toggle(item.id),
                      child: card,
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
      final _CollectionGroup? existing = map[colId];
      if (existing == null) {
        final String name = colId != null
            ? (collectionNames[colId] ?? 'Unknown')
            : uncategorizedLabel;
        final _CollectionGroup group = _CollectionGroup(
          name: name,
          items: <CollectionItem>[item],
          isUncategorized: colId == null,
        );
        map[colId] = group;
        order.add(colId);
      } else {
        existing.items.add(item);
      }
    }
    return <_CollectionGroup>[
      for (final int? id in order)
        if (map[id] case final _CollectionGroup g) g,
    ];
  }

  /// Section header for a collection group: the collection name with a thick
  /// accent underline, its total count, then per-type tallies and a
  /// favourites count.
  Widget _buildCollectionDivider(
    _CollectionGroup group, {
    required bool isFirst,
  }) {
    final Color accent =
        group.isUncategorized ? AppColors.textTertiary : AppColors.brand;

    // Item count per media type, in enum order, for the per-type tallies.
    final Map<MediaType, int> typeCounts = <MediaType, int>{};
    for (final CollectionItem item in group.items) {
      final MediaType t = item.displayMediaType;
      typeCounts[t] = (typeCounts[t] ?? 0) + 1;
    }
    final Map<MediaType, int> orderedCounts = <MediaType, int>{
      for (final MediaType t in MediaType.values)
        if (typeCounts.containsKey(t)) t: typeCounts[t]!,
    };
    final int favorites =
        group.items.where((CollectionItem i) => i.isFavorite).length;

    // Wrap instead of Row: a long collection name plus up to 7 tallies
    // overflows a phone-width header, so the name ellipsizes and the tally
    // chips flow to the next line.
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        isFirst ? AppSpacing.sm : AppSpacing.lg,
        AppSpacing.md,
        0,
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: AppSpacing.xs,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Flexible(
                child: Container(
                  padding: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    border:
                        Border(bottom: BorderSide(color: accent, width: 3)),
                  ),
                  child: Text(
                    group.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        AppTypography.h2.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${group.items.length}',
                style: AppTypography.body.copyWith(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
          ),
          ..._headerInfo(orderedCounts, favorites),
        ],
      ),
    );
  }

  /// Shared info cluster: per-type icon with its item count, then a
  /// favourites tally. Each tally is one self-contained chip so it never
  /// splits when the header wraps.
  List<Widget> _headerInfo(Map<MediaType, int> typeCounts, int favorites) {
    const double iconSize = 20;

    Widget tally(IconData icon, Color color, String text, double size) {
      return Padding(
        padding: const EdgeInsets.only(left: AppSpacing.sm),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: size, color: color),
            const SizedBox(width: 3),
            Text(
              text,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return <Widget>[
      for (final MapEntry<MediaType, int> e in typeCounts.entries.take(6))
        tally(
          MediaTypeTheme.iconFor(e.key),
          MediaTypeTheme.colorFor(e.key).withAlpha(220),
          '${e.value}',
          iconSize,
        ),
      if (favorites > 0)
        tally(
          Icons.favorite,
          AppColors.favorite,
          '$favorites',
          iconSize - 2,
        ),
    ];
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

  bool _isItemEditable(CollectionItem item) {
    if (item.isUncategorized) return true;
    final List<Collection>? collections =
        ref.read(collectionsProvider).valueOrNull;
    final Collection? collection =
        collections?.cast<Collection?>().firstWhere(
      (Collection? c) => c?.id == item.collectionId,
      orElse: () => null,
    );
    return collection?.isEditable ?? false;
  }

  Future<void> _showItemContextMenu(Offset position, CollectionItem item) async {
    if (!_isItemEditable(item)) return;
    final S l = S.of(context);
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;

    final String? value = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      items: <PopupMenuEntry<String>>[
        contextMenuItem<String>(
          value: 'favorite',
          icon: item.isFavorite ? Icons.favorite : Icons.favorite_border,
          label: item.isFavorite ? l.removeFromFavorites : l.addToFavorites,
        ),
        const PopupMenuDivider(),
        contextMenuItem<String>(
          value: 'move',
          icon: Icons.drive_file_move_outlined,
          label: l.collectionMoveToCollection,
        ),
        contextMenuItem<String>(
          value: 'clone',
          icon: Icons.copy_outlined,
          label: l.collectionCopyToCollection,
        ),
        contextMenuItem<String>(
          value: 'copyLink',
          icon: Icons.link,
          label: l.cardLinkCopy,
        ),
        const PopupMenuDivider(),
        contextMenuItem<String>(
          value: 'remove',
          icon: Icons.remove_circle_outline,
          label: l.remove,
          color: AppColors.error,
        ),
        ...statusChipPopupMenuEntries(context: context, item: item),
      ],
    );

    if (value == null || !mounted) return;
    final ItemStatus? newStatus = tryDecodeStatusMenuValue(value);
    if (newStatus != null) {
      if (newStatus != item.status) {
        await ref
            .read(collectionItemsNotifierProvider(item.collectionId).notifier)
            .updateStatus(item.id, newStatus, item.mediaType);
      }
      return;
    }
    switch (value) {
      case 'favorite':
        await ref.read(allItemsNotifierProvider.notifier).toggleFavorite(item.id);
      case 'move':
        await CollectionActions.moveItem(
          context: context,
          ref: ref,
          collectionId: item.collectionId,
          item: item,
        );
      case 'clone':
        await CollectionActions.cloneItem(
          context: context,
          ref: ref,
          collectionId: item.collectionId,
          item: item,
        );
      case 'copyLink':
        if (mounted) CollectionActions.copyItemLink(context, item);
      case 'remove':
        await CollectionActions.removeItem(
          context: context,
          ref: ref,
          collectionId: item.collectionId,
          item: item,
        );
    }
  }

  void _showItemDetails(
    CollectionItem item,
    Map<int, String> collectionNames,
  ) {
    final bool isEditable = _isItemEditable(item);

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
      case MediaType.book:
        return item.book?.releaseYear;
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
      case MediaType.book:
        return ImageType.bookCover;
      case MediaType.custom:
        return ImageType.customCover;
    }
  }
}

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

class _CollectionGroup {
  _CollectionGroup({
    required this.name,
    required this.items,
    this.isUncategorized = false,
  });
  final String name;
  final List<CollectionItem> items;
  final bool isUncategorized;
}
