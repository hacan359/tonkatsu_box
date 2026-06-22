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
import '../../../shared/utils/media_format.dart';
import '../../../shared/widgets/chevron_filter_bar.dart';
import '../../../shared/widgets/filter_subfilter_bar.dart';
import '../../../shared/widgets/media_poster_card.dart';
import '../../collections/helpers/collection_actions.dart';
import '../../collections/providers/all_items_selection_provider.dart';
import '../../collections/providers/collections_provider.dart';
import '../../collections/extensions/item_display_name.dart';
import '../../collections/screens/item_detail_screen.dart';
import '../../collections/widgets/bulk_action_bar.dart';
import '../../collections/widgets/selectable_poster_card.dart';
import '../../collections/widgets/context_menu_item.dart';
import '../../collections/widgets/status_chip_row.dart';
import '../providers/all_items_provider.dart';

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

  static const double _desktopMaxCardWidth = 170;

  /// Below this width the segments show icons instead of text.
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

    final Set<int> selection = ref.watch(allItemsSelectionProvider);
    final List<CollectionItem> allItems =
        itemsAsync.valueOrNull ?? const <CollectionItem>[];
    final List<CollectionItem> visibleItems =
        _applyFilter(allItems, filterStatus, tagsMap, searchQuery);
    final List<CollectionItem> selectedItems = selection.isEmpty
        ? const <CollectionItem>[]
        : <CollectionItem>[
            for (final CollectionItem i in allItems)
              if (selection.contains(i.id)) i,
          ];

    return Column(
      children: <Widget>[
        _buildMediaTypeBar(itemsAsync, filterStatus, tagsMap, searchQuery),
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
              return _buildGridView(visibleItems, collectionNames, tagsMap);
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
    final String query = searchQuery.toLowerCase();
    final String lang =
        ref.read(sharedPreferencesProvider).animeMangaTitleLanguage;
    return items
        .where((CollectionItem item) =>
            (_selectedTypes.isEmpty ||
                _selectedTypes.contains(item.mediaType)) &&
            _matchesNonTypeFilters(item, filterStatus, tagsMap, query, lang))
        .toList();
  }

  bool _matchesNonTypeFilters(
    CollectionItem item,
    ItemStatus? filterStatus,
    Map<int, CollectionTag> tagsMap,
    String lowerQuery,
    String animeMangaTitleLanguage,
  ) {
    if (filterStatus != null && item.status != filterStatus) return false;
    if (_selectedPlatformIds.isNotEmpty &&
        (item.platformId == null ||
            !_selectedPlatformIds.contains(item.platformId))) {
      return false;
    }
    if (!MediaFormat.matchesFormatFilter(
      item,
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
          (item.tagId != null &&
              (tagsMap[item.tagId]?.name.toLowerCase().contains(lowerQuery) ??
                  false)) ||
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
    Map<int, CollectionTag> tagsMap,
    String searchQuery,
  ) {
    final List<CollectionItem>? items = itemsAsync.valueOrNull;
    final Map<MediaType, int> counts =
        _countByMediaType(items, filterStatus, tagsMap, searchQuery);
    final Map<MediaType, int> totals = _rawTotalsByMediaType(items);
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
        type: MediaType.book,
        label: l.allItemsBooks,
        count: counts[MediaType.book] ?? 0,
      ),
      _MediaTypeEntry(
        type: MediaType.custom,
        label: l.allItemsCustom,
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
                subtitle: l.detailStatus,
                onChanged: (ItemStatus? s) =>
                    ref.read(homeStatusFilterProvider.notifier).setFilter(s),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// One subfilter group per active type — game platforms, manga formats,
  /// anime formats — each tinted with its media-type accent, on one row.
  List<List<SubfilterChipData>> _subfilterGroups(
    AsyncValue<List<CollectionItem>> itemsAsync,
  ) {
    final List<CollectionItem> items =
        itemsAsync.valueOrNull ?? const <CollectionItem>[];
    return <List<SubfilterChipData>>[
      if (_selectedTypes.contains(MediaType.game))
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
      _formatGroup(MediaType.manga, _selectedMangaFormats, items),
      _formatGroup(MediaType.anime, _selectedAnimeFormats, items),
    ];
  }

  List<SubfilterChipData> _formatGroup(
    MediaType type,
    Set<String> selected,
    List<CollectionItem> items,
  ) {
    if (!_selectedTypes.contains(type)) return const <SubfilterChipData>[];
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
      totals[item.mediaType] = (totals[item.mediaType] ?? 0) + 1;
    }
    return totals;
  }

  /// Counts items per media type after applying every active filter except
  /// the media-type one — so each chevron shows how many would be visible if
  /// the user picked it.
  Map<MediaType, int> _countByMediaType(
    List<CollectionItem>? items,
    ItemStatus? filterStatus,
    Map<int, CollectionTag> tagsMap,
    String searchQuery,
  ) {
    if (items == null) return <MediaType, int>{};
    final String lower = searchQuery.toLowerCase();
    final String lang =
        ref.read(sharedPreferencesProvider).animeMangaTitleLanguage;
    final Map<MediaType, int> counts = <MediaType, int>{};
    for (final CollectionItem item in items) {
      if (!_matchesNonTypeFilters(item, filterStatus, tagsMap, lower, lang)) {
        continue;
      }
      counts[item.mediaType] = (counts[item.mediaType] ?? 0) + 1;
    }
    return counts;
  }

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
                    final Set<int> selection =
                        ref.watch(allItemsSelectionProvider);
                    final bool isSelected = selection.contains(item.id);
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
                      mediaType: item.mediaType,
                      typeLabelOverride: item.formatLabel,
                      status: item.status,
                      tagName: tag?.name,
                      tagColor: tag?.color,
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
        final _CollectionGroup group =
            _CollectionGroup(name: name, items: <CollectionItem>[item]);
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
          value: 'move',
          icon: Icons.drive_file_move_outlined,
          label: l.collectionMoveToCollection,
        ),
        contextMenuItem<String>(
          value: 'clone',
          icon: Icons.copy_outlined,
          label: l.collectionCopyToCollection,
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
  _CollectionGroup({required this.name, required this.items});
  final String name;
  final List<CollectionItem> items;
}
